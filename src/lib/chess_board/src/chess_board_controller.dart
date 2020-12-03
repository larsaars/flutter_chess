import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart' as chess;

import 'chess_sub.dart';

enum PieceColor {
  White,
  Black,
}

/// Controller for programmatically controlling the board
class ChessBoardController {
  /// The game attached to the controller
  Chess game;

  /// Function from the ScopedModel to refresh board
  Function refreshBoard;

  bool userCanMakeMoves = true;

  /// Resets square
  void resetBoard() {
    game?.reset();
    refreshBoard == null ? this._throwNotAttachedException() : refreshBoard();
  }

  /// Clears board
  void clearBoard() {
    game?.clear();
    refreshBoard == null ? this._throwNotAttachedException() : refreshBoard();
  }

  /// Puts piece on a square
  void putPiece(PieceType piece, String square, PieceColor color) {
    game?.put(_getPiece(piece, color), square);
    refreshBoard == null ? this._throwNotAttachedException() : refreshBoard();
  }

  /// Exception when a controller is not attached to a board
  void _throwNotAttachedException() {
    throw Exception("Controller not attached to a ChessBoard widget!");
  }

  /// Gets respective piece
  chess.Piece _getPiece(PieceType piece, PieceColor color) {
    chess.Color _getColor(PieceColor color) {
      return color == PieceColor.White ? chess.Color.WHITE : chess.Color.BLACK;
    }

    switch (piece) {
      case PieceType.BISHOP:
        return chess.Piece(chess.PieceType.BISHOP, _getColor(color));
      case PieceType.QUEEN:
        return chess.Piece(chess.PieceType.QUEEN, _getColor(color));
      case PieceType.KING:
        return chess.Piece(chess.PieceType.KING, _getColor(color));
      case PieceType.KNIGHT:
        return chess.Piece(chess.PieceType.KNIGHT, _getColor(color));
      case PieceType.PAWN:
        return chess.Piece(chess.PieceType.PAWN, _getColor(color));
      case PieceType.ROOK:
        return chess.Piece(chess.PieceType.ROOK, _getColor(color));
    }

    return chess.Piece(chess.PieceType.PAWN, chess.Color.WHITE);
  }
}
