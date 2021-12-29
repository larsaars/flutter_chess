import 'package:chess_bot/chess_board/chess.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart';

class Evaluation {
  // ignore: non_constant_identifier_names
  final Color _MAX;

  // ignore: non_constant_identifier_names
  final bool endGame;

  // ignore: non_constant_identifier_names
  final double _LARGE;

  Evaluation(this._MAX, this._LARGE, this.endGame);

  // simple material based evaluation
  double evaluatePosition(Chess c, bool gameOver, bool inDraw, int depth) {
    if (gameOver) {
      if (inDraw) {
        // draw is a neutral outcome
        return 0.0;
      } else {
        // otherwise must be a mate
        if (c.game.turn == _MAX) {
          // avoid mates loss, the deeper the better
          //(earlier is worse)
          return -_LARGE - depth;
        } else {
          // go for the loss of the other one, the deeper the worse
          //(earlier is better)
          return _LARGE - depth;
        }
      }
    } else {
      //the final evaluation to be returned
      double eval = 0.0;
      //loop through all squares
      for (int i = Chess.SQUARES_A8; i <= Chess.SQUARES_H1; i++) {
        if ((i & 0x88) != 0) {
          i += 7;
          continue;
        }

        Piece piece = c.game.board[i];
        if (piece != null) {
          //get the x and y from the map
          final x = Chess.file(i), y = Chess.rank(i);
          //evaluate the piece at the position
          eval += _getPieceValue(piece, x, y);
        }
      }

      return eval;
    }
  }

  num _getPieceValue(Piece piece, int x, int y) {
    if (piece == null) {
      return 0;
    }

    var absoluteValue =
        _getAbsoluteValue(piece.type, piece.color == Color.WHITE, x, y);

    if (piece.color == _MAX) {
      //* lower factor to make the game play rather defensive than losing a piece
      return absoluteValue;
    } else {
      return -absoluteValue;
    }
  }

  num _getAbsoluteValue(PieceType piece, bool isWhite, int x, int y) {
    if (piece.name == 'p') {
      return _pieceValues[PieceType.PAWN] +
          (isWhite ? _whitePawnEval[y][x] : _blackPawnEval[y][x]);
    } else if (piece.name == 'r') {
      return _pieceValues[PieceType.ROOK] +
          (isWhite ? _whiteRookEval[y][x] : _blackRookEval[y][x]);
    } else if (piece.name == 'n') {
      return _pieceValues[PieceType.KNIGHT] + _knightEval[y][x];
    } else if (piece.name == 'b') {
      return _pieceValues[PieceType.BISHOP] +
          (isWhite ? _whiteBishopEval[y][x] : _blackBishopEval[y][x]);
    } else if (piece.name == 'q') {
      return _pieceValues[PieceType.QUEEN] + _evalQueen[y][x];
    } else if (piece.name == 'k') {
      if (endGame) {
        return _pieceValues[PieceType.KING] +
            (isWhite
                ? _whiteKingEvalEndGame[y][x]
                : _blackKingEvalEndGame[y][x]);
      } else {
        return _pieceValues[PieceType.KING] +
            (isWhite ? _whiteKingEval[y][x] : _blackKingEval[y][x]);
      }
    }

    return 0;
  }

  //the piece values
  static const Map _pieceValues = const {
    PieceType.PAWN: 100,
    PieceType.KNIGHT: 320,
    PieceType.BISHOP: 330,
    PieceType.ROOK: 500,
    PieceType.QUEEN: 900,
    PieceType.KING: 20000
  };

  static List _reverseList(List list) {
    return [...list].reversed.toList();
  }

  static const _whitePawnEval = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0],
    [1.0, 1.0, 2.0, 3.0, 3.0, 2.0, 1.0, 1.0],
    [0.5, 0.5, 1.0, 2.5, 2.5, 1.0, 0.5, 0.5],
    [0, 0, 0, 2.0, 2.0, 0, 0, 0],
    [0.5, -0.5, -1.0, 0, 0, -1.0, -0.5, 0.5],
    [0.5, 1.0, 1.0, -2.0, -2.0, 1.0, 1.0, 0.5],
    [0, 0, 0, 0, 0, 0, 0, 0]
  ];

  static final _blackPawnEval = _reverseList(_whitePawnEval);

  static const _knightEval = [
    [-5.0, -4.0, -3.0, -3.0, -3.0, -3.0, -4.0, -5.0],
    [-4.0, -2.0, 0, 0, 0, 0, -2.0, -4.0],
    [-3.0, 0, 1.0, 1.5, 1.5, 1.0, 0, -3.0],
    [-3.0, 0.5, 1.5, 2.0, 2.0, 1.5, 0.5, -3.0],
    [-3.0, 0, 1.5, 2.0, 2.0, 1.5, 0, -3.0],
    [-3.0, 0.5, 1.0, 1.5, 1.5, 1.0, 0.5, -3.0],
    [-4.0, -2.0, 0, 0.5, 0.5, 0, -2.0, -4.0],
    [-5.0, -4.0, -3.0, -3.0, -3.0, -3.0, -4.0, -5.0],
  ];

  static const _whiteBishopEval = [
    [-2.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -2.0],
    [-1.0, 0, 0, 0, 0, 0, 0, -1.0],
    [-1.0, 0, 0.5, 1.0, 1.0, 0.5, 0, -1.0],
    [-1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, -1.0],
    [-1.0, 0, 1.0, 1.0, 1.0, 1.0, 0, -1.0],
    [-1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, -1.0],
    [-1.0, 0.5, 0, 0, 0, 0, 0.5, -1.0],
    [-2.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -2.0],
  ];

  static final _blackBishopEval = _reverseList(_whiteBishopEval);

  static const _whiteRookEval = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.5],
    [-0.5, 0, 0, 0, 0, 0, 0, -0.5],
    [-0.5, 0, 0, 0, 0, 0, 0, -0.5],
    [-0.5, 0, 0, 0, 0, 0, 0, -0.5],
    [-0.5, 0, 0, 0, 0, 0, 0, -0.5],
    [-0.5, 0, 0, 0, 0, 0, 0, -0.5],
    [0, 0, 0, 0.5, 0.5, 0, 0, 0]
  ];

  static final _blackRookEval = _reverseList(_whiteRookEval);

  static const _evalQueen = [
    [-2.0, -1.0, -1.0, -0.5, -0.5, -1.0, -1.0, -2.0],
    [-1.0, 0, 0, 0, 0, 0, 0, -1.0],
    [-1.0, 0, 0.5, 0.5, 0.5, 0.5, 0, -1.0],
    [-0.5, 0, 0.5, 0.5, 0.5, 0.5, 0, -0.5],
    [0, 0, 0.5, 0.5, 0.5, 0.5, 0, -0.5],
    [-1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0, -1.0],
    [-1.0, 0, 0.5, 0, 0, 0, 0, -1.0],
    [-2.0, -1.0, -1.0, -0.5, -0.5, -1.0, -1.0, -2.0]
  ];

  static const _whiteKingEval = [
    [-3.0, -4.0, -4.0, -5.0, -5.0, -4.0, -4.0, -3.0],
    [-3.0, -4.0, -4.0, -5.0, -5.0, -4.0, -4.0, -3.0],
    [-3.0, -4.0, -4.0, -5.0, -5.0, -4.0, -4.0, -3.0],
    [-3.0, -4.0, -4.0, -5.0, -5.0, -4.0, -4.0, -3.0],
    [-2.0, -3.0, -3.0, -4.0, -4.0, -3.0, -3.0, -2.0],
    [-1.0, -2.0, -2.0, -2.0, -2.0, -2.0, -2.0, -1.0],
    [2.0, 2.0, 0, 0, 0, 0, 2.0, 2.0],
    [2.0, 3.0, 1.0, 0, 0, 1.0, 3.0, 2.0]
  ];

  static final _blackKingEval = _reverseList(_whiteKingEval);

  static const _whiteKingEvalEndGame = [
    [-5.0, -4.0, -3.0, -2.0, -2.0, -3.0, -4.0, -5.0],
    [-3.0, -2.0, -1.0, 0, 0, -1.0, -2.0, -3.0],
    [-3.0, -1.0, 2.0, 3.0, 3.0, 2.0, -1.0, -3.0],
    [-3.0, -1.0, 3.0, 4.0, 4.0, 3.0, -1.0, -3.0],
    [-3.0, -1.0, 3.0, 4.0, 4.0, 3.0, -1.0, -3.0],
    [-3.0, -1.0, 2.0, 3.0, 3.0, 2.0, -1.0, -3.0],
    [-3.0, -3.0, 0, 0, 0, 0, -3.0, -3.0],
    [-5.0, -3.0, -3.0, -3.0, -3.0, -3.0, -3.0, -5.0]
  ];

  static final _blackKingEvalEndGame = _reverseList(_whiteKingEvalEndGame);

  //for taking good positions, but not for losing a piece
  static const _OWN_LOSS_WORSE_FACTOR = 1;

  static bool isEndGame(Chess chess) {
    int pieceCount = 0;
    chess.forEachPiece((piece) {
      pieceCount++;
    });

    return pieceCount < 12;
  }
}
