import 'dart:math';

import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:chess_bot/chess_controller.dart';

import 'chess_board/chess.dart';

class ChessAI {
  ChessController controller;
  Chess chess;
  Color turn;

  static const double _infinity = 9999999.0;

  ChessAI(this.controller) {
    chess = controller.game;
  }

  Future<Move> find() async {
    const int PLY = 2;
    turn = chess.game.turn;
    List<List> moveEvalPairs = new List<List>();

    for (Move m in chess.generate_moves()) {
      chess.move(m);
      double eval =
          alphaBeta(Chess.fromFEN(chess.fen), PLY, -_infinity, _infinity, turn);
      moveEvalPairs.add([m, eval]);
      chess.undo();
    }

    double highestEval = -_infinity ;
    Move bestMove;

    for (List l in moveEvalPairs) {
      if (l[1] > highestEval) {
        highestEval = l[1];
        bestMove = l[0];
      }
    }

    return bestMove;
  }

  // implements a simple alpha beta algorithm
  double alphaBeta(
      Chess c, int depth, double alpha, double beta, Color player) {
    if (depth == 0 || c.game_over) {
      return evaluatePosition(c, player);
    }

    // if the computer is the current player (MAX)
    if (turn == player) {
      // go through all legal moves
      for (Move m in c.generate_moves()) {
        c.move(m);
        alpha = max(alpha, alphaBeta(c, depth - 1, alpha, beta, player));
        if (alpha >= beta) {
          c.undo();
          break;
        }
        c.undo();
      }
      return alpha;
    } else {
      // opponent ist the player (MIN)
      for (Move m in c.generate_moves()) {
        c.move(m);
        beta = min(beta, alphaBeta(c, depth - 1, alpha, beta, player));
        if (alpha >= beta) {
          c.undo();
          break;
        }

        c.undo();
      }

      return beta;
    }
  }

  static const Map pieceValues = const {
    PieceType.PAWN: 1,
    PieceType.KNIGHT: 3,
    PieceType.BISHOP: 3.2,
    PieceType.ROOK: 5,
    PieceType.QUEEN: 9,
    PieceType.KING: 90,
  };

  // simple material based evaluation
  double evaluatePosition(Chess c, Color player) {
    if (c.game_over) {
      if (c.in_draw) {
        // draw is a neutral outcome
        return 0.0;
      } else {
        // otherwise must be a mate
        if (turn == player) {
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

        Piece piece = chess.game.board[i];
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
