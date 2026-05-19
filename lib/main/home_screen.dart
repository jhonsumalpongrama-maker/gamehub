import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_theme.dart';
import '../core/app_widgets.dart';
import '../core/page_transitions.dart';
import '../screens/scores_screen.dart';
import '../screens/rankings_screen.dart';
import '../games/tic_tac_toe.dart';
import '../games/sea_battle.dart';
import '../games/chess_game.dart';
import '../games/checkers.dart' as games_checkers;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: _buildNeonDrawer(),
      body: Stack(
        children: [
          const BackgroundGlows(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 30),
                Expanded(child: _buildGameGrid()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const NeonText(text: "GAME HUB", color: Colors.white, fontSize: 32),
        const SizedBox(height: 12),
        const GlassCard(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text("SELECT MISSION",
              style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 3)),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Builder(
              builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white70),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  )),
          const Spacer(),
          const Text("OS v1.0",
              style: TextStyle(color: Colors.white24, fontSize: 10)),
          const Spacer(),
          IconButton(
            icon:
                const Icon(Icons.emoji_events_outlined, color: Colors.white70),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                  context, slideUpRoute(page: const RankingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _gameCard(0, "SEA BATTLE", Icons.directions_boat_rounded,
            AppColors.cyan, () => showSeaBattleDialog(context)),
        _gameCard(1, "TIC TAC TOE", Icons.close_rounded, AppColors.pink,
            () => showTicTacToeDialog(context)),
        _gameCard(2, "CHESS PRO", Icons.castle_rounded, AppColors.amber,
            () => showChessDialog(context)),
        _gameCard(3, "CHECKERS", Icons.grid_view_rounded, AppColors.green,
            () => games_checkers.showCheckersDialog(context)),
      ],
    );
  }

  Widget _gameCard(
      int index, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassBase,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color, shadows: [
                  Shadow(color: color.withValues(alpha: 0.5), blurRadius: 15)
                ]),
                const SizedBox(height: 15),
                Text(title, style: AppTextStyles.cardTitle),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 80 * index),
          duration: 400.ms,
        )
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          delay: Duration(milliseconds: 80 * index),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildNeonDrawer() {
    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              child: const Column(
                children: [
                  NeonText(text: "GAME HUB", color: Colors.white, fontSize: 24),
                  SizedBox(height: 8),
                  Text("v1.0.0",
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Divider(color: AppColors.glassBorder),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: AppColors.cyan),
              title:
                  const Text("SCORES", style: TextStyle(color: Colors.white)),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.push(
                    context, slideUpRoute(page: const ScoresScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard, color: AppColors.pink),
              title:
                  const Text("RANKINGS", style: TextStyle(color: Colors.white)),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.push(
                    context, slideUpRoute(page: const RankingsScreen()));
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("SYSTEM ACTIVE",
                  style: TextStyle(color: Colors.white24, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }
}
