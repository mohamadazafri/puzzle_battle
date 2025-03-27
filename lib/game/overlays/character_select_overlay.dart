import 'package:flutter/material.dart';
import '../player.dart';

class CharacterSelectOverlay extends StatefulWidget {
  final List<Character> availableCharacters;
  final Function(Character) onCharacterSelected;
  final Function onBack;

  const CharacterSelectOverlay({
    required this.availableCharacters,
    required this.onCharacterSelected,
    required this.onBack,
    Key? key,
  }) : super(key: key);

  @override
  _CharacterSelectOverlayState createState() => _CharacterSelectOverlayState();
}

class _CharacterSelectOverlayState extends State<CharacterSelectOverlay> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentCharacter = widget.availableCharacters[selectedIndex];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.withOpacity(0.8),
            Colors.purple.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => widget.onBack(),
                  ),
                  Expanded(
                    child: Text(
                      'SELECT CHARACTER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  SizedBox(width: 48), // Balance for the back button
                ],
              ),
            ),

            // Character selection carousel
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.availableCharacters.length,
                itemBuilder: (context, index) => _buildCharacterCard(index),
              ),
            ),

            // Character details
            Expanded(
              child: Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentCharacter.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      currentCharacter.description,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildStatBars(currentCharacter),
                    SizedBox(height: 20),
                    Text(
                      'ABILITIES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: currentCharacter.abilities.length,
                        itemBuilder: (context, index) => _buildAbilityCard(
                          currentCharacter.abilities[index],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Select button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GestureDetector(
                onTap: () => widget.onCharacterSelected(currentCharacter),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'SELECT CHARACTER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(int index) {
    final character = widget.availableCharacters[index];
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        width: 120,
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Character icon placeholder
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _getCharacterColor(character.name),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCharacterIcon(character.name),
                color: Colors.white,
                size: 40,
              ),
            ),
            SizedBox(height: 10),
            Text(
              character.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBars(Character character) {
    return Column(
      children: [
        _buildStatBar('Attack', character.stats.attackMultiplier / 2),
        SizedBox(height: 8),
        _buildStatBar('Defense', character.stats.defenseMultiplier / 2),
        SizedBox(height: 8),
        _buildStatBar('Special Rate', character.stats.specialChargeRate / 2),
        SizedBox(height: 8),
        _buildStatBar('Combo', character.stats.comboEfficiency / 2),
      ],
    );
  }

  Widget _buildStatBar(String label, double value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbilityCard(dynamic ability) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getAbilityIcon(ability.name),
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ability.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  ability.description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${ability.meterCost.toInt()}%',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${ability.cooldown}s',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCharacterColor(String characterName) {
    switch (characterName) {
      case 'Blocker':
        return Colors.blue;
      case 'Aggressor':
        return Colors.red;
      case 'Tactician':
        return Colors.green;
      case 'Trickster':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCharacterIcon(String characterName) {
    switch (characterName) {
      case 'Blocker':
        return Icons.shield;
      case 'Aggressor':
        return Icons.flash_on;
      case 'Tactician':
        return Icons.psychology;
      case 'Trickster':
        return Icons.auto_fix_high;
      default:
        return Icons.person;
    }
  }

  IconData _getAbilityIcon(String abilityName) {
    switch (abilityName) {
      case 'Block Conversion':
        return Icons.autorenew;
      case 'Shield Wall':
        return Icons.shield;
      case 'Double Strike':
        return Icons.flash_on;
      case 'Grid Scramble':
        return Icons.shuffle;
      default:
        return Icons.star;
    }
  }
}
