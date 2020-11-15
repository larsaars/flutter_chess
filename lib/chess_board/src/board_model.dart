import 'dart:ui';

import 'package:chess_bot/chess_board/chess.dart';
import 'package:scoped_model/scoped_model.dart';

import 'chess_board_controller.dart';

typedef void MoveCallback(move);
typedef void CheckMateCallback(int color);
typedef void CheckCallback(int color);
typedef void GameCallback(Chess game);
typedef void ChessBoardControllerCallback(ChessBoardController controller);

class BoardModel extends Model {
  /// The size of the board (The board is a square)
  double size;

  /// Callback for when a move is made
  MoveCallback onMove;

  /// Callback for when a player is checkmated
  CheckMateCallback onCheckMate;

  ///Callback for when a player is in check
  CheckCallback onCheck;

  /// Callback for when the game is a draw (Example: K v K)
  VoidCallback onDraw;

  //the callbacks for returning the controller and game
  GameCallback onGame;
  ChessBoardControllerCallback onChessBoardController;

  /// If the white side of the board is towards the user
  bool whiteSideTowardsUser;

  /// The controller for programmatically making moves
  ChessBoardController chessBoardController;

  /// User moves can be enabled or disabled by this property
  bool enableUserMoves;

  /// Creates a logical game
  Chess game = Chess();

  /// Refreshes board
  void refreshBoard() {
    if (game.in_checkmate) {
      onCheckMate(game.game.turn);
    }
    else if (game.in_draw || game.in_stalemate || game.in_threefold_repetition || game.insufficient_material) {
      onDraw();
    }
    else if (game.in_check) {
      onCheck(game.game.turn);
    }
    notifyListeners();
  }

  BoardModel(
      this.size,
      this.onMove,
      this.onCheckMate,
      this.onCheck,
      this.onDraw,
      this.onGame,
      this.onChessBoardController,
      this.whiteSideTowardsUser,
      this.chessBoardController,
      this.enableUserMoves) {
    chessBoardController?.game = game;
    chessBoardController?.refreshBoard = refreshBoard;
    //return controller and game
    onChessBoardController(chessBoardController);
    onGame(game);
  }
}
