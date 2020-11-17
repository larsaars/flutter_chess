import 'dart:io';

import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/flutter_chess_board.dart';
import 'package:chess_bot/main.dart';
import 'package:chess_bot/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chess_board/src/chess_board_controller.dart';

class ChessController {
  ChessBoardController controller = ChessBoardController();
  Chess game;
  BuildContext context;

  bool whiteSideTowardsUser = true, _showing = false;

  ChessController(this.context);

  //update the views
  var update;

  void onMove(move) {
    //update text
    if (update != null) update();
    print('onMove: $move');
    //the piece
    //if(move[])
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

  void changeBoardStyle() async {
    if (_showing) return;

    _showing = true;

    await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "changeBoardStyle",
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, a1, a2, widget) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: AlertDialog(
                  title: Text(strings.choose_style),
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              InkWell(
                                child: Image.asset(
                                  "res/chess_board/brown_board.png",
                                  height: 100,
                                  width: 100,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop('b');
                                },
                              ),
                              InkWell(
                                child: Image.asset(
                                  "res/chess_board/dark_brown_board.png",
                                  height: 100,
                                  width: 100,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop('d');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              InkWell(
                                child: Image.asset(
                                  "res/chess_board/green_board.png",
                                  height: 100,
                                  width: 100,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop('g');
                                },
                              ),
                              InkWell(
                                child: Image.asset(
                                  "res/chess_board/orange_board.png",
                                  height: 100,
                                  width: 100,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop('o');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )));
      },
    ).then((value) {
      //save the value to the prefs
      prefs
          .setString("board_style", value ?? prefs.getString("board_style"))
          .then((value) => update());
      //then set the board image and refresh the view
      //set showing false
      _showing = false;
    });
  }

  void findMove() {
    //set player can play
  }
}
