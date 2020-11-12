import 'package:chess/chess.dart';

import 'chess_board/src/chess_board.dart';
import 'chess_board/src/chess_board_controller.dart';

class ChessController {
  ChessBoard chessBoard;
  ChessBoardController controller;
  Chess game;

  void onMove(move) {
    print('onMove: $move');

    /*if(chessBoard.chessBoardController.game.in_checkmate)
      onCheckMate();

    if(chessBoard.chessBoardController.game.in_draw)
      onDraw();*/
  }

  void onDraw() {
    print('onDraw');
  }

  void onCheckMate() {
    print('onCheckMate:');
  }
}
