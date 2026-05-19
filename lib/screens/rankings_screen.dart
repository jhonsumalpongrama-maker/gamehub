import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_widgets.dart';
import '../models/game.dart';
import '../models/game_score.dart';
import '../services/database_service.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const NeonText(text: "RANKINGS", color: Colors.white, fontSize: 18),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search player...',
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildRankingsList()),
        ],
      ),
    );
  }

  Widget _buildRankingsList() {
    return FutureBuilder<List<GameScore>>(
      future: _getCombinedRankings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }
        List<GameScore> rankings = snapshot.data!;

        if (_searchQuery.isNotEmpty) {
          rankings = rankings.where((p) => p.playerName.toLowerCase().contains(_searchQuery)).toList();
        }

        if (rankings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.leaderboard_outlined, color: Colors.white24, size: 60),
                const SizedBox(height: 16),
                Text(_searchQuery.isEmpty ? 'No rankings yet' : 'No results found', style: const TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            final player = rankings[index];
            final isTop3 = index < 3;
            final rankBadge = isTop3 ? _getRankBadge(index) : null;
            int totalGames = player.wins + player.losses + player.draws;
            double winRate = totalGames > 0 ? (player.wins / totalGames * 100) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isTop3
                      ? [AppColors.cyan.withValues(alpha: 0.1), AppColors.pink.withValues(alpha: 0.1)]
                      : [AppColors.glassBase.withValues(alpha: 0.3), AppColors.glassBase.withValues(alpha: 0.2)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isTop3 ? (rankBadge ?? AppColors.cyan) : AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isTop3 ? (rankBadge ?? AppColors.cyan).withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isTop3 ? (rankBadge ?? AppColors.cyan) : Colors.white24),
                    ),
                    child: Center(
                      child: Text('#${index + 1}', style: TextStyle(color: isTop3 ? rankBadge ?? AppColors.cyan : Colors.white54, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.playerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _statChip('W', player.wins, AppColors.cyan),
                            const SizedBox(width: 8),
                            _statChip('D', player.draws, Colors.white54),
                            const SizedBox(width: 8),
                            _statChip('L', player.losses, AppColors.pink),
                            const SizedBox(width: 12),
                            _winRateBadge(winRate),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('${player.totalPoints}', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 24)),
                      const Text('PTS', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _winRateBadge(double winRate) {
    Color badgeColor;
    if (winRate >= 60) {
      badgeColor = AppColors.green;
    } else if (winRate >= 40) {
      badgeColor = AppColors.amber;
    } else {
      badgeColor = AppColors.pink;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text('${winRate.toStringAsFixed(0)}%', style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
      child: Text('$label:$value', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color? _getRankBadge(int index) {
    final badges = [AppColors.medalGold, AppColors.medalSilver, AppColors.medalBronze];
    return index < badges.length ? badges[index] : null;
  }

  Future<List<GameScore>> _getCombinedRankings() async {
    List<List<GameScore>> allScores = await Future.wait([
      _db.getTopScores(GameType.ticTacToe, limit: 20),
      _db.getTopScores(GameType.seaBattle, limit: 20),
      _db.getTopScores(GameType.chess, limit: 20),
      _db.getTopScores(GameType.checkers, limit: 20),
    ]);

    Map<String, GameScore> combined = {};

    for (List<GameScore> scores in allScores) {
      for (var score in scores) {
        if (combined.containsKey(score.playerName)) {
          final existing = combined[score.playerName]!;
          combined[score.playerName] = existing.copyWith(
            wins: existing.wins + score.wins,
            losses: existing.losses + score.losses,
            draws: existing.draws + score.draws,
            totalPoints: existing.totalPoints + score.totalPoints,
          );
        } else {
          combined[score.playerName] = score;
        }
      }
    }

    final list = combined.values.toList();
    list.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return list;
  }
}