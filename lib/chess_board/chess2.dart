import 'package:chess_bot/chess_board/src/chess_sub.dart';

/// Class
class Chess2 {
  //game instances
  List<Piece> board = List(128);
  Color turn = Color.WHITE;
  ColorMap castling = ColorMap.of(0);
  int epSquare = -1;
  int halfMoves = 0;
  int moveNumber = 1;
  List<State2> history = [];
  Map pieces = {
    KING: {WHITE: EMPTY, BLACK: EMPTY},
    QUEEN: {WHITE: [], BLACK: []},
    ROOK: {WHITE: [], BLACK: []},
    BISHOP: {WHITE: [], BLACK: []},
    KNIGHT: {WHITE: [], BLACK: []},
    PAWN: {WHITE: [], BLACK: []}
  };
  Map squaresNearKing = {WHITE: [], BLACK: []};
  Map pawnControl = {WHITE: {}, BLACK: {}};
  Map pawnCountsByRank = {
    WHITE: [0, 0, 0, 0, 0, 0, 0, 0],
    BLACK: [0, 0, 0, 0, 0, 0, 0, 0]
  };
  Map pawnCountsByFile = {
    WHITE: [0, 0, 0, 0, 0, 0, 0, 0],
    BLACK: [0, 0, 0, 0, 0, 0, 0, 0]
  };

  Chess2() {
    this.clear();
    this.reset();
  }

  Chess2.fromFen(String fen) {
    loadFen(fen);
  }

  clear() {
    this.board = List(128);
    this.pieces = {
      KING: {WHITE: EMPTY, BLACK: EMPTY},
      QUEEN: {WHITE: [], BLACK: []},
      ROOK: {WHITE: [], BLACK: []},
      BISHOP: {WHITE: [], BLACK: []},
      KNIGHT: {WHITE: [], BLACK: []},
      PAWN: {WHITE: [], BLACK: []}
    };
    this.turn = WHITE;
    this.castling = ColorMap.of(0);
    this.epSquare = EMPTY;
    this.halfMoves = 0;
    this.moveNumber = 1;
    this.history = [];
    this.squaresNearKing = {WHITE: [], BLACK: []};
    this.pawnControl = {WHITE: {}, BLACK: {}};
    this.pawnCountsByRank = {
      WHITE: [0, 0, 0, 0, 0, 0, 0, 0],
      BLACK: [0, 0, 0, 0, 0, 0, 0, 0]
    };
    this.pawnCountsByFile = {
      WHITE: [0, 0, 0, 0, 0, 0, 0, 0],
      BLACK: [0, 0, 0, 0, 0, 0, 0, 0]
    };
  }

  get fen {
    return generateFen();
  }

  Chess2 copy() {
    return new Chess2()
      ..board = List<Piece>.from(this.board)
      ..turn = Color.fromInt(this.turn.value)
      ..castling = new ColorMap.clone(this.castling)
      ..epSquare = this.epSquare
      ..halfMoves = this.halfMoves
      ..moveNumber = this.moveNumber
      ..history = List<State2>.from(this.history);
  }

  reset() {
    this.loadFen(DEFAULT_POSITION);
  }

  bool loadFen(String fen) {
    List tokens = fen.split(new RegExp(r"\s+"));
    String position = tokens[0];
    int square = 0;

    Map validMap = validateFen(fen);
    if (!validMap['valid']) {
      print(validMap['error']);
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
        putPiece(Piece(type, color), square);
        square++;
      }
    }

    if (tokens[1] == 'w') {
      turn = WHITE;
    } else {
      assert(tokens[1] == 'b');
      turn = BLACK;
    }

    if (tokens[2].indexOf('K') > -1) {
      castling[WHITE] |= BITS_KSIDE_CASTLE;
    }
    if (tokens[2].indexOf('Q') > -1) {
      castling[WHITE] |= BITS_QSIDE_CASTLE;
    }
    if (tokens[2].indexOf('k') > -1) {
      castling[BLACK] |= BITS_KSIDE_CASTLE;
    }
    if (tokens[2].indexOf('q') > -1) {
      castling[BLACK] |= BITS_QSIDE_CASTLE;
    }

    epSquare = (tokens[3] == '-') ? EMPTY : SQUARES[tokens[3]];
    halfMoves = int.parse(tokens[4]);
    moveNumber = int.parse(tokens[5]);

    return true;
  }

  static Map validateFen(fen) {
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
    temp = int.parse(tokens[4], onError: (string) => null);
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

  String generateFen() {
    int empty = 0;
    String fen = '';

    for (int i = SQUARES_A8; i <= SQUARES_H1; i++) {
      if (board[i] == null) {
        empty++;
      } else {
        if (empty > 0) {
          fen += empty.toString();
          empty = 0;
        }
        Color color = board[i].color;
        PieceType type = board[i].type;

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
    if ((castling[WHITE] & BITS_KSIDE_CASTLE) != 0) {
      cflags += 'K';
    }
    if ((castling[WHITE] & BITS_QSIDE_CASTLE) != 0) {
      cflags += 'Q';
    }
    if ((castling[BLACK] & BITS_KSIDE_CASTLE) != 0) {
      cflags += 'k';
    }
    if ((castling[BLACK] & BITS_QSIDE_CASTLE) != 0) {
      cflags += 'q';
    }

    /* do we have an empty castling flag? */
    if (cflags == "") {
      cflags = '-';
    }
    String epflags = (epSquare == EMPTY) ? '-' : algebraic(epSquare);

    return [fen, turn, cflags, epflags, halfMoves, moveNumber].join(' ');
  }

  Piece getPiece(square) {
    if (square is int)
      return this.board[square];
    else if (square is String)
      return board[SQUARES[square]];
    else
      return null;
    // final piece = this.board[square];
    // return piece ? { type: piece.type, color: piece.color } : null;
  }

  bool checkPiece(int square, Color color, PieceType type) {
    final piece = this.getPiece(square);
    if (piece == null) return false;
    return piece.color == color && piece.type == type;
  }

  void putPiece(Piece piece, int square) {
    this.board[square] = piece;

    if (piece.type == KING) {
      this.pieces[KING][piece.color] = square;
      this.setSquaresNearKing(piece, square);
    } else {
      this.pieces[piece.type][piece.color].add(square);

      if (piece.type == PAWN) {
        this.addPawnControl(piece, square);
        this.addPawnCounts(piece, square);
      }
    }
  }

  void removePiece(int square) {
    final piece = this.getPiece(square);
    if (piece == null) return;

    this.board[square] = null;

    if (piece.type == KING) {
      this.pieces[KING][piece.color] = EMPTY;
      this.squaresNearKing[piece.color] = [];
    } else {
      final pieces = this.pieces[piece.type][piece.color];
      final index = pieces.indexOf(square);
      pieces.splice(index, 1);

      if (piece.type == PAWN) {
        this.removePawnControl(piece, square);
        this.removePawnCounts(piece, square);
      }
    }
  }

  void movePiece(int from, int to) {
    final piece = this.getPiece(from);
    if (piece == null) return;

    this.board[from] = null;
    this.board[to] = piece;

    if (piece.type == KING) {
      this.pieces[KING][piece.color] = to;
      this.setSquaresNearKing(piece, to);
    } else {
      final pieces = this.pieces[piece.type][piece.color];
      final index = pieces.indexOf(from);
      pieces.splice(index, 1, to);

      if (piece.type == PAWN) {
        this.removePawnControl(piece, from);
        this.addPawnControl(piece, to);
        this.removePawnCounts(piece, from);
        this.addPawnCounts(piece, to);
      }
    }
  }

  forEachPiece(callback) {
    for (var i = SQUARES['a8']; i <= SQUARES['h1']; i++) {
      if (i & 0x88) {
        i += 7;
        continue;
      }

      final piece = this.getPiece(i);
      if (piece == null) continue;
      callback(piece, i);
    }
  }

  setSquaresNearKing(piece, square) {
    // if (piece.type != KING) return;

    this.squaresNearKing[piece.color] = [
          square + V['NORTH'],
          square + V['SOUTH'],
          square + V['EAST'],
          square + V['WEST'],
          square + V['NW'],
          square + V['NE'],
          square + V['SW'],
          square + V['SE']
        ] +
        (piece.color == WHITE
            ? [
                square + V['NN'],
                square + V['NORTH'] + V['NE'],
                square + V['NORTH'] + V['NW']
              ]
            : [
                square + V['SS'],
                square + V['SOUTH'] + V['SE'],
                square + V['SOUTH'] + V['SW']
              ]);
    //.filter(validateSquare); // Validation is so slow
  }

  void addPawnControl(Piece piece, square) {
    // if (piece.type != PAWN) return;

    final squares = [
      square + (piece.color == WHITE ? V['NE'] : V['SE']),
      square + (piece.color == WHITE ? V['NW'] : V['SW'])
    ];

    squares
        // .filter(validateSquare) // Validation is so slow
        .forEach((square) {
      if (this.pawnControl[piece.color][square] == null)
        this.pawnControl[piece.color][square] = 0;

      this.pawnControl[piece.color][square]++;
    });
  }

  void removePawnControl(Piece piece, int square) {
    // if (piece.type != PAWN) return;

    final squares = [
      square + (piece.color == WHITE ? V['NE'] : V['SE']),
      square + (piece.color == WHITE ? V['NW'] : V['SW'])
    ];

    squares
        // .filter(validateSquare)
        .forEach((square) {
      this.pawnControl[piece.color][square]--;

      if (this.pawnControl[piece.color][square] <= 0)
        this.pawnControl[piece.color].remove(square);
    });
  }

  void addPawnCounts(Piece piece, int square) {
    this.pawnCountsByRank[piece.color][rank(square)]++;
    this.pawnCountsByFile[piece.color][file(square)]++;
  }

  void removePawnCounts(Piece piece, int square) {
    this.pawnCountsByRank[piece.color][rank(square)]--;
    this.pawnCountsByFile[piece.color][file(square)]--;
  }

  /**
   * Builds move struct
   */
  Move buildMove(Color color, int from, int to, int flags,
      [PieceType promotion]) {
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
    return Move(color, from, to, flags, board[from].type, captured, promotion);
  }

  List<Move> generatePieceMoves(int square) {
    //Builds move struct and adds them in `moves` array.
    void addMove(List<Move> moves, Color color, int from, int to, int flags) {
      /* if pawn promotion */
      if (this.board[from].type == PAWN &&
          (rank(to) == RANK_8 || rank(to) == RANK_1)) {
        [QUEEN, ROOK, BISHOP, KNIGHT].forEach((piece) {
          moves.add(this.buildMove(color, from, to, flags, piece));
        });
      } else {
        moves.add(this.buildMove(color, from, to, flags));
      }
    }

    final piece = this.getPiece(square);
    final moves = [];

    final us = piece.color;
    final them = swap_color(us);

    switch (piece.type) {
      case PAWN:
        // Forward, non-capturing
        final forwardSquare = square + PAWN_OFFSETS[us][0];
        if (this.board[forwardSquare] == null) {
          addMove(moves, us, square, forwardSquare, BITS_NORMAL);

          final doubleForwardSquare = square + PAWN_OFFSETS[us][1];
          if ({BLACK: RANK_7, WHITE: RANK_2}[us] == rank(square) &&
              this.board[doubleForwardSquare] == null) {
            addMove(moves, us, square, doubleForwardSquare, BITS_BIG_PAWN);
          }
        }

        // Capturing
        for (var j = 2; j < 4; j++) {
          int targetSquare = square + PAWN_OFFSETS[us][j];
          if (targetSquare & 0x88 != 0) continue;

          if (this.board[targetSquare] != null &&
              this.board[targetSquare].color == them) {
            addMove(moves, us, square, targetSquare, BITS_CAPTURE);
          } else if (targetSquare == this.epSquare) {
            addMove(moves, us, square, this.epSquare, BITS_EP_CAPTURE);
          }
        }
        break;

      case KING:
        if ((this.castling[us] & BITS_KSIDE_CASTLE) != 0) {
          final castling_from = this.pieces[KING][us];
          final castling_to = castling_from + 2;

          if (this.board[castling_from + 1] == null &&
              this.board[castling_to] == null &&
              !this.checkColorAttack(them, this.pieces[KING][us]) &&
              !this.checkColorAttack(them, castling_from + 1) &&
              !this.checkColorAttack(them, castling_to)) {
            addMove(moves, us, this.pieces[KING][us], castling_to,
                BITS_KSIDE_CASTLE);
          }
        }

        /* queen-side castling */
        if ((this.castling[us] & BITS_QSIDE_CASTLE) != 0) {
          final castling_from = this.pieces[KING][us];
          final castling_to = castling_from - 2;

          if (this.board[castling_from - 1] == null &&
              this.board[castling_from - 2] == null &&
              this.board[castling_from - 3] == null &&
              // TODO
              !this.checkColorAttack(them, this.pieces[KING][us]) &&
              !this.checkColorAttack(them, castling_from - 1) &&
              !this.checkColorAttack(them, castling_to)) {
            addMove(moves, us, this.pieces[KING][us], castling_to,
                BITS_QSIDE_CASTLE);
          }
        }
        // CAUTION: GOES DOWN!
        // break;
        continue def;

      def:
      default:
        for (var j = 0, len = PIECE_OFFSETS[piece.type].length; j < len; j++) {
          final offset = PIECE_OFFSETS[piece.type][j];
          int targetSquare = square;

          while (true) {
            targetSquare += offset;
            if ((targetSquare & 0x88) != 0) break;

            if (this.board[targetSquare] == null) {
              addMove(moves, us, square, targetSquare, BITS_NORMAL);
            } else {
              if (this.board[targetSquare].color == us) break;
              addMove(moves, us, square, targetSquare, BITS_CAPTURE);
              break;
            }

            /* break, if knight or king */
            // if (piece.type == 'n' || piece.type == 'k') break;
            if (piece.type == KNIGHT || piece.type == KING) break;
          }
        }
        break;
    }

    return moves;
  }

  List<Move> generateAllTurnMoves() {
    List moves = [];

    this.forEachPiece((piece, square) {
      if (piece.color != this.turn) return;
      moves = moves + (this.generatePieceMoves(square));
    });

    return moves.where((move) {
      final us = this.turn;
      this.move(move);
      final valid = !this.isKingAttacked(us);
      this.undo();
      return valid;
    }).toList();
  }

  bool checkPieceAttack(pieceSquare, targetSquare) {
    final piece = this.getPiece(pieceSquare);
    final difference = pieceSquare - targetSquare;
    final index = difference + 119;

    if (ATTACKS[index] & (1 << SHIFTS[piece.type])) {
      if (piece.type == PAWN) {
        if (difference > 0) {
          if (piece.color == WHITE) return true;
        } else {
          if (piece.color == BLACK) return true;
        }

        return false;
      }

      /* if the piece is a knight or a king */
      if (piece.type == KNIGHT || piece.type == KING) return true;

      final offset = RAYS[index];
      var j = pieceSquare + offset;

      var blocked = false;
      while (j != targetSquare) {
        if (this.board[j] != null) {
          blocked = true;
          break;
        }
        j += offset;
      }

      if (!blocked) return true;
    }

    return false;
  }

  bool checkColorAttack(Color color, int targetSquare) {
    bool rv = false;

    this.forEachPiece((piece, square) {
      if (rv) return;
      if (piece.color != color) return;
      rv = rv || this.checkPieceAttack(square, targetSquare);
    });

    return rv;
  }

  /**
   * Is color's king attacked?
   */
  bool isKingAttacked(Color color) {
    return this.checkColorAttack(swap_color(color), this.pieces[KING][color]);
  }

  bool get isCheck {
    return this.isKingAttacked(this.turn);
  }

  bool get isCheckmate {
    return this.isCheck && this.generateAllTurnMoves().length == 0;
  }

  bool get isStalemate {
    return !this.isCheck && this.generateAllTurnMoves().length == 0;
  }

  bool get isInsufficientMaterial {
    final counts = {
      PAWN: this.pieces[PAWN][WHITE].length + this.pieces[PAWN][BLACK].length,
      KNIGHT:
          this.pieces[KNIGHT][WHITE].length + this.pieces[KNIGHT][BLACK].length,
      BISHOP:
          this.pieces[BISHOP][WHITE].length + this.pieces[BISHOP][BLACK].length,
      ROOK: this.pieces[ROOK][WHITE].length + this.pieces[ROOK][BLACK].length,
      QUEEN:
          this.pieces[QUEEN][WHITE].length + this.pieces[QUEEN][BLACK].length,
      KING: 2
    };
    final totalCount = counts[PAWN] +
        counts[KNIGHT] +
        counts[BISHOP] +
        counts[ROOK] +
        counts[QUEEN] +
        counts[KING];

    if (totalCount == 2) return true;

    if (totalCount == 3 && (counts[BISHOP] == 1 || counts[BISHOP] == 1))
      return true;

    if (totalCount == counts[BISHOP] + 2) {
      final bishops = this.pieces[BISHOP][WHITE] + this.pieces[BISHOP][BLACK];
      final colorSum = bishops.reduce((sum, square) {
        return sum + SQUARE_COLORS[square];
      }, 0);

      if (colorSum == 0 || colorSum == bishops.length) return true;
    }

    return false;
  }

  bool get isInThreefoldPosition {
    /* TODO: while this function is fine for casual use, a better
     * implementation would use a Zobrist key (instead of FEN). the
     * Zobrist key would be maintained in the make_move/undo_move functions,
     * avoiding the costly that we do below.
     */
    List moves = [];
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
      var fen = generateFen().split(' ').sublist(0, 4).join(' ');

      /* has the position occurred three or move times */
      positions[fen] = (positions.containsKey(fen)) ? positions[fen] + 1 : 1;
      if (positions[fen] >= 3) {
        repetition = true;
      }

      if (moves.length == 0) {
        break;
      }
      move(moves.removeLast());
    }

    return repetition;
  }

  bool get isDraw {
    return this.isStalemate || this.isInsufficientMaterial;
  }

  bool get isGameOver {
    return this.generateAllTurnMoves().length == 0 ||
        this.isInsufficientMaterial;
  }

  void pushHistory(Move move) {
    this.history.add(State2(
        move,
        this.turn,
        ColorMap.clone(this.castling),
        this.epSquare,
        this.halfMoves,
        this.moveNumber,
        Map.from(this.pawnControl),
        Map.from(this.squaresNearKing),
        Map.from(this.pawnCountsByRank),
        Map.from(this.pawnCountsByFile)));
  }

  bool moveIfFound(Map move) {
    final moves = this.generateAllTurnMoves();
    final found = moves.where((Move move2) {
      return move2.from == move['from'] &&
          move2.to == move['to'] &&
          (move['promotion'] == null ||
              move['promotion'] == move2.promotion.name);
    });
    if (found.length == 0) return false;
    return this.move(found.first);
  }

  bool move(Move move) {
    final piece = this.getPiece(move.from);
    if (piece == null) return false;

    this.removePiece(move.to);
    this.movePiece(move.from, move.to);
    this.pushHistory(move);

    final us = this.turn;
    final them = swap_color(this.turn);

    /* if ep capture, remove the captured pawn */
    if ((move.flags & BITS_EP_CAPTURE) != 0) {
      if (us == BLACK) {
        this.removePiece(move.to - 16);
      } else {
        this.removePiece(move.to + 16);
      }
    }

    /* if pawn promotion, replace with new piece */
    if ((move.flags & BITS_PROMOTION) != 0) {
      this.removePiece(move.to);
      this.putPiece(Piece(move.promotion, us), move.to);
    }

    /* if we moved the king */
    if (piece.type == KING) {
      /* if we castled, move the rook next to the king */
      if ((move.flags & BITS_KSIDE_CASTLE) != 0) {
        final castling_to = move.to - 1;
        final castling_from = move.to + 1;
        this.movePiece(castling_from, castling_to);
      } else if ((move.flags & BITS_QSIDE_CASTLE) != 0) {
        final castling_to = move.to + 1;
        final castling_from = move.to - 2;
        this.movePiece(castling_from, castling_to);
      }

      /* turn off castling */
      this.castling[us] = 0;
    }

    /* turn off castling if we move a rook */
    if (this.castling[us] != 0) {
      final rooks = ROOKS[us];
      for (var i = 0, len = rooks.length; i < len; i++) {
        if (move.from == rooks[i].square &&
            ((this.castling[us] & rooks[i].flag) != 0)) {
          this.castling[us] ^= rooks[i].flag;
          break;
        }
      }
    }

    /* turn off castling if we capture a rook */
    if (this.castling[them] != 0) {
      final rooks = ROOKS[them];
      for (var i = 0, len = rooks.length; i < len; i++) {
        if (move.to == rooks[i].square &&
            ((this.castling[them] & rooks[i].flag) != 0)) {
          this.castling[them] ^= rooks[i].flag;
          break;
        }
      }
    }

    /* if big pawn move, update the en passant square */
    if ((move.flags & BITS_BIG_PAWN) != 0) {
      if (us == BLACK) {
        this.epSquare = move.to - 16;
      } else {
        this.epSquare = move.to + 16;
      }
    } else {
      this.epSquare = EMPTY;
    }

    /* reset the 50 move counter if a pawn is moved or a piece is captured */
    if (move.piece == PAWN) {
      this.halfMoves = 0;
    } else if ((move.flags & (BITS_CAPTURE | BITS_EP_CAPTURE)) != 0) {
      this.halfMoves = 0;
    } else {
      this.halfMoves++;
    }

    if (us == BLACK) {
      this.moveNumber++;
    }

    this.turn = swap_color(turn);
    return true;
  }

  Move undo() {
    if (history.isEmpty) {
      return null;
    }
    State2 old = history.removeLast();
    if (old == null) {
      return null;
    }

    Move move = old.move;
    this.turn = old.turn;
    this.castling = old.castling;
    this.epSquare = old.epSquare;
    this.halfMoves = old.halfMoves;
    this.moveNumber = old.moveNumber;
    this.pawnControl = old.pawnControl;
    this.squaresNearKing = old.squaresNearKing;
    this.pawnCountsByRank = old.pawnCountsByRank;
    this.pawnCountsByFile = old.pawnCountsByFile;

    Color us = turn;
    Color them = swap_color(turn);

    board[move.from] = board[move.to];
    board[move.from].type = move.piece; // to undo any promotions
    board[move.to] = null;

    if ((move.flags & BITS_CAPTURE) != 0) {
      board[move.to] = new Piece(move.captured, them);
    } else if ((move.flags & BITS_EP_CAPTURE) != 0) {
      var index;
      if (us == BLACK) {
        index = move.to - 16;
      } else {
        index = move.to + 16;
      }
      board[index] = new Piece(PAWN, them);
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

      board[castling_to] = board[castling_from];
      board[castling_from] = null;
    }

    return move;
  }

  String ascii() {
    var s = '   +------------------------+\n';
    for (var i = SQUARES['a8']; i <= SQUARES['h1']; i++) {
      /* display the rank */
      if (file(i) == 0) {
        s += ' ' + '87654321'[rank(i)] + ' |';
      }

      /* empty piece */
      if (this.board[i] == null) {
        s += ' . ';
      } else {
        final piece = this.board[i].type;
        final color = this.board[i].color;
        final symbol =
            (color == WHITE) ? piece.toUpperCase() : piece.toLowerCase();
        s += ' ' + symbol + ' ';
      }

      if ((i + 1) & 0x88) {
        s += '|\n';
        i += 8;
      }
    }
    s += '   +------------------------+\n';
    s += '     a  b  c  d  e  f  g  h\n';

    return s;
  }

  /**
   * Helper functions
   */
// Horizontal row number
  static int rank(int i) {
    return i >> 4;
  }

  // Vertical column number (0 => a, 1=> b, ...)
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

  static bool validateSquare(square) {
    return rank(square) < 8 && file(square) < 8;
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

  static const SQUARE_COLORS = [
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    1,
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
    1,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    1,
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
    1,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    1,
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
    1,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];

  static const SHIFTS = {
    PAWN: 0,
    KNIGHT: 1,
    BISHOP: 2,
    ROOK: 3,
    QUEEN: 4,
    KING: 5
  };

  static const V = {
    'NORTH': -16,
    'NN': -32,
    'SOUTH': 16,
    'SS': 32,
    'EAST': 1,
    'WEST': -1,
    'NE': -15,
    'SW': 15,
    'NW': -17,
    'SE': 17
  };

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
