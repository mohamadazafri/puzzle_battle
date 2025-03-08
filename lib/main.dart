import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/puzzle_battle_game.dart';

void main() {
  runApp(PuzzleBattleApp());
}

class PuzzleBattleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzle Battle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PuzzleBattleGameScreen(),
    );
  }
}

class PuzzleBattleGameScreen extends StatefulWidget {
  @override
  _PuzzleBattleGameScreenState createState() => _PuzzleBattleGameScreenState();
}

class _PuzzleBattleGameScreenState extends State<PuzzleBattleGameScreen> {
  late PuzzleBattleGame game;

  @override
  void initState() {
    super.initState();
    game = PuzzleBattleGame();

    // Initialize the overlayManager immediately to ensure it's not null
    game.initializeOverlayManager();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        return !game.onBackPressed();
      },
      child: Scaffold(
        body: GameWidget(
          game: game,
          initialActiveOverlays: const ['mainMenu'],
          // Use null-safe access with the non-null assertion operator
          overlayBuilderMap: game.overlayManager!.getOverlayBuilderMap(),
        ),
      ),
    );
  }
}
