import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Data class for a single instruction step.
class InstructionStep {
  final IconData icon;
  final String title;
  final String body;
  const InstructionStep({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// Central registry — one entry per GameType index.
/// Order must match GameType enum: ticTacToe(0), seaBattle(1), chess(2), checkers(3).
class GameInstructions {
  static const Map<int, _GameInfo> _data = {
    0: _GameInfo(
      title: 'TIC TAC TOE',
      accentColor: AppColors.pink,
      icon: Icons.close_rounded,
      objective: 'Be the first to place three of your marks in a horizontal, '
          'vertical, or diagonal row on a 3×3 grid.',
      steps: [
        InstructionStep(
          icon: Icons.sports_esports_rounded,
          title: 'Choose Sides',
          body: 'Player X always goes first. Player O goes second.',
        ),
        InstructionStep(
          icon: Icons.touch_app_rounded,
          title: 'Take Turns',
          body: 'Tap any empty cell to place your mark. '
              'You cannot change a placed mark.',
        ),
        InstructionStep(
          icon: Icons.emoji_events_rounded,
          title: 'Win the Round',
          body: 'Three marks in a row (horizontal, vertical, or diagonal) '
              'wins the round. If the board fills with no winner, it\'s a draw.',
        ),
        InstructionStep(
          icon: Icons.repeat_rounded,
          title: 'Best-of Series',
          body: 'Play a best-of-3, 5, or 7 series. '
              'First to win the majority of rounds wins the match.',
        ),
      ],
    ),
    1: _GameInfo(
      title: 'SEA BATTLE',
      accentColor: AppColors.cyan,
      icon: Icons.directions_boat_rounded,
      objective: 'Sink all of your opponent\'s ships before they sink yours '
          'on a 10×10 grid.',
      steps: [
        InstructionStep(
          icon: Icons.anchor_rounded,
          title: 'Place Your Fleet',
          body: 'Drag or tap to place ships of sizes 4, 3, 3, 2, 2, 2, 1, 1, 1, 1. '
              'Ships cannot overlap or touch diagonally.',
        ),
        InstructionStep(
          icon: Icons.my_location_rounded,
          title: 'Fire!',
          body: 'Tap any cell on the enemy grid to fire. '
              'A hit is marked in red; a miss in white.',
        ),
        InstructionStep(
          icon: Icons.local_fire_department_rounded,
          title: 'Sink Ships',
          body: 'Hit every cell of a ship to sink it. '
              'The game announces when a ship is fully sunk.',
        ),
        InstructionStep(
          icon: Icons.emoji_events_rounded,
          title: 'Win',
          body: 'The first player to sink all 10 enemy ships wins.',
        ),
      ],
    ),
    2: _GameInfo(
      title: 'CHESS PRO',
      accentColor: AppColors.amber,
      icon: Icons.castle_rounded,
      objective: 'Checkmate your opponent\'s King — put it under attack '
          'with no legal escape.',
      steps: [
        InstructionStep(
          icon: Icons.people_rounded,
          title: 'White Goes First',
          body: 'White pieces always open the game. '
              'Players alternate turns, one piece per turn.',
        ),
        InstructionStep(
          icon: Icons.grid_on_rounded,
          title: 'Piece Movement',
          body: 'King: 1 square any direction. Queen: any distance any direction. '
              'Rook: horizontal/vertical. Bishop: diagonal. '
              'Knight: L-shape (can jump). Pawn: forward 1 (or 2 from start), '
              'captures diagonally.',
        ),
        InstructionStep(
          icon: Icons.warning_amber_rounded,
          title: 'Check & Checkmate',
          body: 'If your King is threatened it is "in check" — you MUST resolve it. '
              'If there is no legal move out of check, that is checkmate and the game ends.',
        ),
        InstructionStep(
          icon: Icons.handshake_rounded,
          title: 'Draw Conditions',
          body: 'The game is a draw on stalemate (no legal moves, not in check), '
              'insufficient material, or threefold repetition.',
        ),
      ],
    ),
    3: _GameInfo(
      title: 'CHECKERS',
      accentColor: AppColors.green,
      icon: Icons.grid_view_rounded,
      objective: 'Capture all of your opponent\'s pieces or leave them with '
          'no legal moves.',
      steps: [
        InstructionStep(
          icon: Icons.swap_horiz_rounded,
          title: 'Movement',
          body: 'Pieces move diagonally forward one square to an empty cell. '
              'Only Kings may move backward.',
        ),
        InstructionStep(
          icon: Icons.bolt_rounded,
          title: 'Capturing',
          body: 'Jump over an adjacent enemy piece into the empty square beyond it '
              'to capture it. Multiple jumps in one turn are allowed and mandatory '
              'if available.',
        ),
        InstructionStep(
          icon: Icons.stars_rounded,
          title: 'Becoming a King',
          body: 'Reach the opponent\'s back row to promote your piece to a King. '
              'Kings can move and capture in all four diagonal directions.',
        ),
        InstructionStep(
          icon: Icons.emoji_events_rounded,
          title: 'Win',
          body: 'Capture all 12 enemy pieces or block every legal move '
              'your opponent could make.',
        ),
      ],
    ),
  };

  static _GameInfo? forGameIndex(int gameIndex) => _data[gameIndex];
}

class _GameInfo {
  final String title;
  final Color accentColor;
  final IconData icon;
  final String objective;
  final List<InstructionStep> steps;
  const _GameInfo({
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.objective,
    required this.steps,
  });
}

/// Call this from any launch dialog to show the instructions sheet.
void showHowToPlay(BuildContext context, int gameIndex) {
  final info = GameInstructions.forGameIndex(gameIndex);
  if (info == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HowToPlaySheet(info: info),
  );
}

class _HowToPlaySheet extends StatelessWidget {
  final _GameInfo info;
  const _HowToPlaySheet({required this.info});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.92),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: info.accentColor.withValues(alpha: 0.4)),
              ),
              child: ListView(
                controller: controller,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.glassBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Game icon + title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(info.icon,
                          color: info.accentColor,
                          size: 28,
                          shadows: [
                            Shadow(
                                color: info.accentColor.withValues(alpha: 0.6),
                                blurRadius: 12)
                          ]),
                      const SizedBox(width: 12),
                      Text(
                        'HOW TO PLAY',
                        style: TextStyle(
                          color: info.accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                                color: info.accentColor, blurRadius: 10)
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    info.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 3),
                  ),
                  const SizedBox(height: 20),

                  // Objective banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: info.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: info.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OBJECTIVE',
                          style: TextStyle(
                              color: info.accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          info.objective,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Steps
                  ...info.steps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step number + icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  info.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: info.accentColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(step.icon,
                                    color: info.accentColor, size: 20),
                                Positioned(
                                  top: 3,
                                  right: 5,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                        color: info.accentColor
                                            .withValues(alpha: 0.5),
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                      color: info.accentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step.body,
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.glassBase,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'GOT IT',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}