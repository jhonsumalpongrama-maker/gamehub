import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_widgets.dart';
import '../models/game.dart';
import '../models/game_score.dart';
import '../services/database_service.dart';

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const NeonText(text: "SCORES", color: Colors.white, fontSize: 18),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: Colors.white54,
          dividerColor: Colors.transparent,
          tabs: GameType.values.map((t) => Tab(text: t.displayName.toUpperCase())).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: GameType.values.map((type) => _buildScoreList(type)).toList(),
      ),
    );
  }

  Widget _buildScoreList(GameType type) {
    return FutureBuilder<List<GameScore>>(
      future: _db.getTopScores(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 60),
                SizedBox(height: 16),
                Text('No scores yet', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }
        final scores = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final score = scores[index];
            final isTop3 = index < 3;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.glassBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTop3 ? _getMedalColor(index) : AppColors.glassBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isTop3 ? _getMedalColor(index) : Colors.transparent,
                      border: Border.all(color: isTop3 ? _getMedalColor(index) : Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${index + 1}', style: TextStyle(color: isTop3 ? Colors.black : Colors.white24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(score.playerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('${score.wins}W - ${score.losses}L - ${score.draws}D', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                    ),
                    child: Text('${score.totalPoints} pts', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getMedalColor(int index) {
    const badges = [AppColors.medalGold, AppColors.medalSilver, AppColors.medalBronze];
    return index < badges.length ? badges[index] : Colors.transparent;
  }
}