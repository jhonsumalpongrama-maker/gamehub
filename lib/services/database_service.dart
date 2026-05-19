import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';
import '../models/game_score.dart';

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  
  @override
  String toString() => message;
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static const int _dbVersion = 2;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gamehub.db');
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        totalGames INTEGER DEFAULT 0,
        wins INTEGER DEFAULT 0,
        draws INTEGER DEFAULT 0,
        losses INTEGER DEFAULT 0,
        totalScore INTEGER DEFAULT 0
      )
    ''');

    for (var gameType in GameType.values) {
      await db.execute('''
        CREATE TABLE ${gameType.tableName} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type INTEGER,
          player1Name TEXT NOT NULL,
          player2Name TEXT NOT NULL,
          winner TEXT,
          isDraw INTEGER DEFAULT 0,
          playedAt TEXT NOT NULL,
          player1Score INTEGER DEFAULT 0,
          player2Score INTEGER DEFAULT 0,
          rounds INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE ${gameType.tableName}_scores (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playerName TEXT NOT NULL,
          gameId INTEGER,
          wins INTEGER DEFAULT 0,
          losses INTEGER DEFAULT 0,
          draws INTEGER DEFAULT 0,
          totalPoints INTEGER DEFAULT 0
        )
      ''');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (var gameType in GameType.values) {
        try {
          await db.execute('''
            ALTER TABLE ${gameType.tableName} ADD COLUMN type INTEGER
          ''');
        } catch (_) {}
      }
    }
  }

  Future<int> saveGame(Game game) async {
    try {
      final db = await database;
      int id = await db.insert(game.type.tableName, game.toMap());
      return id;
    } catch (e) {
      throw DatabaseException('Failed to save game: $e');
    }
  }

  Future<void> saveGameScore(GameScore score) async {
    try {
      final db = await database;
      final tableName = GameType.values[score.gameId].tableName;
      await db.insert('${tableName}_scores', score.toMap());
    } catch (e) {
      throw DatabaseException('Failed to save game score: $e');
    }
  }

  Future<List<Game>> getGamesByType(GameType type, {int limit = 50}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        type.tableName,
        orderBy: 'playedAt DESC',
        limit: limit,
      );
      return maps.map((m) => Game.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get games: $e');
    }
  }

  Future<List<GameScore>> getTopScores(GameType type, {int limit = 10}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT playerName, 
               SUM(wins) as wins,
               SUM(losses) as losses,
               SUM(draws) as draws,
               SUM(totalPoints) as totalPoints
        FROM ${type.tableName}_scores
        GROUP BY playerName
        ORDER BY totalPoints DESC
        LIMIT ?
      ''', [limit]);
      return maps.map((m) => GameScore(
        playerName: m['playerName'] as String,
        gameId: type.index,
        wins: m['wins'] as int? ?? 0,
        losses: m['losses'] as int? ?? 0,
        draws: m['draws'] as int? ?? 0,
        totalPoints: m['totalPoints'] as int? ?? 0,
      )).toList();
    } catch (e) {
      throw DatabaseException('Failed to get top scores: $e');
    }
  }

  Future<Map<String, int>> getPlayerStats(String playerName) async {
    try {
      final db = await database;
      Map<String, int> stats = {'wins': 0, 'draws': 0, 'losses': 0, 'totalGames': 0};
      
      for (var gameType in GameType.values) {
        final result = await db.rawQuery('''
          SELECT SUM(wins) as w, SUM(draws) as d, SUM(losses) as l
          FROM ${gameType.tableName}_scores
          WHERE playerName = ?
        ''', [playerName]);
        
        if (result.isNotEmpty) {
          stats['wins'] = (stats['wins'] ?? 0) + (result.first['w'] as int? ?? 0);
          stats['draws'] = (stats['draws'] ?? 0) + (result.first['d'] as int? ?? 0);
          stats['losses'] = (stats['losses'] ?? 0) + (result.first['l'] as int? ?? 0);
        }
      }
      
      stats['totalGames'] = stats['wins']! + stats['draws']! + stats['losses']!;
      return stats;
    } catch (e) {
      throw DatabaseException('Failed to get player stats: $e');
    }
  }

  Future<void> updateOrCreatePlayer(String name) async {
    try {
      final db = await database;
      await db.insert('players', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
      
      final statsResult = await db.rawQuery('''
        SELECT 
          SUM(wins) as totalWins,
          SUM(draws) as totalDraws,
          SUM(losses) as totalLosses,
          SUM(totalPoints) as totalScore
        FROM (
          SELECT wins, draws, losses, totalPoints FROM ticTacToe_scores WHERE playerName = ?
          UNION ALL
          SELECT wins, draws, losses, totalPoints FROM seaBattle_scores WHERE playerName = ?
          UNION ALL
          SELECT wins, draws, losses, totalPoints FROM chess_scores WHERE playerName = ?
          UNION ALL
          SELECT wins, draws, losses, totalPoints FROM checkers_scores WHERE playerName = ?
        )
      ''', [name, name, name, name]);
      
      if (statsResult.isNotEmpty) {
        final stats = statsResult.first;
        await db.update(
          'players',
          {
            'wins': stats['totalWins'] as int? ?? 0,
            'draws': stats['totalDraws'] as int? ?? 0,
            'losses': stats['totalLosses'] as int? ?? 0,
            'totalScore': stats['totalScore'] as int? ?? 0,
            'totalGames': ((stats['totalWins'] as int? ?? 0) + (stats['totalDraws'] as int? ?? 0) + (stats['totalLosses'] as int? ?? 0)),
          },
          where: 'name = ?',
          whereArgs: [name],
        );
      }
    } catch (e) {
      throw DatabaseException('Failed to update player: $e');
    }
  }

  Future<void> deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'gamehub.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
    } catch (e) {
      throw DatabaseException('Failed to delete database: $e');
    }
  }

  Future<void> resetAllData() async {
    try {
      final db = await database;
      for (var gameType in GameType.values) {
        await db.delete(gameType.tableName);
        await db.delete('${gameType.tableName}_scores');
      }
      await db.delete('players');
      _database = null;
    } catch (e) {
      throw DatabaseException('Failed to reset data: $e');
    }
  }
}