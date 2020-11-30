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
  static const double _INFINITY = 99999999.0, _LARGE = 9999999;

  //the maximum depth, will change according to difficulty level
  // ignore: non_constant_identifier_names
  static int _MAX_DEPTH = 3, _SET_DEPTH = 0;

  //the actual method starting the alpha beta pruning
  static void _findBestMove(Chess chess, SendPort messenger) {
    //get the start time
    num startTime = DateTime.now().millisecondsSinceEpoch;

    //set the random
    _random = Random();

    //get the MAX and MIN color
    _MAX = chess.game.turn;
    _MIN = Chess.swap_color(chess.game.turn);

    //init the eval
    _eval = Evaluation(_MAX, _MIN, _LARGE, Evaluation.isEndGame(chess));

    //calc the max depth
    _calcMaxDepth(chess);

    Move bestMove = _prepareAndStartMinimax(chess, messenger);

    //if there is no move, send null
    if (bestMove == null) {
      messenger.send('no_moves');
      return;
    }

    //print
    print('selected: $bestMove');

    //get the end time
    num endTime = DateTime.now().millisecondsSinceEpoch;

    //send the best move up again
    //also return as second argument the time needed
    messenger.send([bestMove, (endTime - startTime)]);
  }

  //prepare the minimax iteratively, meaning:
  //go through all branches with normal minimax without alpha beta pruning till the depth _MAX_DEPTH - 1,
  //generate all move lists and evaluate each board in every depth
  //by that, sort all nodes
  //when all nodes (move lists) in all depths till _MAX_DEPTH - 1 are sorted,
  //start the real minimax with alpha beta pruning, without requiring to
  //generate any move lists, since they are all in the RAM already and
  //with already having sorted lists, which makes the whole process a lot faster,
  //as then alpha beta pruning will cut of much more trees faster
  static Move _prepareAndStartMinimax(Chess c, SendPort messenger) {
    //set a root move
    Move rootMove = Move(null, null, null, null, null, null, null);
    //call the iterative method prepare minimax here
    _prepareMinimax(rootMove, c, 0, _MAX);
    //then start the real minimax with alpha beta pruning
    //the first minimax iteration will be called from here as max
    //list of moves and their evals
    List evalPairs = [];
    //loop through the root moves children (sorted)
    for(Move child in rootMove.children) {

    }
  }

  //the iterative repetition to prepare minimax:
  //generate all child nodes
  //and sort all them until the depth of _MAX_DEPTH - 2,
  //all moves till _MAX_DEPTH - 1 will be generated this way
  static void _prepareMinimax(Move root, Chess c, int depth, Color player) {
    //generate the move list
    root.children = c.generateMoves();
    //generate the booleans for evaluation
    bool gameOver = c.gameOver(root.children.length == 0);
    bool gameDraw = c.lastInDraw;

    //eval the root move and set the eval
    root.eval = _eval.evaluatePosition(c, gameOver, gameDraw, depth);

    //don't go deeper if the _MAX_DEPTH - 1 is reached
    //only the evaluation shall be returned
    if (depth >= (_MAX_DEPTH - 1)) return;

    //loop through all children
    for (Move child in root.children) {
      //make the move on the chess board for the next eval
      c.make_move(child);
      //iteratively call _prepareMinimax to evaluate all boards
      //with inverted player
      _prepareMinimax(child, c, depth + 1, Color.flip(player));
      //undo the move again
      c.undo();
    }

    //sort moves according to if is _MAX or _MIN after evaluating all children
    if (player == _MAX) {
      //sort for max
      //the big values first
      root.children.sort((a, b) => b.eval.compareTo(a.eval));
    } else {
      //sort for min
      //the low values first
      root.children.sort((a, b) => a.eval.compareTo(b.eval));
    }
  }

  // implements a simple alpha beta algorithm
  static double _minimax(Move parentMove, Chess c, int depth, double alpha,
      double beta, Color player) {
    //update idx
    _idx++;
    //if this is the max depth, then in the preparation the child nodes have not
    //been generated yet (performance)
    if (depth == _MAX_DEPTH) {
      //now generate moves
      parentMove.children = c.generateMoves();
      //is game over if generated moves len is still zero
      parentMove.gameOver = c.gameOver(parentMove.children.length == 0);
      //take the last in draw bool
      parentMove.gameDraw = c.lastInDraw;
    }
    //is leaf
    if (depth >= _MAX_DEPTH || parentMove.gameOver) {
      //return the end node evaluation
      return parentMove.eval = _eval.evaluatePosition(
          c, parentMove.gameOver, parentMove.gameDraw, depth);
    }

    // if the computer is the current player (MAX)
    if (player == _MAX) {
      // go through all legal moves
      for (Move m in parentMove.children) {
        //move to be able to generate future moves
        c.make_move(m);
        //recursive execute of alpha beta
        alpha = max(alpha, _minimax(m, c, depth + 1, alpha, beta, _MIN));
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
      for (Move m in parentMove.children) {
        //try move
        c.make_move(m);
        //minimize beta from new alpha beta
        beta = min(beta, _minimax(m, c, depth + 1, alpha, beta, _MAX));
        //undo the moves
        c.undo();
        //cut off here as well
        if (alpha >= beta) {
          break;
        }
      }
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
