import 'package:chess/chess.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class ChessController {
  ChessBoard chessBoard;

  Chess game() {
    return chessBoard.chessBoardController.game;
  }

  void onMove(move) {
    print('onMove: $move');

    if(game().in_checkmate)
      onCheckMate();

    if(game().in_draw)
      onDraw();
  }

  void onDraw() {
    print('onDraw');
  }

  void onCheckMate() {
    print('onCheckMate:');
  }
}
