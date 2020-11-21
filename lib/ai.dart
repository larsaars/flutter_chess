import 'dart:isolate';
import 'dart:math';

import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:flutter/material.dart';

import 'chess_board/chess.dart';

class ChessAI {
  //the entry point for the new isolate
  static void entryPointMoveFinderIsolate(List context) {
    //init the messenger, which sends messages back to the main thread
    final SendPort messenger = context[0];
    //set the difficulty
    _difficulty = context[2];
    //if the received object is a chess game, start the move generation
    //hand over the messenger and the chess
    _findBestMove(Chess.fromFEN(context[1]), messenger);
  }

  //the current index for looping
  static int _idx = 0;

  // ignore: non_constant_identifier_names
  static Color _MAX, _MIN;

  //big enough to be infinity in this case
  static const double _INFINITY = 99999999.0;

  //the maximum depth, will change according to difficulty level
  // ignore: non_constant_identifier_names
  static int _MAX_DEPTH = 3;

  //the difficulty level
  //0 - easy
  //1 - medium
  //2 - normal
  //3 - hard
  static int _difficulty = 0;

  //the actual method starting the alpha beta pruning
  static void _findBestMove(Chess chess, SendPort messenger) {
    //get the start time
    num startTime = DateTime.now().millisecondsSinceEpoch;
    //set the the depth from the difficulty
    if (_difficulty == 0)
      _MAX_DEPTH = 2;

    //get the MAX and MIN color
    _MAX = chess.game.turn;
    _MIN = (chess.game.turn == Color.BLACK) ? Color.WHITE : Color.BLACK;

    //execute the first depth of max
    List<List> moveEvalPairs = new List<List>();

    _idx = 0;
    for (Move m in chess.generate_moves()) {
      //perform an alpha beta minimax algorithm in the first gen with max to min
      chess.move(m);
      double eval = _alphaBeta(chess, 1, -_INFINITY, _INFINITY, _MIN);
      moveEvalPairs.add([m, eval]);
      chess.undo();
      //print the progress
      print('m$_idx with $eval');
      //send a progress via send function
      messenger.send(_idx);
    }

    //determine the highest eval score
    double highestEval = -_INFINITY;

    for (List pair in moveEvalPairs) {
      if (pair[1] > highestEval) {
        highestEval = pair[1];
      }
    }

    var bestMoves = [];
    for (List pair in moveEvalPairs) {
      if (pair[1] == highestEval) bestMoves.add(pair[0]);
    }

    //if there is no move, send null
    if (bestMoves.length == 0) {
      messenger.send('no_moves');
      return;
    }

    //random one of the same scores
    var bestMove = bestMoves[Random().nextInt(bestMoves.length)];

    //print
    print('selected: $bestMove with $highestEval');

    //get the end time
    num endTime = DateTime.now().millisecondsSinceEpoch;

    //send the best move up again
    //also return as second argument the time needed
    messenger.send([bestMove, (endTime - startTime)]);
  }

  // implements a simple alpha beta algorithm
  static double _alphaBeta(
      Chess c, int depth, double alpha, double beta, Color whoNow) {
    //update idx
    _idx++;

    //is leaf
    if (depth >= _MAX_DEPTH || c.game_over) {
      return _evaluatePosition(c, depth);
    }

    // if the computer is the current player (MAX)
    if (whoNow == _MAX) {
      // go through all legal moves
      for (Move m in c.generate_moves()) {
        //move to be able to generate future moves
        c.make_move(m);
        //recursive execute of alpha beta
        alpha = max(alpha, _alphaBeta(c, depth + 1, alpha, beta, _MIN));
        //undo after alpha beta
        c.undo_move();
        //cut of branches
        if (alpha >= beta) {
          break;
        }
      }
      //return the alpha
      return alpha;
      //the same of min
    } else {
      // opponent ist he player (MIN)
      for (Move m in c.generate_moves()) {
        //try move
        c.move(m);
        //minimize beta from new alpha beta
        beta = min(beta, _alphaBeta(c, depth + 1, alpha, beta, _MAX));
        //undo the moves
        c.undo_move();
        //cut off here as well
        if (alpha >= beta) {
          break;
        }
      }
      return beta;
    }
  }

  // simple material based evaluation
  static double _evaluatePosition(Chess c, int depth) {
    if (c.game_over) {
      if (c.in_draw) {
        // draw is a neutral outcome
        return 0.0;
      } else {
        // otherwise must be a mate
        if (c.game.turn == _MAX) {
          // avoid mates loss, the deeper the better
          //(earlier is worse)
          return -_INFINITY - depth;
        } else {
          // go for the loss of the other one, the deeper the worse
          //(earlier is better)
          return _INFINITY - depth;
        }
      }
    } else {
      //the final evaluation to be returned
      double eval = 0.0;
      //if the difficulty is easy, eval material
      if (_difficulty == 0 || _difficulty == 1) {
        for (int i = Chess.SQUARES_A8; i <= Chess.SQUARES_H1; i++) {
          if ((i & 0x88) != 0) {
            i += 7;
            continue;
          }

          Piece piece = c.game.board[i];
          if (piece != null) {
            eval += (piece.color == _MAX)
                ? _easyPieceValues[piece.type]
                : -_easyPieceValues[piece.type];
          }
        }
        //else eval individually piece value in the current position
      } else {
        //keep track of pawns in columns (files)
        List<int> maxPawnsInFiles = List.generate(8, (index) => 0),
            minPawnsInFiles = List.generate(8, (index) => 0);
        //loop through all squares
        for (int i = Chess.SQUARES_A8; i <= Chess.SQUARES_H1; i++) {
          if ((i & 0x88) != 0) {
            i += 7;
            continue;
          }

          Piece piece = c.game.board[i];
          if (piece != null) {
            //get the x and y from the map
            final xAndY = _COORDINATES_SQUARES[i];
            //evaluate the piece at the position
            eval += _getPieceValue(piece, xAndY[0], xAndY[1]);
            //add to pawns list
            if(piece.type == PieceType.PAWN && _difficulty == 3) {
              if(piece.color == _MAX) maxPawnsInFiles[xAndY[1]]++;
              else minPawnsInFiles[xAndY[1]]++;
            }
          }
        }

        if(_difficulty == 3) {
          for (int i = 0; i < 8; i++) {
            int sum = maxPawnsInFiles[i] + minPawnsInFiles[i];
            if (maxPawnsInFiles[i] >= 1 && minPawnsInFiles[i] >= 1)
              eval -= 0.05 * sum;
            if (maxPawnsInFiles[i] >= 1)
              eval -= 0.06 * maxPawnsInFiles[i];
            if (minPawnsInFiles[i] >= 1)
              eval += 0.06 * minPawnsInFiles[i];
          }

          if(c.king_attacked(_MIN))
            eval += 50;
          else if(c.king_attacked(_MAX))
            eval += 50;
        }
      }

      return eval;
    }
  }

  static double _getPieceValue(Piece piece, int x, int y) {
    if (piece == null) {
      return 0;
    }

    var absoluteValue =
        _getAbsoluteValue(piece.type, piece.color == Color.WHITE, x, y);

    if (piece.color == _MAX) {
      return absoluteValue;
    } else {
      return -absoluteValue;
    }
  }

  static double _getAbsoluteValue(PieceType piece, bool isWhite, int x, int y) {
    if (piece.name == 'p') {
      return _easyPieceValues[PieceType.PAWN] + (isWhite ? _whitePawnEval[y][x] : _blackPawnEval[y][x]);
    } else if (piece.name == 'r') {
      return _easyPieceValues[PieceType.ROOK] + (isWhite ? _whiteRookEval[y][x] : _blackRookEval[y][x]);
    } else if (piece.name == 'n') {
      return _easyPieceValues[PieceType.KNIGHT] + _knightEval[y][x];
    } else if (piece.name == 'b') {
      return _easyPieceValues[PieceType.BISHOP] + (isWhite ? _whiteBishopEval[y][x] : _blackBishopEval[y][x]);
    } else if (piece.name == 'q') {
      return _easyPieceValues[PieceType.QUEEN] + _evalQueen[y][x];
    } else if (piece.name == 'k') {
      return _easyPieceValues[PieceType.KING] + (isWhite ? _whiteKingEval[y][x] : _blackKingEval[y][x]);
    }

    return 0;
  }

  //the piece values
  static const Map _easyPieceValues = const {
    PieceType.PAWN: 10,
    PieceType.KNIGHT: 32,
    PieceType.BISHOP: 33,
    PieceType.ROOK: 50,
    PieceType.QUEEN: 90,
    PieceType.KING: 20000
  };

  static const Map _COORDINATES_SQUARES = const {
    0: [0, 7],
    1: [1, 7],
    2: [2, 7],
    3: [3, 7],
    4: [4, 7],
    5: [5, 7],
    6: [6, 7],
    7: [7, 7],
    16: [0, 6],
    17: [1, 6],
    18: [2, 6],
    19: [3, 6],
    20: [4, 6],
    21: [5, 6],
    22: [6, 6],
    23: [7, 6],
    32: [0, 5],
    33: [1, 5],
    34: [2, 5],
    35: [3, 5],
    36: [4, 5],
    37: [5, 5],
    38: [6, 5],
    39: [7, 5],
    48: [0, 4],
    49: [1, 4],
    50: [2, 4],
    51: [3, 4],
    52: [4, 4],
    53: [5, 4],
    54: [6, 4],
    55: [7, 4],
    64: [0, 3],
    65: [1, 3],
    66: [2, 3],
    67: [3, 3],
    68: [4, 3],
    69: [5, 3],
    70: [6, 3],
    71: [7, 3],
    80: [0, 2],
    81: [1, 2],
    82: [2, 2],
    83: [3, 2],
    84: [4, 2],
    85: [5, 2],
    86: [6, 2],
    87: [7, 2],
    96: [0, 1],
    97: [1, 1],
    98: [2, 1],
    99: [3, 1],
    100: [4, 1],
    101: [5, 1],
    102: [6, 1],
    103: [7, 1],
    112: [0, 0],
    113: [1, 0],
    114: [2, 0],
    115: [3, 0],
    116: [4, 0],
    117: [5, 0],
    118: [6, 0],
    119: [7, 0]
  };

  static List _reverseList(List list) {
    return [...list].reversed.toList();
  }

  static const _whitePawnEval = [
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0],
    [1.0, 1.0, 2.0, 3.0, 3.0, 2.0, 1.0, 1.0],
    [0.5, 0.5, 1.0, 2.5, 2.5, 1.0, 0.5, 0.5],
    [0.0, 0.0, 0.0, 2.0, 2.0, 0.0, 0.0, 0.0],
    [0.5, -0.5, -1.0, 0.0, 0.0, -1.0, -0.5, 0.5],
    [0.5, 1.0, 1.0, -2.0, -2.0, 1.0, 1.0, 0.5],
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  ];

  static final _blackPawnEval = _reverseList(_whitePawnEval);

  static const _knightEval = [
    [-5.0, -4.0, -3.0, -3.0, -3.0, -3.0, -4.0, -5.0],
    [-4.0, -2.0, 0.0, 0.0, 0.0, 0.0, -2.0, -4.0],
    [-3.0, 0.0, 1.0, 1.5, 1.5, 1.0, 0.0, -3.0],
    [-3.0, 0.5, 1.5, 2.0, 2.0, 1.5, 0.5, -3.0],
    [-3.0, 0.0, 1.5, 2.0, 2.0, 1.5, 0.0, -3.0],
    [-3.0, 0.5, 1.0, 1.5, 1.5, 1.0, 0.5, -3.0],
    [-4.0, -2.0, 0.0, 0.5, 0.5, 0.0, -2.0, -4.0],
    [-5.0, -4.0, -3.0, -3.0, -3.0, -3.0, -4.0, -5.0]
  ];

  static const _whiteBishopEval = [
    [-2.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -2.0],
    [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0],
    [-1.0, 0.0, 0.5, 1.0, 1.0, 0.5, 0.0, -1.0],
    [-1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, -1.0],
    [-1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, -1.0],
    [-1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, -1.0],
    [-1.0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.5, -1.0],
    [-2.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -2.0]
  ];

  static final _blackBishopEval = _reverseList(_whiteBishopEval);

  static const _whiteRookEval = [
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.5],
    [-0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.5],
    [-0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.5],
    [-0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.5],
    [-0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.5],
    [-0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.5],
    [0.0, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0, 0.0]
  ];

  static final _blackRookEval = _reverseList(_whiteRookEval);

  static const _evalQueen = [
    [-2.0, -1.0, -1.0, -0.5, -0.5, -1.0, -1.0, -2.0],
    [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0],
    [-1.0, 0.0, 0.5, 0.5, 0.5, 0.5, 0.0, -1.0],
    [-0.5, 0.0, 0.5, 0.5, 0.5, 0.5, 0.0, -0.5],
    [0.0, 0.0, 0.5, 0.5, 0.5, 0.5, 0.0, -0.5],
    [-1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.0, -1.0],
    [-1.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, -1.0],
    [-2.0, -1.0, -1.0, -0.5, -0.5, -1.0, -1.0, -2.0]
  ];

  static const _whiteKingEval = [
    [-3.0, -4.0, -4.0, -5.0, -5.0, -4.0, -4.0, -3.0],
    [-3.0, -4.0, -4.0, -5.0, -5.0, -4.0, -4.0, -3.0],
    [-3.0, -4.0, -4.0, -5.0, -5.0, -4.0, -4.0, -3.0],
    [-3.0, -4.0, -4.0, -5.0, -5.0, -4.0, -4.0, -3.0],
    [-2.0, -3.0, -3.0, -4.0, -4.0, -3.0, -3.0, -2.0],
    [-1.0, -2.0, -2.0, -2.0, -2.0, -2.0, -2.0, -1.0],
    [2.0, 2.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0],
    [2.0, 3.0, 1.0, 0.0, 0.0, 1.0, 3.0, 2.0]
  ];

  static final _blackKingEval = _reverseList(_whiteKingEval);
}
