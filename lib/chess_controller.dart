import 'dart:io';
import 'dart:isolate';

import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/flutter_chess_board.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:chess_bot/main.dart';
import 'package:chess_bot/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ai.dart';
import 'chess_board/src/chess_board_controller.dart';

class ChessController {
  ChessBoardController controller = ChessBoardController();
  Chess game;
  BuildContext context;

  bool whiteSideTowardsUser = true, _showing = false, loadingBotMoves = false;
  int progress = 0;

  ChessController(this.context);

  //update the views
  var update;

  void onMove(move) {
    //update text
    if (update != null) update();
    //print the move
    print('onMove: $move');
    //and then update the ui
    update();
    print(Isolate.current.debugName);
    //check if bot should make a move
    if (move['color'] == PieceColor.White && prefs.getBool('bot')) {
      findMove();
    }
  }

  void findMove() async {
    //loading bot moves shall be true
    loadingBotMoves = true;
    //set player cannot change anything
    controller.userCanMakeMoves = false;
    //for the method _ai.find a new thread (isolate)
    //is spawned
    ReceivePort receivePort =
        ReceivePort(); //port for this main isolate to receive messages
    //send the game to the isolate
    //generated from fen string, so that the history list is empty and
    //the move generation algorithm can work faster (lightweight)
    Isolate isolate = await Isolate.spawn(
      ChessAI.entryPointMoveFinderIsolate,
      [receivePort.sendPort, controller.game.fen],
      debugName: 'chess_move_generator',
    );
    //listen at the receive port for the game (exit point)
    receivePort.listen((message) {
      //if message is the move, execute further actions
      if (message is Move) {
        //execute exitPointMoveFinderIsolate
        //in the main thread again, manage the move object
        //make the move, if there is one
        if (message != null) controller.game.make_move(message);
        //now set user can make moves true again
        controller.userCanMakeMoves = true;
        //set loading false
        loadingBotMoves = false;
        //for the listeners to be called in case
        controller.refreshBoard();
        //update the text etc
        update();
        //kill the isolate
        isolate.kill();
        //reset progress
        progress = 0;
        //if the message is an int, it is the progress
      } else if (message is int) {
        //set progress
        progress = message;
        //call update to update the text
        update();
      }
    });
  }

  void onDraw() {
    //show the dialog
    showTextDialog(strings.draw, strings.draw_desc,
        onDoneText: strings.replay, onDone: (value) => resetBoard);
  }

  void onCheckMate(color) {
    //determine winner and loser
    var winner = color == PieceColor.White ? strings.black : strings.white;
    var loser = color == PieceColor.White ? strings.white : strings.black;
    //show the dialog
    showTextDialog(strings.checkmate, strings.check_mate_desc(loser, winner),
        onDoneText: strings.replay, onDone: (value) => resetBoard);
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
    showTextDialog(strings.replay, strings.replay_desc, onDoneText: strings.ok,
        onDone: (value) {
      game.reset();
      update();
    });
  }

  void undo() {
    //undo two times if the bot is moving, too
    if (prefs.getBool('bot')) {
      _undo();
    }

    _undo();
  }

  void _undo() {
    game.undo_move() != null
        ? controller.refreshBoard()
        : showTextDialog(strings.undo, strings.undo_impossible);
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

  void onHardnessChange() {
    List difficulties = strings.difficulties.split(',');

    showTextDialog(strings.difficulty, null,
        onDoneText: strings.ok,
        onDone: (value) {
          //the idx from Nav.of.pop
          int idx = value as int;
          //
        },
        children: [
          SizedBox(
            height: 200,
            child: ListView.separated(
                itemBuilder: (ctx, idx) => GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop(idx);
                  },
                  child: Center(
                        child: Text(
                          difficulties[idx],
                          style: Theme.of(ContextSingleton.context)
                              .textTheme
                              .subtitle1,
                        ),
                      ),
                ),
                separatorBuilder: (_, idx) => Divider(),
                itemCount: difficulties.length
            ),
          )
        ]);
  }
}
