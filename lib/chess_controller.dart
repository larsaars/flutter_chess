import 'dart:io';

import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart' as chess;
import 'package:chess_bot/main.dart';
import 'package:chess_bot/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chess_board/src/chess_board_controller.dart';

class ChessController {
  ChessBoardController controller;
  Chess game;
  BuildContext context;
  bool _showing = false;
  bool hasReadGameState = false;

  ChessController(this.context);

  void onMove(move) {
    print('onMove: $move');
    //the piece
    chess.Piece piece = game.get(move['square']);

  }

  void onDraw() {
    print('onDraw');

  }

  void onCheckMate(color) async {
    if(_showing)
      return;

    //determine winner and loser
    var winner = color == PieceColor.White ? strings.black : strings.white;
    var loser = color == PieceColor.White ? strings.white : strings.black;
    //show dialog
    (await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
              child: Text(
                  strings.checkmate
              )
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children : <Widget>[
              Expanded(
                child: Text(
                  strings.check_mate_desc(loser, winner),
                  textAlign: TextAlign.center,
                  style: TextStyle(

                    color: Colors.red,
                  ),
                ),
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: Text(strings.cancel),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            FlatButton(
                child: Text(strings.replay),
                onPressed: () {
                  Navigator.of(context).pop();
                })
          ],
        );
      },
    )).then((value) => _showing = false);
  }

  void onCheck(color) {
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

      hasReadGameState = true;

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
