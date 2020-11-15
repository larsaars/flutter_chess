// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chess_sub.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Game _$GameFromJson(Map<String, dynamic> json) {
  return Game()
    ..board = (json['board'] as List)
        ?.map(
            (e) => e == null ? null : Piece.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..kings = json['kings'] == null
        ? null
        : ColorMap.fromJson(json['kings'] as Map<String, dynamic>)
    ..turn = json['turn'] as int
    ..castling = json['castling'] == null
        ? null
        : ColorMap.fromJson(json['castling'] as Map<String, dynamic>)
    ..ep_square = json['ep_square'] as int
    ..half_moves = json['half_moves'] as int
    ..move_number = json['move_number'] as int
    ..history = (json['history'] as List)
        ?.map(
            (e) => e == null ? null : State.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..header = json['header'] as Map<String, dynamic>;
}

Map<String, dynamic> _$GameToJson(Game instance) => <String, dynamic>{
      'board': instance.board,
      'kings': instance.kings,
      'turn': instance.turn,
      'castling': instance.castling,
      'ep_square': instance.ep_square,
      'half_moves': instance.half_moves,
      'move_number': instance.move_number,
      'history': instance.history,
      'header': instance.header,
    };

Move _$MoveFromJson(Map<String, dynamic> json) {
  return Move(
    json['color'] as int,
    json['from'] as int,
    json['to'] as int,
    json['flags'] as int,
    json['piece'] == null
        ? null
        : PieceType.fromJson(json['piece'] as Map<String, dynamic>),
    json['captured'] == null
        ? null
        : PieceType.fromJson(json['captured'] as Map<String, dynamic>),
    json['promotion'] == null
        ? null
        : PieceType.fromJson(json['promotion'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$MoveToJson(Move instance) => <String, dynamic>{
      'color': instance.color,
      'from': instance.from,
      'to': instance.to,
      'flags': instance.flags,
      'piece': instance.piece,
      'captured': instance.captured,
      'promotion': instance.promotion,
    };

State _$StateFromJson(Map<String, dynamic> json) {
  return State(
    json['move'] == null
        ? null
        : Move.fromJson(json['move'] as Map<String, dynamic>),
    json['kings'] == null
        ? null
        : ColorMap.fromJson(json['kings'] as Map<String, dynamic>),
    json['turn'] as int,
    json['castling'] == null
        ? null
        : ColorMap.fromJson(json['castling'] as Map<String, dynamic>),
    json['ep_square'] as int,
    json['half_moves'] as int,
    json['move_number'] as int,
  );
}

Map<String, dynamic> _$StateToJson(State instance) => <String, dynamic>{
      'move': instance.move,
      'kings': instance.kings,
      'turn': instance.turn,
      'castling': instance.castling,
      'ep_square': instance.ep_square,
      'half_moves': instance.half_moves,
      'move_number': instance.move_number,
    };

Piece _$PieceFromJson(Map<String, dynamic> json) {
  return Piece(
    json['type'] == null
        ? null
        : PieceType.fromJson(json['type'] as Map<String, dynamic>),
    json['color'] as int,
  );
}

Map<String, dynamic> _$PieceToJson(Piece instance) => <String, dynamic>{
      'type': instance.type,
      'color': instance.color,
    };

PieceType _$PieceTypeFromJson(Map<String, dynamic> json) {
  return PieceType(
    name: json['name'] as String,
    shift: json['shift'] as int,
  );
}

Map<String, dynamic> _$PieceTypeToJson(PieceType instance) => <String, dynamic>{
      'shift': instance.shift,
      'name': instance.name,
    };

ColorMap _$ColorMapFromJson(Map<String, dynamic> json) {
  return ColorMap()
    ..white = json['white'] as int
    ..black = json['black'] as int;
}

Map<String, dynamic> _$ColorMapToJson(ColorMap instance) => <String, dynamic>{
      'white': instance.white,
      'black': instance.black,
    };
