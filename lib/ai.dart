import 'dart:math';

import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:chess_bot/chess_controller.dart';

import 'chess_board/chess.dart';

class ChessAI {
  ChessController controller;
  Chess chess;

  ChessAI(this.controller) {
    chess = controller.game;
  }

  get turn {
    return chess.game.turn;
  }

  Future<Move> find() async {
    const int PLY = 2;
    Color toPlay = chess.game.turn;
    List<List> moveEvalPairs = new List<List>();

    for (Move m in chess.moves({
      "asObjects": true
    })) {
      chess.move(m);
      double eval = alphaBeta(new Chess.fromFEN(chess.fen), PLY, -9999999.0, 9999999.0, toPlay);
      moveEvalPairs.add([m, eval]);
      chess.undo();
    }

    double highestEval = -9999999.0;
    Move bestMove = null;

    for (List l in moveEvalPairs) {
      if (l[1] > highestEval) {
        highestEval = l[1];
        bestMove = l[0];
      }
    }

    return bestMove;
  }

// implements a simple alpha beta algorithm
  double alphaBeta(Chess c, int depth, double alpha, double beta, Color player) {
    if (depth == 0 || c.game_over) {
      return evaluatePosition(c, player);
    }

    // if the computer is the current player
    if (turn == player) {
      // go through all legal moves
      for (Move m in c.moves({
        "asObjects": true
      })) {
        c.move(m);
        alpha = max(alpha, alphaBeta(c, depth - 1, alpha, beta, player));
        if (beta <= alpha) {
          c.undo();
          break;
        }
        c.undo();
      }
      return alpha;
    } else { // opponent ist he player
      for (Move m in c.moves({
        "asObjects": true
      })) {
        c.move(m);
        beta = min(beta, alphaBeta(c, depth - 1, alpha, beta, player));
        if (beta <= alpha) {
          c.undo();
          break;
        }
        c.undo();
      }
      return beta;
    }
  }

  static const Map pieceValues = const {PieceType.PAWN: 1, PieceType.KNIGHT: 3, PieceType.BISHOP: 3.5, PieceType.ROOK: 5, PieceType.QUEEN: 9, PieceType.KING: 10};

  // simple material based evaluation
  double evaluatePosition(Chess c, Color player) {
    if (c.game_over) {
      if (c.in_draw) { // draw is a neutral outcome
        return 0.0;
      }
      else { // otherwise must be a mate
        if (turn == player) {  // avoid mates
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

        Piece piece = chess.game.board[i];
        if (piece != null) {
          evaluation += (piece.color == player) ? pieceValues[piece.type] : -pieceValues[piece.type];
        }
      }

      return evaluation;
    }
  }
}