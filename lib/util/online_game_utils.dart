import 'package:chess_bot/util/utils.dart';

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

String get currentGameCode {
  return _currentGameCode == null ? strings.local : _currentGameCode;
}

bool get inOnlineGame {
  return _currentGameCode != null;
}