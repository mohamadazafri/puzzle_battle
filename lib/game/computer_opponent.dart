import 'dart:math';
import 'package:puzzle_battle/game/grid.dart';
import 'package:puzzle_battle/game/puzzle_battle_game.dart';

// Add this class to your project
class ComputerOpponent {
  final PuzzleBattleGame game;
  final Grid grid;
  final Random random = Random();

  // Difficulty settings
  final double thinkingTime; // Time between moves in seconds
  final double skillLevel; // 0.0-1.0 where 1.0 is perfect play

  double _decisionTimer = 0.0;
  bool _isPlacingBlock = false;

  ComputerOpponent({
    required this.game,
    required this.grid,
    this.thinkingTime = 1.0,
    this.skillLevel = 0.5,
  });

  void update(double dt) {
    // Only do something if we have an active block
    if (grid.activeBlock == null) {
      // Spawn a new block for the AI
      game.spawnOpponentBlock();
      return;
    }

    // Update decision timer
    _decisionTimer += dt;

    // Make a move after the thinking time has elapsed
    if (_decisionTimer >= thinkingTime && !_isPlacingBlock) {
      _isPlacingBlock = true;
      _makeMove();
    }
  }

  void _makeMove() {
    // AI's decision-making process
    if (grid.activeBlock == null) return;

    // Calculate best move based on skill level
    final moves = _calculatePossibleMoves();

    // Choose a move (perfectly with skillLevel probability, randomly otherwise)
    Move selectedMove;
    if (random.nextDouble() < skillLevel && moves.isNotEmpty) {
      // Choose best move
      selectedMove = _getBestMove(moves);
    } else {
      // Choose random move
      selectedMove = moves[random.nextInt(moves.length)];
    }

    // Execute the move
    _executeMove(selectedMove);
  }

  List<Move> _calculatePossibleMoves() {
    // Calculate all possible placements of the current block
    List<Move> possibleMoves = [];

    // Get the current block
    final block = grid.activeBlock!;
    final originalRotation = block.rotation;

    // Try each rotation
    for (int r = 0; r < 4; r++) {
      // Set block to this rotation
      block.rotation = r;

      // Try each column position
      for (int c = 0; c < grid.columns; c++) {
        // Can we place the block here?
        if (grid.canPlaceBlockAt(block, block.row, c)) {
          // Find how far down the block can go
          int lowestRow = block.row;
          while (lowestRow < grid.rows - 1 && grid.canPlaceBlockAt(block, lowestRow + 1, c)) {
            lowestRow++;
          }

          // Create a move
          Move move = Move(
            rotation: r,
            column: c,
            row: lowestRow,
          );

          // Evaluate how good this move is
          move.score = _evaluateMove(move);

          possibleMoves.add(move);
        }
      }
    }

    // Restore original rotation
    block.rotation = originalRotation;

    return possibleMoves;
  }

  double _evaluateMove(Move move) {
    // Score the move based on several factors
    double score = 0.0;

    // Prefer moves that clear lines
    int linesCleared = _estimateLinesCleared(move);
    score += linesCleared * 10.0;

    // Prefer moves that don't create holes
    int holes = _estimateHoles(move);
    score -= holes * 5.0;

    // Prefer moves that keep the stack low
    int height = _estimateHeight(move);
    score -= height * 0.5;

    return score;
  }

  int _estimateLinesCleared(Move move) {
    // Estimate how many lines would be cleared with this move
    // Simplified implementation
    return 0;
  }

  int _estimateHoles(Move move) {
    // Estimate how many holes this move would create
    // Simplified implementation
    return 0;
  }

  int _estimateHeight(Move move) {
    // Estimate the resulting stack height
    return move.row;
  }

  Move _getBestMove(List<Move> moves) {
    // Sort moves by score (highest first)
    moves.sort((a, b) => b.score.compareTo(a.score));
    return moves.first;
  }

  void _executeMove(Move move) {
    if (grid.activeBlock == null) {
      _isPlacingBlock = false;
      return;
    }

    // Set the rotation
    while (grid.activeBlock!.rotation != move.rotation) {
      grid.rotateActiveBlock();
    }

    // Move horizontally
    int targetColumn = move.column;
    int currentColumn = grid.activeBlock!.column;

    if (currentColumn < targetColumn) {
      // Need to move right
      grid.moveBlock(grid.activeBlock!, grid.activeBlock!.row, currentColumn + 1);
    } else if (currentColumn > targetColumn) {
      // Need to move left
      grid.moveBlock(grid.activeBlock!, grid.activeBlock!.row, currentColumn - 1);
    } else {
      // Correct horizontal position, drop the block
      grid.moveBlock(grid.activeBlock!, move.row, move.column);

      // Lock the block
      grid.activeBlock!.isActive = false;

      // Check for completed lines
      List<int> completedLines = grid.checkCompletedLines();
      if (completedLines.isNotEmpty) {
        // Clear lines
        grid.clearLines(completedLines);

        // Send attack to player based on lines cleared
        int attackPower = completedLines.length * 2; // 2 junk blocks per line
        game.playerReceiveAttack(attackPower);
      }

      // Reset block and timer
      grid.activeBlock = null;
      _decisionTimer = 0.0;
      _isPlacingBlock = false;
    }
  }
}

// Helper class for AI move representation
class Move {
  final int rotation;
  final int column;
  final int row;
  double score = 0.0;

  Move({
    required this.rotation,
    required this.column,
    required this.row,
  });
}
