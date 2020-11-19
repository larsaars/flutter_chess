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
    //if the received object is a chess game, start the move generation
    //hand over the messenger and the chess
    _findBestMove(Chess.fromFEN(context[1]), messenger);
  }

  static int idx = 0;

  // ignore: non_constant_identifier_names
  static Color MAX, MIN;

  //the piece values
  static const Map _pieceValues = const {
    PieceType.PAWN: 1,
    PieceType.KNIGHT: 3,
    PieceType.BISHOP: 3.5,
    PieceType.ROOK: 5,
    PieceType.QUEEN: 9,
    PieceType.KING: 10
  };

  static void _findBestMove(Chess chess, SendPort messenger) {
    //the constant values
    const int MAX_DEPTH = 3;
    const double INFINITY = 9999999.0;

    print(Isolate.current.debugName);

    //get the MAX and MIN color
    MAX = chess.game.turn;
    MIN = (chess.game.turn == Color.BLACK) ? Color.WHITE : Color.BLACK;

    //execute the first depth of max
    List<List> moveEvalPairs = new List<List>();

    idx = 3;
    _alphaBeta(chess, MAX_DEPTH, -INFINITY, INFINITY, MAX);
    for (Move m in chess.generate_moves()) {
      chess.move(m);
      double eval = _alphaBeta(chess, MAX_DEPTH, -INFINITY, INFINITY, MIN);
      moveEvalPairs.add([m, eval]);
      chess.undo();
      print('m$idx with $eval (eval)');
    }

    double highestEval = -INFINITY;
    Move bestMove;

    for (List l in moveEvalPairs) {
      if (l[1] > highestEval) {
        highestEval = l[1];
        bestMove = l[0];
      }
    }

    //send the best move up again, even if it is null
    messenger.send(bestMove);
  }

  // implements a simple alpha beta algorithm
  static double _alphaBeta(
      Chess c, int depth, double alpha, double beta, Color whoNow) {
    idx++;

    if (depth <= 0 || c.game_over) {
      return _evaluatePosition(c, whoNow);
    }

    // if the computer is the current player (MAX)
    if (whoNow == MAX) {
      // go through all legal moves
      for (Move m in c.generate_moves()) {
        c.move(m);
        alpha = max(alpha, _alphaBeta(c, depth - 1, alpha, beta, MIN)[0]);
        c.undo();
        if (alpha >= beta) {
          break;
        }
      }
      return alpha;
    } else {
      // opponent ist he player (MIN)
      for (Move m in c.generate_moves()) {
        c.move(m);
        beta = min(beta, _alphaBeta(c, depth - 1, alpha, beta, MAX));
        if (alpha >= beta) {
          c.undo();
          break;
        }
        c.undo();
      }
      return beta;
    }
  }

  // simple material based evaluation
  static double _evaluatePosition(Chess c, Color player) {
    if (c.game_over) {
      if (c.in_draw) {
        // draw is a neutral outcome
        return 0.0;
      } else {
        // otherwise must be a mate
        if (c.game.turn == player) {
          // avoid mates
          return -9999.99;
        } else {
          // go for mating
          return 9999.99;
        }
      }
    } else {
      // otherwise do a simple material evaluation
      double evaluation = 0.0;
      var sq_color = 0;
      for (int i = Chess.SQUARES_A8; i <= Chess.SQUARES_H1; i++) {
        sq_color = (sq_color + 1) % 2;
        if ((i & 0x88) != 0) {
          i += 7;
          continue;
        }

        Piece piece = c.game.board[i];
        if (piece != null) {
          evaluation += (piece.color == player)
              ? _pieceValues[piece.type]
              : -_pieceValues[piece.type];
        }
      }

      return evaluation;
    }
  }
}
