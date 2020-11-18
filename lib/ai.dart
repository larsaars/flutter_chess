import 'dart:isolate';
import 'dart:math';

import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:chess_bot/chess_controller.dart';
import 'package:flutter/material.dart';

import 'chess_board/chess.dart';

class ChessAI {
  //this is the only variable from the other class, with all needed variables for
  //the move generation
  ChessController controller;

  //initialize
  ChessAI(this.controller);

  //the entry point for the new isolate
  void entryPointMoveFinderIsolate(List context) {
    //init the messenger, which sends messages back to the main thread
    final SendPort messenger = context[0];
    //if the received object is a chess game, start the move generation
    //hand over the messenger and the chess
    _findBestMove(context[1], messenger);
  }

  //the exit point, here the isolate is being killed after receiving the move
  void exitPointMoveFinderIsolate(Move move) {
    //in the main thread again, manage the move object
    //make the move, if there is one
    if (move != null) controller.game.make_move(move);
    //now set user can make moves true again
    controller.controller.userCanMakeMoves = true;
    //set loading false
    controller.loadingBotMoves = false;
    //update the board
    controller.update();
  }

  void _findBestMove(Chess chess, SendPort messenger) {
    //the constant values
    const int PLY = 2;
    const double infinity = 9999999.0;
    const Map pieceValues = const {PieceType.PAWN: 1, PieceType.KNIGHT: 3, PieceType.BISHOP: 3.5, PieceType.ROOK: 5, PieceType.QUEEN: 9, PieceType.KING: 10};

    //execute the first depth of max
    List<List> moveEvalPairs = new List<List>();

    int idx = 0;
    for (Move m in chess.generate_moves()) {
      print('new m: $idx');
      chess.move(m);
      double eval =
          alphaBeta(chess, PLY, -infinity, infinity, chess.game.turn, pieceValues);
      moveEvalPairs.add([m, eval]);
      chess.undo();

      idx++;
    }

    double highestEval = -infinity ;
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
  double alphaBeta(Chess c, int depth, double alpha, double beta, Color player, Map pieceValues) {
    if (depth == 0 || c.game_over) {
      return evaluatePosition(c, pieceValues, player);
    }

    // if the computer is the current player
    if (c.game.turn == player) {
      // go through all legal moves
      for (Move m in c.generate_moves()) {
        c.move(m);
        alpha = max(alpha, alphaBeta(c, depth - 1, alpha, beta, player, pieceValues));
        if (beta <= alpha) {
          c.undo();
          break;
        }
        c.undo();
      }
      return alpha;
    } else { // opponent ist he player
      for (Move m in c.generate_moves()) {
        c.move(m);
        beta = min(beta, alphaBeta(c, depth - 1, alpha, beta, player, pieceValues));
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
  double evaluatePosition(Chess c, Map pieceValues, Color player) {
    if (c.game_over) {
      if (c.in_draw) { // draw is a neutral outcome
        return 0.0;
      }
      else { // otherwise must be a mate
        if (c.game.turn == player) {  // avoid mates
          return -9999.99;
        } else {  // go for mating
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
          evaluation += (piece.color == player) ? pieceValues[piece.type] : -pieceValues[piece.type];
        }
      }

      return evaluation;
    }
  }
}
