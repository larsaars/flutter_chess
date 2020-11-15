import 'package:json_annotation/json_annotation.dart';

import '../chess.dart';

part 'chess_sub.g.dart';

@JsonSerializable()
class Game {
  Game();

  List<Piece> board = List(128);
  ColorMap kings = ColorMap.of(-1);
  int turn = WHITE;
  ColorMap castling = ColorMap.of(0);
  int ep_square = -1;
  int half_moves = 0;
  int move_number = 1;
  List<State> history = [];
  Map header = {};

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
  Map<String, dynamic> toJson() => _$GameToJson(this);
}

@JsonSerializable()
class Move {
  final int color;
  final int from;
  final int to;
  final int flags;
  final PieceType piece;
  final PieceType captured;
  final PieceType promotion;
  const Move(this.color, this.from, this.to, this.flags, this.piece, this.captured, this.promotion);

  String get fromAlgebraic {
    return Chess.algebraic(from);
  }

  String get toAlgebraic {
    return Chess.algebraic(to);
  }

  factory Move.fromJson(Map<String, dynamic> json) => _$MoveFromJson(json);
  Map<String, dynamic> toJson() => _$MoveToJson(this);
}

@JsonSerializable()
class State {
  final Move move;
  final ColorMap kings;
  final int turn;
  final ColorMap castling;
  final int ep_square;
  final int half_moves;
  final int move_number;
  const State(this.move, this.kings, this.turn, this.castling, this.ep_square, this.half_moves, this.move_number);

  factory State.fromJson(Map<String, dynamic> json) => _$StateFromJson(json);
  Map<String, dynamic> toJson() => _$StateToJson(this);
}

@JsonSerializable()
class Piece {
  PieceType type;
  int color;
  Piece(this.type, this.color);

  factory Piece.fromJson(Map<String, dynamic> json) => _$PieceFromJson(json);
  Map<String, dynamic> toJson() => _$PieceToJson(this);
}

@JsonSerializable()
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

  factory PieceType.fromJson(Map<String, dynamic> json) => _$PieceTypeFromJson(json);
  Map<String, dynamic> toJson() => _$PieceTypeToJson(this);
}

const int WHITE = 0;
const int BLACK = 1;

@JsonSerializable()
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

  int operator [](int color) {
    return (color == WHITE) ? white : black;
  }

  void operator []=(int color, int value) {
    if (color == WHITE) {
      white = value;
    } else {
      black = value;
    }
  }

  factory ColorMap.fromJson(Map<String, dynamic> json) => _$ColorMapFromJson(json);
  Map<String, dynamic> toJson() => _$ColorMapToJson(this);
}