import 'package:flutter_chess_board/flutter_chess_board.dart';

class ChessController {
  ChessBoard chessBoard;

  void onMove(move) {
    print('onMove: $move');
  }

  void onDraw() {
    print('onDraw');
  }

  void onCheckMate(color) {
    print('onCheckMate: $color');
  }
}
