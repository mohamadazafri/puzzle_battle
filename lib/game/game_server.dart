import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'special_ability.dart';

class GameServer {
  WebSocketChannel? _channel;
  String serverUrl = 'wss://your-game-server.com/ws';
  String roomId = '';
  GameState currentState = GameState();

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      // Listen for server messages
      _channel?.stream.listen(
        (message) {
          final data = jsonDecode(message);
          currentState = GameState.fromJson(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Failed to connect to server: $e');
      rethrow;
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }

  Future<void> joinRoom(String id) async {
    if (_channel == null) {
      await connect();
    }

    roomId = id;
    _sendMessage({
      'action': 'join_room',
      'room_id': roomId,
    });
  }

  Future<void> createRoom() async {
    if (_channel == null) {
      await connect();
    }

    _sendMessage({
      'action': 'create_room',
    });
  }

  void startGame() {
    _sendMessage({
      'action': 'start_game',
      'room_id': roomId,
    });
  }

  void sendAttack(int attackPower) {
    _sendMessage({
      'action': 'attack',
      'room_id': roomId,
      'power': attackPower,
    });
  }

  void sendBlockMovement(dynamic block) {
    _sendMessage({
      'action': 'block_movement',
      'room_id': roomId,
      'block': {
        'row': block.row,
        'column': block.column,
      },
    });
  }

  void sendAbilityUsed(SpecialAbility ability) {
    _sendMessage({
      'action': 'ability_used',
      'room_id': roomId,
      'ability': {
        'name': ability.name,
      },
    });
  }

  void listenForEvents(Function(Map<String, dynamic>) callback) {
    _channel?.stream.listen((message) {
      callback(jsonDecode(message));
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel?.sink.add(jsonEncode(message));
    }
  }
}

class GameState {
  String gameId = '';
  Map<String, dynamic> players = {};
  GameStatus status = GameStatus.waiting;
  int currentRound = 0;
  Map<String, int> scores = {};

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'players': players,
      'status': status.index,
      'current_round': currentRound,
      'scores': scores,
    };
  }

  static GameState fromJson(Map<String, dynamic> json) {
    final state = GameState();
    state.gameId = json['game_id'] ?? '';
    state.players = json['players'] ?? {};
    state.status = GameStatus.values[json['status'] ?? 0];
    state.currentRound = json['current_round'] ?? 0;
    state.scores = Map<String, int>.from(json['scores'] ?? {});
    return state;
  }
}

enum GameStatus {
  waiting,
  ready,
  playing,
  paused,
  finished,
}
