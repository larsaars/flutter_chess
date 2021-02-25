import 'package:quiver/core.dart';

import '../chess.dart';

class Game {
  Game();

  List<Piece> board = List.filled(128, null);
  ColorMap kings = ColorMap.of(-1);
  Color turn = Color.WHITE;
  ColorMap castling = ColorMap.of(0);
  int epSquare = -1;
  int halfMoves = 0;
  int moveNumber = 1;
  List<State> history = [];
}

class Move {
  final Color color;
  final int from;
  final int to;
  final int flags;
  final PieceType piece;
  final PieceType captured;
  final PieceType promotion;

  //for iterative deepening
  List<Move> children = [];
  num eval = 0;
  bool gameOver = false, gameDraw = false, additionalEvaluated = false;

  Move(this.color, this.from, this.to, this.flags, this.piece,
      this.captured, this.promotion);

  String get fromAlgebraic {
    return Chess.algebraic(from);
  }

  String get toAlgebraic {
    return Chess.algebraic(to);
  }

  @override
  String toString() {
    String fromAlg = Chess.algebraic(from), toAlg = Chess.algebraic(to);
    return 'from: $fromAlg to $toAlg';
  }

  @override
  bool operator ==(Object other) {
    return (other is Move) && (hashCode == other.hashCode);
  }

  @override
  int get hashCode {
    return hashObjects([color, from, to, flags, piece, captured, promotion]);
  }
}

class State {
  final Move move;
  final ColorMap kings;
  final Color turn;
  final ColorMap castling;
  final int epSquare;
  final int halfMoves;
  final int moveNumber;

  State(this.move, this.kings, this.turn, this.castling, this.epSquare,
      this.halfMoves, this.moveNumber);
}

class State2 {
  final Move move;
  final ColorMap castling;
  final Color turn;
  final int epSquare, halfMoves, moveNumber;
  final Map pawnControl, squaresNearKing, pawnCountsByRank, pawnCountsByFile;

  State2(
      this.move,
      this.turn,
      this.castling,
      this.epSquare,
      this.halfMoves,
      this.moveNumber,
      this.pawnControl,
      this.squaresNearKing,
      this.pawnCountsByRank,
      this.pawnCountsByFile);
}

class Piece {
  PieceType type;
  final Color color;

  Piece(this.type, this.color);

  @override
  int get hashCode => hash2(type, color);

  @override
  bool operator ==(Object other) {
    return (other is Piece) && (other.hashCode == hashCode);
  }

  //white is upper case
  @override
  String toString() => color == Color.WHITE ? type.name.toUpperCase() : type.name;

}

class PieceType {
  PieceType({this.name, this.shift});

  final int shift;
  final String name;

  const PieceType._internal(this.shift, this.name);

  static const PieceType PAWN = const PieceType._internal(0, 'p');
  static const PieceType KNIGHT = const PieceType._internal(1, 'n');
  static const PieceType BISHOP = const PieceType._internal(2, 'b');
  static const PieceType ROOK = const PieceType._internal(3, 'r');
  static const PieceType QUEEN = const PieceType._internal(4, 'q');
  static const PieceType KING = const PieceType._internal(5, 'k');

  int get hashCode => shift;

  String toString() => name;

  String toLowerCase() => name;

  String toUpperCase() => name.toUpperCase();
}

class Color {
  static Color flip(Color color) {
    return (color == WHITE) ? BLACK : WHITE;
  }

  final int value;

  Color.fromInt(this.value);

  const Color._internal(this.value);

  static const Color WHITE = Color._internal(0);
  static const Color BLACK = Color._internal(1);

  int get hashCode => value;

  String toString() => (this == WHITE) ? 'w' : 'b';

  @override
  bool operator ==(Object other) {
    return ((other is Color) && (this.value == other.value)) ||
        ((other is String) && (other == toString()));
  }
}

class ColorMap {
  int white;
  int black;

  ColorMap.of(int value)
      : white = value,
        black = value;

  ColorMap.clone(ColorMap other)
      : white = other.white,
        black = other.black;

  ColorMap();

  int operator [](Color color) {
    return (color == Color.WHITE) ? white : black;
  }

  void operator []=(Color color, int value) {
    if (color == Color.WHITE) {
      white = value;
    } else {
      black = value;
    }
  }

  @override
  int get hashCode => hash2(white, black);

  @override
  bool operator ==(Object other) {
    return (other is ColorMap) && (other.hashCode == hashCode);
  }
}
