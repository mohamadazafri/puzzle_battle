import 'dart:collection';
import 'dart:math';
import 'block.dart';

class BlockSpawner {
  final Queue<BlockType> nextBlocks = Queue<BlockType>();
  final int previewCount;
  final Random random = Random();

  BlockSpawner({required this.previewCount}) {
    refillQueue();
  }

  Block generateNextBlock() {
    if (nextBlocks.isEmpty) {
      refillQueue();
    }

    final type = nextBlocks.removeFirst();

    if (type == BlockType.special) {
      return Block.special();
    } else if (type == BlockType.powerUp) {
      return Block.powerUp();
    } else {
      return Block(
        type: type,
        row: 0,
        column: 4,
      );
    }
  }

  List<BlockType> peekNextBlocks() {
    return nextBlocks.take(previewCount).toList();
  }

  void refillQueue() {
    // Basic block types that will appear regularly
    List<BlockType> standardTypes = [
      // BlockType.,
      // BlockType.blue,
      // BlockType.green,
      // BlockType.yellow,
      // BlockType.purple,

      BlockType.I, // Line piece
      BlockType.O, // Square piece
      BlockType.T, // T-shaped piece
      BlockType.S, // S-shaped piece
      BlockType.Z, // Z-shaped piece
      BlockType.J, // J-shaped piece
      BlockType.L, // L-shaped piece
      BlockType.junk,
      BlockType.powerUp,
      BlockType.special
    ];

    // Create a batch of blocks
    List<BlockType> newBatch = [];

    // Add standard blocks
    // for (int i = 0; i < 20; i++) {
    //   newBatch.add(standardTypes[random.nextInt(standardTypes.length)]);
    // }
    for (int i = 0; i < 20; i++) {
      BlockType type = standardTypes[random.nextInt(standardTypes.length)];
      newBatch.add(type);

      // Add J blocks occasionally for testing
      if (i % 5 == 0) {
        print("Explicitly adding J block to batch at position $i");
        newBatch.add(BlockType.J);
      }
    }

    // Occasionally add special blocks
    if (random.nextDouble() < 0.1) {
      newBatch.add(BlockType.special);
    }

    // Occasionally add power-up blocks
    if (random.nextDouble() < 0.05) {
      newBatch.add(BlockType.powerUp);
    }

    // Shuffle the batch and add to queue
    newBatch.shuffle(random);
    nextBlocks.addAll(newBatch);

    print("Queue refilled. First 5 blocks: ${nextBlocks.take(5).toList()}");
  }
}
