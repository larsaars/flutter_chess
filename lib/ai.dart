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

  static void _findBestMove(Chess chess, SendPort messenger) {
    //the constant values
    const int PLY = 3;
    const double infinity = 9999999.0;
    const Map pieceValues = const {
      PieceType.PAWN: 1,
      PieceType.KNIGHT: 3,
      PieceType.BISHOP: 3.5,
      PieceType.ROOK: 5,
      PieceType.QUEEN: 9,
      PieceType.KING: 10
    };

    //execute the first depth of max
    List<List> moveEvalPairs = new List<List>();

    int idx = 0;
    for (Move m in chess.generate_moves()) {
      print('new m: $idx');
      chess.move(m);
      double eval = _alphaBeta(
          chess, PLY, -infinity, infinity, chess.game.turn, pieceValues);
      moveEvalPairs.add([m, eval]);
      chess.undo();

      idx++;
    }

    double highestEval = -infinity;
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
  static double _alphaBeta(Chess c, int depth, double alpha, double beta,
      Color player, Map pieceValues) {
    if (depth == 0 || c.game_over) {
      return _evaluatePosition(c, pieceValues, player);
    }

    // if the computer is the current player
    if (c.game.turn == player) {
      // go through all legal moves
      for (Move m in c.generate_moves()) {
        c.move(m);
        alpha = max(
            alpha, _alphaBeta(c, depth - 1, alpha, beta, player, pieceValues));
        if (beta <= alpha) {
          c.undo();
          break;
        }
        c.undo();
      }
      return alpha;
    } else {
      // opponent ist he player
      for (Move m in c.generate_moves()) {
        c.move(m);
        beta = min(
            beta, _alphaBeta(c, depth - 1, alpha, beta, player, pieceValues));
        if (beta <= alpha) {
          c.undo();
          break;
        }
        c.undo();
      }
      return beta;
    }
  }

  // simple material based evaluation
  static double _evaluatePosition(Chess c, Map pieceValues, Color player) {
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
              ? pieceValues[piece.type]
              : -pieceValues[piece.type];
        }
      }

      return evaluation;
    }
  }
}
