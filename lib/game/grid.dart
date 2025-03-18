import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'block.dart' as game_block;

class Grid extends PositionComponent {
  final List<List<game_block.Block?>> cells;
  final int rows;
  final int columns;
  final double cellSize;
  bool isVisible = true;

  game_block.Block? activeBlock;

  Grid({
    required Vector2 position,
    required Vector2 size,
    required this.rows,
    required this.columns,
  })  : cells = List.generate(rows, (_) => List.filled(columns, null)),
        cellSize = size.x / columns,
        super(position: position, size: size);

// Add this as a class property at the top of your Grid class
  int _frameCounter = 0;

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    super.render(canvas);

    // Increment frame counter
    _frameCounter++;

    // Draw grid background
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.8);
    canvas.drawRect(rect, backgroundPaint);

    // Draw grid lines
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Draw horizontal lines
    for (int i = 0; i <= rows; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.x, y),
        linePaint,
      );
    }

    // Draw vertical lines
    for (int i = 0; i <= columns; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.y),
        linePaint,
      );
    }

    // Occasional debug info
    if (_frameCounter % 60 == 0) {
      Map<String, int> cellMap = {};
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < columns; c++) {
          if (cells[r][c] != null) {
            String key = "${cells[r][c]!.type}";
            cellMap[key] = (cellMap[key] ?? 0) + 1;
          }
        }
      }

      if (cellMap.isNotEmpty) {
        // print("Filled cells: $cellMap");
      }
    }

    // Draw cells
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        if (cells[r][c] != null) {
          // Get the block type for this cell
          final blockType = cells[r][c]!.type;

          // Debug to verify correct block type
          if (_frameCounter % 60 == 0 && blockType == game_block.BlockType.J) {
            // print("Drawing J block cell at [$r][$c]");
          }

          // Calculate cell rectangle
          final blockRect = Rect.fromLTWH(
            c * cellSize,
            r * cellSize,
            cellSize,
            cellSize,
          );

          // Get color for this block type with high visibility
          Color blockColor;
          switch (blockType) {
            case game_block.BlockType.I:
              blockColor = Colors.cyan.shade400;
              break;
            case game_block.BlockType.O:
              blockColor = Colors.yellow.shade400;
              break;
            case game_block.BlockType.T:
              blockColor = Colors.purple.shade400;
              break;
            case game_block.BlockType.S:
              blockColor = Colors.green.shade400;
              break;
            case game_block.BlockType.Z:
              blockColor = Colors.red.shade400;
              break;
            case game_block.BlockType.J:
              blockColor = Colors.lightBlue.shade300; // Brighter blue for J
              break;
            case game_block.BlockType.L:
              blockColor = Colors.orange.shade400;
              break;
            case game_block.BlockType.junk:
              blockColor = Colors.grey.shade400;
              break;
            case game_block.BlockType.special:
              blockColor = Colors.pink.shade300;
              break;
            case game_block.BlockType.powerUp:
              blockColor = Colors.amber.shade300;
              break;
            default:
              blockColor = Colors.white;
          }

          // Draw block with solid color
          final blockPaint = Paint()..color = blockColor;
          canvas.drawRect(blockRect, blockPaint);

          // Draw border
          final borderPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;

          canvas.drawRect(blockRect, borderPaint);

          // If it's the active block, add a marker
          if (cells[r][c] == activeBlock) {
            final centerX = c * cellSize + cellSize / 2;
            final centerY = r * cellSize + cellSize / 2;
            final dotSize = cellSize * 0.2;

            final dotPaint = Paint()..color = Colors.white;
            canvas.drawCircle(Offset(centerX, centerY), dotSize, dotPaint);
          }
        }
      }
    }
  }

  void removeBlock(game_block.Block block) {
    print("removeBlock called for ${block.type} block");
    print(StackTrace.current);
    // Special case for active block
    if (block == activeBlock) {
      List<List<int>> pattern = block.getShapePattern();

      for (int r = 0; r < pattern.length; r++) {
        for (int c = 0; c < pattern[r].length; c++) {
          if (pattern[r][c] == 1) {
            int gridRow = block.row + r;
            int gridCol = block.column + c;

            if (gridRow >= 0 && gridRow < rows && gridCol >= 0 && gridCol < columns) {
              cells[gridRow][gridCol] = null;
            }
          }
        }
      }
    } else {
      // For non-active blocks, we don't have shape info
      // so we need to check all cells
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < columns; c++) {
          if (cells[r][c] == block) {
            cells[r][c] = null;
          }
        }
      }
    }
  }

  bool moveBlock(game_block.Block block, int newRow, int newCol) {
    if (block != activeBlock) return false;

    // Check if move is valid
    if (!canPlaceBlockAt(block, newRow, newCol)) {
      return false;
    }

    // Remove from current cells
    removeBlockFromCells(block);

    // Update position
    block.row = newRow;
    block.column = newCol;

    // Place at new position
    placeBlockInCells(block);

    return true;
  }

  void removeBlockFromCells(game_block.Block block) {
    // For multi-cell blocks, we need to check the whole grid
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        // Only remove cells that contain this specific block reference
        if (cells[r][c] == block) {
          cells[r][c] = null;
          // print("Removed block cell at [$r][$c]");
        }
      }
    }
  }

  bool canPlaceBlockAt(game_block.Block block, int row, int col) {
    List<List<int>> pattern = block.getShapePattern();

    for (int r = 0; r < pattern.length; r++) {
      for (int c = 0; c < pattern[r].length; c++) {
        if (pattern[r][c] == 1) {
          int newRow = row + r;
          int newCol = col + c;

          // Check if out of bounds
          if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= columns) {
            return false;
          }

          // Check if cell is already occupied by another block
          if (cells[newRow][newCol] != null && cells[newRow][newCol] != block) {
            return false;
          }
        }
      }
    }

    return true;
  }

  bool rotateActiveBlock() {
    if (activeBlock == null) return false;

    // Save the current rotation and get old pattern
    int originalRotation = activeBlock!.rotation;
    List<List<int>> oldPattern = activeBlock!.getShapePattern();

    // Track current cells occupied by this block
    List<List<int>> oldCells = [];
    for (int r = 0; r < oldPattern.length; r++) {
      for (int c = 0; c < oldPattern[r].length; c++) {
        if (oldPattern[r][c] == 1) {
          oldCells.add([activeBlock!.row + r, activeBlock!.column + c]);
        }
      }
    }

    // Try to rotate
    activeBlock!.rotate();

    // Check if new rotation is valid
    if (!canPlaceBlockAt(activeBlock!, activeBlock!.row, activeBlock!.column)) {
      // Try wall kick - adjust position if against a wall
      bool validPositionFound = false;

      // Try positions to the left and right
      for (int xOffset = -1; xOffset <= 1; xOffset++) {
        if (xOffset == 0) continue; // Skip original position

        if (canPlaceBlockAt(activeBlock!, activeBlock!.row, activeBlock!.column + xOffset)) {
          // Found a valid position with wall kick
          validPositionFound = true;
          activeBlock!.column += xOffset;
          break;
        }
      }

      if (!validPositionFound) {
        // Revert rotation
        activeBlock!.rotation = originalRotation;
        return false;
      }
    }

    // Completely clear all old cells
    for (List<int> cell in oldCells) {
      int row = cell[0];
      int col = cell[1];
      if (row >= 0 && row < rows && col >= 0 && col < columns) {
        cells[row][col] = null;
      }
    }

    // Place at new rotated position
    placeBlockInCells(activeBlock!);

    return true;
  }

  void addBlock(game_block.Block block) {
    if (activeBlock != null) {
      // Already have an active block
      return;
    }

    // Place block at top center, adjusted for shape width
    block.row = 0;

    // Get pattern to determine width
    List<List<int>> pattern = block.getShapePattern();
    int patternWidth = pattern[0].length;

    // Center the block horizontally
    block.column = (columns - patternWidth) ~/ 2;

    // Check if placement is possible
    if (!canPlaceBlockAt(block, block.row, block.column)) {
      print("Can't place new block - game over condition");
      return;
    }

    activeBlock = block;
    placeBlockInCells(block);
  }

  void placeBlockInCells(game_block.Block block) {
    List<List<int>> pattern = block.getShapePattern();
    // print("Placing block type ${block.type} with pattern of size ${pattern.length}x${pattern[0].length}");

    for (int r = 0; r < pattern.length; r++) {
      for (int c = 0; c < pattern[r].length; c++) {
        if (pattern[r][c] == 1) {
          int newRow = block.row + r;
          int newCol = block.column + c;

          if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < columns) {
            // Critical: Set reference to the block object in each cell it occupies
            cells[newRow][newCol] = block;
            // print("Cell placed at [$newRow][$newCol]");
          } else {
            print("WARNING: Cell out of bounds at [$newRow][$newCol]");
          }
        }
      }
    }
  }

  void addBlockToGridCells(game_block.Block block) {
    List<List<int>> pattern = block.getShapePattern();

    for (int r = 0; r < pattern.length; r++) {
      for (int c = 0; c < pattern[r].length; c++) {
        if (pattern[r][c] == 1) {
          int gridRow = block.row + r;
          int gridCol = block.column + c;
          cells[gridRow][gridCol] = block;
        }
      }
    }
  }

  bool dropActiveBlock() {
    if (activeBlock == null) return false;

    int newRow = activeBlock!.row;

    // Find the lowest possible position
    while (newRow < rows - 1 && canPlaceBlockAt(activeBlock!, newRow + 1, activeBlock!.column)) {
      newRow++;
    }

    if (newRow != activeBlock!.row) {
      return moveBlock(activeBlock!, newRow, activeBlock!.column);
    }

    // Lock the block in place
    activeBlock!.isActive = false;
    activeBlock = null;

    return true;
  }

  List<List<game_block.Block>> checkForMatches() {
    List<List<game_block.Block>> allMatches = [];

    // Check horizontal matches
    for (int r = 0; r < rows; r++) {
      int c = 0;
      while (c < columns - 2) {
        if (cells[r][c] != null) {
          final blockType = cells[r][c]!.type;
          int matchLength = 1;

          while (c + matchLength < columns && cells[r][c + matchLength] != null && cells[r][c + matchLength]!.type == blockType) {
            matchLength++;
          }

          if (matchLength >= 3) {
            List<game_block.Block> match = [];
            for (int i = 0; i < matchLength; i++) {
              match.add(cells[r][c + i]!);
            }
            allMatches.add(match);
            c += matchLength;
          } else {
            c++;
          }
        } else {
          c++;
        }
      }
    }

    List<int> checkForCompletedRows() {
      List<int> completedRows = [];

      for (int r = 0; r < rows; r++) {
        bool rowComplete = true;

        for (int c = 0; c < columns; c++) {
          if (cells[r][c] == null || cells[r][c] == activeBlock) {
            rowComplete = false;
            break;
          }
        }

        if (rowComplete) {
          completedRows.add(r);
        }
      }

      return completedRows;
    }

    // Check vertical matches
    for (int c = 0; c < columns; c++) {
      int r = 0;
      while (r < rows - 2) {
        if (cells[r][c] != null) {
          final blockType = cells[r][c]!.type;
          int matchLength = 1;

          while (r + matchLength < rows && cells[r + matchLength][c] != null && cells[r + matchLength][c]!.type == blockType) {
            matchLength++;
          }

          if (matchLength >= 3) {
            List<game_block.Block> match = [];
            for (int i = 0; i < matchLength; i++) {
              match.add(cells[r + i][c]!);
            }
            allMatches.add(match);
            r += matchLength;
          } else {
            r++;
          }
        } else {
          r++;
        }
      }
    }

    return allMatches;
  }

  bool isFull() {
    // Game is over if the top row has any settled blocks
    for (int c = 0; c < columns; c++) {
      if (cells[0][c] != null && cells[0][c] != activeBlock) {
        return true;
      }
    }
    return false;
  }

  void addJunkBlocks(int count) {
    // Shift all existing blocks up
    for (int r = 0; r < rows - count; r++) {
      for (int c = 0; c < columns; c++) {
        cells[r][c] = cells[r + count][c];
        if (cells[r][c] != null) {
          cells[r][c]!.row = r;
        }
      }
    }

    // Add junk blocks at the bottom
    for (int r = rows - count; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        cells[r][c] = game_block.Block(
          type: game_block.BlockType.junk,
          row: r,
          column: c,
          isActive: false,
        );
      }
    }
  }

  void clearRows(List<int> rowsToClear) {
    // Sort rows in descending order to start from the bottom
    rowsToClear.sort((a, b) => b.compareTo(a));

    for (int rowIndex in rowsToClear) {
      // Clear the row
      for (int c = 0; c < columns; c++) {
        cells[rowIndex][c] = null;
      }

      // Move all rows above down by one
      for (int r = rowIndex - 1; r >= 0; r--) {
        for (int c = 0; c < columns; c++) {
          if (cells[r][c] != null && cells[r][c] != activeBlock) {
            // Move this block down
            cells[r + 1][c] = cells[r][c];
            cells[r][c] = null;

            // Update the block's row property if needed
            // This is tricky with multi-cell blocks, as the cell might belong to a block whose reference row is different
            // For simplicity in this example, we'll skip this step, which works for rendered display
            // In a full game, you'd need to track block ownership
          }
        }
      }
    }
  }

  void clearRow(int row) {
    // Clear the specified row
    for (int c = 0; c < columns; c++) {
      cells[row][c] = null;
    }

    // Move all rows above down by one
    for (int r = row - 1; r >= 0; r--) {
      for (int c = 0; c < columns; c++) {
        if (cells[r][c] != null && cells[r][c] != activeBlock) {
          // Move this block down
          cells[r + 1][c] = cells[r][c];
          cells[r][c] = null;
        }
      }
    }
  }

  Color getColorForBlockType(game_block.BlockType type) {
    switch (type) {
      case game_block.BlockType.I:
        return Colors.cyan.shade400;
      case game_block.BlockType.O:
        return Colors.yellow.shade400;
      case game_block.BlockType.T:
        return Colors.purple.shade400;
      case game_block.BlockType.S:
        return Colors.green.shade400;
      case game_block.BlockType.Z:
        return Colors.red.shade400;
      case game_block.BlockType.J:
        return Colors.blue.shade300; // Lighter blue for better visibility
      case game_block.BlockType.L:
        return Colors.orange.shade400;
      case game_block.BlockType.junk:
        return Colors.grey.shade600;
      case game_block.BlockType.special:
        return Colors.pink.shade300;
      case game_block.BlockType.powerUp:
        return Colors.amber.shade300;
      default:
        return Colors.white;
    }
  }

  Vector2 toLocal(Vector2 gamePosition) {
    // Convert game coordinates to local grid coordinates
    return gamePosition - position;
  }

  void reset() {
    // Clear all cells
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        cells[r][c] = null;
      }
    }

    // Reset active block
    activeBlock = null;
  }

  List<int> checkCompletedLines() {
    List<int> completedLines = [];

    // Check each row, starting from the bottom
    for (int r = rows - 1; r >= 0; r--) {
      bool isComplete = true;
      int filledCells = 0;

      // A line is complete when all cells are filled
      for (int c = 0; c < columns; c++) {
        if (cells[r][c] != null) {
          filledCells++;
        } else {
          isComplete = false;
        }
      }

      // print("Row $r: $filledCells/$columns cells filled, isComplete: $isComplete");

      if (isComplete) {
        completedLines.add(r);
        print("COMPLETE LINE DETECTED: Row $r");
      }
    }

    if (completedLines.isNotEmpty) {
      print("Found ${completedLines.length} completed lines: $completedLines");
    }

    return completedLines;
  }

  void clearLines(List<int> lines) {
    if (lines.isEmpty) return;

    // Sort lines in descending order (clear from bottom to top)
    lines.sort((a, b) => b.compareTo(a));
    print("Clearing lines: $lines");

    // First, mark all cells in these lines for removal
    for (int lineIndex in lines) {
      for (int c = 0; c < columns; c++) {
        cells[lineIndex][c] = null;
      }
    }

    // Then, for each column, shift down all cells above the highest cleared line
    int highestClearedLine = lines.last; // After sorting, this is the smallest index (highest on screen)

    for (int c = 0; c < columns; c++) {
      // Count empty cells for each column
      int shiftAmount = 0;

      // Process from bottom to top
      for (int r = rows - 1; r >= 0; r--) {
        // If this is a cleared line, increase shift amount
        if (lines.contains(r)) {
          shiftAmount++;
          continue;
        }

        // If there's a block and we need to shift it
        if (cells[r][c] != null && shiftAmount > 0) {
          // Move the block down by the shift amount
          int newRow = r + shiftAmount;
          if (newRow < rows) {
            // Make sure we're still in bounds
            cells[newRow][c] = cells[r][c];
            cells[r][c] = null;

            // Update the block's position
            if (cells[newRow][c] != null && cells[newRow][c] != activeBlock) {
              cells[newRow][c]!.row = newRow;
            }
          }
        }
      }
    }

    print("Cleared ${lines.length} lines");
  }
}
