import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rama_app/models/game.dart';
import 'package:rama_app/models/game_score.dart';
import 'package:rama_app/services/database_service.dart';
import 'package:rama_app/core/app_theme.dart';

abstract class BaseGameWidget extends StatefulWidget {
  final String p1;
  final String p2;
  final GameType gameType;

  const BaseGameWidget({
    super.key,
    required this.p1,
    required this.p2,
    required this.gameType,
  });
}

abstract class BaseGameState<T extends BaseGameWidget> extends State<T> {
  final DatabaseService db = DatabaseService();

  Color get p1Color => AppColors.cyan;
  Color get p2Color => AppColors.pink;
  Color get bgColor => AppColors.bg;
  Color get glassBase => AppColors.glassBase;
  Color get glassBorder => AppColors.glassBorder;

  int p1Wins = 0;
  int p2Wins = 0;
  int draws = 0;

  int _prevP1Wins = 0;
  int _prevP2Wins = 0;
  int _prevDraws = 0;

  Future<void> _saveGameResult(String winner,
      {bool isDraw = false, int p1Score = 0, int p2Score = 0}) async {
    try {
      final game = Game(
        type: widget.gameType,
        player1Name: widget.p1,
        player2Name: widget.p2,
        winner: isDraw ? null : winner,
        isDraw: isDraw,
        player1Score: p1Score,
        player2Score: p2Score,
      );
      await db.saveGame(game);
      await db.updateOrCreatePlayer(widget.p1);
      await db.updateOrCreatePlayer(widget.p2);

      await db.saveGameScore(GameScore(
        playerName: widget.p1,
        gameId: widget.gameType.index,
        wins: p1Score > p2Score ? 1 : 0,
        losses: p1Score < p2Score ? 1 : 0,
        draws: isDraw ? 1 : 0,
        totalPoints: isDraw ? 1 : (p1Score > p2Score ? 3 : 0),
      ));

      await db.saveGameScore(GameScore(
        playerName: widget.p2,
        gameId: widget.gameType.index,
        wins: p2Score > p1Score ? 1 : 0,
        losses: p2Score < p1Score ? 1 : 0,
        draws: isDraw ? 1 : 0,
        totalPoints: isDraw ? 1 : (p2Score > p1Score ? 3 : 0),
      ));
    } catch (e) {
      debugPrint('Database error: $e');
    }
  }

  Future<void> saveP1Win({int p1Score = 1, int p2Score = 0}) async {
    HapticFeedback.mediumImpact();
    _prevP1Wins = p1Wins;
    p1Wins++;
    await _saveGameResult(widget.p1, p1Score: p1Score, p2Score: p2Score);
  }

  Future<void> saveP2Win({int p1Score = 0, int p2Score = 1}) async {
    HapticFeedback.mediumImpact();
    _prevP2Wins = p2Wins;
    p2Wins++;
    await _saveGameResult(widget.p2, p1Score: p1Score, p2Score: p2Score);
  }

  Future<void> saveDraw() async {
    HapticFeedback.lightImpact();
    _prevDraws = draws;
    draws++;
    await _saveGameResult('', isDraw: true);
  }

  Widget buildScoreDashboard() {
    Widget dashboard = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: glassBase,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _scoreStat(widget.p1, p1Wins, p1Color, _prevP1Wins != p1Wins),
                _scoreStat('DRAWS', draws, Colors.white38, _prevDraws != draws),
                _scoreStat(widget.p2, p2Wins, p2Color, _prevP2Wins != p2Wins),
              ],
            ),
          ),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _prevP1Wins = p1Wins;
          _prevP2Wins = p2Wins;
          _prevDraws = draws;
        });
      }
    });

    return dashboard;
  }

  Widget _scoreStat(String label, int val, Color color, bool animating) {
    String displayLabel =
        label.length > 8 ? '${label.substring(0, 8)}..' : label;
    Widget textWidget = Text(
      '$val',
      style: TextStyle(
        color: color,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        shadows: [if (val > 0) Shadow(color: color, blurRadius: 10)],
      ),
    );

    if (animating) {
      textWidget = textWidget.animate().scale(
            begin: const Offset(1.2, 1.2),
            end: const Offset(1, 1),
            duration: 400.ms,
            curve: Curves.elasticOut,
          );
    }

    return Column(
      children: [
        Text(displayLabel,
            style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        textWidget,
      ],
    );
  }

  void showResultDialog({
    required String title,
    required String message,
    required Color color,
    bool isDraw = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: bgColor.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: color),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [Shadow(color: color, blurRadius: 10)],
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          actions: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onRematch();
                    },
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color),
                      ),
                      child: Center(
                        child: Text(
                          "REMATCH",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "EXIT",
                      style: TextStyle(
                          color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onRematch() {
    // Override in child classes to handle rematch
  }
}
