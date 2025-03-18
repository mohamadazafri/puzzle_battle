import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_battle/game/puzzle_battle_game.dart';
import 'grid.dart';
import 'block.dart' as game_block;
import 'package:flutter/services.dart';
import 'dart:math';

enum SwipeDirection {
  left,
  right,
  down,
  up,
}

class InputController {
  final Grid grid;
  final Function onBlockPlaced;
  final PuzzleBattleGame game;

  // Gesture properties
  Offset? dragStart;
  DateTime? dragStartTime;

  bool _isAcceleratingDown = false; // Flag for sustained downward pressure
  double _accelerationTimer = 0.0; // Timer for sustained downward movement
  bool _hasHandledDownSwipe = false; // Track if we've already handled a down swipe in this gesture
  double _lastDownY = 0.0; // Track finger position for soft drop
  double _initialDragY = 0.0; // Track initial touch position

  InputController({
    required this.grid,
    required this.onBlockPlaced,
    required this.game,
  });

  // Instead of directly setting gestureRecognizers on the game,
  // we'll create a method to be called from PuzzleBattleGame
  List<GestureRecognizer> createGestureRecognizers() {
    return [
      PanGestureRecognizer(),
      TapGestureRecognizer(),
    ];
  }

  void handleKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (game.isPaused || game.isGameOver) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _moveActiveBlockLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _moveActiveBlockRight();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveActiveBlockDown();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _rotateActiveBlock();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        _dropActiveBlock();
      }
    }
  }

  void handleTap(TapDownDetails details, Vector2 gamePosition) {
    // Convert game position to grid coordinates by subtracting grid position
    Vector2 localPosition = gamePosition - grid.position;
    final column = (localPosition.x / grid.cellSize).floor();
    final row = (localPosition.y / grid.cellSize).floor();

    // Handle taps based on game state
    if (grid.activeBlock != null) {
      // Rotate the active block
      grid.rotateActiveBlock();
    } else {
      // Check if tapped on a special or power-up block
      if (row >= 0 && row < grid.rows && column >= 0 && column < grid.columns) {
        final block = grid.cells[row][column];
        if (block != null && (block.type == game_block.BlockType.special || block.type == game_block.BlockType.powerUp)) {
          // Activate the special block
          _activateSpecialBlock(block);
        }
      }
    }
  }

  void handleDrag(DragUpdateDetails details) {
    if (dragStart == null) {
      dragStart = details.globalPosition;
      _initialDragY = details.globalPosition.dy; // Record initial Y position
      dragStartTime = DateTime.now();
      _hasHandledDownSwipe = false;
      _isAcceleratingDown = false;
      return;
    }

    // Calculate total drag distance from start
    final totalDragDistanceY = details.globalPosition.dy - _initialDragY;
    final dragDistance = details.globalPosition - dragStart!;
    final timeDiff = DateTime.now().difference(dragStartTime!).inMilliseconds;

    // Minimum drag distance to trigger a swipe
    const minDistance = 20.0;

    // Make downward swipe detection more lenient
    if (totalDragDistanceY > 30) {
      // Clearly moving downward by at least 30 pixels from start
      // This is definitely a downward gesture, not a tap
      if (!_hasHandledDownSwipe && !_isAcceleratingDown) {
        double speed = dragDistance.distance / max(timeDiff, 1);

        if (speed > 2.0 && timeDiff < 150) {
          // Fast swipe - treat as hard drop
          _hasHandledDownSwipe = true;
          _dropActiveBlock();
        } else {
          // Slower downward movement - enable soft drop
          _isAcceleratingDown = true;
          _lastDownY = details.globalPosition.dy;

          // Tell the game to accelerate falling
          game.setBlockFallSpeedMultiplier(5.0);
        }
      } else if (_isAcceleratingDown) {
        // Continue soft drop logic
        double yDelta = details.globalPosition.dy - _lastDownY;
        if (yDelta > grid.cellSize / 2) {
          _moveActiveBlockDown();
          _lastDownY = details.globalPosition.dy;
        }
      }
    }
    // Handle horizontal movement if significant
    else if (dragDistance.dx.abs() > minDistance) {
      SwipeDirection direction = dragDistance.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      handleSwipe(direction);

      // Reset drag start for continuous horizontal movement
      dragStart = details.globalPosition;
      dragStartTime = DateTime.now();
    }
  }

  void handleDragEnd(DragEndDetails details) {
    // If we were accelerating, restore normal fall speed
    if (_isAcceleratingDown) {
      game.setBlockFallSpeedMultiplier(1.0);
      _isAcceleratingDown = false;
    }

    dragStart = null;
    dragStartTime = null;
    _hasHandledDownSwipe = false;
  }

  // void _hardDrop() {
  //   // Implement hard drop - move block all the way down
  //   if (grid.activeBlock != null) {
  //     game.dropActiveBlock();
  //   }
  // }

  void handleSwipe(SwipeDirection direction) {
    if (grid.activeBlock == null) return;

    switch (direction) {
      case SwipeDirection.left:
        _moveActiveBlockLeft();
        break;
      case SwipeDirection.right:
        _moveActiveBlockRight();
        break;
      case SwipeDirection.down:
        _dropActiveBlock();
        break;
      case SwipeDirection.up:
        grid.rotateActiveBlock();
        break;
    }
  }

  void _moveActiveBlockLeft() {
    if (grid.activeBlock != null) {
      final newColumn = grid.activeBlock!.column - 1;

      // Check if movement is valid
      if (grid.canPlaceBlockAt(grid.activeBlock!, grid.activeBlock!.row, newColumn)) {
        grid.moveBlock(grid.activeBlock!, grid.activeBlock!.row, newColumn);
      }
    }
  }

  void _moveActiveBlockRight() {
    if (grid.activeBlock != null) {
      final newColumn = grid.activeBlock!.column + 1;

      // Check if movement is valid
      if (grid.canPlaceBlockAt(grid.activeBlock!, grid.activeBlock!.row, newColumn)) {
        grid.moveBlock(grid.activeBlock!, grid.activeBlock!.row, newColumn);
      }
    }
  }

  void _moveActiveBlockDown() {
    if (grid.activeBlock != null) {
      int newRow = grid.activeBlock!.row + 1;
      if (newRow < grid.rows && grid.canPlaceBlockAt(grid.activeBlock!, newRow, grid.activeBlock!.column)) {
        grid.moveBlock(grid.activeBlock!, newRow, grid.activeBlock!.column);
      }
    }
  }
  // void _moveActiveBlockDown() {
  //   if (grid.activeBlock != null) {
  //     final newRow = grid.activeBlock!.row + 1;

  //     // Check if movement is valid
  //     if (grid.canPlaceBlockAt(grid.activeBlock!, newRow, grid.activeBlock!.column)) {
  //       grid.moveBlock(grid.activeBlock!, newRow, grid.activeBlock!.column);
  //     } else {
  //       // Block can't move down further, lock it in place
  //       _lockActiveBlock();
  //     }
  //   }
  // }

  void _rotateActiveBlock() {
    if (grid.activeBlock != null) {
      grid.rotateActiveBlock();
    }
  }

  void _dropActiveBlock() {
    if (grid.activeBlock != null) {
      // Find the lowest valid position
      int row = grid.activeBlock!.row;
      int column = grid.activeBlock!.column;

      while (row < grid.rows - 1 && grid.canPlaceBlockAt(grid.activeBlock!, row + 1, column)) {
        row++;
      }

      // Move block to the lowest position
      if (row != grid.activeBlock!.row) {
        grid.moveBlock(grid.activeBlock!, row, column);
      }

      // Lock the block in place immediately
      _lockActiveBlock();

      // Call onBlockPlaced to spawn a new block immediately
      onBlockPlaced();
    }
  }

  void _lockActiveBlock() {
    // Call the game's lock method instead
    game.lockActiveBlock();
  }

  void _activateSpecialBlock(game_block.Block block) {
    // Handle different types of special blocks
    if (block.type == game_block.BlockType.special) {
      if (block.properties['specialType'] == 'bomb') {
        // Bomb effect: clear nearby blocks
        _clearNearbyBlocks(block.row, block.column, block.properties['power'] ?? 1);
      }
    } else if (block.type == game_block.BlockType.powerUp) {
      switch (block.properties['powerUpType']) {
        case 'freeze':
          // Freeze effect would be handled at the game level
          break;
        case 'clear':
          // Clear effect: remove blocks in the same row
          _clearRow(block.row);
          break;
        case 'shield':
          // Shield effect would be handled at the game level
          break;
      }
    }

    // Remove the activated block
    grid.removeBlock(block);
  }

  void _clearNearbyBlocks(int row, int column, int radius) {
    for (int r = row - radius; r <= row + radius; r++) {
      for (int c = column - radius; c <= column + radius; c++) {
        if (r >= 0 && r < grid.rows && c >= 0 && c < grid.columns) {
          final block = grid.cells[r][c];
          if (block != null) {
            grid.removeBlock(block);
          }
        }
      }
    }
  }

  void _clearRow(int row) {
    grid.clearRow(row);
  }
}
