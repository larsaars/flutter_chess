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

  Future<Chess> loadOldGame() async {
    final root = await rootDir;
    final saveFile = File('$root/game.fen');
    if(await saveFile.exists()) {
      String json = await saveFile.readAsString();
      if(json.length < 15)
        return null;
      Map<String, dynamic> jsonMap = jsonDecode(json);

      /*int b = 0, w = 0, n = 0;
      for(var piece in game.game.board) {
        if(piece == null)
          n++;
        else if(piece.color.value == 1)
          b++;
        else if(piece.color.value == 0)
          w++;
      }

      print('comp: w=$w; b=$b; n=$n');*/

      print('game loaded');

      return chess.Game.fromJson(jsonMap);
    }

    return null;
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
