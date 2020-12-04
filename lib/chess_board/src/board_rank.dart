import 'package:flutter/material.dart';

import 'board_square.dart';

/// Creates a rank(row) on the chessboard
class ChessBoardRank extends StatelessWidget {
  /// The list of squares in the rank
  final List<String> children;

  ChessBoardRank({this.children});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Row(
        children: children
            .map(
              (squareName) => BoardSquare(
                squareName: squareName,
              ),
            )
            .toList(),
      ),
    );
  }
}
