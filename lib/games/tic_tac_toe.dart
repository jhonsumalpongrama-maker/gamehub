import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_theme.dart';
import '../core/app_widgets.dart';
import '../core/page_transitions.dart';
import '../core/game_instructions.dart';
import '../models/base_game.dart';
import '../models/game.dart';

class TicTacToeScreen extends BaseGameWidget {
  const TicTacToeScreen({super.key, required super.p1, required super.p2})
      : super(gameType: GameType.ticTacToe);

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends BaseGameState<TicTacToeScreen> {
  late List<List<String>> _board;
  String _current = "X";
  bool _gameOver = false;
  int get _requiredWins => 2;
  List<List<int>> _winningCells = [];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _board = List.generate(3, (_) => List.generate(3, (_) => ""));
      _current = "X";
      _gameOver = false;
      _winningCells = [];
    });
  }

  void _handleTap(int r, int c) {
    if (_board[r][c] != "" || _gameOver) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _board[r][c] = _current;
      if (_checkWinner(r, c)) {
        _gameOver = true;
        _saveRoundResult();
      } else if (!_board.any((row) => row.any((cell) => cell == ""))) {
        _gameOver = true;
        _saveDrawResult();
      } else {
        _current = _current == "X" ? "O" : "X";
      }
    });
  }

  void _saveRoundResult() async {
    if (_current == "X") {
      await saveP1Win();
    } else {
      await saveP2Win();
    }
    _checkMatchEnd();
  }

  void _saveDrawResult() async {
    await saveDraw();
    _checkMatchEnd();
  }

  void _checkMatchEnd() {
    if (p1Wins >= _requiredWins) {
      _showResultDialog(
        title: "VICTORY",
        message: "${widget.p1} DOMINATED THE GRID",
        color: AppColors.cyan,
      );
    } else if (p2Wins >= _requiredWins) {
      _showResultDialog(
        title: "VICTORY",
        message: "${widget.p2} DOMINATED THE GRID",
        color: AppColors.pink,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _reset();
      });
    }
  }

  bool _checkWinner(int r, int c) {
    List<List<int>>? cells;

    if (_board[r].every((e) => e == _current)) {
      cells = [
        [r, 0], [r, 1], [r, 2]
      ];
    } else if (_board.every((row) => row[c] == _current)) {
      cells = [
        [0, c], [1, c], [2, c]
      ];
    } else if (r == c &&
        _board[0][0] == _current &&
        _board[1][1] == _current &&
        _board[2][2] == _current) {
      cells = [
        [0, 0], [1, 1], [2, 2]
      ];
    } else if (r + c == 2 &&
        _board[0][2] == _current &&
        _board[1][1] == _current &&
        _board[2][0] == _current) {
      cells = [
        [0, 2], [1, 1], [2, 0]
      ];
    }

    if (cells != null) {
      setState(() => _winningCells = cells!);
      HapticFeedback.mediumImpact();
      return true;
    }
    return false;
  }

  void _showResultDialog({
    required String title,
    required String message,
    required Color color,
  }) {
    showResultDialog(
      title: title,
      message: message,
      color: color,
      isDraw: false,
    );
  }

  @override
  void onRematch() {
    _reset();
  }

  Widget _buildBoard() {
    return Container(
      margin: const EdgeInsets.all(30),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.glassBase,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: 9,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, i) {
          int r = i ~/ 3, c = i % 3;
          String val = _board[r][c];
          Color cellColor = val == "X" ? AppColors.cyan : AppColors.pink;
          bool isWinningCell = _winningCells.any((cell) => cell[0] == r && cell[1] == c);

          return GestureDetector(
            onTap: () => _handleTap(r, c),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isWinningCell
                      ? cellColor
                      : (val == "" ? AppColors.glassBorder : cellColor.withValues(alpha: 0.5)),
                  width: isWinningCell ? 2 : 1,
                ),
                boxShadow: isWinningCell
                    ? [BoxShadow(color: cellColor.withValues(alpha: 0.5), blurRadius: 10)]
                    : null,
              ),
              child: Center(
                child: val.isNotEmpty
                    ? Text(
                        val,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: cellColor,
                          shadows: [Shadow(color: cellColor, blurRadius: 15)],
                        ),
                      ).animate(
                        target: isWinningCell ? 1 : 0,
                      ).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ).then().scale(
                        begin: const Offset(1.1, 1.1),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color turnColor = _current == "X" ? AppColors.cyan : AppColors.pink;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [turnColor.withValues(alpha: 0.05), AppColors.bg],
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 20),
              buildScoreDashboard(),
              const SizedBox(height: 30),
              _buildTurnIndicator(turnColor),
              const Spacer(),
              _buildBoard(),
              const Spacer(),
              const Text("SYSTEM STATUS: ACTIVE",
                  style: TextStyle(
                      color: Colors.white10, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context)),
          const Spacer(),
          const Text("TIC TAC TOE OS",
              style: TextStyle(
                  color: Colors.white24, fontSize: 10, letterSpacing: 2)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white24),
              onPressed: _reset),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(Color color) {
    if (_gameOver && p1Wins >= _requiredWins) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
        ),
        child: Text(
          "${widget.p1} WINS THE MATCH",
          style: TextStyle(
              color: AppColors.cyan, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      );
    } else if (_gameOver && p2Wins >= _requiredWins) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.pink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.pink.withValues(alpha: 0.5)),
        ),
        child: Text(
          "${widget.p2} WINS THE MATCH",
          style: TextStyle(
              color: AppColors.pink, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        "${_current == "X" ? widget.p1 : widget.p2}'S TURN",
        style: TextStyle(
            color: color, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }
}

class TicTacToeLaunchDialog extends StatefulWidget {
  const TicTacToeLaunchDialog({super.key});

  @override
  State<TicTacToeLaunchDialog> createState() => _TicTacToeLaunchDialogState();
}

class _TicTacToeLaunchDialogState extends State<TicTacToeLaunchDialog> {
  final p1Controller = TextEditingController(text: "Commander 1");
  final p2Controller = TextEditingController(text: "Commander 2");
  int _bestOf = 3;

  @override
  void dispose() {
    p1Controller.dispose();
    p2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: AlertDialog(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: AppColors.glassBorder)),
        title: const NeonText(
          text: "INITIALIZE GAME",
          color: AppColors.pink,
          fontSize: 14,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassInput(
              controller: p1Controller,
              hint: "Player X",
              accentColor: AppColors.cyan,
            ),
            const SizedBox(height: 15),
            GlassInput(
              controller: p2Controller,
              hint: "Player O",
              accentColor: AppColors.pink,
            ),
            const SizedBox(height: 20),
            const Text(
              "BEST OF",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 3, label: Text("3")),
                ButtonSegment(value: 5, label: Text("5")),
                ButtonSegment(value: 7, label: Text("7")),
              ],
              selected: {_bestOf},
              onSelectionChanged: (set) {
                setState(() => _bestOf = set.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.pink.withValues(alpha: 0.2);
                  }
                  return AppColors.glassBase;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.pink;
                  }
                  return Colors.white54;
                }),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, 0),
              icon: const Icon(Icons.help_outline_rounded,
                  size: 16, color: AppColors.pink),
              label: const Text(
                'HOW TO PLAY',
                style: TextStyle(
                    color: AppColors.pink, fontSize: 10, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 10),
            GlassButton(
              label: "LAUNCH",
              color: AppColors.pink,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  slideUpRoute(
                    page: TicTacToeScreen(p1: p1Controller.text, p2: p2Controller.text),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void showTicTacToeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const TicTacToeLaunchDialog(),
  );
}