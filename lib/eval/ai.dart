import 'dart:isolate';
import 'dart:math';

import 'package:chess_bot/chess_board/src/chess_sub.dart';
import 'package:flutter/foundation.dart';

import '../chess_board/chess.dart';
import 'eval.dart';

class ChessAI {
  //the entry point for the new isolate
  static void entryPointMoveFinderIsolate(List context) async {
    //init the messenger, which sends messages back to the main thread
    final messenger = context[0];
    //set the set depth
    _SET_DEPTH = context[2];
    //if the set depth is not zero, add one since this is just the list index
    if (_SET_DEPTH != 0) _SET_DEPTH++;
    print('set depth is now $_SET_DEPTH');
    //if the received object is a chess game, start the move generation
    //hand over the messenger and the chess
    _findBestMove(Chess.fromFEN(context[1]), messenger);
  }

  //find move on web in async
  static Future<List> entryPointMoveFinderNoIsolateAsync(
      String fen, int setDepth) async {
    //set the set depth
    _SET_DEPTH = setDepth;
    //if the set depth is not zero, add one since this is just the list index
    if (_SET_DEPTH != 0) _SET_DEPTH++;
    //if the received object is a chess game, start the move generation
    //hand over the messenger and the chess
    return _findBestMove(Chess.fromFEN(fen), null);
  }

  //determine to send via dorker or isolate
  static void _send(messenger, data) {
    if (!kIsWeb && (messenger is SendPort)) messenger.send(data);
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
  static List _findBestMove(Chess chess, messenger) {
    //get the start time
    num startTime = DateTime.now().millisecondsSinceEpoch;

    //set the random
    _random = Random();

    //get the MAX and MIN color
    _MAX = chess.game.turn;
    _MIN = Chess.swap_color(chess.game.turn);

    //init the eval
    _eval = Evaluation(_MAX, _LARGE, Evaluation.isEndGame(chess));

    //calc the max depth
    _calcMaxDepth(chess);

    Move bestMove = _prepareAndStartMinimax(chess, messenger);

    //if there is no move, send null
    if (bestMove == null) {
      _send(messenger, 'no_moves');
      return null;
    }

    //print
    print('selected: $bestMove');

    //get the end time
    num endTime = DateTime.now().millisecondsSinceEpoch;

    //send the best move up again
    //also return as second argument the time needed
    if (kIsWeb)
      return [bestMove, (endTime - startTime)];
    else {
      _send(messenger, [bestMove, (endTime - startTime)]);
      return null;
    }
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
  static Move _prepareAndStartMinimax(Chess c, messenger) {
    //set a root move
    Move rootMove = Move(null, null, null, null, null, null, null);
    //call the iterative method prepare minimax here
    _prepareMinimax(rootMove, c, 0, _MAX, messenger);
    //after the prepare minimax reset the idx
    _idx = 0;
    //then start the real minimax with alpha beta pruning
    //the first minimax iteration will be called from here as max
    //list of moves and their eval
    List evalPairs = [];
    //loop through the root moves children (sorted)
    for (Move child in rootMove.children) {
      //make the move on the board
      c.makeMove(child);
      //add the child and the real eval, not the pre-eval
      evalPairs.add([
        child,
        _minimax(child, c, 1, -_INFINITY, _INFINITY, _MIN, child.gameOver,
            child.gameDraw)
      ]);
      //undo the move
      c.undo();
      //send the progress
      _send(messenger, _idx);
    }

    //if there are no moves, return null
    if (evalPairs.length == 0) return null;

    //get the best eval
    double bestEval = -_INFINITY;
    for (List pair in evalPairs) {
      if (pair[1] > bestEval) bestEval = pair[1];
    }

    //get the best eval moves
    List<Move> bestMoves = [];
    for (List pair in evalPairs) {
      if (pair[1] == bestEval) bestMoves.add(pair[0]);
    }

    //return one random out of the best moves
    return bestMoves[_random.nextInt(bestMoves.length)];
  }

  //the iterative repetition to prepare minimax:
  //generate all child nodes
  //and sort all them until the depth of _MAX_DEPTH - 1,
  //all moves till _MAX_DEPTH - 1 will be generated this way
  //this is basically a minimax without alpha beta pruning to sort
  //all nodes till _MAX_DEPTH - 1
  static double _prepareMinimax(
      Move root, Chess c, int depth, Color player, messenger) {
    //update idx
    _idx++;
    //generate the nodes
    root.children = c.generateMoves();
    //is game over if generated moves len is still zero
    root.gameOver = c.gameOver(root.children.length == 0);
    //take the last in draw bool
    root.gameDraw = c.lastInDraw;
    //is leaf (_MAX_DEPTH - 1)
    if (depth >= (_MAX_DEPTH - 1) || root.gameOver) {
      //return the end node evaluation
      return root.eval =
          _eval.evaluatePosition(c, root.gameOver, root.gameDraw, depth);
    }

    // if the computer is the current player (MAX)
    if (player == _MAX) {
      //the value
      double value = -_INFINITY;
      // go through all legal moves
      for (Move m in root.children) {
        //move to be able to generate future moves
        c.makeMove(m);
        //recursive execute of minimax
        //get the maximizing value
        value = max(value, _prepareMinimax(m, c, depth + 1, _MIN, messenger));
        //undo after alpha beta
        c.undo();
        //if this is depth 0, report to messenger
        if (depth == 0) _send(messenger, _idx);
      }
      //sort the branches for max first (big eval numbers first)
      root.children.sort((Move a, Move b) => b.eval.compareTo(a.eval));
      //then return the value
      return value;
      //the same of min
    } else {
      //the value
      double value = _INFINITY;
      // go through all legal moves
      for (Move m in root.children) {
        //move to be able to generate future moves
        c.makeMove(m);
        //recursive execute of minimax
        //get the minimizing value
        value = min(value, _prepareMinimax(m, c, depth + 1, _MAX, messenger));
        //undo after alpha beta
        c.undo();
      }
      //sort the branches for max first (small eval numbers first)
      root.children.sort((Move a, Move b) => a.eval.compareTo(b.eval));
      //then return the value
      return value;
    }
  }

  // implements a simple alpha beta algorithm
  static double _minimax(Move root, Chess c, int depth, double alpha,
      double beta, Color player, bool upperIsGameOver, bool upperIsDraw) {
    //update idx
    _idx++;
    //if this is the max depth, then in the preparation the child nodes have not
    //been generated yet (performance)
    //this does not check all child nodes,
    //and just keeps the gameDraw and gameOver value of it predecessor,
    //which makes it a hybrid of _MAX_DEPTH and _MAX_DEPTH - 1
    //the value could be false,
    //but it increases the performance by highest levels!
    if (depth == _MAX_DEPTH) {
      //is game over if generated moves len is still zero
      root.gameOver = upperIsGameOver; //c.gameOver(c.moveCountIsZero(false));
      //take the last in draw bool
      root.gameDraw = upperIsDraw; //c.lastInDraw;
    }
    //is leaf
    if (depth >= _MAX_DEPTH || root.gameOver) {
      //return the end node evaluation
      if (root.additionalEvaluated)
        return root.eval;
      else
        return root.eval =
            _eval.evaluatePosition(c, root.gameOver, root.gameDraw, depth);
    }

    // if the computer is the current player (MAX)
    if (player == _MAX) {
      // go through all legal moves
      for (Move m in root.children) {
        //move to be able to generate future moves
        c.makeMove(m);
        //recursive execute of alpha beta
        alpha = max(
            alpha,
            _minimax(m, c, depth + 1, alpha, beta, _MIN, root.gameOver,
                root.gameDraw));
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
      for (Move m in root.children) {
        //try move
        c.makeMove(m);
        //minimize beta from new alpha beta
        beta = min(
            beta,
            _minimax(m, c, depth + 1, alpha, beta, _MAX, root.gameOver,
                root.gameDraw));
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
    } else {
      _MIN_CALC_DEPTH = kIsWeb ? 3 : 4;
      _MAX_CALC_DEPTH = 5;
    }

    //max depth cannot be lower than 2 because of preparation of minimax etc.
    if (_MAX_DEPTH < 2) {
      _MAX_DEPTH = 2;
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
          root.makeMove(moves[_random.nextInt(moves.length)]);
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

  // ignore: non_constant_identifier_names
  static int _MIN_CALC_DEPTH = kIsWeb ? 3 : 4, _MAX_CALC_DEPTH = 5;
  static const _MAX_CALC_ESTIMATED_MOVES = kIsWeb ? 30000 : 135000;
}
