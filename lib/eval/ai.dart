import 'dart:isolate';
import 'dart:math';

import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../chess_board/chess.dart';
import 'eval.dart';

class ChessAI {
  //the entry point for the new isolate
  static void entryPointMoveFinderIsolate(List context) {
    //init the messenger, which sends messages back to the main thread
    final SendPort messenger = context[0];
    //if the received object is a chess game, start the move generation
    //hand over the messenger and the chess
    _findBestMove(Chess.fromFEN(context[1]), messenger);
  }

  //the random
  static Random _random;

  //the current index for looping
  static int _idx = 0;

  // ignore: non_constant_identifier_names
  static Color _MAX, _MIN;

  //the eval
  static Evaluation _eval;

  //big enough to be infinity in this case
  static const double _INFINITY = 99999999.0, _LARGE = 9999999;

  //the maximum depth, will change according to difficulty level
  // ignore: non_constant_identifier_names
  static int _MAX_DEPTH = 3;

  //the actual method starting the alpha beta pruning
  static void _findBestMove(Chess chess, SendPort messenger) {
    //get the start time
    num startTime = DateTime.now().millisecondsSinceEpoch;

    //set the random
    _random = Random();

    //calc the max depth
    _calcMaxDepth(chess);

    //get the MAX and MIN color
    _MAX = chess.game.turn;
    _MIN = Chess.swap_color(chess.game.turn);

    //init the eval
    _eval = Evaluation(_MIN, _MAX, _LARGE, Evaluation.isEndGame(chess));

    //execute the first depth of max
    List<List> moveEvalPairs = new List<List>();

    _idx = 0;
    for (Move m in chess.generateMoves()) {
      //perform an alpha beta minimax algorithm in the first gen with max to min
      chess.make_move(m);
      double eval = _alphaBeta(chess, 1, -_INFINITY, _INFINITY, _MIN);
      moveEvalPairs.add([m, eval]);
      chess.undo();
      //print the progress
      print('m$_idx with $eval');
      //send a progress via send function
      messenger.send(_idx);
    }

    //determine the highest eval score
    double highestEval = -_INFINITY;

    for (List pair in moveEvalPairs) {
      if (pair[1] > highestEval) {
        highestEval = pair[1];
      }
    }

    var bestMoves = [];
    for (List pair in moveEvalPairs) {
      if (pair[1] == highestEval) bestMoves.add(pair[0]);
    }

    //if there is no move, send null
    if (bestMoves.length == 0) {
      messenger.send('no_moves');
      return;
    }

    //random one of the same scores
    var bestMove = bestMoves[_random.nextInt(bestMoves.length)];
    print('best moves: $bestMoves');

    //print
    print('selected: $bestMove with $highestEval');

    //get the end time
    num endTime = DateTime.now().millisecondsSinceEpoch;

    //send the best move up again
    //also return as second argument the time needed
    messenger.send([bestMove, (endTime - startTime)]);
  }

  // implements a simple alpha beta algorithm
  static double _alphaBeta(
      Chess c, int depth, double alpha, double beta, Color whoNow) {
    //update idx
    _idx++;
    //generate the moves for eval and normal minimax / alpha-beta
    List<Move> futureMoves = c.generateMoves();

    //is leaf
    bool gameOver = c.gameOver(futureMoves.length == 0);
    if (depth >= _MAX_DEPTH || gameOver) {
      //return the end node evaluation
      return _eval.evaluatePosition(c, gameOver, c.lastInDraw, depth);
    }

    // if the computer is the current player (MAX)
    if (whoNow == _MAX) {
      // go through all legal moves
      for (Move m in futureMoves) {
        //move to be able to generate future moves
        c.make_move(m);
        //recursive execute of alpha beta
        alpha = max(alpha, _alphaBeta(c, depth + 1, alpha, beta, _MIN));
        //undo after alpha beta
        c.undo();
        //cut of branches
        if (alpha >= beta) {
          break;
        }
      }
      //return the alpha
      return alpha;
      //the same of min
    } else {
      // opponent ist he player (MIN)
      for (Move m in futureMoves) {
        //try move
        c.make_move(m);
        //minimize beta from new alpha beta
        beta = min(beta, _alphaBeta(c, depth + 1, alpha, beta, _MAX));
        //undo the moves
        c.undo();
        //cut off here as well
        if (alpha >= beta) {
          break;
        }
      }
      return beta;
    }
  }

  static void _calcMaxDepth(Chess chess) {
    //calc the expected time expenditure in a sub function
    num expectedTimeExpenditure(int depth) {
      //always generate the first move if possible, then check how many moves there are
      num prod = 1;
      void addNumRecursive(Chess root, int thisDepth) {
        //check for not hitting too deep
        if (thisDepth > depth) return;
        //list of moves
        List moves = root.generateMoves();
        if (moves.length > 0) {
          //create the product
          prod *= moves.length;
          //make one of them randomly, always selecting 0 move could be wrong
          root.make_move(moves[_random.nextInt(moves.length)]);
          //call this one recursive
          addNumRecursive(root, thisDepth + 1);
          //then undo it
          root.undo();
        }
      }

      //call the recursive counter
      addNumRecursive(chess, 1);
      //calc prod * 3/4 because of pruning
      return prod * 0.75;
    }

    //if is not end game, keep in layer 3
    if(!_eval.endGame) {
      _MAX_DEPTH = _MIN_CALC_DEPTH;
      return;
    }

    //WE DON'T USE THE SHANNON NUMBER
    //first calculate the number of pieces on the board,
    //from that calculate the time expenditure for alpha beta pruning:
    //b^(3/4)
    //based on that then decide how deep we want to go with alpha beta pruning
    //depth, pm
    //minimizing loop
    bool changed = false;
    for (int depth = _MAX_CALC_DEPTH; depth >= _MIN_CALC_DEPTH; depth--) {
      num exp = expectedTimeExpenditure(depth);
      print('expected: $exp');
      if (exp < _MAX_CALC_ESTIMATED_MOVES) {
        _MAX_DEPTH = depth;
        changed = true;
        break;
      }
    }

    if (!changed) _MAX_DEPTH = _MIN_CALC_DEPTH;

    print('set max depth to $_MAX_DEPTH');
  }

  static const _MIN_CALC_DEPTH = 3,
      _MAX_CALC_DEPTH = 5,
      _MAX_CALC_ESTIMATED_MOVES = 135000;
}
