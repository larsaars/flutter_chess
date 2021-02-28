library chess;

import 'package:chess_bot/chess_board/src/chess_sub.dart';

/*  Copyright (c) 2014, David Kopec (my first name at oaksnow dot com)
 *  Released under the MIT license
 *  https://github.com/davecom/chess.dart/blob/master/LICENSE
 *
 *  Based on chess.js
 *  Copyright (c) 2013, Jeff Hlywa (jhlywa@gmail.com)
 *  Released under the BSD license
 *  https://github.com/jhlywa/chess.js/blob/master/LICENSE
 *
 *  Manipulated 2020-21 by Lars Specht
 */

typedef void ForEachPieceCallback(Piece piece);

class Chess {
  // Instance Variables
  Game game = Game();

  /// By default start with the standard chess starting position
  Chess() {
    load(DEFAULT_POSITION);
  }

  /// Start with a position from a FEN
  Chess.fromFEN(String fen) {
    load(fen);
  }

  /// Deep copy of the current Chess instance
  Chess copy() {
    return new Chess()
      ..game.board = new List<Piece>.from(this.game.board)
      ..game.kings = new ColorMap.clone(this.game.kings)
      ..game.turn = new Color.fromInt(this.game.turn.value)
      ..game.castling = new ColorMap.clone(this.game.castling)
      ..game.epSquare = this.game.epSquare
      ..game.halfMoves = this.game.halfMoves
      ..game.moveNumber = this.game.moveNumber
      ..game.history = new List<State>.from(this.game.history);
  }

  /// Reset all of the instance variables
  void clear() {
    game = Game();
  }

  /// Go back to the chess starting position
  void reset() {
    load(DEFAULT_POSITION);
  }

  /// Load a position from a FEN String
  bool load(String fen) {
    List tokens = fen.split(new RegExp(r"\s+"));
    String position = tokens[0];
    int square = 0;

    Map validMap = validate_fen(fen);
    if (!validMap["valid"]) {
      print(validMap["error"]);
      return false;
    }

    clear();

    for (int i = 0; i < position.length; i++) {
      String piece = position[i];

      if (piece == '/') {
        square += 8;
      } else if (is_digit(piece)) {
        square += int.parse(piece);
      } else {
        Color color = (piece == piece.toUpperCase()) ? WHITE : BLACK;
        PieceType type = PIECE_TYPES[piece.toLowerCase()];
        put(new Piece(type, color), algebraic(square));
        square++;
      }
    }

    if (tokens[1] == 'w') {
      game.turn = WHITE;
    } else {
      assert(tokens[1] == 'b');
      game.turn = BLACK;
    }

    if (tokens[2].indexOf('K') > -1) {
      game.castling[WHITE] |= BITS_KSIDE_CASTLE;
    }
    if (tokens[2].indexOf('Q') > -1) {
      game.castling[WHITE] |= BITS_QSIDE_CASTLE;
    }
    if (tokens[2].indexOf('k') > -1) {
      game.castling[BLACK] |= BITS_KSIDE_CASTLE;
    }
    if (tokens[2].indexOf('q') > -1) {
      game.castling[BLACK] |= BITS_QSIDE_CASTLE;
    }

    game.epSquare = (tokens[3] == '-') ? EMPTY : SQUARES[tokens[3]];
    game.halfMoves = int.parse(tokens[4]);
    game.moveNumber = int.parse(tokens[5]);
    return true;
  }

  /// Check the formatting of a FEN String is correct
  /// Returns a Map with keys valid, error_number, and error
  static Map validate_fen(fen) {
    Map errors = {
      0: 'No errors.',
      1: 'FEN string must contain six space-delimited fields.',
      2: '6th field (move number) must be a positive integer.',
      3: '5th field (half move counter) must be a non-negative integer.',
      4: '4th field (en-passant square) is invalid.',
      5: '3rd field (castling availability) is invalid.',
      6: '2nd field (side to move) is invalid.',
      7: '1st field (piece positions) does not contain 8 \'/\'-delimited rows.',
      8: '1st field (piece positions) is invalid [consecutive numbers].',
      9: '1st field (piece positions) is invalid [invalid piece].',
      10: '1st field (piece positions) is invalid [row too large].',
    };

    /* 1st criterion: 6 space-seperated fields? */
    List tokens = fen.split(new RegExp(r"\s+"));
    if (tokens.length != 6) {
      return {'valid': false, 'error_number': 1, 'error': errors[1]};
    }

    /* 2nd criterion: move number field is a integer value > 0? */
    int temp = int.parse(tokens[5], onError: (String) => null);
    if (temp != null) {
      if (temp <= 0) {
        return {'valid': false, 'error_number': 2, 'error': errors[2]};
      }
    } else {
      return {'valid': false, 'error_number': 2, 'error': errors[2]};
    }

    /* 3rd criterion: half move counter is an integer >= 0? */
    temp = int.parse(tokens[4], onError: (String) => null);
    if (temp != null) {
      if (temp < 0) {
        return {'valid': false, 'error_number': 3, 'error': errors[3]};
      }
    } else {
      return {'valid': false, 'error_number': 3, 'error': errors[3]};
    }

    /* 4th criterion: 4th field is a valid e.p.-string? */
    RegExp check4 = new RegExp(r"^(-|[abcdefgh][36])$");
    if (check4.firstMatch(tokens[3]) == null) {
      return {'valid': false, 'error_number': 4, 'error': errors[4]};
    }

    /* 5th criterion: 3th field is a valid castle-string? */
    RegExp check5 = new RegExp(r"^(KQ?k?q?|Qk?q?|kq?|q|-)$");
    if (check5.firstMatch(tokens[2]) == null) {
      return {'valid': false, 'error_number': 5, 'error': errors[5]};
    }

    /* 6th criterion: 2nd field is "w" (white) or "b" (black)? */
    RegExp check6 = new RegExp(r"^([wb])$");
    if (check6.firstMatch(tokens[1]) == null) {
      return {'valid': false, 'error_number': 6, 'error': errors[6]};
    }

    /* 7th criterion: 1st field contains 8 rows? */
    List rows = tokens[0].split('/');
    if (rows.length != 8) {
      return {'valid': false, 'error_number': 7, 'error': errors[7]};
    }

    /* 8th criterion: every row is valid? */
    for (int i = 0; i < rows.length; i++) {
      /* check for right sum of fields AND not two numbers in succession */
      int sum_fields = 0;
      bool previous_was_number = false;

      for (int k = 0; k < rows[i].length; k++) {
        int temp2 = int.parse(rows[i][k], onError: (String) => null);
        if (temp2 != null) {
          if (previous_was_number) {
            return {'valid': false, 'error_number': 8, 'error': errors[8]};
          }
          sum_fields += temp2;
          previous_was_number = true;
        } else {
          RegExp checkOM = new RegExp(r"^[prnbqkPRNBQK]$");
          if (checkOM.firstMatch(rows[i][k]) == null) {
            return {'valid': false, 'error_number': 9, 'error': errors[9]};
          }
          sum_fields += 1;
          previous_was_number = false;
        }
      }

      if (sum_fields != 8) {
        return {'valid': false, 'error_number': 10, 'error': errors[10]};
      }
    }

    /* everything's okay! */
    return {'valid': true, 'error_number': 0, 'error': errors[0]};
  }

  /// Returns a FEN String representing the current position
  String generate_fen() {
    int empty = 0;
    String fen = '';

    for (int i = SQUARES_A8; i <= SQUARES_H1; i++) {
      if (game.board[i] == null) {
        empty++;
      } else {
        if (empty > 0) {
          fen += empty.toString();
          empty = 0;
        }
        Color color = game.board[i].color;
        PieceType type = game.board[i].type;

        fen += (color == WHITE) ? type.toUpperCase() : type.toLowerCase();
      }

      if (((i + 1) & 0x88) != 0) {
        if (empty > 0) {
          fen += empty.toString();
        }

        if (i != SQUARES_H1) {
          fen += '/';
        }

        empty = 0;
        i += 8;
      }
    }

    String cflags = '';
    if ((game.castling[WHITE] & BITS_KSIDE_CASTLE) != 0) {
      cflags += 'K';
    }
    if ((game.castling[WHITE] & BITS_QSIDE_CASTLE) != 0) {
      cflags += 'Q';
    }
    if ((game.castling[BLACK] & BITS_KSIDE_CASTLE) != 0) {
      cflags += 'k';
    }
    if ((game.castling[BLACK] & BITS_QSIDE_CASTLE) != 0) {
      cflags += 'q';
    }

    /* do we have an empty castling flag? */
    if (cflags == "") {
      cflags = '-';
    }
    String epflags = (game.epSquare == EMPTY) ? '-' : algebraic(game.epSquare);

    return [fen, game.turn, cflags, epflags, game.halfMoves, game.moveNumber]
        .join(' ');
  }

  /// Returns the piece at the square in question or null
  /// if there is none
  Piece get(String square) {
    return game.board[SQUARES[square]];
  }

  /// Put [piece] on [square]
  bool put(Piece piece, String square) {
    /* check for piece */
    if (SYMBOLS.indexOf(piece.type.toLowerCase()) == -1) {
      return false;
    }

    /* check for valid square */
    if (!(SQUARES.containsKey(square))) {
      return false;
    }

    int sq = SQUARES[square];
    game.board[sq] = piece;
    if (piece.type == KING) {
      game.kings[piece.color] = sq;
    }

    return true;
  }

  /// Removes a piece from a square and returns it,
  /// or null if none is present
  Piece remove(String square) {
    Piece piece = get(square);
    game.board[SQUARES[square]] = null;
    if (piece != null && piece.type == KING) {
      game.kings[piece.color] = EMPTY;
    }

    return piece;
  }

  Move build_move(List<Piece> board, from, to, flags, [PieceType promotion]) {
    if (promotion != null) {
      flags |= BITS_PROMOTION;
    }

    PieceType captured;
    Piece toPiece = board[to];
    if (toPiece != null) {
      captured = toPiece.type;
    } else if ((flags & BITS_EP_CAPTURE) != 0) {
      captured = PAWN;
    }
    return new Move(
        game.turn, from, to, flags, board[from].type, captured, promotion);
  }

  List<Move> generateMoves([Map options]) {
    // ignore: non_constant_identifier_names
    void add_move(List<Move> moves, from, to, flags) {
      /* if pawn promotion */
      if (game.board[from].type == PAWN &&
          (rank(to) == RANK_8 || rank(to) == RANK_1)) {
        List pieces = [QUEEN, ROOK, BISHOP, KNIGHT];
        for (var i = 0, len = pieces.length; i < len; i++) {
          moves.add(build_move(game.board, from, to, flags, pieces[i]));
        }
      } else {
        moves.add(build_move(game.board, from, to, flags));
      }
    }

    List<Move> moves = [];
    Color us = game.turn;
    Color them = swap_color(us);
    ColorMap second_rank = new ColorMap.of(0);
    second_rank[BLACK] = RANK_7;
    second_rank[WHITE] = RANK_2;

    var first_sq = SQUARES_A8;
    var last_sq = SQUARES_H1;
    bool single_square = false;

    /* are we generating moves for a single square? */
    if (options != null && options.containsKey('square')) {
      if (SQUARES.containsKey(options['square'])) {
        first_sq = last_sq = SQUARES[options['square']];
        single_square = true;
      } else {
        /* invalid square */
        return [];
      }
    }

    for (int i = first_sq; i <= last_sq; i++) {
      /* did we run off the end of the board */
      if ((i & 0x88) != 0) {
        i += 7;
        continue;
      }

      Piece piece = game.board[i];
      if (piece == null || piece.color != us) {
        continue;
      }

      if (piece.type == PAWN) {
        /* single square, non-capturing */
        int square = i + PAWN_OFFSETS[us][0];
        if (game.board[square] == null) {
          add_move(moves, i, square, BITS_NORMAL);

          /* double square */
          var square2 = i + PAWN_OFFSETS[us][1];
          if (second_rank[us] == rank(i) && game.board[square2] == null) {
            add_move(moves, i, square2, BITS_BIG_PAWN);
          }
        }

        /* pawn captures */
        for (int j = 2; j < 4; j++) {
          int square = i + PAWN_OFFSETS[us][j];
          if ((square & 0x88) != 0) continue;

          if (game.board[square] != null && game.board[square].color == them) {
            add_move(moves, i, square, BITS_CAPTURE);
          } else if (square == game.epSquare) {
            add_move(moves, i, game.epSquare, BITS_EP_CAPTURE);
          }
        }
      } else {
        for (int j = 0, len = PIECE_OFFSETS[piece.type].length; j < len; j++) {
          var offset = PIECE_OFFSETS[piece.type][j];
          var square = i;

          while (true) {
            square += offset;
            if ((square & 0x88) != 0) break;

            if (game.board[square] == null) {
              add_move(moves, i, square, BITS_NORMAL);
            } else {
              if (game.board[square].color == us) {
                break;
              }
              add_move(moves, i, square, BITS_CAPTURE);
              break;
            }

            /* break, if knight or king */
            if (piece.type == KNIGHT || piece.type == KING) break;
          }
        }
      }
    }

    // check for castling if: a) we're generating all moves, or b) we're doing
    // single square move generation on the king's square
    if ((!single_square) || last_sq == game.kings[us]) {
      /* king-side castling */
      if ((game.castling[us] & BITS_KSIDE_CASTLE) != 0) {
        var castling_from = game.kings[us];
        var castling_to = castling_from + 2;

        if (game.board[castling_from + 1] == null &&
            game.board[castling_to] == null &&
            !attacked(them, game.kings[us]) &&
            !attacked(them, castling_from + 1) &&
            !attacked(them, castling_to)) {
          add_move(moves, game.kings[us], castling_to, BITS_KSIDE_CASTLE);
        }
      }

      /* queen-side castling */
      if ((game.castling[us] & BITS_QSIDE_CASTLE) != 0) {
        var castling_from = game.kings[us];
        var castling_to = castling_from - 2;

        if (game.board[castling_from - 1] == null &&
            game.board[castling_from - 2] == null &&
            game.board[castling_from - 3] == null &&
            !attacked(them, game.kings[us]) &&
            !attacked(them, castling_from - 1) &&
            !attacked(them, castling_to)) {
          add_move(moves, game.kings[us], castling_to, BITS_QSIDE_CASTLE);
        }
      }
    }

    /* return all pseudo-legal moves (this includes moves that allow the king
     * to be captured)
     */
    List<Move> legalMoves = [];
    for (int i = 0, len = moves.length; i < len; i++) {
      makeMove(moves[i]);
      if (!king_attacked(us)) {
        legalMoves.add(moves[i]);
      }
      undo();
    }

    return legalMoves;
  }

  //for the last depth, normally all moves are generated,
  //but since we dont need the pure move object,
  //here a simplification is done for performance so that not over 1M+ moves have
  //to be generated every time
  //this will just return the move count, since it will just be check if it is zero
  bool moveCountIsZero([bool checkLegal]) {
    if (checkLegal == null) checkLegal = true;

    // ignore: non_constant_identifier_names
    void add_move(List<Move> moves, from, to, flags) {
      /* if pawn promotion */
      if (game.board[from].type == PAWN &&
          (rank(to) == RANK_8 || rank(to) == RANK_1)) {
        List pieces = [QUEEN, ROOK, BISHOP, KNIGHT];
        for (var i = 0, len = pieces.length; i < len; i++) {
          moves.add(build_move(game.board, from, to, flags, pieces[i]));
        }
      } else {
        moves.add(build_move(game.board, from, to, flags));
      }
    }

    List<Move> moves = [];
    Color us = game.turn;
    Color them = swap_color(us);
    ColorMap second_rank = new ColorMap.of(0);
    second_rank[BLACK] = RANK_7;
    second_rank[WHITE] = RANK_2;

    var first_sq = SQUARES_A8;
    var last_sq = SQUARES_H1;
    bool single_square = false;

    for (int i = first_sq; i <= last_sq; i++) {
      /* did we run off the end of the board */
      if ((i & 0x88) != 0) {
        i += 7;
        continue;
      }

      Piece piece = game.board[i];
      if (piece == null || piece.color != us) {
        continue;
      }

      if (piece.type == PAWN) {
        /* single square, non-capturing */
        int square = i + PAWN_OFFSETS[us][0];
        if (game.board[square] == null) {
          if (!checkLegal) return false;
          add_move(moves, i, square, BITS_NORMAL);

          /* double square */
          var square2 = i + PAWN_OFFSETS[us][1];
          if (second_rank[us] == rank(i) && game.board[square2] == null) {
            add_move(moves, i, square2, BITS_BIG_PAWN);
          }
        }

        /* pawn captures */
        for (int j = 2; j < 4; j++) {
          int square = i + PAWN_OFFSETS[us][j];
          if ((square & 0x88) != 0) continue;

          if (game.board[square] != null && game.board[square].color == them) {
            if (!checkLegal) return false;
            add_move(moves, i, square, BITS_CAPTURE);
          } else if (square == game.epSquare) {
            if (!checkLegal) return false;
            add_move(moves, i, game.epSquare, BITS_EP_CAPTURE);
          }
        }
      } else {
        for (int j = 0, len = PIECE_OFFSETS[piece.type].length; j < len; j++) {
          var offset = PIECE_OFFSETS[piece.type][j];
          var square = i;

          while (true) {
            square += offset;
            if ((square & 0x88) != 0) break;

            if (game.board[square] == null) {
              if (!checkLegal) return false;
              add_move(moves, i, square, BITS_NORMAL);
            } else {
              if (game.board[square].color == us) {
                break;
              }
              if (!checkLegal) return false;
              add_move(moves, i, square, BITS_CAPTURE);
              break;
            }

            /* break, if knight or king */
            if (piece.type == KNIGHT || piece.type == KING) break;
          }
        }
      }
    }

    // check for castling if: a) we're generating all moves, or b) we're doing
    // single square move generation on the king's square
    if ((!single_square) || last_sq == game.kings[us]) {
      /* king-side castling */
      if ((game.castling[us] & BITS_KSIDE_CASTLE) != 0) {
        var castling_from = game.kings[us];
        var castling_to = castling_from + 2;

        if (game.board[castling_from + 1] == null &&
            game.board[castling_to] == null &&
            !attacked(them, game.kings[us]) &&
            !attacked(them, castling_from + 1) &&
            !attacked(them, castling_to)) {
          if (!checkLegal) return false;
          add_move(moves, game.kings[us], castling_to, BITS_KSIDE_CASTLE);
        }
      }

      /* queen-side castling */
      if ((game.castling[us] & BITS_QSIDE_CASTLE) != 0) {
        var castling_from = game.kings[us];
        var castling_to = castling_from - 2;

        if (game.board[castling_from - 1] == null &&
            game.board[castling_from - 2] == null &&
            game.board[castling_from - 3] == null &&
            !attacked(them, game.kings[us]) &&
            !attacked(them, castling_from - 1) &&
            !attacked(them, castling_to)) {
          if (!checkLegal) return false;
          add_move(moves, game.kings[us], castling_to, BITS_QSIDE_CASTLE);
        }
      }
    }

    //if it did make it this far, return true
    if (!checkLegal) return true;

    List<Move> legal_moves = [];
    for (int i = 0, len = moves.length; i < len; i++) {
      makeMove(moves[i]);
      if (!king_attacked(us)) {
        legal_moves.add(moves[i]);
      }
      undo();
    }

    return legal_moves.length == 0;
  }

  /// Convert a move from 0x88 coordinates to Standard Algebraic Notation(SAN)
  String moveToSan(Move move) {
    String output = '';
    int flags = move.flags;
    if ((flags & BITS_KSIDE_CASTLE) != 0) {
      output = 'O-O';
    } else if ((flags & BITS_QSIDE_CASTLE) != 0) {
      output = 'O-O-O';
    } else {
      var disambiguator = get_disambiguator(move);

      if (move.piece != PAWN) {
        output += move.piece.toUpperCase() + disambiguator;
      }

      if ((flags & (BITS_CAPTURE | BITS_EP_CAPTURE)) != 0) {
        if (move.piece == PAWN) {
          output += move.fromAlgebraic[0];
        }
        output += 'x';
      }

      output += move.toAlgebraic;

      if ((flags & BITS_PROMOTION) != 0) {
        output += '=' + move.promotion.toUpperCase();
      }
    }

    makeMove(move);
    if (in_check()) {
      if (inCheckmate(moveCountIsZero())) {
        output += '#';
      } else {
        output += '+';
      }
    }
    undo();

    return output;
  }

  bool attacked(Color color, int square) {
    for (int i = SQUARES_A8; i <= SQUARES_H1; i++) {
      /* did we run off the end of the board */
      if ((i & 0x88) != 0) {
        i += 7;
        continue;
      }

      /* if empty square or wrong color */
      Piece piece = game.board[i];
      if (piece == null || piece.color != color) continue;

      var difference = i - square;
      var index = difference + 119;
      PieceType type = piece.type;

      if ((ATTACKS[index] & (1 << type.shift)) != 0) {
        if (type == PAWN) {
          if (difference > 0) {
            if (color == WHITE) return true;
          } else {
            if (color == BLACK) return true;
          }
          continue;
        }

        /* if the piece is a knight or a king */
        if (type == KNIGHT || type == KING) return true;

        var offset = RAYS[index];
        var j = i + offset;

        var blocked = false;
        while (j != square) {
          if (game.board[j] != null) {
            blocked = true;
            break;
          }
          j += offset;
        }

        if (!blocked) return true;
      }
    }

    return false;
  }

  bool king_attacked(Color color) {
    return attacked(swap_color(color), game.kings[color]);
  }

  bool in_check() {
    return king_attacked(game.turn);
  }

  bool inCheckmate(bool genMoveZero) {
    return in_check() && genMoveZero;
  }

  bool inStalemate(bool genMoveZero) {
    return !in_check() && genMoveZero;
  }

  bool insufficientMaterial() {
    Map pieces = {};
    List bishops = [];
    int num_pieces = 0;
    var sq_color = 0;

    for (int i = SQUARES_A8; i <= SQUARES_H1; i++) {
      sq_color = (sq_color + 1) % 2;
      if ((i & 0x88) != 0) {
        i += 7;
        continue;
      }

      var piece = game.board[i];
      if (piece != null) {
        pieces[piece.type] =
            (pieces.containsKey(piece.type)) ? pieces[piece.type] + 1 : 1;
        if (piece.type == BISHOP) {
          bishops.add(sq_color);
        }
        num_pieces++;
      }
    }

    /* k vs. k */
    if (num_pieces == 2) {
      return true;
    }
    /* k vs. kn .... or .... k vs. kb */
    else if (num_pieces == 3 && (pieces[BISHOP] == 1 || pieces[KNIGHT] == 1)) {
      return true;
    }
    /* kb vs. kb where any number of bishops are all on the same color */
    else if (pieces.containsKey(BISHOP) && num_pieces == (pieces[BISHOP] + 2)) {
      var sum = 0;
      var len = bishops.length;
      for (int i = 0; i < len; i++) {
        sum += bishops[i];
      }
      if (sum == 0 || sum == len) {
        return true;
      }
    }

    return false;
  }

  bool in_threefold_repetition() {
    //don't check for this because of performance
    return false;
    /* TODO: while this function is fine for casual use, a better
     * implementation would use a Zobrist key (instead of FEN). the
     * Zobrist key would be maintained in the make_move/undo_move functions,
     * avoiding the costly that we do below.
     */

    /*List moves = [];
    Map positions = {};
    bool repetition = false;

    while (true) {
      var move = undo();
      if (move == null) {
        break;
      }
      moves.add(move);
    }

    while (true) {
      /* remove the last two fields in the FEN string, they're not needed
       * when checking for draw by rep */
      var fen = generate_fen().split(' ').sublist(0, 4).join(' ');

      /* has the position occurred three or move times */
      positions[fen] = (positions.containsKey(fen)) ? positions[fen] + 1 : 1;
      if (positions[fen] >= 3) {
        repetition = true;
      }

      if (moves.length == 0) {
        break;
      }
      make_move(moves.removeLast());
    }

    return repetition;*/
  }

  void push(Move move) {
    game.history.add(new State(
        move,
        new ColorMap.clone(game.kings),
        game.turn,
        new ColorMap.clone(game.castling),
        game.epSquare,
        game.halfMoves,
        game.moveNumber));
  }

  void makeMove(Move move) {
    Color us = game.turn;
    Color them = swap_color(us);
    push(move);

    game.board[move.to] = game.board[move.from];
    game.board[move.from] = null;

    /* if ep capture, remove the captured pawn */
    if ((move.flags & BITS_EP_CAPTURE) != 0) {
      if (game.turn == BLACK) {
        game.board[move.to - 16] = null;
      } else {
        game.board[move.to + 16] = null;
      }
    }

    /* if pawn promotion, replace with new piece */
    if ((move.flags & BITS_PROMOTION) != 0) {
      game.board[move.to] = Piece(move.promotion, us);
    }

    /* if we moved the king */
    if (game.board[move.to].type == KING) {
      game.kings[game.board[move.to].color] = move.to;

      /* if we castled, move the rook next to the king */
      if ((move.flags & BITS_KSIDE_CASTLE) != 0) {
        var castling_to = move.to - 1;
        var castling_from = move.to + 1;
        game.board[castling_to] = game.board[castling_from];
        game.board[castling_from] = null;
      } else if ((move.flags & BITS_QSIDE_CASTLE) != 0) {
        var castling_to = move.to + 1;
        var castling_from = move.to - 2;
        game.board[castling_to] = game.board[castling_from];
        game.board[castling_from] = null;
      }

      /* turn off castling */
      game.castling[us] = 0;
    }

    /* turn off castling if we move a rook */
    if (game.castling[us] != 0) {
      for (int i = 0, len = ROOKS[us].length; i < len; i++) {
        if (move.from == ROOKS[us][i]['square'] &&
            ((game.castling[us] & ROOKS[us][i]['flag']) != 0)) {
          game.castling[us] ^= ROOKS[us][i]['flag'];
          break;
        }
      }
    }

    /* turn off castling if we capture a rook */
    if (game.castling[them] != 0) {
      for (int i = 0, len = ROOKS[them].length; i < len; i++) {
        if (move.to == ROOKS[them][i]['square'] &&
            ((game.castling[them] & ROOKS[them][i]['flag']) != 0)) {
          game.castling[them] ^= ROOKS[them][i]['flag'];
          break;
        }
      }
    }

    /* if big pawn move, update the en passant square */
    if ((move.flags & BITS_BIG_PAWN) != 0) {
      if (game.turn == BLACK) {
        game.epSquare = move.to - 16;
      } else {
        game.epSquare = move.to + 16;
      }
    } else {
      game.epSquare = EMPTY;
    }

    /* reset the 50 move counter if a pawn is moved or a piece is captured */
    if (move.piece == PAWN) {
      game.halfMoves = 0;
    } else if ((move.flags & (BITS_CAPTURE | BITS_EP_CAPTURE)) != 0) {
      game.halfMoves = 0;
    } else {
      game.halfMoves++;
    }

    if (game.turn == BLACK) {
      game.moveNumber++;
    }
    game.turn = swap_color(game.turn);
  }

  /// Undoes a move and returns it, or null if move history is empty
  Move undo() {
    if (game.history.isEmpty) {
      return null;
    }
    State old = game.history.removeLast();
    if (old == null) {
      return null;
    }

    Move move = old.move;
    game.kings = old.kings;
    game.turn = old.turn;
    game.castling = old.castling;
    game.epSquare = old.epSquare;
    game.halfMoves = old.halfMoves;
    game.moveNumber = old.moveNumber;

    Color us = game.turn;
    Color them = swap_color(game.turn);

    game.board[move.from] = game.board[move.to];
    game.board[move.from].type = move.piece; // to undo any promotions
    game.board[move.to] = null;

    if ((move.flags & BITS_CAPTURE) != 0) {
      game.board[move.to] = new Piece(move.captured, them);
    } else if ((move.flags & BITS_EP_CAPTURE) != 0) {
      var index;
      if (us == BLACK) {
        index = move.to - 16;
      } else {
        index = move.to + 16;
      }
      game.board[index] = new Piece(PAWN, them);
    }

    if ((move.flags & (BITS_KSIDE_CASTLE | BITS_QSIDE_CASTLE)) != 0) {
      var castling_to, castling_from;
      if ((move.flags & BITS_KSIDE_CASTLE) != 0) {
        castling_to = move.to + 1;
        castling_from = move.to - 1;
      } else if ((move.flags & BITS_QSIDE_CASTLE) != 0) {
        castling_to = move.to - 2;
        castling_from = move.to + 1;
      }

      game.board[castling_to] = game.board[castling_from];
      game.board[castling_from] = null;
    }

    return move;
  }

  /* this function is used to uniquely identify ambiguous moves */
  get_disambiguator(Move move) {
    List<Move> moves = generateMoves();

    var from = move.from;
    var to = move.to;
    var piece = move.piece;

    var ambiguities = 0;
    var same_rank = 0;
    var same_file = 0;

    for (int i = 0, len = moves.length; i < len; i++) {
      var ambig_from = moves[i].from;
      var ambig_to = moves[i].to;
      var ambig_piece = moves[i].piece;

      /* if a move of the same piece type ends on the same to square, we'll
       * need to add a disambiguator to the algebraic notation
       */
      if (piece == ambig_piece && from != ambig_from && to == ambig_to) {
        ambiguities++;

        if (rank(from) == rank(ambig_from)) {
          same_rank++;
        }

        if (file(from) == file(ambig_from)) {
          same_file++;
        }
      }
    }

    if (ambiguities > 0) {
      /* if there exists a similar moving piece on the same rank and file as
       * the move in question, use the square as the disambiguator
       */
      if (same_rank > 0 && same_file > 0) {
        return algebraic(from);
      }
      /* if the moving piece rests on the same file, use the rank symbol as the
       * disambiguator
       */
      else if (same_file > 0) {
        return algebraic(from)[1];
      }
      /* else use the file symbol */
      else {
        return algebraic(from)[0];
      }
    }

    return '';
  }

  /// Returns a String representation of the current position
  /// complete with ascii art
  String get ascii {
    String s = '   +------------------------+\n';
    for (var i = SQUARES_A8; i <= SQUARES_H1; i++) {
      /* display the rank */
      if (file(i) == 0) {
        s += ' ' + '87654321'[rank(i)] + ' |';
      }

      /* empty piece */
      if (game.board[i] == null) {
        s += ' . ';
      } else {
        PieceType type = game.board[i].type;
        Color color = game.board[i].color;
        var symbol = (color == WHITE) ? type.toUpperCase() : type.toLowerCase();
        s += ' ' + symbol + ' ';
      }

      if (((i + 1) & 0x88) != 0) {
        s += '|\n';
        i += 8;
      }
    }
    s += '   +------------------------+\n';
    s += '     a  b  c  d  e  f  g  h\n';

    return s;
  }

  // Utility Functions
  //the y, but strangely inverted, so (87654321)
  static int rank(int i) {
    return i >> 4;
  }

  //the x, so (abcdefg)
  static int file(int i) {
    return i & 15;
  }

  static String algebraic(int i) {
    var f = file(i), r = rank(i);
    return 'abcdefgh'.substring(f, f + 1) + '87654321'.substring(r, r + 1);
  }

  static Color swap_color(Color c) {
    return c == WHITE ? BLACK : WHITE;
  }

  static bool is_digit(String c) {
    return '0123456789'.contains(c);
  }

  void forEachPiece(ForEachPieceCallback callback) {
    for (int i = Chess.SQUARES_A8; i <= Chess.SQUARES_H1; i++) {
      if ((i & 0x88) != 0) {
        i += 7;
        continue;
      }

      Piece piece = game.board[i];
      if (piece != null && callback != null) {
        callback(piece);
      }
    }
  }

  //reads the board to a matrix that can be entered into the trained tensorflow model
  List<List<List<double>>> transformForTFModel() {
    List<List<List<double>>> matrix = [];
    List<List<double>> currentList;
    for (int i = Chess.SQUARES_A8; i <= Chess.SQUARES_H1; i++) {
      if ((i & 0x88) != 0) {
        i += 7;
        continue;
      }

      if (i % 8 == 0) {
        if (currentList != null) matrix.add(currentList);
        currentList = [];
      }

      Piece piece = game.board[i];
      currentList
          .add(TRANSFORMATION_MAP[piece == null ? '.' : piece.toString()]);

      if (i == SQUARES_H1) matrix.add(currentList);
    }

    return matrix;
  }

  //reads the board to a matrix that can be entered into the trained tensorflow model
  List<double> transformForTFModelFlat() {
    List<double> matrix = [];
    for (int i = Chess.SQUARES_A8; i <= Chess.SQUARES_H1; i++) {
      if ((i & 0x88) != 0) {
        i += 7;
        continue;
      }

      Piece piece = game.board[i];
      for (double i
          in TRANSFORMATION_MAP[piece == null ? '.' : piece.toString()])
        matrix.add(i);
    }

    return matrix;
  }

  String trim(String str) {
    return str.replaceAll(new RegExp(r"^\s+|\s+$"), '');
  }

  bool lastInDraw = false;

  bool inDraw(bool genMoveZero) {
    return lastInDraw = (game.halfMoves >= 100 ||
        inStalemate(genMoveZero) ||
        insufficientMaterial() ||
        in_threefold_repetition());
  }

  bool gameOver(bool genMoveZero) {
    return inDraw(genMoveZero) || inCheckmate(genMoveZero);
  }

  String get fen {
    return generate_fen();
  }

  /// The move function can be called with in the following parameters:
  /// .move('Nxb7')      <- where 'move' is a case-sensitive SAN string
  /// .move({ from: 'h7', <- where the 'move' is a move object (additional
  ///      to :'h8',      fields are ignored)
  ///      promotion: 'q',
  ///      })
  /// or it can be called with a Move object
  /// It returns true if the move was made, or false if it could not be.
  bool move(move) {
    Move move_obj = null;
    List<Move> moves = generateMoves();

    if (move is String) {
      /* convert the move string to a move object */
      for (int i = 0; i < moves.length; i++) {
        if (move == moveToSan(moves[i])) {
          move_obj = moves[i];
          break;
        }
      }
    } else if (move is Map) {
      /* convert the pretty move object to an ugly move object */
      for (var i = 0; i < moves.length; i++) {
        if (move['from'] == moves[i].fromAlgebraic &&
            move['to'] == moves[i].toAlgebraic &&
            (moves[i].promotion == null ||
                move['promotion'] == moves[i].promotion.name)) {
          move_obj = moves[i];
          break;
        }
      }
    } else if (move is Move) {
      move_obj = move;
    }

    /* failed to find move */
    if (move_obj == null) {
      return false;
    }

    /* need to make a copy of move because we can't generate SAN after the
       * move is made
       */

    makeMove(move_obj);

    return true;
  }

  /// Returns the color of the square ('light' or 'dark'), or null if [square] is invalid
  String square_color(square) {
    if (SQUARES.containsKey(square)) {
      var sq_0x88 = SQUARES[square];
      return ((rank(sq_0x88) + file(sq_0x88)) % 2 == 0) ? 'light' : 'dark';
    }

    return null;
  }

  // Constants/Class Variables
  static const Color BLACK = Color.BLACK;
  static const Color WHITE = Color.WHITE;

  static const int EMPTY = -1;

  static const PieceType PAWN = PieceType.PAWN;
  static const PieceType KNIGHT = PieceType.KNIGHT;
  static const PieceType BISHOP = PieceType.BISHOP;
  static const PieceType ROOK = PieceType.ROOK;
  static const PieceType QUEEN = PieceType.QUEEN;
  static const PieceType KING = PieceType.KING;

  static const Map<String, PieceType> PIECE_TYPES = const {
    'p': PieceType.PAWN,
    'n': PieceType.KNIGHT,
    'b': PieceType.BISHOP,
    'r': PieceType.ROOK,
    'q': PieceType.QUEEN,
    'k': PieceType.KING
  };

  static const String SYMBOLS = 'pnbrqkPNBRQK';

  static const String DEFAULT_POSITION =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  static const List POSSIBLE_RESULTS = const ['1-0', '0-1', '1/2-1/2', '*'];

  static Map<Color, List> PAWN_OFFSETS = {
    BLACK: const [16, 32, 17, 15],
    WHITE: const [-16, -32, -17, -15]
  };

  static const Map<PieceType, List> PIECE_OFFSETS = const {
    KNIGHT: const [-18, -33, -31, -14, 18, 33, 31, 14],
    BISHOP: const [-17, -15, 17, 15],
    ROOK: const [-16, 1, 16, -1],
    QUEEN: const [-17, -16, -15, 1, 17, 16, 15, -1],
    KING: const [-17, -16, -15, 1, 17, 16, 15, -1]
  };

  static const List ATTACKS = const [
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    24,
    0,
    0,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    0,
    24,
    0,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    24,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    24,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    24,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    20,
    2,
    24,
    2,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    2,
    53,
    56,
    53,
    2,
    0,
    0,
    0,
    0,
    0,
    0,
    24,
    24,
    24,
    24,
    24,
    24,
    56,
    0,
    56,
    24,
    24,
    24,
    24,
    24,
    24,
    0,
    0,
    0,
    0,
    0,
    0,
    2,
    53,
    56,
    53,
    2,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    20,
    2,
    24,
    2,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    24,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    24,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    24,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    0,
    24,
    0,
    0,
    0,
    0,
    0,
    20,
    0,
    0,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    24,
    0,
    0,
    0,
    0,
    0,
    0,
    20
  ];

  static const List RAYS = const [
    17,
    0,
    0,
    0,
    0,
    0,
    0,
    16,
    0,
    0,
    0,
    0,
    0,
    0,
    15,
    0,
    0,
    17,
    0,
    0,
    0,
    0,
    0,
    16,
    0,
    0,
    0,
    0,
    0,
    15,
    0,
    0,
    0,
    0,
    17,
    0,
    0,
    0,
    0,
    16,
    0,
    0,
    0,
    0,
    15,
    0,
    0,
    0,
    0,
    0,
    0,
    17,
    0,
    0,
    0,
    16,
    0,
    0,
    0,
    15,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    17,
    0,
    0,
    16,
    0,
    0,
    15,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    17,
    0,
    16,
    0,
    15,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    17,
    16,
    15,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    0,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    -15,
    -16,
    -17,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    -15,
    0,
    -16,
    0,
    -17,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    -15,
    0,
    0,
    -16,
    0,
    0,
    -17,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    -15,
    0,
    0,
    0,
    -16,
    0,
    0,
    0,
    -17,
    0,
    0,
    0,
    0,
    0,
    0,
    -15,
    0,
    0,
    0,
    0,
    -16,
    0,
    0,
    0,
    0,
    -17,
    0,
    0,
    0,
    0,
    -15,
    0,
    0,
    0,
    0,
    0,
    -16,
    0,
    0,
    0,
    0,
    0,
    -17,
    0,
    0,
    -15,
    0,
    0,
    0,
    0,
    0,
    0,
    -16,
    0,
    0,
    0,
    0,
    0,
    0,
    -17
  ];

  static const Map<String, String> FLAGS = const {
    'NORMAL': 'n',
    'CAPTURE': 'c',
    'BIG_PAWN': 'b',
    'EP_CAPTURE': 'e',
    'PROMOTION': 'p',
    'KSIDE_CASTLE': 'k',
    'QSIDE_CASTLE': 'q'
  };

  static const Map<String, int> BITS = const {
    'NORMAL': BITS_NORMAL,
    'CAPTURE': BITS_CAPTURE,
    'BIG_PAWN': BITS_BIG_PAWN,
    'EP_CAPTURE': BITS_EP_CAPTURE,
    'PROMOTION': BITS_PROMOTION,
    'KSIDE_CASTLE': BITS_KSIDE_CASTLE,
    'QSIDE_CASTLE': BITS_QSIDE_CASTLE
  };

  static const int BITS_NORMAL = 1;
  static const int BITS_CAPTURE = 2;
  static const int BITS_BIG_PAWN = 4;
  static const int BITS_EP_CAPTURE = 8;
  static const int BITS_PROMOTION = 16;
  static const int BITS_KSIDE_CASTLE = 32;
  static const int BITS_QSIDE_CASTLE = 64;

  static const int RANK_1 = 7;
  static const int RANK_2 = 6;
  static const int RANK_3 = 5;
  static const int RANK_4 = 4;
  static const int RANK_5 = 3;
  static const int RANK_6 = 2;
  static const int RANK_7 = 1;
  static const int RANK_8 = 0;

  static const Map SQUARES = const {
    'a8': 0,
    'b8': 1,
    'c8': 2,
    'd8': 3,
    'e8': 4,
    'f8': 5,
    'g8': 6,
    'h8': 7,
    'a7': 16,
    'b7': 17,
    'c7': 18,
    'd7': 19,
    'e7': 20,
    'f7': 21,
    'g7': 22,
    'h7': 23,
    'a6': 32,
    'b6': 33,
    'c6': 34,
    'd6': 35,
    'e6': 36,
    'f6': 37,
    'g6': 38,
    'h6': 39,
    'a5': 48,
    'b5': 49,
    'c5': 50,
    'd5': 51,
    'e5': 52,
    'f5': 53,
    'g5': 54,
    'h5': 55,
    'a4': 64,
    'b4': 65,
    'c4': 66,
    'd4': 67,
    'e4': 68,
    'f4': 69,
    'g4': 70,
    'h4': 71,
    'a3': 80,
    'b3': 81,
    'c3': 82,
    'd3': 83,
    'e3': 84,
    'f3': 85,
    'g3': 86,
    'h3': 87,
    'a2': 96,
    'b2': 97,
    'c2': 98,
    'd2': 99,
    'e2': 100,
    'f2': 101,
    'g2': 102,
    'h2': 103,
    'a1': 112,
    'b1': 113,
    'c1': 114,
    'd1': 115,
    'e1': 116,
    'f1': 117,
    'g1': 118,
    'h1': 119
  };

  // ignore: non_constant_identifier_names
  static const Map TRANSFORMATION_MAP = {
    'p': <double>[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'P': <double>[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
    'n': <double>[0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'N': <double>[0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
    'b': <double>[0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'B': <double>[0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
    'r': <double>[0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    'R': <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
    'q': <double>[0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
    'Q': <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
    'k': <double>[0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
    'K': <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    '.': <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  };

  static const int SQUARES_A1 = 112;
  static const int SQUARES_A8 = 0;
  static const int SQUARES_H1 = 119;
  static const int SQUARES_H8 = 7;

  static final Map<Color, List> ROOKS = {
    WHITE: [
      {'square': SQUARES_A1, 'flag': BITS_QSIDE_CASTLE},
      {'square': SQUARES_H1, 'flag': BITS_KSIDE_CASTLE}
    ],
    BLACK: [
      {'square': SQUARES_A8, 'flag': BITS_QSIDE_CASTLE},
      {'square': SQUARES_H8, 'flag': BITS_KSIDE_CASTLE}
    ]
  };
}
