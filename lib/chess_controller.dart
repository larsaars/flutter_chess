import 'dart:io';

import 'package:chess_bot/chess_board/chess.dart' as chess;
import 'package:chess_bot/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chess_board/src/chess_board_controller.dart';

class ChessController {
  ChessBoardController controller;
  chess.Chess game;
  BuildContext context;

  ChessController(this.context);

  void onMove(move) {
    print('onMove: $move');
    //the piece
    chess.Piece piece = game.get(move['square']);
  }

  void onDraw() {
    print('onDraw');
  }

  void onCheckMate(color) {
    print('onCheckMate: $color');
  }

  void onCheck() {
    print('onCheck');
  }

  void onReloadLastGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.pgn');
    if(await saveFile.exists())
      controller.loadPGN(await saveFile.readAsString());
  }

  void onSaveGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.pgn');
    if(!await saveFile.exists())
      await saveFile.create();
    print('pgn save: ' + game.pgn());
    saveFile.writeAsString(game.pgn());
  }

  void resetBoard() {

  }
}
