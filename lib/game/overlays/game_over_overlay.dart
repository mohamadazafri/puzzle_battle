import 'package:flutter/material.dart';
import 'dart:ui';

class GameOverOverlay extends StatelessWidget {
  final int finalScore;
  final bool isWinner;
  final int? highScore;
  final Function onPlayAgain;
  final Function onMainMenu;
  final Function? onShare;

  const GameOverOverlay({
    required this.finalScore,
    required this.isWinner,
    this.highScore,
    required this.onPlayAgain,
    required this.onMainMenu,
    this.onShare,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game over title
                Text(
                  isWinner ? 'VICTORY!' : 'GAME OVER',
                  style: TextStyle(
                    color: isWinner ? Colors.green.shade400 : Colors.red.shade400,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: (isWinner ? Colors.green : Colors.red).withOpacity(0.5),
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Score display
                _buildScoreCard(),
                SizedBox(height: 50),
                // Action buttons
                _buildMenuButton('PLAY AGAIN', Icons.replay, onPlayAgain),
                SizedBox(height: 16),
                if (onShare != null) _buildMenuButton('SHARE SCORE', Icons.share, onShare!),
                if (onShare != null) SizedBox(height: 16),
                _buildMenuButton('MAIN MENU', Icons.home, onMainMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final isNewHighScore = highScore != null && finalScore > highScore!;

    return Container(
      width: 300,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'YOUR SCORE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            finalScore.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isNewHighScore) ...[
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Text(
                'NEW HIGH SCORE!',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else if (highScore != null) ...[
            SizedBox(height: 15),
            Text(
              'HIGH SCORE: $highScore',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuButton(String text, IconData icon, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: 240,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
