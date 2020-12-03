import 'dart:html';

import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/flutter_chess_board.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:chess_bot/main.dart';
import 'package:chess_bot/utils.dart';
import 'package:dorker/dorker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_radio_button/group_radio_button.dart';

import 'chess_board/src/chess_board_controller.dart';
import 'eval/ai.dart';

class ChessController {
  ChessBoardController controller = ChessBoardController();
  Chess game;
  BuildContext context;

  bool whiteSideTowardsUser = true;
  bool _showing = false, botBattle = false;
  int progress = 0;

  Color botColor = Color.BLACK;

  static bool loadingBotMoves = false;
  static String moveFrom, moveTo, kingInCheck;

  ChessController(this.context);

  //update the views
  var update;

  void onMove(move) {
    //set the king if needed
    setKingInCheckSquare();
    //set the move from and move to object
    //for the animation in board_square
    ChessController.moveFrom = move['from'];
    ChessController.moveTo = move['to'];
    //print the move
    print('onMove: $move');
    // update the ui
    update();
    //check if bot should make a move
    //and then find it
    //make move if needed
    makeBotMoveIfRequired();
  }

  void findMove() async {
    //do nothing if controller or game is null
    //also return the method if is already called
    if (controller == null || game == null || loadingBotMoves) {
      return;
    }
    //loading bot moves shall be true
    loadingBotMoves = true;
    //set player cannot change anything
    controller.userCanMakeMoves = false;
    //if is on web, html workers have to be used instead of isolates
    await _findMoveWorker();
  }

  Future<void> _findMoveWorker() async {
    //workers are not supported
    if(!Worker.supported)
      return;

    //for the method _ai.find a new thread (worker)
    //is spawned
    //send the game to the isolate
    //generated from fen string, so that the history list is empty and
    //the move generation algorithm can work faster (lightweight)
    DorkerWorker dorker = DorkerWorker(Worker('lib/eval/ai.dart.js'));
    //listen to the dorker
    dorker.onMessage.listen((event) {
      _receiveAiCallback(event.data, dorker);
    });
    //post
    dorker.postMessage.add([game.fen, (prefs.getInt('set_depth') ?? 0)]);
  }

  void _receiveAiCallback(message, DorkerWorker isolate) {
    //if message is the move, execute further actions
    if (message is List) {
      //execute exitPointMoveFinderIsolate
      //in the main thread again, manage the move object
      //get the move object
      var move = message[0] as Move;
      //set the move from and move to object
      //for the animation in board_square
      moveFrom = move.fromAlgebraic;
      moveTo = move.toAlgebraic;
      //make the move, if there is one
      if (message != null) game.makeMove(move);
      //set king in check square
      setKingInCheckSquare();
      //now set user can make moves true again
      controller.userCanMakeMoves = true;
      //set loading false
      loadingBotMoves = false;
      //for the listeners to be called in case
      controller.refreshBoard();
      //update the text etc
      update();
      //kill the isolate or worker
      isolate.dispose();
      //reset progress
      progress = 0;
      //print how long it took
      num time = message[1];
      print('finished in $time ms');
      //if botbattle is activated, wait a certain amount of time,
      //then inverse botColor and
      //make check if bot move is required
      if (botBattle) {
        Future.delayed(Duration(milliseconds: 350)).then((value) {
          botColor = Color.flip(botColor);
          update();
          makeBotMoveIfRequired();
        });
      }
      //if the message is an int, it is the progress
    } else if (message is int) {
      //set progress
      progress = message;
      //call update to update the text
      update();
    } else if (message is String && message == 'no_moves') {
      //kill the isolate or worker since there are no moves
      isolate.dispose();
      //and update the board
      controller.userCanMakeMoves = true;
      loadingBotMoves = false;
      update();
    }
  }

  void setKingInCheckSquare() {
    bool isCheck = false;
    for (Color color in [Color.WHITE, Color.BLACK]) {
      if (game.king_attacked(color)) {
        kingInCheck = Chess.algebraic(game.game.kings[color]);
        print('$kingInCheck');
        isCheck = true;
      }
    }

    if (!isCheck) kingInCheck = null;
  }

  bool makeBotMoveIfRequired() {
    //make move if needed
    if (((game?.game?.turn ?? Color.flip(botColor)) == botColor) &&
        prefs.getBool('bot')) {
      findMove();
      return true;
    }

    return false;
  }

  void onDraw() {
    //show the dialog
    showTextDialog(strings.draw, strings.draw_desc, onDoneText: strings.replay,
        onDone: (value) {
      game.reset();
      update();
    });
  }

  void onCheckMate(color) {
    //determine winner and loser
    var winner = color == PieceColor.White ? strings.black : strings.white;
    var loser = color == PieceColor.White ? strings.white : strings.black;
    //show the dialog
    showTextDialog(strings.checkmate, strings.check_mate_desc(loser, winner),
        onDoneText: strings.replay, onDone: (value) {
      game.reset();
      update();
    });
  }

  void onCheck(color) {
    print('onCheck');
  }

  void resetBoard() {
    showTextDialog(strings.replay, strings.replay_desc, onDoneText: strings.ok,
        onDone: (value) {
      if (value == 'ok') {
        moveTo = null;
        moveFrom = null;
        kingInCheck = null;
        game.reset();
        update();
        makeBotMoveIfRequired();
      }
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
    game.undo() != null
        ? controller.refreshBoard()
        : showTextDialog(strings.undo, strings.undo_impossible);
  }

  void switchColors() {
    whiteSideTowardsUser = !whiteSideTowardsUser;
    prefs.setBool('whiteSideTowardsUser', whiteSideTowardsUser);
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

  void onSetDepth() {
    List difficulties = strings.difficulties.split(',');
    BuildContext ctx;

    showTextDialog(strings.difficulty, null,
        setStateCallback: (ctx0, setState) {
      ctx = ctx0;
    }, children: [
      RadioGroup.builder(
          direction: Axis.vertical,
          onChanged: (value) {
            //get diff int
            int diff = difficulties.indexOf(value);
            //save in the prefs
            prefs.setInt('set_depth', diff);
            //then pop the nav
            Navigator.of(ctx).pop();
          },
          groupValue: difficulties[prefs.getInt('set_depth') ?? 0],
          items: difficulties,
          itemBuilder: (item) => RadioButtonBuilder(item,
              textPosition: RadioButtonTextPosition.right))
    ]);
  }

  void onFen() {
    BuildContext ctx;
    showTextDialog(null, null, onDone: (value) {
      if (value == 'yes') update();
    }, setStateCallback: (ctx0, setState) {
      ctx = ctx0;
    }, children: [
      Align(
        alignment: Alignment.centerLeft,
        child: FlatButton(
          shape: roundButtonShape,
          child: Text(strings.copy_fen),
          onPressed: () {
            Clipboard.setData(new ClipboardData(text: game.fen));
            Navigator.of(ctx).pop('yes');
          },
        ),
      ),
      TextField(
        maxLines: 2,
        onChanged: (text) {
          print(text);
          if(text.endsWith('\n')){
            game = Chess.fromFEN(text.replaceAll('\n', ''));
            moveTo = null;
            moveFrom = null;
            kingInCheck = null;
            Navigator.of(ctx).pop('yes');
          }
        },
      )
    ]);
  }
}
