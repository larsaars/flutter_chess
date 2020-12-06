import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:chess_bot/chess_control/chess_controller.dart';
import 'package:chess_bot/util/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';

String _createGameCode() {
  final availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      .runes
      .map((int rune) => String.fromCharCode(rune))
      .toList();
  String out = '';
  for (int i = 0; i < 6; i++)
    out += availableChars[random.nextInt(availableChars.length)];
  return out;
}

String _currentGameCode;

String joinGameCode({String gameCode}) {
  if (gameCode != null)
    return _currentGameCode = gameCode;
  else
    return _currentGameCode = _createGameCode();
}

DocumentReference get currentGameDoc {
  if (inOnlineGame)
    return FirebaseFirestore.instance.collection('games').doc(_currentGameCode);
  else
    return null;
}

String get currentGameCode {
  return _currentGameCode == null ? strings.local : _currentGameCode;
}

bool get inOnlineGame {
  return _currentGameCode != null;
}

class OnlineGameController {
  final ChessController _chessController;
  Function update;

  OnlineGameController(this._chessController);

  void finallyCreateGameCode() {
    //create new game id locally
    joinGameCode();
    //create the bucket in cloud firestore
    //reset the local game
    _chessController.controller.resetBoard();
    //new game map
    Map<String, dynamic> game = {};
    game['white'] = uuid;
    game['black'] = null;
    game['fen'] = _chessController.game.fen;
    game['turn'] = Color.WHITE.value;
    game['blackTurn'] = null;
    game['whiteTurn'] = null;
    //upload to firebase
    currentGameDoc.set(game);
    //lock listener
    currentGameDoc.snapshots().listen((event) {

    });
    //update views
    update();
  }
}
