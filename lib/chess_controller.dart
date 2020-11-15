import 'dart:convert';
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

  void onReloadLastGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.json');
    if(await saveFile.exists()) {
      String json = await saveFile.readAsString();
      print('json: $json');
      Map<String, dynamic> jsonMap = jsonDecode(json);
      //set game object
      game.game = chess.Game.fromJson(jsonMap);
      //after sync reload game view
      controller.refreshBoard();
    }
  }

  void onSaveGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.json');
    if(!await saveFile.exists())
      await saveFile.create();
    String jsonString = jsonEncode(game.game.toJson());
    print('json: $jsonString');
    await saveFile.writeAsString(jsonString);
  }

  void resetBoard() {

  }
}
