class GameScore {
  final int? id;
  final String playerName;
  final int gameId;
  final int wins;
  final int losses;
  final int draws;
  final int totalPoints;

  GameScore({
    this.id,
    required this.playerName,
    required this.gameId,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.totalPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerName': playerName,
      'gameId': gameId,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'totalPoints': totalPoints,
    };
  }

  factory GameScore.fromMap(Map<String, dynamic> map) {
    return GameScore(
      id: map['id'] as int?,
      playerName: map['playerName'] as String,
      gameId: map['gameId'] as int,
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
      draws: map['draws'] as int? ?? 0,
      totalPoints: map['totalPoints'] as int? ?? 0,
    );
  }

  GameScore copyWith({
    int? id,
    String? playerName,
    int? gameId,
    int? wins,
    int? losses,
    int? draws,
    int? totalPoints,
  }) {
    return GameScore(
      id: id ?? this.id,
      playerName: playerName ?? this.playerName,
      gameId: gameId ?? this.gameId,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}