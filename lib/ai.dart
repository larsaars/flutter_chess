import 'dart:isolate';
import 'dart:math';

import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chess_board/chess.dart';

class ChessAI {
  //the entry point for the new isolate
  static void entryPointMoveFinderIsolate(List context) {
    //init the messenger, which sends messages back to the main thread
    final SendPort messenger = context[0];
    //if the received object is a chess game, start the move generation
    //hand over the messenger and the chess
    _findBestMove(Chess.fromFEN(context[1]), messenger);
  }

  //the random
  static Random _random;

  //the current index for looping
  static int _idx = 0;

  // ignore: non_constant_identifier_names
  static Color _MAX, _MIN;

  //big enough to be infinity in this case
  static const double _INFINITY = 99999999.0, _LARGE = 9999999;

  //the maximum depth, will change according to difficulty level
  // ignore: non_constant_identifier_names
  static int _MAX_DEPTH = 3;

  //the actual method starting the alpha beta pruning
  static void _findBestMove(Chess chess, SendPort messenger) {
    //get the start time
    num startTime = DateTime.now().millisecondsSinceEpoch;

    //set the random
    _random = Random();

    //calc the max depth
    _calcMaxDepth(chess);

    //get the MAX and MIN color
    _MAX = chess.game.turn;
    _MIN = Chess.swap_color(chess.game.turn);

    //execute the first depth of max
    List<List> moveEvalPairs = new List<List>();

    _idx = 0;
    for (Move m in chess.generateMoves()) {
      //perform an alpha beta minimax algorithm in the first gen with max to min
      chess.make_move(m);
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
    var bestMove = bestMoves[_random.nextInt(bestMoves.length)];

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

    //is leaf
    bool gameOver = c.game_over;
    if (depth >= _MAX_DEPTH || gameOver) {
      //update idx
      _idx++;
      //return the end node evaluation
      return _evaluatePosition(c, gameOver, depth);
    }

    // if the computer is the current player (MAX)
    if (whoNow == _MAX) {
      // go through all legal moves
      for (Move m in c.generateMoves()) {
        //move to be able to generate future moves
        c.make_move(m);
        //recursive execute of alpha beta
        alpha = max(alpha, _alphaBeta(c, depth + 1, alpha, beta, _MIN));
        //undo after alpha beta
        c.undo();
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
      for (Move m in c.generateMoves()) {
        //try move
        c.make_move(m);
        //minimize beta from new alpha beta
        beta = min(beta, _alphaBeta(c, depth + 1, alpha, beta, _MAX));
        //undo the moves
        c.undo();
        //cut off here as well
        if (alpha >= beta) {
          break;
        }
      }
      return beta;
    }
  }

  // simple material based evaluation
  static double _evaluatePosition(Chess c, bool gameOver, int depth) {
    if (gameOver) {
      if (c.in_draw) {
        // draw is a neutral outcome
        return 0.0;
      } else {
        // otherwise must be a mate
        if (c.game.turn == _MAX) {
          // avoid mates loss, the deeper the better
          //(earlier is worse)
          return -_LARGE - depth;
        } else {
          // go for the loss of the other one, the deeper the worse
          //(earlier is better)
          return _LARGE - depth;
        }
      }
    } else {
      //the final evaluation to be returned
      double eval = 0.0;
      //eval individually piece value in the current position
      //keep track of pawns in columns (files)
      List<int> maxPawnsInY = List.generate(8, (index) => 0),
          minPawnsInY = List.generate(8, (index) => 0);
      //loop through all squares
      for (int i = Chess.SQUARES_A8; i <= Chess.SQUARES_H1; i++) {
        if ((i & 0x88) != 0) {
          i += 7;
          continue;
        }

        Piece piece = c.game.board[i];
        if (piece != null) {
          //get the x and y from the map
          final x = Chess.file(i), y = Chess.rank(i);
          //evaluate the piece at the position
          eval += _getPieceValue(piece, x, y);
          //add to pawns list
          if (piece.type == PieceType.PAWN) {
            if (piece.color == _MAX)
              maxPawnsInY[y]++;
            else
              minPawnsInY[y]++;
          }
        }
      }

      //duplicate pawns
      /*for (int i = 0; i < 8; i++) {
        int sum = maxPawnsInY[i] + minPawnsInY[i];
        if (maxPawnsInY[i] >= 1 && minPawnsInY[i] >= 1) eval -= 0.05 * sum;
        if (maxPawnsInY[i] >= 1) eval -= 0.06 * maxPawnsInY[i];
        if (minPawnsInY[i] >= 1) eval += 0.06 * minPawnsInY[i];
      }*/

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
      return _easyPieceValues[PieceType.PAWN] +
          (isWhite ? _whitePawnEval[y][x] : _blackPawnEval[y][x]);
    } else if (piece.name == 'r') {
      return _easyPieceValues[PieceType.ROOK] +
          (isWhite ? _whiteRookEval[y][x] : _blackRookEval[y][x]);
    } else if (piece.name == 'n') {
      return _easyPieceValues[PieceType.KNIGHT] + _knightEval[y][x];
    } else if (piece.name == 'b') {
      return _easyPieceValues[PieceType.BISHOP] +
          (isWhite ? _whiteBishopEval[y][x] : _blackBishopEval[y][x]);
    } else if (piece.name == 'q') {
      return _easyPieceValues[PieceType.QUEEN] + _evalQueen[y][x];
    } else if (piece.name == 'k') {
      return _easyPieceValues[PieceType.KING] +
          (isWhite ? _whiteKingEval[y][x] : _blackKingEval[y][x]);
    }

    return 0;
  }

  static void _calcMaxDepth(Chess chess) {
    //calc the expected time expenditure in a sub function
    num expectedTimeExpenditure(int depth) {
      //always generate the first move if possible, then check how many moves there are
      num prod = 1;
      void addNumRecursive(Chess root, int thisDepth) {
        //check for not hitting too deep
        if(thisDepth > depth)
          return;
        //list of moves
        List moves = root.generateMoves();
        if(moves.length > 0) {
          //create the product
          prod *= moves.length;
          //make one of them randomly, always selecting 0 move could be wrong
          root.make_move(moves[_random.nextInt(moves.length)]);
          //call this one recursive
          addNumRecursive(root, thisDepth + 1);
          //then undo it
          root.undo();
        }
      }
      //call the recursive counter
      addNumRecursive(chess, 1);
      //calc prod * 3/4 because of pruning
      return prod * 0.75;
    }
    //WE DON'T USE THE SHANNON NUMBER
    //first calculate the number of pieces on the board,
    //from that calculate the time expenditure for alpha beta pruning:
    //b^(3/4)
    //based on that then decide how deep we want to go with alpha beta pruning
    //depth, pm
    //minimizing loop
    bool changed = false;
    for(int depth = _MAX_CALC_DEPTH; depth >= _MIN_CALC_DEPTH; depth--) {
      num exp = expectedTimeExpenditure(depth);
      print('expected: $exp');
      if(exp < _MAX_CALC_ESTIMATED_MOVES) {
        _MAX_DEPTH = depth;
        changed = true;
        break;
      }
    }

    if(!changed)
      _MAX_DEPTH = _MIN_CALC_DEPTH;

    print('set max depth to $_MAX_DEPTH');
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

  static const _MIN_CALC_DEPTH = 3, _MAX_CALC_DEPTH = 6, _MAX_CALC_ESTIMATED_MOVES = 50000;
}
