// block.dart
import 'dart:math';
import 'package:flutter/material.dart';

enum BlockType {
  I, // Line piece
  O, // Square piece
  T, // T-shaped piece
  S, // S-shaped piece
  Z, // Z-shaped piece
  J, // J-shaped piece
  L, // L-shaped piece
  junk, // Junk blocks
  special, // Special blocks
  powerUp // Power-up blocks
}

class Block {
  final BlockType type;
  int row;
  int column;
  bool isActive;
  int rotation = 0; // 0, 1, 2, 3 for the 4 possible rotations
  Map<String, dynamic> properties;

  Block({
    required this.type,
    required this.row,
    required this.column,
    this.isActive = true,
    Map<String, dynamic>? properties,
  }) : this.properties = properties ?? {};

  static Block random() {
    final random = Random();
    final types = [
      BlockType.I,
      BlockType.O,
      BlockType.T,
      BlockType.S,
      BlockType.Z,
      BlockType.J,
      BlockType.L,
    ];

    return Block(
      type: types[random.nextInt(types.length)],
      row: 0,
      column: 4, // Center of a 10-column grid
    );
  }

  static Block special() {
    return Block(
      type: BlockType.special,
      row: 0,
      column: 4,
      properties: {
        'specialType': 'bomb',
        'power': 3,
      },
    );
  }

  static Block powerUp() {
    final random = Random();
    final powerUpTypes = ['freeze', 'clear', 'shield'];

    return Block(
      type: BlockType.powerUp,
      row: 0,
      column: 4,
      properties: {
        'powerUpType': powerUpTypes[random.nextInt(powerUpTypes.length)],
        'duration': 5.0,
      },
    );
  }

  // Get the shape pattern based on block type and rotation
  List<List<int>> getShapePattern() {
    switch (type) {
      case BlockType.I:
        return _getIPattern();
      case BlockType.O:
        return _getOPattern();
      case BlockType.T:
        return _getTPattern();
      case BlockType.S:
        return _getSPattern();
      case BlockType.Z:
        return _getZPattern();
      case BlockType.J:
        // return _getJPattern();
        List<List<int>> pattern = _getJPattern();
        return pattern;
      case BlockType.L:
        return _getLPattern();
      default:
        // Default for single blocks (junk, special, powerup)
        return [
          [1]
        ];
    }
  }

  // Rotate the block
  void rotate() {
    // Rotate 90 degrees clockwise
    rotation = (rotation + 1) % 4;
  }

// I-shaped piece (line)
  List<List<int>> _getIPattern() {
    if (rotation % 2 == 0) {
      return [
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0]
      ];
    } else {
      return [
        [0, 1, 0, 0],
        [0, 1, 0, 0],
        [0, 1, 0, 0],
        [0, 1, 0, 0]
      ];
    }
  }

  // O-shaped piece (square)
  List<List<int>> _getOPattern() {
    return [
      [1, 1],
      [1, 1]
    ];
  }

// T-shaped piece
  List<List<int>> _getTPattern() {
    switch (rotation) {
      case 0:
        return [
          [0, 1, 0],
          [1, 1, 1],
          [0, 0, 0]
        ];
      case 1:
        return [
          [0, 1, 0],
          [0, 1, 1],
          [0, 1, 0]
        ];
      case 2:
        return [
          [0, 0, 0],
          [1, 1, 1],
          [0, 1, 0]
        ];
      case 3:
        return [
          [0, 1, 0],
          [1, 1, 0],
          [0, 1, 0]
        ];
      default:
        return [
          [0, 1, 0],
          [1, 1, 1],
          [0, 0, 0]
        ];
    }
  }

  // S-shaped piece
  List<List<int>> _getSPattern() {
    if (rotation % 2 == 0) {
      return [
        [0, 1, 1],
        [1, 1, 0],
        [0, 0, 0]
      ];
    } else {
      return [
        [0, 1, 0],
        [0, 1, 1],
        [0, 0, 1]
      ];
    }
  }

  // Z-shaped piece
  List<List<int>> _getZPattern() {
    if (rotation % 2 == 0) {
      return [
        [1, 1, 0],
        [0, 1, 1],
        [0, 0, 0]
      ];
    } else {
      return [
        [0, 0, 1],
        [0, 1, 1],
        [0, 1, 0]
      ];
    }
  }

// J-shaped piece
  List<List<int>> _getJPattern() {
    switch (rotation) {
      case 0:
        return [
          [1, 0, 0],
          [1, 1, 1],
          [0, 0, 0]
        ];
      case 1:
        return [
          [0, 1, 1],
          [0, 1, 0],
          [0, 1, 0]
        ];
      case 2:
        return [
          [0, 0, 0],
          [1, 1, 1],
          [0, 0, 1]
        ];
      case 3:
        return [
          [0, 1, 0],
          [0, 1, 0],
          [1, 1, 0]
        ];
      default:
        print("WARNING: Invalid rotation value: $rotation for J block");
        return [
          [1, 0, 0],
          [1, 1, 1],
          [0, 0, 0]
        ];
    }
  }

// L-shaped piece
  List<List<int>> _getLPattern() {
    switch (rotation) {
      case 0:
        return [
          [0, 0, 1],
          [1, 1, 1],
          [0, 0, 0]
        ];
      case 1:
        return [
          [0, 1, 0],
          [0, 1, 0],
          [0, 1, 1]
        ];
      case 2:
        return [
          [0, 0, 0],
          [1, 1, 1],
          [1, 0, 0]
        ];
      case 3:
        return [
          [1, 1, 0],
          [0, 1, 0],
          [0, 1, 0]
        ];
      default:
        return [
          [0, 0, 1],
          [1, 1, 1],
          [0, 0, 0]
        ];
    }
  }
}
