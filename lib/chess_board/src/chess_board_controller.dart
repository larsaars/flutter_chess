
import '../chess2.dart';

enum PieceColor {
  White,
  Black,
}

/// Controller for programmatically controlling the board
class ChessBoardController {
  /// The game attached to the controller
  Chess2 game;

  /// Function from the ScopedModel to refresh board
  Function refreshBoard;

  bool userCanMakeMoves = true;


  /// Makes move and promotes pawn to piece (from is a square like d4, to is also a square like e3, pieceToPromoteTo is a String like "Q".
  /// pieceToPromoteTo String will be changed to enum in a future update and this method will be deprecated in the future
  void makeMoveWithPromotion(String from, String to, String pieceToPromoteTo) {
    game?.moveIfFound({"from": from, "to": to, "promotion": pieceToPromoteTo});
    refreshBoard == null ? this._throwNotAttachedException() : refreshBoard();
  }

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

  /// Exception when a controller is not attached to a board
  void _throwNotAttachedException() {
    throw Exception("Controller not attached to a ChessBoard widget!");
  }
}
