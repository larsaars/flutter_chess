import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'dart:math' as Math;

import 'package:quiver/iterables.dart';

class _Eval2 {

  static const Color w = Color.WHITE,
      b = Color.BLACK;
  static const PieceType KING = PieceType.KING,
      QUEEN = PieceType.QUEEN,
      ROOK = PieceType.ROOK,
      BISHOP = PieceType.BISHOP,
      KNIGHT = PieceType.KNIGHT,
      PAWN = PieceType.PAWN;

  static const PIECE_VALUES = {
    KING: 0,
    QUEEN: 975,
    ROOK: 500,
    BISHOP: 335,
    KNIGHT: 325,
    PAWN: 100
  };

  // Adjustements of piece values based on the number of own pawns
  static const KNIGHT_VALUE_ADJUSTMENTS = [-20, -16, -12, -8, -4, 0, 4, 8, 12];
  static const ROOK_VALUE_ADJUSTMENTS = [15, 12, 9, 6, 3, 0, -3, -6, -9];

  static const BISHOP_PAIR_BONUS = 30;
  static const KNIGHT_PAIR_PENALTY = 8;
  static const ROOK_PAIR_PENALTY = 16;

  static const KING_BLOCKS_ROOK_PENALTY = 24;
  static const BLOCK_CENTRAL_PAWN_PENALTY = 24;
  static const BISHOP_TRAPPED_A7_PENALTY = 150;
  static const BISHOP_TRAPPED_A6_PENALTY = 50;
  static const KNIGHT_TRAPPED_A8_PENALTY = 150;
  static const KNIGHT_TRAPPED_A7_PENALTY = 100;

  static const C3_KNIGHT_PENALTY = 5;

  static const KING_SHIELD_RANK_2_BONUS = 10;
  static const KING_SHIELD_RANK_3_BONUS = 5;
  static const KING_NO_SHIELD_PENALTY = 10;

  static const ROOK_OPEN_BONUS = 10;
  static const ROOK_HALF_BONUS = 5;
  static const RETURNING_BISHOP_BONUS = 20;

// PSTs
  static const PAWN_MG_PST = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 1, 1, 1, 1, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 1, 2, 2, 1, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 2, 8, 8, 2, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 5, 10, 10, 5, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, -4, 1, 5, 5, 1, -4, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 1, -24, -24, 1, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const PAWN_EG_PST = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 1, 1, 1, 1, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 1, 2, 2, 1, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 2, 8, 8, 2, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 5, 10, 10, 5, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, -4, 1, 5, 5, 1, -4, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -6, -4, 1, -24, -24, 1, -4, -6, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const KNIGHT_MG_PST = [
    -8, -8, -8, -8, -8, -8, -8, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 0, 0, 0, 0, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 4, 6, 6, 4, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 6, 8, 8, 6, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 6, 8, 8, 6, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 4, 6, 6, 4, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 1, 2, 2, 1, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -16, -12, -8, -8, -8, -8, -12, -16, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const KNIGHT_EG_PST = [
    -8, -8, -8, -8, -8, -8, -8, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 0, 0, 0, 0, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 4, 6, 6, 4, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 6, 8, 8, 6, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 6, 8, 8, 6, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 4, 6, 6, 4, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -8, 0, 1, 2, 2, 1, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0,
    -16, -12, -8, -8, -8, -8, -12, -16, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const BISHOP_MG_PST = [
    -4, -4, -4, -4, -4, -4, -4, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 0, 0, 0, 0, 0, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 0, 2, 4, 4, 2, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 0, 4, 6, 6, 4, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 0, 4, 6, 6, 4, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 1, 2, 4, 4, 2, 1, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 2, 1, 1, 1, 1, 2, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, -4, -12, -4, -4, -12, -4, -4, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const BISHOP_EG_PST = [
    -4, -4, -4, -4, -4, -4, -4, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 0, 0, 0, 0, 0, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 0, 2, 4, 4, 2, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 0, 4, 6, 6, 4, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 0, 4, 6, 6, 4, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 1, 2, 4, 4, 2, 1, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, 2, 1, 1, 1, 1, 2, -4, 0, 0, 0, 0, 0, 0, 0, 0,
    -4, -4, -12, -4, -4, -12, -4, -4, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const ROOK_MG_PST = [
    5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const ROOK_EG_PST = [
    5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const QUEEN_MG_PST = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 2, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 2, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, -5, -5, -5, -5, -5, -5, -5, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const QUEEN_EG_PST = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 2, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 2, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    -5, -5, -5, -5, -5, -5, -5, -5, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const KING_MG_PST = [
    -40, -30, -50, -70, -70, -50, -30, -40, 0, 0, 0, 0, 0, 0, 0, 0,
    -30, -20, -40, -60, -60, -40, -20, -30, 0, 0, 0, 0, 0, 0, 0, 0,
    -20, -10, -30, -50, -50, -30, -10, -20, 0, 0, 0, 0, 0, 0, 0, 0,
    -10, 0, -20, -40, -40, -20, 0, -10, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 10, -10, -30, -30, -10, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    10, 20, 0, -20, -20, 0, 20, 10, 0, 0, 0, 0, 0, 0, 0, 0,
    30, 40, 20, 0, 0, 20, 40, 30, 0, 0, 0, 0, 0, 0, 0, 0,
    40, 50, 30, 10, 10, 30, 50, 40, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const KING_EG_PST = [
    -72, -48, -36, -24, -24, -36, -48, -72, 0, 0, 0, 0, 0, 0, 0, 0,
    -48, -24, -12, 0, 0, -12, -24, -48, 0, 0, 0, 0, 0, 0, 0, 0,
    -36, -12, 0, 12, 12, 0, -12, -36, 0, 0, 0, 0, 0, 0, 0, 0,
    -24, 0, 12, 24, 24, 12, 0, -24, 0, 0, 0, 0, 0, 0, 0, 0,
    -24, 0, 12, 24, 24, 12, 0, -24, 0, 0, 0, 0, 0, 0, 0, 0,
    -36, -12, 0, 12, 12, 0, -12, -36, 0, 0, 0, 0, 0, 0, 0, 0,
    -48, -24, -12, 0, 0, -12, -24, -48, 0, 0, 0, 0, 0, 0, 0, 0,
    -72, -48, -36, -24, -24, -36, -48, -72, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  static final PST = {
    'mg': { //mid game
      PAWN: {w: PAWN_MG_PST, b: mirrorPST(PAWN_MG_PST)},
      KNIGHT: {w: KNIGHT_MG_PST, b: mirrorPST(KNIGHT_MG_PST)},
      BISHOP: {w: BISHOP_MG_PST, b: mirrorPST(BISHOP_MG_PST)},
      ROOK: {w: ROOK_MG_PST, b: mirrorPST(ROOK_MG_PST)},
      QUEEN: {w: QUEEN_MG_PST, b: mirrorPST(QUEEN_MG_PST)},
      KING: {w: KING_MG_PST, b: mirrorPST(KING_MG_PST)}
    },
    'eg': { //end game
      PAWN: {w: PAWN_EG_PST, b: mirrorPST(PAWN_EG_PST)},
      KNIGHT: {w: KNIGHT_EG_PST, b: mirrorPST(KNIGHT_EG_PST)},
      BISHOP: {w: BISHOP_EG_PST, b: mirrorPST(BISHOP_EG_PST)},
      ROOK: {w: ROOK_EG_PST, b: mirrorPST(ROOK_EG_PST)},
      QUEEN: {w: QUEEN_EG_PST, b: mirrorPST(QUEEN_EG_PST)},
      KING: {w: KING_EG_PST, b: mirrorPST(KING_EG_PST)}
    }
  };


  void eval2(Chess game) {
    var result = 0;
    var phase = 0;
    var mgScore = 0;
    var egScore = 0;

    final materials = {w: 0, b: 0};
    final pieceAdjustment = {w: 0, b: 0};
    final mgPSTs = {w: 0, b: 0};
    final egPSTs = {w: 0, b: 0};
    final kingsShield = {w: 0, b: 0};
    final blockages = {w: 0, b: 0};
    final positionalThemes = {w: 0, b: 0};
    final mgMobility = {w: 0, b: 0};
    final egMobility = {w: 0, b: 0};
    final attackerCount = {w: 0, b: 0};
    final attackWeight = {w: 0, b: 0};
    final mgTropism = {w: 0, b: 0};
    final egTropism = {w: 0, b: 0};


    /**
     * Foreach piece on the board
     */
    _.forEach(game.pieces, (pieces, pieceType) {
      [w, b].forEach((color) {
        final squares = pieceType == 'k' ? [pieces[color]] : pieces[color];

        // Piece values
        final score = squares.length * PIECE_VALUES[pieceType];
        materials[color] += score;

        // Piece value adjustments and pair bonuses
        var adjustment = 0;
        if (pieceType == b && squares.length > 1) {
          adjustment += BISHOP_PAIR_BONUS;
        } else if (pieceType == 'n' || pieceType == 'r') {
          if (squares.length > 1) {
            final penalty = pieceType == 'n'
                ? KNIGHT_PAIR_PENALTY
                : ROOK_PAIR_PENALTY;
            adjustment -= penalty;
          }

          final pawnCount = game.pieces.p[color].length;
          final adj = pieceType == 'n'
              ? KNIGHT_VALUE_ADJUSTMENTS
              : ROOK_VALUE_ADJUSTMENTS;
          adjustment += adj[pawnCount] * squares.length;
        }
        pieceAdjustment[color] += adjustment;

        // PSTs
        squares.forEach((square) {
          mgPSTs[color] += PST['mg'][pieceType][color][square];
          egPSTs[color] += PST['eg'][pieceType][color][square];
        });

        // Game phase
        if (pieceType == 'n' || pieceType == b) {
          phase += 1;
        } else if (pieceType == 'r') {
          phase += 2;
        } else if (pieceType == 'q') {
          phase += 4;
        }
      });
    });


    /**
     * King's shield
     */
    [w, b].forEach((color) {
      if (Chess.file(game.pieces.k[color]) > 4) {
        // Squares are for white, we use relativeSquare to convert it to black
        final f2 = game.getPiece(relativeSquare(101, color));
        final g2 = game.getPiece(relativeSquare(102, color));
        final h2 = game.getPiece(relativeSquare(103, color));
        final f3 = game.getPiece(relativeSquare(85, color));
        final g3 = game.getPiece(relativeSquare(86, color));
        final h3 = game.getPiece(relativeSquare(87, color));

        if (f2 && f2.type == 'p' && f2.color == color)
          kingsShield[color] += KING_SHIELD_RANK_2_BONUS;
        else if (f3 && f3.type == 'p' && f3.color == color)
          kingsShield[color] += KING_SHIELD_RANK_3_BONUS;

        if (g2 && g2.type == 'p' && g2.color == color)
          kingsShield[color] += KING_SHIELD_RANK_2_BONUS;
        else if (g3 && g3.type == 'p' && g3.color == color)
          kingsShield[color] += KING_SHIELD_RANK_3_BONUS;

        if (h2 && h2.type == 'p' && h2.color == color)
          kingsShield[color] += KING_SHIELD_RANK_2_BONUS;
        else if (h3 && h3.type == 'p' && h3.color == color)
          kingsShield[color] += KING_SHIELD_RANK_3_BONUS;
      } else if (Chess.file(game.pieces.k[color]) < 3) {
        final a2 = game.getPiece(relativeSquare(96, color));
        final b2 = game.getPiece(relativeSquare(97, color));
        final c2 = game.getPiece(relativeSquare(98, color));
        final a3 = game.getPiece(relativeSquare(80, color));
        final b3 = game.getPiece(relativeSquare(81, color));
        final c3 = game.getPiece(relativeSquare(82, color));

        if (a2 && a2.type == 'p' && a2.color == color)
          kingsShield[color] += KING_SHIELD_RANK_2_BONUS;
        else if (a3 && a3.type == 'p' && a3.color == color)
          kingsShield[color] += KING_SHIELD_RANK_3_BONUS;

        if (b2 && b2.type == 'p' && b2.color == color)
          kingsShield[color] += KING_SHIELD_RANK_2_BONUS;
        else if (b3 && b3.type == 'p' && b3.color == color)
          kingsShield[color] += KING_SHIELD_RANK_3_BONUS;

        if (c2 && c2.type == 'p' && c2.color == color)
          kingsShield[color] += KING_SHIELD_RANK_2_BONUS;
        else if (c3 && c3.type == 'p' && c3.color == color)
          kingsShield[color] += KING_SHIELD_RANK_3_BONUS;
      }
    });


    /**
     * Blocked pieces
     */
    [w, b].forEach((color) {
      final us = color;
      final them = Chess.swap_color(color);

      // Central pawn, hard to develop bishop
      if (game.checkPiece(relativeSquare(114, us), us, b) &&
          game.checkPiece(relativeSquare(99, us), us, 'p') &&
          game.getPiece(relativeSquare(83, us))) {
        blockages[us] -= BLOCK_CENTRAL_PAWN_PENALTY;
      }

      if (game.checkPiece(relativeSquare(117, us), us, b) &&
          game.checkPiece(relativeSquare(100, us), us, 'p') &&
          game.getPiece(relativeSquare(84, us))) {
        blockages[us] -= BLOCK_CENTRAL_PAWN_PENALTY;
      }

      // Trapped knight
      if (game.checkPiece(relativeSquare(0, us), us, 'n') &&
          (game.checkPiece(relativeSquare(16, us), them, 'p') ||
              game.checkPiece(relativeSquare(18, us), them, 'p'))) {
        blockages[us] -= KNIGHT_TRAPPED_A8_PENALTY;
      }

      if (game.checkPiece(relativeSquare(7, us), us, 'n') &&
          (game.checkPiece(relativeSquare(23, us), them, 'p') ||
              game.checkPiece(relativeSquare(21, us), them, 'p'))) {
        blockages[us] -= KNIGHT_TRAPPED_A8_PENALTY;
      }

      if (game.checkPiece(relativeSquare(16, us), us, 'n') &&
          game.checkPiece(relativeSquare(32, us), them, 'p') &&
          game.checkPiece(relativeSquare(17, us), them, 'p')) {
        blockages[us] -= KNIGHT_TRAPPED_A7_PENALTY;
      }

      if (game.checkPiece(relativeSquare(23, us), us, 'n') &&
          game.checkPiece(relativeSquare(39, us), them, 'p') &&
          game.checkPiece(relativeSquare(22, us), them, 'p')) {
        blockages[us] -= KNIGHT_TRAPPED_A7_PENALTY;
      }

      // Knight blocking queenside pawns
      if (game.checkPiece(relativeSquare(82, us), us, 'n') &&
          game.checkPiece(relativeSquare(98, us), us, 'p') &&
          game.checkPiece(relativeSquare(67, us), us, 'p') &&
          !game.checkPiece(relativeSquare(68, us), us, 'p')) {
        blockages[us] -= C3_KNIGHT_PENALTY;
      }

      // Trapped bishop
      if (game.checkPiece(relativeSquare(16, us), us, b) &&
          game.checkPiece(relativeSquare(33, us), them, 'p')) {
        blockages[us] -= BISHOP_TRAPPED_A7_PENALTY;
      }

      if (game.checkPiece(relativeSquare(23, us), us, b) &&
          game.checkPiece(relativeSquare(38, us), them, 'p')) {
        blockages[us] -= BISHOP_TRAPPED_A7_PENALTY;
      }

      if (game.checkPiece(relativeSquare(1, us), us, b) &&
          game.checkPiece(relativeSquare(18, us), them, 'p')) {
        blockages[us] -= BISHOP_TRAPPED_A7_PENALTY;
      }

      if (game.checkPiece(relativeSquare(6, us), us, b) &&
          game.checkPiece(relativeSquare(21, us), them, 'p')) {
        blockages[us] -= BISHOP_TRAPPED_A7_PENALTY;
      }

      if (game.checkPiece(relativeSquare(32, us), us, b) &&
          game.checkPiece(relativeSquare(49, us), them, 'p')) {
        blockages[us] -= BISHOP_TRAPPED_A6_PENALTY;
      }

      if (game.checkPiece(relativeSquare(39, us), us, b) &&
          game.checkPiece(relativeSquare(54, us), them, 'p')) {
        blockages[us] -= BISHOP_TRAPPED_A6_PENALTY;
      }

      // Bishop at initial sqare that supporting castled king
      if (game.checkPiece(relativeSquare(117, us), us, b) &&
          game.checkPiece(relativeSquare(118, us), us, 'k')) {
        positionalThemes[us] += RETURNING_BISHOP_BONUS;
      }

      if (game.checkPiece(relativeSquare(114, us), us, b) &&
          game.checkPiece(relativeSquare(113, us), us, 'k')) {
        positionalThemes[us] += RETURNING_BISHOP_BONUS;
      }

      // Uncastled king that blocking rook
      if ((game.checkPiece(relativeSquare(117, us), us, 'k') ||
          game.checkPiece(relativeSquare(118, us), us, 'k')) &&
          (game.checkPiece(relativeSquare(118, us), us, 'r') ||
              game.checkPiece(relativeSquare(119, us), us, 'r'))) {
        blockages[us] -= KING_BLOCKS_ROOK_PENALTY;
      }

      if ((game.checkPiece(relativeSquare(113, us), us, 'k') ||
          game.checkPiece(relativeSquare(114, us), us, 'k')) &&
          (game.checkPiece(relativeSquare(112, us), us, 'r') ||
              game.checkPiece(relativeSquare(113, us), us, 'r'))) {
        blockages[us] -= KING_BLOCKS_ROOK_PENALTY;
      }
    });


    /**
     * Knight
     */
    [w, b].forEach((color) {
      final us = color;
      final them = Chess.swap_color(us);

      game.pieces.n[us].forEach((square) {
        final moves = game.generatePieceMoves(square);
        var mobility = 0;
        var kingAttacks = 0;

        moves.forEach((move) {
          if (!game.pawnControl[them][move.to] ||
              game.pawnControl[them][move.to] <= 0) mobility++;
          if (game.squaresNearKing[them].indexOf(move.to) > -1) kingAttacks++;
        });

        mgMobility[us] += 4 * (mobility - 4);
        egMobility[us] += 4 * (mobility - 4);

        if (kingAttacks > 0) {
          attackerCount[us]++;
          attackWeight[us] += 2 * kingAttacks;
        }

        final tropism = getTropism(square, game.pieces.k[them]);
        mgTropism[us] += 3 * tropism;
        egTropism[us] += 3 * tropism;
      });
    });


    /**
     * Bishop
     */
    [w, b].forEach((color) {
      final us = color;
      final them = Chess.swap_color(us);

      game.pieces.b[us].forEach((square) {
        final moves = game.generatePieceMoves(square);
        var mobility = 0;
        var kingAttacks = 0;

        moves.forEach((move) {
          if (!move.captured) {
            if (!game.pawnControl[them][move.to] ||
                game.pawnControl[them][move.to] <= 0) mobility++;
          } else {
            mobility++;
          }

          if (game.squaresNearKing[them].indexOf(move.to) > -1) kingAttacks++;
        });

        mgMobility[us] += 3 * (mobility - 7);
        egMobility[us] += 3 * (mobility - 7);

        if (kingAttacks > 0) {
          attackerCount[us]++;
          attackWeight[us] += 2 * kingAttacks;
        }

        final tropism = getTropism(square, game.pieces.k[them]);
        mgTropism[us] += 2 * tropism;
        egTropism[us] += 1 * tropism;
      });
    });


    /**
     * Rook
     */
    [w, b].forEach((color) {
      final us = color;
      final them = Chess.swap_color(us);

      game.pieces.r[us].forEach((square) {
        final moves = game.generatePieceMoves(square);
        var mobility = 0;
        var kingAttacks = 0;

        // 7th row bonus
        final seventhRowRank = relativeRank(6, us);
        if (Chess.rank(square) == seventhRowRank &&
            (game.pawnCountsByRank[them][seventhRowRank] > 0 ||
                Chess.rank(game.pieces.k[them]) == relativeRank(7, us))) {
          mgMobility[us] += 20;
          egMobility[us] += 30;
        }

        // Open column bonus
        final fileCount = Chess.file(square);
        if (game.pawnCountsByFile[us][fileCount] == 0) {
          if (game.pawnCountsByFile[them][fileCount] == 0) {
            mgMobility[us] += ROOK_OPEN_BONUS;
            egMobility[us] += ROOK_OPEN_BONUS;
            if (abs(fileCount - Chess.file(game.pieces.k[them])) < 2)
              attackWeight[us] += 1;
          } else {
            mgMobility[us] += ROOK_HALF_BONUS;
            egMobility[us] += ROOK_HALF_BONUS;
            if (abs(fileCount - Chess.file(game.pieces.k[them])) < 2)
              attackWeight[us] += 2;
          }
        }


        moves.forEach((move) {
          mobility++;
          if (game.squaresNearKing[them].indexOf(move.to) > -1) kingAttacks++;
        });

        mgMobility[us] += 2 * (mobility - 7);
        egMobility[us] += 3 * (mobility - 7);

        if (kingAttacks > 0) {
          attackerCount[us]++;
          attackWeight[us] += 3 * kingAttacks;
        }

        final tropism = getTropism(square, game.pieces.k[them]);
        mgTropism[us] += 2 * tropism;
        egTropism[us] += 1 * tropism;
      });
    });

    /**
     * Queen
     */
    [w, b].forEach((color) {
      final us = color;
      final them = Chess.swap_color(us);

      game.pieces.q[us].forEach((square) {
        final moves = game.generatePieceMoves(square);
        var mobility = 0;
        var kingAttacks = 0;

        // 7th row bonus
        final seventhRowRank = relativeRank(6, us);
        if (Chess.rank(square) == seventhRowRank &&
            (game.pawnCountsByRank[them][seventhRowRank] > 0 ||
                Chess.rank(game.pieces.k[them]) == relativeRank(7, us))) {
          mgMobility[us] += 20;
          egMobility[us] += 30;
        }

        // Penalty for early development
        final secondRowRank = relativeRank(1, us);
        if ((us == w && Chess.rank(square) < secondRowRank) ||
            (us == w && Chess.rank(square) > secondRowRank)) {
          if (game.checkPiece(relativeSquare(113, us), us, 'n'))
            positionalThemes[us] -= 2;
          if (game.checkPiece(relativeSquare(114, us), us, b))
            positionalThemes[us] -= 2;
          if (game.checkPiece(relativeSquare(117, us), us, b))
            positionalThemes[us] -= 2;
          if (game.checkPiece(relativeSquare(118, us), us, 'n'))
            positionalThemes[us] -= 2;
        }

        moves.forEach((move) {
          mobility++;
          if (game.squaresNearKing[them].indexOf(move.to) > -1) kingAttacks++;
        });

        mgMobility[us] += 1 * (mobility - 14);
        egMobility[us] += 2 * (mobility - 14);

        if (kingAttacks > 0) {
          attackerCount[us]++;
          attackWeight[us] += 4 * kingAttacks;
        }

        final tropism = getTropism(square, game.pieces.k[them]);
        mgTropism[us] += 2 * tropism;
        egTropism[us] += 4 * tropism;
      });
    });


    // Calculate result
    phase = Math.min(phase, 24);

    mgScore = materials[w] - materials[b] + mgPSTs[w] - mgPSTs[b];
    egScore = mgScore;

    mgScore += kingsShield[w] - kingsShield[b];

    mgScore += mgMobility[w] - mgMobility[b];
    egScore += egMobility[w] - egMobility[b];

    mgScore += mgTropism[w] - mgTropism[b];
    egScore += egTropism[w] - egTropism[b];

    result += (((phase * mgScore) + ((24 - phase) * egScore)) / 24) as int;
    result += pieceAdjustment[w] - pieceAdjustment[b];
    result += blockages[w] - blockages[b];
    result += positionalThemes[w] - positionalThemes[b];

    return verbose == false ? result : [
      result,
      phase,
      mgScore,
      egScore,
      materials,
      pieceAdjustment,
      mgPSTs,
      egPSTs,
      kingsShield,
      blockages,
      positionalThemes,
      mgMobility,
      egMobility,
      attackerCount,
      attackWeight,
      mgTropism,
      egTropism
    ];
  }


  void eval2_basic(game) {
    var result = 0;
    var phase = 0;

    final materials = {w: 0, b: 0};
    final pieceAdjustment = {w: 0, b: 0};
    final mgPSTs = {w: 0, b: 0};
    final egPSTs = {w: 0, b: 0};


    /**
     * Foreach piece on the board
     */
    _.forEach(game.pieces, (pieces, pieceType) {
      [w, b].forEach((color) {
        final squares = pieceType == 'k' ? [pieces[color]] : pieces[color];

        // Piece values
        final score = squares.length * PIECE_VALUES[pieceType];
        materials[color] += score;

        // Piece value adjustments and pair bonuses
        var adjustment = 0;
        if (pieceType == b && squares.length > 1) {
          adjustment += BISHOP_PAIR_BONUS;
        } else if (pieceType == 'n' || pieceType == 'r') {
          if (squares.length > 1) {
            final penalty = pieceType == 'n'
                ? KNIGHT_PAIR_PENALTY
                : ROOK_PAIR_PENALTY;
            adjustment -= penalty;
          }

          final pawnCount = game.pieces[PAWN][color].length;
          final adj = pieceType == 'n'
              ? KNIGHT_VALUE_ADJUSTMENTS
              : ROOK_VALUE_ADJUSTMENTS;
          adjustment += adj[pawnCount] * squares.length;
        }
        pieceAdjustment[color] += adjustment;

        // PSTs
        squares.forEach((square) {
          mgPSTs[color] += PST.mg[pieceType][color][square];
          egPSTs[color] += PST.eg[pieceType][color][square];
        });

        // Game phase
        if (pieceType == 'n' || pieceType == b) {
          phase += 1;
        } else if (pieceType == 'r') {
          phase += 2;
        } else if (pieceType == 'q') {
          phase += 4;
        }
      });
    });


    // Calculate result
    phase = Math.min(phase, 24);

    mgScore = materials[w] - materials[b] + mgPSTs[w] - mgPSTs[b];
    egScore = mgScore;

    result += (((phase * mgScore) + ((24 - phase) * egScore)) / 24) as int;
    result += pieceAdjustment[w] - pieceAdjustment[b];

    return result;
  }


  // Helpers
  static List mirrorPST(List arr) {
    return partition(arr, 16)
        .toList()
        .reversed
        .expand((i) => i)
        .toList();
    //return _.flatten(_.chunk(arr, 16).reverse());
  }

  static const BLACK_INDEXES = _.flatten(
      _.chunk(_.times(128, i => i), 16).reverse());


  void relativeSquare(i, color) {
    if (color == w) return i;
    return BLACK_INDEXES[i];
  }

  num abs(num n) {
    return n < 0 ? -n : n;
  }

  num getTropism(from, to) {
    return 7 - abs(Chess.rank(from) - Chess.rank(to)) +
        abs(Chess.file(from) - Chess.file(to));
  }

  num relativeRank(rank, color) {
    if (color == b) return rank;
    return 7 - rank;
  }
}