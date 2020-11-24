
import '../chess.dart';

class Game {
  Game();

  List<Piece> board = List(128);
  ColorMap kings = ColorMap.of(-1);
  Color turn = Color.WHITE;
  ColorMap castling = ColorMap.of(0);
  int ep_square = -1;
  int half_moves = 0;
  int move_number = 1;
  List<State> history = [];
  Map header = {};
}

class Move {
  final Color color;
  final int from;
  final int to;
  final int flags;
  final PieceType piece;
  final PieceType captured;
  final PieceType promotion;

  const Move(this.color, this.from, this.to, this.flags, this.piece,
      this.captured, this.promotion);

  String get fromAlgebraic {
    return Chess.algebraic(from);
  }

  String get toAlgebraic {
    return Chess.algebraic(to);
  }

  @override
  String toString() {
    return 'from: $from to $to';
  }
}

class State {
  final Move move;
  final ColorMap kings;
  final Color turn;
  final ColorMap castling;
  final int ep_square;
  final int half_moves;
  final int move_number;

  State(this.move, this.kings, this.turn, this.castling, this.ep_square,
      this.half_moves, this.move_number);
}

class Piece {
  PieceType type;
  final Color color;

  Piece(this.type, this.color);
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
  static Color inverse(Color color) {
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
}
