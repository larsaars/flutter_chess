import 'dart:io';

import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/flutter_chess_board.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart' as chess;
import 'package:chess_bot/main.dart';
import 'package:chess_bot/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chess_board/src/chess_board_controller.dart';

class ChessController {
  ChessBoardController controller = ChessBoardController();
  Chess game;
  BuildContext context;

  BoardType boardType = BoardType.darkBrown;
  bool whiteSideTowardsUser = true;

  ChessController(this.context);

  //update the views
  var update;

  void onMove(move) {
    //update text
    if (update != null) update();
    print('onMove: $move');
    //the piece
    chess.Piece piece = game.get(move['square']);
  }

  void onDraw() {
    //show the dialog
    showTextDialog(strings.draw, strings.draw_desc, strings.replay, resetBoard);
  }

  void onCheckMate(color) {
    //determine winner and loser
    var winner = color == PieceColor.White ? strings.black : strings.white;
    var loser = color == PieceColor.White ? strings.white : strings.black;
    //show the dialog
    showTextDialog(strings.checkmate, strings.check_mate_desc(loser, winner),
        strings.replay, resetBoard);
  }

  void onCheck(color) {
    print('onCheck');
  }

  Future<void> loadOldGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.fen');
    if (await saveFile.exists()) {
      String fen = await saveFile.readAsString();
      if (fen.length < 2) {
        game = Chess();
        return;
      }

      print('game loaded');

      game = Chess.fromFEN(fen);
    } else
      game = Chess();
  }

  void saveOldGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.fen');
    if (!await saveFile.exists()) await saveFile.create();
    await saveFile.writeAsString(game.generate_fen());

    print('game saved');
  }

  void resetBoard() {
    showTextDialog(
        strings.replay, strings.replay_desc, strings.ok, controller.resetBoard);
  }

  void undo() {
    game.undo_move() != null
        ? controller.refreshBoard()
        : showTextDialog(strings.undo, strings.undo_impossible, null, null);
  }

  void switchColors() {
    whiteSideTowardsUser = !whiteSideTowardsUser;
    update();
  }
}
