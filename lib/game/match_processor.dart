import 'grid.dart';
import 'player.dart';
import 'block.dart';
import 'puzzle_battle_game.dart';

class MatchProcessor {
  final Grid grid;
  final Player player;
  final PuzzleBattleGame game;

  MatchProcessor({
    required this.grid,
    required this.player,
    required this.game,
  });

  List<List<Block>> findMatches() {
    return grid.checkForMatches();
  }

  void processMatches(List<List<Block>> matches) {
    if (matches.isEmpty) {
      player.resetCombo();
      return;
    }

    // Calculate total points from block matches
    int totalPoints = 0;

    // Process each match
    for (final match in matches) {
      // Calculate points for this match
      final points = calculatePoints(match);
      totalPoints += points;

      // Check if this match creates a special block
      final specialBlock = createSpecialBlock(match);

      // Remove matched blocks (but not the active block)
      for (final block in match) {
        if (block != grid.activeBlock) {
          grid.removeBlock(block);
        }
      }

      // Add special block if created
      if (specialBlock != null) {
        grid.cells[specialBlock.row][specialBlock.column] = specialBlock;
      }
    }

    // After processing matches, check for completed lines
    List<int> completedLines = grid.checkCompletedLines();
    if (completedLines.isNotEmpty) {
      // Calculate score based on number of lines cleared
      int lineCount = completedLines.length;
      int lineScore = 0;

      // Determine the score based on line count
      switch (lineCount) {
        case 1:
          lineScore = 100; // Single line
          break;
        case 2:
          lineScore = 300; // Double
          break;
        case 3:
          lineScore = 500; // Triple
          break;
        case 4:
          lineScore = 800; // Tetris!
          break;
        default:
          lineScore = lineCount * 100; // More than 4 lines
      }

      // Apply combo multiplier
      int finalScore = lineScore * player.comboMultiplier;
      totalPoints += finalScore;

      // Record lines cleared for level calculation
      game.scoreManager.addLines(lineCount);

      // Clear the lines
      grid.clearLines(completedLines);

      // Add attack power based on lines cleared
      int attackPower = lineCount * 2; // Simple formula: 2 junk blocks per line cleared

      // Send attack if in multiplayer
      if (game.isMultiplayer) {
        game.gameServer.sendAttack(attackPower);
      }

      // Increase combo after successful line clear
      player.increaseCombo();
    } else if (totalPoints == 0) {
      // No points from matches or line clears, reset combo
      player.resetCombo();
    }

    // Add points to player's score
    if (totalPoints > 0) {
      game.scoreManager.addScore(totalPoints);

      // Increase special meter based on points
      double meterIncrease = totalPoints / 100.0; // Simple formula: 1 point of meter per 100 score
      player.increaseSpecialMeter(meterIncrease);
    }
  }

  int calculatePoints(List<Block> match) {
    // Base points based on match length
    int basePoints = match.length * 10;

    // Bonus points for longer matches
    if (match.length > 3) {
      basePoints += (match.length - 3) * 20;
    }

    // Bonus points for special block types
    for (final block in match) {
      if (block.type == BlockType.special) {
        basePoints += 50;
      } else if (block.type == BlockType.powerUp) {
        basePoints += 30;
      }
    }

    return basePoints;
  }

  Block? createSpecialBlock(List<Block> match) {
    // Create special blocks for large matches
    if (match.length >= 5) {
      // Create at the position of the first block in the match
      return Block.special()
        ..row = match[0].row
        ..column = match[0].column
        ..isActive = false;
    } else if (match.length == 4 && match.any((block) => block.type == BlockType.special)) {
      // Create a power-up if matching 4 with a special block
      return Block.powerUp()
        ..row = match[0].row
        ..column = match[0].column
        ..isActive = false;
    }

    return null;
  }
}
