import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/app_theme.dart';
import '../core/app_widgets.dart';
import '../core/page_transitions.dart';
import '../core/game_instructions.dart';
import '../models/game.dart';
import '../models/game_score.dart';
import '../services/database_service.dart';

class CheckersPage extends StatefulWidget {
  final String p1;
  final String p2;

  const CheckersPage({super.key, required this.p1, required this.p2});

  @override
  State<CheckersPage> createState() => _CheckersPageState();
}

enum PieceType { player1, player2, p1King, p2King }

class _CheckersPageState extends State<CheckersPage> {
  // --- DESIGN TOKENS ---
  static const Color bgColor = Color(0xFF0D1117);
  static const Color glassBase = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color neonCyan = Color(0xFF00FBFF);
  static const Color neonPink = Color(0xFFFF006E);

  final DatabaseService _db = DatabaseService();

  // --- GAME STATE ---
  late List<PieceType?> board;
  int? selectedIndex;
  bool isPlayer1Turn = true;
  List<int> validMoves = [];
  bool multiJumpActive = false;

  // --- SCORE TRACKING ---
  int p1Pieces = 12;
  int p2Pieces = 12;
  int p1Wins = 0; // Persistent Win Count
  int p2Wins = 0; // Persistent Win Count

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      board = List.generate(64, (index) {
        int row = index ~/ 8;
        int col = index % 8;
        if ((row + col) % 2 != 0) {
          if (row < 3) return PieceType.player2;
          if (row > 4) return PieceType.player1;
        }
        return null;
      });
      selectedIndex = null;
      validMoves = [];
      isPlayer1Turn = true;
      multiJumpActive = false;
      _updatePieceCounts();
    });
  }

  void _updatePieceCounts() {
    int p1 = 0;
    int p2 = 0;
    for (var piece in board) {
      if (piece == PieceType.player1 || piece == PieceType.p1King) p1++;
      if (piece == PieceType.player2 || piece == PieceType.p2King) p2++;
    }
    p1Pieces = p1;
    p2Pieces = p2;
  }

  void _onTap(int index) {
    if (p1Pieces == 0 || p2Pieces == 0) return;

    if (multiJumpActive) {
      if (validMoves.contains(index)) {
        _movePiece(selectedIndex!, index);
      }
      return;
    }

    if (board[index] != null && _isOwnPiece(board[index]!)) {
      setState(() {
        selectedIndex = index;
        validMoves = _getValidMoves(index);
      });
    } else if (selectedIndex != null && validMoves.contains(index)) {
      _movePiece(selectedIndex!, index);
    }
  }

  bool _isOwnPiece(PieceType piece) {
    if (isPlayer1Turn) {
      return piece == PieceType.player1 || piece == PieceType.p1King;
    }
    return piece == PieceType.player2 || piece == PieceType.p2King;
  }

  List<int> _getValidMoves(int index) {
    List<int> jumpMoves = [];
    List<int> simpleMoves = [];
    PieceType? piece = board[index];
    if (piece == null) return [];

    bool isKing = piece == PieceType.p1King || piece == PieceType.p2King;
    List<int> rowDirs =
        isKing ? [-1, 1] : (piece == PieceType.player1 ? [-1] : [1]);

    for (int rd in rowDirs) {
      for (int cd in [-1, 1]) {
        int tRow = (index ~/ 8) + rd;
        int tCol = (index % 8) + cd;
        if (_inBounds(tRow, tCol)) {
          int tIdx = tRow * 8 + tCol;
          if (board[tIdx] == null) {
            simpleMoves.add(tIdx);
          } else if (!_isOwnPiece(board[tIdx]!)) {
            int jRow = tRow + rd;
            int jCol = tCol + cd;
            if (_inBounds(jRow, jCol)) {
              int jIdx = jRow * 8 + jCol;
              if (board[jIdx] == null) jumpMoves.add(jIdx);
            }
          }
        }
      }
    }

    if (multiJumpActive) return jumpMoves;

    bool globalJumpAvailable = _canAnyPieceJump();
    return jumpMoves.isNotEmpty
        ? jumpMoves
        : (globalJumpAvailable ? [] : simpleMoves);
  }

  bool _canAnyPieceJump() {
    for (int i = 0; i < 64; i++) {
      if (board[i] != null && _isOwnPiece(board[i]!)) {
        if (_calculatePotentialJumps(i).isNotEmpty) return true;
      }
    }
    return false;
  }

  List<int> _calculatePotentialJumps(int index) {
    List<int> jumps = [];
    PieceType? p = board[index];
    if (p == null) return [];

    bool isK = p == PieceType.p1King || p == PieceType.p2King;
    List<int> dirs = isK ? [-1, 1] : (p == PieceType.player1 ? [-1] : [1]);

    for (int rd in dirs) {
      for (int cd in [-1, 1]) {
        int tRow = (index ~/ 8) + rd, tCol = (index % 8) + cd;
        int jRow = tRow + rd, jCol = tCol + cd;
        if (_inBounds(jRow, jCol)) {
          int tIdx = tRow * 8 + tCol, jIdx = jRow * 8 + jCol;
          if (board[tIdx] != null &&
              !_isOwnPiece(board[tIdx]!) &&
              board[jIdx] == null) {
            jumps.add(jIdx);
          }
        }
      }
    }
    return jumps;
  }

  bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  void _movePiece(int from, int to) {
    setState(() {
      bool captured = (to - from).abs() > 10;
      board[to] = board[from];
      board[from] = null;

      if (captured) {
        board[(from + to) ~/ 2] = null;
        _updatePieceCounts();
      }

      if (to ~/ 8 == 0 && board[to] == PieceType.player1) {
        board[to] = PieceType.p1King;
      }
      if (to ~/ 8 == 7 && board[to] == PieceType.player2) {
        board[to] = PieceType.p2King;
      }

      if (captured) {
        List<int> nextJumps = _calculatePotentialJumps(to);
        if (nextJumps.isNotEmpty) {
          selectedIndex = to;
          validMoves = nextJumps;
          multiJumpActive = true;
          return;
        }
      }

      selectedIndex = null;
      validMoves = [];
      multiJumpActive = false;
      isPlayer1Turn = !isPlayer1Turn;

      if (p1Pieces == 0 || p2Pieces == 0) {
        if (p1Pieces == 0) {
          p2Wins++;
          _saveResult(widget.p2);
        } else {
          p1Wins++;
          _saveResult(widget.p1);
        }
        _showWinDialog();
      }
    });
  }

  Future<void> _saveResult(String winner) async {
    final game = Game(
        type: GameType.checkers,
        player1Name: widget.p1,
        player2Name: widget.p2,
        winner: winner);
    await _db.saveGame(game);
    await _db.updateOrCreatePlayer(widget.p1);
    await _db.updateOrCreatePlayer(widget.p2);
    await _db.saveGameScore(GameScore(
        playerName: widget.p1,
        gameId: GameType.checkers.index,
        wins: winner == widget.p1 ? 1 : 0,
        losses: winner == widget.p2 ? 1 : 0,
        totalPoints: winner == widget.p1 ? 3 : 0));
    await _db.saveGameScore(GameScore(
        playerName: widget.p2,
        gameId: GameType.checkers.index,
        wins: winner == widget.p2 ? 1 : 0,
        losses: winner == widget.p1 ? 1 : 0,
        totalPoints: winner == widget.p2 ? 3 : 0));
  }

  void _showWinDialog() {
    String winner = p1Pieces == 0 ? widget.p2 : widget.p1;
    Color winColor = p1Pieces == 0 ? neonPink : neonCyan;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: winColor.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: winColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5)
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined, color: winColor, size: 50),
                  const SizedBox(height: 16),
                  Text("$winner VICTORIOUS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: winColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const SizedBox(height: 12),
                  const Text(
                      "Fleet objectives completed. Systems ready for redeployment.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _resetGame();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: winColor),
                        boxShadow: [
                          BoxShadow(
                              color: winColor.withValues(alpha: 0.1),
                              blurRadius: 4)
                        ],
                      ),
                      child: Text("REDEPLOY",
                          style: TextStyle(
                              color: winColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              isPlayer1Turn
                  ? neonCyan.withValues(alpha: 0.05)
                  : neonPink.withValues(alpha: 0.05),
              bgColor
            ],
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 10),
              _buildScoreBoard(),
              const SizedBox(height: 20),
              _buildTurnIndicator(),
              Expanded(child: Center(child: _buildBoard())),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context)),
          const Spacer(),
          const Text("CHECKERS OS",
              style: TextStyle(
                  color: Colors.white24, fontSize: 10, letterSpacing: 2)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white38),
              onPressed: _resetGame),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
                color: glassBase,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: glassBorder)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _scoreItem("P1 PIECES", p1Pieces, neonCyan),
                _scoreItem("P1 WINS", p1Wins, neonCyan, isSmall: true),
                Container(width: 1, height: 30, color: glassBorder),
                _scoreItem("P2 WINS", p2Wins, neonPink, isSmall: true),
                _scoreItem("P2 PIECES", p2Pieces, neonPink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreItem(String label, int count, Color color,
      {bool isSmall = false}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontSize: isSmall ? 8 : 10,
                fontWeight: FontWeight.bold)),
        Text("$count",
            style: TextStyle(
                color: color,
                fontSize: isSmall ? 14 : 20,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: color, blurRadius: 10)])),
      ],
    );
  }

  Widget _buildTurnIndicator() {
    Color activeColor = isPlayer1Turn ? neonCyan : neonPink;
    String playerName = isPlayer1Turn ? widget.p1 : widget.p2;
    String displayName = playerName.length > 10
        ? '${playerName.substring(0, 10)}...'
        : playerName;
    return Column(
      children: [
        Text(displayName,
            style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: [Shadow(color: activeColor, blurRadius: 10)])),
        const SizedBox(height: 4),
        Text(multiJumpActive ? "CHAIN ATTACK ACTIVE" : "YOUR MOVE COMMANDER",
            style: const TextStyle(
                color: Colors.white24, fontSize: 8, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildBoard() {
    double size = MediaQuery.of(context).size.width - 40;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: glassBase,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: glassBorder)),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemCount: 64,
        itemBuilder: (context, index) {
          int row = index ~/ 8, col = index % 8;
          bool isDark = (row + col) % 2 != 0;
          bool isSelected = selectedIndex == index;
          bool isValid = validMoves.contains(index);
          return GestureDetector(
            onTap: () => _onTap(index),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isSelected
                    ? neonCyan.withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(4),
                border: isValid
                    ? Border.all(color: Colors.white54, width: 1)
                    : (isSelected
                        ? Border.all(color: neonCyan, width: 1)
                        : null),
              ),
              child: Center(child: _buildPiece(board[index], index)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPiece(PieceType? type, int index) {
    if (type == null) {
      return validMoves.contains(index)
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle))
          : const SizedBox();
    }
    bool isP1 = type == PieceType.player1 || type == PieceType.p1King;
    bool isKing = type == PieceType.p1King || type == PieceType.p2King;
    Color pColor = isP1 ? neonCyan : neonPink;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pColor.withValues(alpha: 0.2),
        border: Border.all(color: pColor, width: 2),
        boxShadow: [
          BoxShadow(color: pColor.withValues(alpha: 0.3), blurRadius: 8)
        ],
      ),
      child: isKing ? Icon(Icons.star, color: pColor, size: 16) : null,
    );
  }
}

class CheckersLaunchDialog extends StatefulWidget {
  const CheckersLaunchDialog({super.key});

  @override
  State<CheckersLaunchDialog> createState() => _CheckersLaunchDialogState();
}

class _CheckersLaunchDialogState extends State<CheckersLaunchDialog> {
  final p1Controller = TextEditingController(text: 'Red Player');
  final p2Controller = TextEditingController(text: 'Black Player');

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
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const NeonText(
            text: 'INITIALIZE CHECKERS',
            color: AppColors.green,
            fontSize: 14),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassInput(
              controller: p1Controller,
              hint: 'Red Player',
              accentColor: AppColors.checkRed,
            ),
            const SizedBox(height: 15),
            GlassInput(
              controller: p2Controller,
              hint: 'Black Player',
              accentColor: Colors.white54,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, 3),
              icon: const Icon(Icons.help_outline_rounded,
                  size: 16, color: AppColors.green),
              label: const Text(
                'HOW TO PLAY',
                style: TextStyle(
                    color: AppColors.green, fontSize: 10, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 10),
            GlassButton(
              label: 'LAUNCH',
              color: AppColors.green,
              onPressed: () {
                final p1 = p1Controller.text.trim();
                final p2 = p2Controller.text.trim();
                if (p1.isEmpty || p2.isEmpty) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  slideUpRoute(
                    page: CheckersPage(p1: p1, p2: p2),
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

void showCheckersDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const CheckersLaunchDialog(),
  );
}
