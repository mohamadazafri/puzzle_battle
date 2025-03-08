import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'grid.dart';
import 'player.dart';
import 'block.dart' as game_block;
import 'game_server.dart';
import 'block_spawner.dart';
import 'score_manager.dart';
import 'match_processor.dart';
import 'special_ability.dart';
import 'input_controller.dart';
import 'overlays/overlay_manager.dart';
import 'package:flutter/services.dart';
import 'overlays/game_overlay.dart';

class PuzzleBattleGame extends FlameGame with TapDetector, PanDetector, KeyboardEvents {
  final GlobalKey<GameOverlayState> gameOverlayKey = GlobalKey<GameOverlayState>();

  final Map<int, int> lineScores = {
    1: 100, // Single line
    2: 300, // Double
    3: 500, // Triple
    4: 800 // Tetris!
  };

  // Game components
  late Grid playerGrid;
  late Grid opponentGrid;
  late Player currentPlayer;
  late Player opponent;
  late GameServer gameServer;
  late BlockSpawner blockSpawner;
  late ScoreManager scoreManager;
  late MatchProcessor matchProcessor;
  bool isWinner = false;
  bool isGameOver = false;
  late InputController inputController;

  // Game state
  bool isPaused = false;
  bool isMultiplayer = false;
  String roomId = '';
  String previousOverlay = 'mainMenu';
  double _blockFallTimer = 0;
  double _blockFallSpeed = 1.0; // Blocks per second
  double _fallSpeedMultiplier = 1.0;
  bool _isInLockDelay = false;
  double _lockDelayTimer = 0.0;
  final double _lockDelayDuration = 1.0; // 0.5 seconds for adjustment

  OverlayManager? _overlayManager;

  set overlayManager(OverlayManager? manager) {
    _overlayManager = manager;
  }

  OverlayManager? get overlayManager => _overlayManager;

  void initializeOverlayManager() {
    overlayManager = OverlayManager(this);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Only process inputs if game is active
    if (isPaused || isGameOver) return KeyEventResult.ignored;

    // Delegate to input controller
    inputController.handleKeyEvent(event, keysPressed);

    // Return handled to indicate we've processed this event
    return KeyEventResult.handled;
  }

  @override
  Future<void> onLoad() async {
    final screenSize = size;
    final gridWidth = screenSize.x * 0.8;
    final gridHeight = screenSize.y * 0.7;

    if (overlayManager == null) {
      initializeOverlayManager();
    }

    // // Load assets
    // await images.loadAll([
    //   'blocks/red.png',
    //   'blocks/blue.png',
    //   'blocks/green.png',
    //   'blocks/yellow.png',
    //   'blocks/purple.png',
    //   'blocks/special.png',
    //   'blocks/junk.png',
    //   'characters/blocker.png',
    //   'characters/aggressor.png',
    //   'ui/background.png',
    // ]);

    images.prefix = '';

    // Position grids with spacing
    final leftGridX = screenSize.x * 0.15; // 15% from left
    final rightGridX = screenSize.x * 0.55; // 55% from left
    final gridY = screenSize.y * 0.15; // 15% from top
    // Calculate cell size based on grid dimensions and desired rows/columns
    final cellWidth = gridWidth / 10; // 10 columns
    final cellHeight = gridHeight / 20; // 20 rows
    // Use the smaller dimension to ensure square cells
    final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;
    // Recalculate final grid dimensions to ensure cells are square
    final finalGridWidth = cellSize * 10;
    final finalGridHeight = cellSize * 20;

    playerGrid = Grid(
      position: Vector2(screenSize.x / 2 - gridWidth / 2, screenSize.y * 0.2),
      size: Vector2(gridWidth, gridHeight),
      rows: 20,
      columns: 10,
    );

    opponentGrid = Grid(
      position: Vector2(screenSize.x / 2 - gridWidth / 2, screenSize.y * 0.2),
      size: Vector2(gridWidth, gridHeight),
      rows: 20,
      columns: 10,
    );

    opponentGrid.isVisible = false;

    currentPlayer = Player(
      id: 'player1',
      character: Character(
        name: 'Blocker',
        description: 'Specializes in defense',
        stats: CharacterStats(
          attackMultiplier: 1.0,
          defenseMultiplier: 1.5,
          specialChargeRate: 1.0,
          comboEfficiency: 1.2,
        ),
        abilities: [
          SpecialAbility(
            name: 'Block Conversion',
            description: 'Converts 3 junk blocks to normal blocks',
            cooldown: 10.0,
            meterCost: 25.0,
          ),
          SpecialAbility(
            name: 'Shield Wall',
            description: 'Blocks the next incoming attack',
            cooldown: 15.0,
            meterCost: 40.0,
          ),
        ],
      ),
    );

    opponent = Player(
      id: 'player2',
      character: Character(
        name: 'Aggressor',
        description: 'Specializes in attack',
        stats: CharacterStats(
          attackMultiplier: 1.5,
          defenseMultiplier: 0.8,
          specialChargeRate: 1.2,
          comboEfficiency: 1.0,
        ),
        abilities: [
          SpecialAbility(
            name: 'Double Strike',
            description: 'Next attack sends twice as many junk blocks',
            cooldown: 12.0,
            meterCost: 30.0,
          ),
          SpecialAbility(
            name: 'Grid Scramble',
            description: 'Randomizes the position of 5 blocks in opponent grid',
            cooldown: 20.0,
            meterCost: 50.0,
          ),
        ],
      ),
    );

    // Initialize input controller after grid is created
    inputController = InputController(
      grid: playerGrid,
      onBlockPlaced: spawnNewBlock,
      game: this,
    );

    blockSpawner = BlockSpawner(previewCount: 3);
    scoreManager = ScoreManager(this);
    matchProcessor = MatchProcessor(grid: playerGrid, player: currentPlayer, game: this);

    // Initialize multiplayer if needed
    if (isMultiplayer) {
      gameServer = GameServer();
      await gameServer.connect();
      if (roomId.isNotEmpty) {
        await gameServer.joinRoom(roomId);
      } else {
        await gameServer.createRoom();
      }

      // Listen for multiplayer events
      gameServer.listenForEvents((event) {
        handleMultiplayerEvent(event);
      });
    }

    // Add components to game
    add(playerGrid);
    add(opponentGrid);

    // Game starts in paused state until player selects "Play" from menu
    isPaused = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isPaused || isGameOver || !overlays.isActive('gameOverlay')) {
      return;
    }

    // Update game logic
    currentPlayer.character.abilities.forEach((ability) {
      ability.updateCooldown(dt);
    });

    // Only check for matches when the block has settled
    // Don't check for matches if there's an active block that the player is still controlling
    if (playerGrid.activeBlock == null) {
      // Check for matches
      final matches = matchProcessor.findMatches();
      if (matches.isNotEmpty) {
        matchProcessor.processMatches(matches);

        // Check for attacks to send
        final attackPower = calculateAttackPower(matches.expand((m) => m).toList());
        if (attackPower > 0 && isMultiplayer) {
          gameServer.sendAttack(attackPower);
        }
      }
    }

    // Update block movement
    _updateBlockMovement(dt);

    // Check game over condition only if no active block
    if (playerGrid.activeBlock == null) {
      if (checkGameOver()) {
        isGameOver = true;
        overlays.add('gameOver');
      }
    }
  }

  void spawnNewBlock() {
    print("Spawning new block");
    if (isGameOver || isPaused) {
      print("Cannot spawn block: game is over or paused");
      return;
    }

    // Remove any debugging code that forces J blocks
    // final newBlock = Block(type: BlockType.J, row: 0, column: 4);

    // Use blockSpawner to get the next block from the queue
    final newBlock = blockSpawner.generateNextBlock();

    // Add the new block to the grid
    playerGrid.addBlock(newBlock);
  }

  void _updateBlockMovement(double dt) {
    if (playerGrid.activeBlock == null) return;

    // Get fall speed based on current level and apply multiplier
    _blockFallSpeed = scoreManager.getBlockFallSpeed() * _fallSpeedMultiplier;

    // Update fall timer
    _blockFallTimer += dt;

    // Check if block is at the bottom or resting on another block
    bool isAtRest = _isBlockAtRest();

    // If block is at rest, start lock delay logic
    if (isAtRest) {
      if (!_isInLockDelay) {
        _isInLockDelay = true;
        _lockDelayTimer = 0.0;
      } else {
        _lockDelayTimer += dt;

        // If lock delay expires, lock the block
        if (_lockDelayTimer >= _lockDelayDuration) {
          _lockActiveBlock();
          _isInLockDelay = false;
          return;
        }
      }
    } else {
      // Block is moving, reset lock delay
      _isInLockDelay = false;
    }

    // Time to move block down?
    if (_blockFallTimer >= 1 / _blockFallSpeed) {
      _blockFallTimer = 0;

      // Try to move block down
      int newRow = playerGrid.activeBlock!.row + 1;

      // Check if we can move down
      if (newRow < playerGrid.rows && playerGrid.canPlaceBlockAt(playerGrid.activeBlock!, newRow, playerGrid.activeBlock!.column)) {
        playerGrid.moveBlock(playerGrid.activeBlock!, newRow, playerGrid.activeBlock!.column);
      }
      // Don't lock the block here - let the lock delay handle it
    }
  }

  bool _isBlockAtRest() {
    if (playerGrid.activeBlock == null) return false;

    int newRow = playerGrid.activeBlock!.row + 1;
    int column = playerGrid.activeBlock!.column;

    // Check if block can move down
    return newRow >= playerGrid.rows || !playerGrid.canPlaceBlockAt(playerGrid.activeBlock!, newRow, column);
  }

  int calculateAttackPower(List<game_block.Block> matchedBlocks) {
    // Calculate base power from number of blocks
    int basePower = 0;
    if (matchedBlocks.length == 3) {
      basePower = 1;
    } else if (matchedBlocks.length == 4) {
      basePower = 2;
    } else if (matchedBlocks.length >= 5) {
      basePower = matchedBlocks.length - 2;
    }

    // Apply character's attack multiplier
    return (basePower * currentPlayer.character.stats.attackMultiplier * currentPlayer.comboMultiplier).round();
  }

  void receiveAttack(int attackPower) {
    // Apply character's defense multiplier
    final adjustedPower = (attackPower * (1 / currentPlayer.character.stats.defenseMultiplier)).round();

    // Add junk blocks to player grid
    if (adjustedPower > 0) {
      playerGrid.addJunkBlocks(adjustedPower);
    }
  }

  void applySpecialAbility(SpecialAbility ability) {
    if (!ability.isReady() || currentPlayer.specialMeter < ability.meterCost) {
      return;
    }

    // Apply ability effect
    ability.activate(this);

    // Consume special meter
    currentPlayer.specialMeter -= ability.meterCost;

    // Reset cooldown
    ability.currentCooldown = ability.cooldown;

    // Send ability used event in multiplayer mode
    if (isMultiplayer) {
      gameServer.sendAbilityUsed(ability);
    }
  }

  bool checkGameOver() {
    if (playerGrid.activeBlock != null) {
      return false;
    }
    // Only check if there's an active game
    if (isGameOver) return true;

    // Check if player's grid is full
    bool playerLost = playerGrid.isFull();

    if (playerLost) {
      print("GAME OVER DETECTED: Player grid is full");

      // Debug - print the top row state
      String topRowState = "";
      for (int c = 0; c < playerGrid.columns; c++) {
        topRowState += playerGrid.cells[0][c] != null ? "X" : "O";
      }
      print("Top row state: $topRowState");
    }

    // Check if opponent's grid is full (for AI or multiplayer)
    bool opponentLost = opponentGrid.isFull();

    // Set game over state and winner
    if (playerLost || opponentLost) {
      isGameOver = true;
      isWinner = !playerLost || opponentLost;

      // Add a slight delay before showing game over screen
      Future.delayed(Duration(milliseconds: 500), () {
        overlays.add('gameOver');
      });

      return true;
    }

    return false;
  }

// Also update the handleMultiplayerEvent method to handle game over events
  void handleMultiplayerEvent(Map<String, dynamic> event) {
    final eventType = event['type'] as String;

    switch (eventType) {
      case 'attack':
        final attackPower = event['power'] as int;
        receiveAttack(attackPower);
        break;
      case 'ability_used':
        // Handle opponent using ability
        break;
      case 'game_over':
        isGameOver = true;
        isWinner = event['winner'] == currentPlayer.id;
        overlays.add('gameOver');
        break;
      default:
        // Handle other event types
        break;
    }
  }

// Add these methods to your PuzzleBattleGame class

  void startGame() {
    // Reset game state
    isGameOver = false;
    isPaused = false;

    // Clear grids properly
    playerGrid.reset(); // Create a new reset method
    opponentGrid.reset();

    // Reset game state to ensure a clean start
    isGameOver = false;
    isPaused = false;
    isWinner = false; // Make sure this is reset

    // Set up the initial game state
    scoreManager.currentScore = 0;
    currentPlayer.comboMultiplier = 1;
    currentPlayer.specialMeter = 0.0;

    // Clear grids
    _clearGrid(playerGrid);
    _clearGrid(opponentGrid);

    // Reset abilities cooldowns
    for (var ability in currentPlayer.character.abilities) {
      ability.currentCooldown = 0.0;
    }

    // Add a delay before spawning the first block
    // This ensures all initialization is complete
    Future.delayed(Duration(milliseconds: 500), () {
      // Start the game by spawning the first block
      spawnNewBlock();
    });
  }

  void resetGame() {
    // Store the current score as high score if it's higher
    if (scoreManager.currentScore > scoreManager.highScore) {
      scoreManager.highScore = scoreManager.currentScore;
    }

    // Reset to initial state
    startGame();
  }

  void _clearGrid(Grid grid) {
    for (int r = 0; r < grid.rows; r++) {
      for (int c = 0; c < grid.columns; c++) {
        grid.cells[r][c] = null;
      }
    }
    grid.activeBlock = null;
  }

// Then modify the togglePause method to track the previous overlay
  void togglePause() {
    if (isGameOver) return;

    isPaused = !isPaused;
    if (isPaused) {
      // Store current overlay before showing pause menu
      if (overlays.activeOverlays.isNotEmpty) {
        previousOverlay = overlays.activeOverlays.first;
      } else {
        previousOverlay = 'gameOverlay';
      }
      overlays.add('pauseMenu');
    } else {
      // Remove pause menu
      overlays.remove('pauseMenu');
    }
  }

// Method to handle back button press (useful for mobile)
  bool onBackPressed() {
    if (overlays.isActive('gameOverlay') && !isPaused) {
      togglePause();
      return true; // Handled
    }
    return false; // Not handled, let the system handle it
  }

  // Add these helper methods to manage overlays and track the previous one
  void showOverlay(String overlayName) {
    // Store current active overlay as previous
    if (overlays.activeOverlays.isNotEmpty) {
      previousOverlay = overlays.activeOverlays.first;
    }

    // Remove current overlays and show the new one
    overlays.clear();
    overlays.add(overlayName);
  }

  void returnToPreviousOverlay() {
    overlays.clear();
    overlays.add(previousOverlay);
  }

  // Override input handlers and delegate to InputController
  @override
  void onTapDown(TapDownInfo info) {
    if (isPaused || isGameOver) return;

    // Use the correct property - in newer Flame versions it's just 'game'
    Vector2 gamePosition = info.eventPosition.global; // or info.eventPosition.global

    inputController.handleTap(
      TapDownDetails(globalPosition: info.eventPosition.global.toOffset()),
      gamePosition,
    );
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isPaused || isGameOver) return;

    inputController.handleDrag(
      DragUpdateDetails(
        globalPosition: info.eventPosition.global.toOffset(),
        delta: info.delta.global.toOffset(),
      ),
    );
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (isPaused || isGameOver) return;

    inputController.handleDragEnd(
      DragEndDetails(),
    );
  }

// In your PuzzleBattleGame's _lockActiveBlock method
  void _lockActiveBlock() {
    if (playerGrid.activeBlock != null) {
      playerGrid.activeBlock!.isActive = false;

      // Check for completed lines
      List<int> completedLines = playerGrid.checkCompletedLines();
      if (completedLines.isNotEmpty) {
        print("SCORE DEBUG: Found ${completedLines.length} completed lines");

        // Calculate score based on lines cleared
        int lineScore = getLineScore(completedLines.length);
        int totalScore = lineScore * currentPlayer.comboMultiplier;

        print("SCORE DEBUG: Calculated score = $lineScore × ${currentPlayer.comboMultiplier} = $totalScore");

        // Update scoreManager directly
        scoreManager.addScore(totalScore);
        scoreManager.addLines(completedLines.length);

        // Update player combo
        currentPlayer.increaseCombo();

        // Clear the lines
        playerGrid.clearLines(completedLines);

        print("Updated score: ${scoreManager.currentScore}");
      } else {
        currentPlayer.resetCombo();
      }

      playerGrid.activeBlock = null;
      spawnNewBlock();
    }
  }

  void lockActiveBlock() {
    _lockActiveBlock();
  }

  int getLineScore(int lineCount) {
    switch (lineCount) {
      case 1:
        return 100; // Single
      case 2:
        return 300; // Double
      case 3:
        return 500; // Triple
      case 4:
        return 800; // Tetris
      default:
        return lineCount * 100;
    }
  }

  void setBlockFallSpeedMultiplier(double multiplier) {
    _fallSpeedMultiplier = multiplier;
  }

  void toggleOpponentGridVisibility(bool visible) {
    opponentGrid.isVisible = visible;
  }
}
