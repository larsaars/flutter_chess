import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../chess.dart';
import 'board_model.dart';
import 'board_rank.dart';
import 'chess_board_controller.dart';

var whiteSquareList = [
  ["a8", "b8", "c8", "d8", "e8", "f8", "g8", "h8"],
  ["a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7"],
  ["a6", "b6", "c6", "d6", "e6", "f6", "g6", "h6"],
  ["a5", "b5", "c5", "d5", "e5", "f5", "g5", "h5"],
  ["a4", "b4", "c4", "d4", "e4", "f4", "g4", "h4"],
  ["a3", "b3", "c3", "d3", "e3", "f3", "g3", "h3"],
  ["a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2"],
  ["a1", "b1", "c1", "d1", "e1", "f1", "g1", "h1"],
];

/// Enum which stores board types
enum BoardType {
  brown,
  darkBrown,
  orange,
  green,
}

BoardType boardTypeFromString(String type) {
  switch (type) {
    case 'b':
      return BoardType.brown;
    case 'o':
      return BoardType.orange;
    case 'g':
      return BoardType.green;
    default:
      return BoardType.darkBrown;
  }
}

/// The Chessboard Widget
class ChessBoard extends StatefulWidget {
  /// Size of chessboard
  final double size;

  /// Callback for when move is made
  final MoveCallback onMove;

  /// Callback for when a player is checkmated
  final CheckMateCallback onCheckMate;

  /// Callback for when a player is in check
  final CheckCallback onCheck;

  /// Callback for when the game is a draw
  final VoidCallback onDraw;

  //the callbacks for returning the controller and game
  final Chess chess;

  /// A boolean which notes if white board side is towards users
  final bool whiteSideTowardsUser;

  /// A controller to programmatically control the chess board
  final ChessBoardController chessBoardController;

  /// A boolean which checks if the user should be allowed to make moves
  final bool enableUserMoves;

  /// The color type of the board
  final BoardType boardType;

  ChessBoard(
      {this.size = 200.0,
      this.whiteSideTowardsUser = true,
      @required this.onMove,
      @required this.onCheckMate,
      @required this.onCheck,
      @required this.onDraw,
      this.chessBoardController,
      this.enableUserMoves = true,
      this.boardType = BoardType.brown,
      this.chess});

  @override
  _ChessBoardState createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  @override
  Widget build(BuildContext context) {
    return ScopedModel(
      model: BoardModel(
        widget.size,
        widget.onMove,
        widget.onCheckMate,
        widget.onCheck,
        widget.onDraw,
        widget.whiteSideTowardsUser,
        widget.chessBoardController,
        widget.enableUserMoves,
        widget.chess,
      ),
      child: Container(
        height: widget.size,
        width: widget.size,
        child: Stack(
          children: <Widget>[
            Container(
              height: widget.size,
              width: widget.size,
              child: _getBoardImage(),
            ),
            //Overlaying draggables / dragTargets onto the squares
            Center(
              child: Container(
                height: widget.size,
                width: widget.size,
                child: buildChessBoard(),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Builds the board
  Widget buildChessBoard() {
    return Column(
      children: widget.whiteSideTowardsUser
          ? whiteSquareList.map((row) {
              return ChessBoardRank(
                children: row,
              );
            }).toList()
          : whiteSquareList.reversed.map((row) {
              return ChessBoardRank(
                children: row.reversed.toList(),
              );
            }).toList(),
    );
  }

  /// Returns the board image
  Image _getBoardImage() {
    switch (widget.boardType) {
      case BoardType.brown:
        return Image.asset(
          "res/chess_board/brown_board.png",
          fit: BoxFit.cover,
        );
      case BoardType.darkBrown:
        return Image.asset(
          "res/chess_board/dark_brown_board.png",
          fit: BoxFit.cover,
        );
      case BoardType.green:
        return Image.asset(
          "res/chess_board/green_board.png",
          fit: BoxFit.cover,
        );
      case BoardType.orange:
        return Image.asset(
          "res/chess_board/orange_board.png",
          fit: BoxFit.cover,
        );
      default:
        return null;
    }
  }
}
