import 'dart:async';

import 'package:chess_bot/chess_board/src/chess_sub.dart' as chess;
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../main.dart';
import 'board_model.dart';

/// A single square on the chessboard
class BoardSquare extends StatelessWidget {
  /// The square name (a2, d3, e4, etc.)
  final squareName;

  BoardSquare({this.squareName});

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<BoardModel>(builder: (context, _, model) {
      return Expanded(
        flex: 1,
        child: DragTarget(builder: (context, accepted, rejected) {
          return model.game.getPiece(squareName) != null
              ? Draggable(
                  child: _getImageToDisplay(size: model.size / 8, model: model),
                  feedback: _getImageToDisplay(
                      size: (1.2 * (model.size / 8)), model: model),
                  onDragCompleted: () {},
                  data: [
                    squareName,
                    model.game.getPiece(squareName).type.toUpperCase(),
                    model.game.getPiece(squareName).color,
                  ],
                )
              : Container();
        }, onWillAccept: (willAccept) {
          return (model?.chessBoardController?.userCanMakeMoves ?? false);
        }, onAccept: (List moveInfo) {
          // A way to check if move occurred.
          chess.Color moveColor = model.game.turn;

          if (moveInfo[1] == "P" &&
              ((moveInfo[0][1] == "7" &&
                      squareName[1] == "8" &&
                      moveInfo[2] == chess.Color.WHITE) ||
                  (moveInfo[0][1] == "2" &&
                      squareName[1] == "1" &&
                      moveInfo[2] == chess.Color.BLACK))) {
            _promotionDialog(context).then((value) {
              model.game.moveIfFound(
                  {"from": moveInfo[0], "to": squareName, "promotion": value});
              //refresh the board
              model.refreshBoard();
              //after the promotion refresh the board and call on move
              if (model.game.turn != moveColor) {
                model.onMove({
                  'piece': moveInfo[1],
                  'square': squareName,
                  'color': moveInfo[2],
                });
              }
            });
          } else {
            model.game.moveIfFound({"from": moveInfo[0], "to": squareName});
          }

          model.refreshBoard();

          if (model.game.turn != moveColor) {
            model.onMove({
              'piece': moveInfo[1],
              'square': squareName,
              'color': moveInfo[2],
            });
          }
        }),
      );
    });
  }

  /// Show dialog when pawn reaches last square
  Future<String> _promotionDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: Text(strings.choose_promotion),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: WhiteQueen(),
                onTap: () {
                  Navigator.of(context).pop("q");
                },
              ),
              InkWell(
                child: WhiteRook(),
                onTap: () {
                  Navigator.of(context).pop("r");
                },
              ),
              InkWell(
                child: WhiteBishop(),
                onTap: () {
                  Navigator.of(context).pop("b");
                },
              ),
              InkWell(
                child: WhiteKnight(),
                onTap: () {
                  Navigator.of(context).pop("n");
                },
              ),
            ],
          ),
        );
      },
    ).then((value) {
      return value;
    });
  }

  /// Get image to display on square
  Widget _getImageToDisplay({double size, BoardModel model}) {
    Widget imageToDisplay = Container();

    if (model.game.getPiece(squareName) == null) {
      return Container();
    }

    var piece0 = model.game.getPiece(squareName);
    String piece = piece0.color.toString().substring(0, 1).toUpperCase() +
        model.game.getPiece(squareName).type.toUpperCase();

    switch (piece) {
      case "WP":
        imageToDisplay = WhitePawn(size: size);
        break;
      case "WR":
        imageToDisplay = WhiteRook(size: size);
        break;
      case "WN":
        imageToDisplay = WhiteKnight(size: size);
        break;
      case "WB":
        imageToDisplay = WhiteBishop(size: size);
        break;
      case "WQ":
        imageToDisplay = WhiteQueen(size: size);
        break;
      case "WK":
        imageToDisplay = WhiteKing(size: size);
        break;
      case "BP":
        imageToDisplay = BlackPawn(size: size);
        break;
      case "BR":
        imageToDisplay = BlackRook(size: size);
        break;
      case "BN":
        imageToDisplay = BlackKnight(size: size);
        break;
      case "BB":
        imageToDisplay = BlackBishop(size: size);
        break;
      case "BQ":
        imageToDisplay = BlackQueen(size: size);
        break;
      case "BK":
        imageToDisplay = BlackKing(size: size);
        break;
      default:
        imageToDisplay = WhitePawn(size: size);
    }

    /*//turn the image in if is needed
    if ((ChessController.whiteSideTowardsUser &&
            piece0.color == chess.Color.BLACK) ||
        (!ChessController.whiteSideTowardsUser &&
            piece0.color == chess.Color.WHITE))
      return Transform.rotate(
        angle: pi,
        child: imageToDisplay,
      );*/

    return imageToDisplay;
  }
}
