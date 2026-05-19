class Player {
  final int? id;
  final String name;
  final int totalGames;
  final int wins;
  final int draws;
  final int losses;
  final int totalScore;

  Player({
    this.id,
    required this.name,
    this.totalGames = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.totalScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalGames': totalGames,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'totalScore': totalScore,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int?,
      name: map['name'] as String,
      totalGames: map['totalGames'] as int? ?? 0,
      wins: map['wins'] as int? ?? 0,
      draws: map['draws'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
      totalScore: map['totalScore'] as int? ?? 0,
    );
  }

  Player copyWith({
    int? id,
    String? name,
    int? totalGames,
    int? wins,
    int? draws,
    int? losses,
    int? totalScore,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}