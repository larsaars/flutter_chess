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
    //set the set depth
    _SET_DEPTH = context[2];
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
  static const double _INFINITY = 99999999.0,
      _LARGE = 9999999;

  //the maximum depth, will change according to difficulty level
  // ignore: non_constant_identifier_names
  static int _MAX_DEPTH = 3,
      _SET_DEPTH = 0;

  //the actual method starting the alpha beta pruning
  static void _findBestMove(Chess chess, SendPort messenger) {
    //get the start time
    num startTime = DateTime
        .now()
        .millisecondsSinceEpoch;

    //set the random
    _random = Random();

    //get the MAX and MIN color
    _MAX = chess.game.turn;
    _MIN = Chess.swap_color(chess.game.turn);

    //init the eval
    _eval = Evaluation(_MAX, _MIN, _LARGE, Evaluation.isEndGame(chess));

    //calc the max depth
    _calcMaxDepth(chess);

    //execute the first depth of max
    List<List> moveEvalPairs = new List<List>();

    _idx = 0;
    for (Move m in chess.generateMoves()) {
      //perform an alpha beta minimax algorithm in the first gen with max to min
      chess.make_move(m);
      double eval = _minimax(chess, 1, -_INFINITY, _INFINITY, _MIN);
      moveEvalPairs.add([m, eval]);
      chess.undo();
      //print the progress
      print('$_idx with $eval');
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
    num endTime = DateTime
        .now()
        .millisecondsSinceEpoch;

    //send the best move up again
    //also return as second argument the time needed
    messenger.send([bestMove, (endTime - startTime)]);
  }

  //iterative deepening that repeats the minimax
  //again each time with 1 depth deeper, saving all lists
  //and using hash sort
  Move _iterativeDeepening(Chess c) {
    //set a root move
    Move rootMove = Move(null, null, null, null, null, null, null);
    //loop through the max depth
    for (int maxDepthNow = 1; maxDepthNow <= _MAX_DEPTH; maxDepthNow++) {
      _minimax(rootMove, c, 1, maxDepthNow, _INFINITY, -_INFINITY, _MAX);
    }
    //the best move is the root move at zero++
    //TODO: return the one of the best moves randomly
  }

  // implements a simple alpha beta algorithm
  static double _minimax(Move parentMove, Chess c,
      int thisDepth,
      int maxDepthNow, double alpha, double beta, Color whoNow) {
    //update idx
    _idx++;
    //if the passed list future moves has the length zero,
    //this depth has not been explored before
    //because of this, generate then the moves here newly
    //and also gameOver / gameDraw
    if (parentMove.explored) {
      //set explored true for not generating moves a second time,
      //checking for list.len == 0 could be wrong since it could be a game over
      parentMove.explored = true;
      //now generate moves
      parentMove.childMoves = c.generateMoves();
      //is game over if generated moves len is still zero
      parentMove.gameOver = c.gameOver(parentMove.childMoves.length == 0);
      //take the last in draw bool
      parentMove.gameDraw = c.lastInDraw;
    }
    //TODO: is currently not yet sorting the eval moves.
    //is leaf
    if (thisDepth >= maxDepthNow || parentMove.gameOver) {
      //return the end node evaluation
      return _eval.evaluatePosition(
          c, parentMove.gameOver, parentMove.gameDraw, thisDepth);
    }

    // if the computer is the current player (MAX)
    if (whoNow == _MAX) {
      // go through all legal moves
      for (Move m in parentMove.childMoves) {
        //move to be able to generate future moves
        c.make_move(m);
        //recursive execute of alpha beta
        alpha = max(alpha, _minimax(
            m,
            c,
            thisDepth + 1,
            maxDepthNow,
            alpha,
            beta,
            _MIN));
        //undo after alpha beta
        c.undo();
        //cut of branches
        if (alpha >= beta) {
          break;
        }
      }
      //now sort the moves for max afterwards
      //sortMovesForMax(parentMove.genMoves);
      parentMove.childMoves.sort((a, b) => b.eval.compareTo(a.eval));
      //return the alpha
      return alpha;
      //the same of min
    } else {
      // opponent ist he player (MIN)
      for (Move m in parentMove.childMoves) {
        //try move
        c.make_move(m);
        //minimize beta from new alpha beta
        beta = min(beta, _minimax(
            m,
            c,
            thisDepth + 1,
            maxDepthNow,
            alpha,
            beta,
            _MAX));
        //undo the moves
        c.undo();
        //cut off here as well
        if (alpha >= beta) {
          break;
        }
      }
      //now sort the moves for the min in the next iterative deepening
      //sortMovesForMin(parentMove.genMoves);
      parentMove.childMoves.sort((a, b) => a.eval.compareTo(b.eval));
      //return the min beta value for upper max
      return beta;
    }
  }

  static void _calcMaxDepth(Chess chess) {
    //check if is not default but set depth
    if (_SET_DEPTH != 0) {
      _MAX_DEPTH = _SET_DEPTH;
      return;
    }
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

  static const _MIN_CALC_DEPTH = 4,
      _MAX_CALC_DEPTH = 5,
      _MAX_CALC_ESTIMATED_MOVES = 135000;
}
