import 'dart:ui';

import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart' as chess;
import 'package:scoped_model/scoped_model.dart';

import 'chess_board_controller.dart';

typedef void MoveCallback(move);
typedef void CheckMateCallback(PieceColor color);
typedef void CheckCallback(PieceColor color);
typedef void GameCallback();

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

  /// If the white side of the board is towards the user
  bool whiteSideTowardsUser;

  /// The controller for programmatically making moves
  ChessBoardController chessBoardController;

  /// Creates a logical game
  Chess game;

  String fen;

  /// Refreshes board
  void refreshBoard() {
    bool generatedMovesLen0 = game.moveCountIsZero();
    if (game.inCheckmate(generatedMovesLen0)) {
      onCheckMate(game.game.turn == chess.Color.WHITE ? PieceColor.White : PieceColor.Black);
    }
    else if (game.inDraw(generatedMovesLen0) || game.inStalemate(generatedMovesLen0) || game.in_threefold_repetition() || game.insufficientMaterial()) {
      onDraw();
    }
    else if (game.in_check()) {
      onCheck(game.game.turn == chess.Color.WHITE ? PieceColor.White : PieceColor.Black);
    }
    notifyListeners();
  }

  BoardModel(
      this.size,
      this.onMove,
      this.onCheckMate,
      this.onCheck,
      this.onDraw,
      this.whiteSideTowardsUser,
      this.chessBoardController,
      bool userCanMakeMoves,
      this.game) {
    chessBoardController?.game = game;
    chessBoardController?.refreshBoard = refreshBoard;
    chessBoardController?.userCanMakeMoves = userCanMakeMoves;
  }
}
