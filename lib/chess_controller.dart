import 'dart:io';

import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart' as chess;
import 'package:chess_bot/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chess_board/src/chess_board_controller.dart';

class ChessController {
  ChessBoardController controller;
  Chess game;
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

  Future<String> loadOldGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.fen');
    if(await saveFile.exists()) {
      String fen = await saveFile.readAsString();
      if(fen.length < 2)
        return Chess.DEFAULT_POSITION;

      print('game loaded');

      return fen;
    }

    return Chess.DEFAULT_POSITION;
  }

  void saveOldGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.fen');
    if(!await saveFile.exists())
      await saveFile.create();
    await saveFile.writeAsString(game.generate_fen());

    print('game saved');
  }

  void resetBoard() {

  }
}
