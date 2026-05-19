enum GameType {
  ticTacToe,
  seaBattle,
  chess,
  checkers,
}

extension GameTypeExtension on GameType {
  String get displayName {
    switch (this) {
      case GameType.ticTacToe:
        return 'Tic Tac Toe';
      case GameType.seaBattle:
        return 'Sea Battle';
      case GameType.chess:
        return 'Chess';
      case GameType.checkers:
        return 'Checkers';
    }
  }

  String get tableName {
    switch (this) {
      case GameType.ticTacToe:
        return 'ticTacToe_scores';
      case GameType.seaBattle:
        return 'seaBattle_scores';
      case GameType.chess:
        return 'chess_scores';
      case GameType.checkers:
        return 'checkers_scores';
    }
  }

  int get winPoints => 3;
  int get drawPoints => 1;
  int get lossPoints => 0;
}

class Game {
  final int? id;
  final GameType type;
  final String player1Name;
  final String player2Name;
  final String? winner;
  final bool isDraw;
  final DateTime playedAt;
  final int player1Score;
  final int player2Score;
  final int rounds;

  Game({
    this.id,
    required this.type,
    required this.player1Name,
    required this.player2Name,
    this.winner,
    this.isDraw = false,
    DateTime? playedAt,
    this.player1Score = 0,
    this.player2Score = 0,
    this.rounds = 0,
  }) : playedAt = playedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'winner': winner,
      'isDraw': isDraw ? 1 : 0,
      'playedAt': playedAt.toIso8601String(),
      'player1Score': player1Score,
      'player2Score': player2Score,
      'rounds': rounds,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      type: GameType.values[map['type'] as int],
      player1Name: map['player1Name'] as String,
      player2Name: map['player2Name'] as String,
      winner: map['winner'] as String?,
      isDraw: (map['isDraw'] as int) == 1,
      playedAt: DateTime.parse(map['playedAt'] as String),
      player1Score: map['player1Score'] as int? ?? 0,
      player2Score: map['player2Score'] as int? ?? 0,
      rounds: map['rounds'] as int? ?? 0,
    );
  }
}