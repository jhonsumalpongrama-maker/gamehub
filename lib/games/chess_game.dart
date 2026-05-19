import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../core/app_widgets.dart';
import '../core/page_transitions.dart';
import '../core/game_instructions.dart';
import '../models/base_game.dart';
import '../models/game.dart';
import '../models/game_score.dart';

class ChessGame extends BaseGameWidget {
  const ChessGame({super.key, required super.p1, required super.p2})
      : super(gameType: GameType.chess);

  @override
  State<ChessGame> createState() => _ChessGameState();
}

class _ChessGameState extends BaseGameState<ChessGame> {
  late List<List<String>> _initialBoard;
  late List<List<String>> board;
  int? selectedRow;
  int? selectedCol;
  bool isWhiteTurn = true;
  bool isGameOver = false;

  final List<MoveRecord> _moveHistory = [];
  int _reviewIndex = -1;
  bool _isReviewMode = false;

  bool whiteKingMoved = false;
  bool blackKingMoved = false;
  bool whiteHRookMoved = false;
  bool whiteARookMoved = false;
  bool blackHRookMoved = false;
  bool blackARookMoved = false;

  int? enPassantRow;
  int? enPassantCol;

  int _halfMoveClock = 0;
  List<String> capturedByWhite = [];
  List<String> capturedByBlack = [];

  @override
  void initState() {
    super.initState();
    _initialBoard = [
      ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'],
      ['p', 'p', 'p', 'p', 'p', 'p', 'p', 'p'],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
      ['R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R'],
    ];
    _resetBoard();
  }

  void _resetBoard() {
    setState(() {
      board = List.generate(8, (r) => List.from(_initialBoard[r]));
      isWhiteTurn = true;
      isGameOver = false;
      selectedRow = null;
      selectedCol = null;
      whiteKingMoved = false;
      blackKingMoved = false;
      whiteHRookMoved = false;
      whiteARookMoved = false;
      blackHRookMoved = false;
      blackARookMoved = false;
      enPassantRow = null;
      enPassantCol = null;
      _halfMoveClock = 0;
      _moveHistory.clear();
      _reviewIndex = -1;
      _isReviewMode = false;
      capturedByWhite.clear();
      capturedByBlack.clear();
      p1Wins = 0;
      p2Wins = 0;
      draws = 0;
    });
  }

  bool _isWhite(String p) => p.isNotEmpty && p == p.toUpperCase();

  List<Position> _getLegalMoves(int fR, int fC) {
    List<Position> moves = [];
    if (fR < 0 || fR >= 8 || fC < 0 || fC >= 8) return moves;
    if (board.length <= fR || board[fR].length < 8) return moves;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (_isValidMove(fR, fC, r, c, board)) {
          if (!_wouldBeInCheckAfterMove(fR, fC, r, c)) {
            moves.add(Position(r, c));
          }
        }
      }
    }
    return moves;
  }

  bool _isValidMove(int fR, int fC, int tR, int tC, List<List<String>> b) {
    if (fR < 0 || fR >= 8 || fC < 0 || fC >= 8) return false;
    if (tR < 0 || tR > 7 || tC < 0 || tC > 7) return false;
    String piece = b[fR][fC].toLowerCase();
    String target = b[tR][tC];

    if (target.isNotEmpty && _isWhite(target) == _isWhite(b[fR][fC])) return false;

    switch (piece) {
      case 'r':
        return (fR == tR || fC == tC) && _isPathClear(fR, fC, tR, tC, b);
      case 'b':
        return (fR - tR).abs() == (fC - tC).abs() && _isPathClear(fR, fC, tR, tC, b);
      case 'q':
        return ((fR == tR || fC == tC) || (fR - tR).abs() == (fC - tC).abs()) &&
            _isPathClear(fR, fC, tR, tC, b);
      case 'n':
        return ((fR - tR).abs() == 2 && (fC - tC).abs() == 1) ||
            ((fR - tR).abs() == 1 && (fC - tC).abs() == 2);
      case 'p':
        int dir = _isWhite(b[fR][fC]) ? -1 : 1;
        if (fC == tC && target.isEmpty && tR == fR + dir) return true;
        if (fC == tC && target.isEmpty && tR == fR + 2 * dir &&
            (fR == 1 || fR == 6) && b[fR + dir][fC].isEmpty && _isPathClear(fR, fC, tR, tC, b)) {
          return true;
        }
        if ((fC - tC).abs() == 1 && tR == fR + dir && target.isNotEmpty) return true;
        if ((fC - tC).abs() == 1 && tR == fR + dir && target.isEmpty &&
            enPassantRow != null && tR == enPassantRow && tC == enPassantCol) {
          return true;
        }
        return false;
      case 'k':
        if ((fR - tR).abs() <= 1 && (fC - tC).abs() <= 1) return true;
        if (fR == 7 && fC == 4 && tR == 7 && tC == 6 && !whiteKingMoved && !whiteHRookMoved &&
            _isPathClear(fR, fC, tR, tC, b) && !_isKingInCheck(true, b) &&
            !_isSquareAttacked(7, 5, false, b) && !_isSquareAttacked(7, 6, false, b)) {
          return true;
        }
        if (fR == 7 && fC == 4 && tR == 7 && tC == 2 && !whiteKingMoved && !whiteARookMoved &&
            _isPathClear(fR, fC, tR, tC, b) && !_isKingInCheck(true, b) &&
            !_isSquareAttacked(7, 3, false, b) && !_isSquareAttacked(7, 2, false, b)) {
          return true;
        }
        if (fR == 0 && fC == 4 && tR == 0 && tC == 6 && !blackKingMoved && !blackHRookMoved &&
            _isPathClear(fR, fC, tR, tC, b) && !_isKingInCheck(false, b) &&
            !_isSquareAttacked(0, 5, true, b) && !_isSquareAttacked(0, 6, true, b)) {
          return true;
        }
        if (fR == 0 && fC == 4 && tR == 0 && tC == 2 && !blackKingMoved && !blackARookMoved &&
            _isPathClear(fR, fC, tR, tC, b) && !_isKingInCheck(false, b) &&
            !_isSquareAttacked(0, 3, true, b) && !_isSquareAttacked(0, 2, true, b)) {
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  bool _isPathClear(int fR, int fC, int tR, int tC, List<List<String>> b) {
    int rowStep = (tR - fR).compareTo(0);
    int colStep = (tC - fC).compareTo(0);
    int currR = fR + rowStep;
    int currC = fC + colStep;
    while (currR != tR || currC != tC) {
      if (b[currR][currC].isNotEmpty) return false;
      currR += rowStep;
      currC += colStep;
    }
    return true;
  }

  bool _isKingInCheck(bool whiteKing, List<List<String>> b) {
    if (b.length < 8) return false;
    int kR = -1, kC = -1;
    String kingChar = whiteKing ? 'K' : 'k';
    for (int r = 0; r < 8; r++) {
      if (b[r].length < 8) continue;
      for (int c = 0; c < 8; c++) {
        if (b[r][c] == kingChar) {
          kR = r;
          kC = c;
          break;
        }
      }
    }
    if (kR == -1) return false;
    return _isSquareAttacked(kR, kC, !whiteKing, b);
  }

  bool _isSquareAttacked(int targetR, int targetC, bool byWhite, List<List<String>> b) {
    for (int r = 0; r < 8; r++) {
      if (b[r].length < 8) continue;
      for (int c = 0; c < 8; c++) {
        if (b[r][c].isNotEmpty && _isWhite(b[r][c]) == byWhite) {
          if (_isValidMove(r, c, targetR, targetC, b)) return true;
        }
      }
    }
    return false;
  }

  bool _wouldBeInCheckAfterMove(int fR, int fC, int tR, int tC) {
    List<List<String>> ghostBoard = List.generate(8, (i) => List.from(board[i]));
    ghostBoard[tR][tC] = ghostBoard[fR][fC];
    ghostBoard[fR][fC] = '';
    return _isKingInCheck(isWhiteTurn, ghostBoard);
  }

  bool _isCheckmate(bool whiteTurn) {
    if (!_isKingInCheck(whiteTurn, board)) return false;
    for (int r = 0; r < 8; r++) {
      if (board.length <= r || board[r].length < 8) continue;
      for (int c = 0; c < 8; c++) {
        if (board[r][c].isNotEmpty && _isWhite(board[r][c]) == whiteTurn) {
          for (int tR = 0; tR < 8; tR++) {
            for (int tC = 0; tC < 8; tC++) {
              if (_isValidMove(r, c, tR, tC, board)) {
                if (!_wouldBeInCheckAfterMove(r, c, tR, tC)) return false;
              }
            }
          }
        }
      }
    }
    return true;
  }

  bool _isStalemate(bool whiteTurn) {
    if (_isKingInCheck(whiteTurn, board)) return false;
    for (int r = 0; r < 8; r++) {
      if (board.length <= r || board[r].length < 8) continue;
      for (int c = 0; c < 8; c++) {
        if (board[r][c].isNotEmpty && _isWhite(board[r][c]) == whiteTurn) {
          for (int tR = 0; tR < 8; tR++) {
            for (int tC = 0; tC < 8; tC++) {
              if (_isValidMove(r, c, tR, tC, board)) {
                if (!_wouldBeInCheckAfterMove(r, c, tR, tC)) return false;
              }
            }
          }
        }
      }
    }
    return true;
  }

  bool _hasInsufficientMaterial() {
    List<String> pieces = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c].isNotEmpty) {
          pieces.add(board[r][c].toLowerCase());
        }
      }
    }
    if (pieces.length == 2) return true;
    if (pieces.length == 3 && (pieces.contains('n') || pieces.contains('b'))) return true;
    if (pieces.length == 4 && pieces.where((p) => p == 'n' || p == 'b').length == 2) return true;
    return false;
  }

  String _toAlgebraic(int row, int col) => '${'abcdefgh'[col]}${8 - row}';

  String _getPieceSymbol(String piece) {
    switch (piece.toLowerCase()) {
      case 'k': return 'K';
      case 'q': return 'Q';
      case 'r': return 'R';
      case 'b': return 'B';
      case 'n': return 'N';
      default: {
        return '';
      }
    }
  }

  String _getMoveNotation(int fR, int fC, int tR, int tC, String piece, bool captured, bool isCheck, bool isCheckmate) {
    if (piece.toLowerCase() == 'k' && (fC - tC).abs() == 2) {
      return tC > fC ? 'O-O' : 'O-O-O';
    }
    String notation = _getPieceSymbol(piece);
    if (captured) notation += 'x';
    notation += _toAlgebraic(tR, tC);
    if (isCheckmate) {
      notation += '#';
    } else if (isCheck) {
      notation += '+';
    }
    return notation;
  }

  void _handleTap(int r, int c) {
    if (isGameOver || _isReviewMode) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (selectedRow == null) {
        if (board[r][c].isNotEmpty && _isWhite(board[r][c]) == isWhiteTurn) {
          selectedRow = r;
          selectedCol = c;
        }
      } else {
        if (selectedRow != null && selectedCol != null && r == selectedRow && c == selectedCol) {
          selectedRow = null;
          selectedCol = null;
        } else if (selectedRow != null && selectedCol != null && _isValidMove(selectedRow!, selectedCol!, r, c, board)) {
          if (_wouldBeInCheckAfterMove(selectedRow!, selectedCol!, r, c)) {
            _showOSDialog("ILLEGAL MOVE", "You must protect your King!", AppColors.checkRed);
          } else {
            _executeMove(selectedRow!, selectedCol!, r, c);
          }
        } else if (board[r][c].isNotEmpty && _isWhite(board[r][c]) == isWhiteTurn) {
          selectedRow = r;
          selectedCol = c;
        } else {
          selectedRow = null;
          selectedCol = null;
        }
      }
    });
  }

  void _executeMove(int fR, int fC, int tR, int tC) {
    String piece = board[fR][fC];
    bool captured = board[tR][tC].isNotEmpty;
    bool wasEnPassant = false;

    if (piece.toLowerCase() == 'p' && enPassantRow != null &&
        tR == enPassantRow && tC == enPassantCol) {
      int capturedRow = isWhiteTurn ? tR + 1 : tR - 1;
      board[capturedRow][tC] = '';
      captured = true;
      wasEnPassant = true;
    }

    if (captured) {
      capturedByWhite.add(board[tR][tC]);
    }

    if (piece.toLowerCase() == 'k' && (fC - tC).abs() == 2) {
      if (tC == 6) {
        board[fR][5] = board[fR][7];
        board[fR][7] = '';
      } else if (tC == 2) {
        board[fR][3] = board[fR][0];
        board[fR][0] = '';
      }
      if (isWhiteTurn) {
        whiteKingMoved = true;
      } else {
        blackKingMoved = true;
      }
    }

    if (piece.toLowerCase() == 'r') {
      if (fR == 0 && fC == 0) {
        whiteARookMoved = true;
      }
      if (fR == 0 && fC == 7) {
        whiteHRookMoved = true;
      }
      if (fR == 7 && fC == 0) {
        blackARookMoved = true;
      }
      if (fR == 7 && fC == 7) {
        blackHRookMoved = true;
      }
    }

    if (piece.toLowerCase() == 'k') {
      if (isWhiteTurn) {
        whiteKingMoved = true;
      } else {
        blackKingMoved = true;
      }
    }

    board[tR][tC] = piece;
    board[fR][fC] = '';

    if (piece.toLowerCase() == 'p' && (tR - fR).abs() == 2) {
      enPassantRow = isWhiteTurn ? tR + 1 : tR - 1;
      enPassantCol = tC;
    } else {
      enPassantRow = null;
      enPassantCol = null;
    }

    bool isCheck = _isKingInCheck(!isWhiteTurn, board);
    bool isCheckmate = _isCheckmate(!isWhiteTurn);

    if ((tR == 0 || tR == 7) && piece.toLowerCase() == 'p') {
      _showPromotionDialog(tR, tC, isWhiteTurn);
    }

    String notation = _getMoveNotation(fR, fC, tR, tC, piece, captured, isCheck, isCheckmate);

    if (piece.toLowerCase() == 'p' || captured || wasEnPassant) {
      _halfMoveClock = 0;
    } else {
      _halfMoveClock++;
    }

    _moveHistory.add(MoveRecord(
      notation: notation,
      fromRow: fR,
      fromCol: fC,
      toRow: tR,
      toCol: tC,
      piece: piece,
      captured: captured,
      isWhite: isWhiteTurn,
      promotion: null,
      castle: null,
    ));

    _finishMove(isCheckmate);
  }

  void _finishMove(bool isCheckmate) {
    selectedRow = null;
    selectedCol = null;

    if (isCheckmate) {
      isGameOver = true;
      HapticFeedback.mediumImpact();
      if (isWhiteTurn) {
        p2Wins++;
        _saveResult(widget.p2);
      } else {
        p1Wins++;
        _saveResult(widget.p1);
      }
      _showGameOverDialog();
    } else if (_isStalemate(!isWhiteTurn)) {
      isGameOver = true;
      HapticFeedback.lightImpact();
      draws++;
      _saveResult("DRAW");
      _showDrawDialog("STALEMATE", "No legal moves available!", AppColors.cyan);
    } else if (_halfMoveClock >= 100) {
      isGameOver = true;
      draws++;
      _saveResult("DRAW");
      _showDrawDialog("50-MOVE RULE", "No pawn move or capture in 50 moves!", AppColors.cyan);
    } else if (_hasInsufficientMaterial()) {
      isGameOver = true;
      draws++;
      _saveResult("DRAW");
      _showDrawDialog("INSUFFICIENT MATERIAL", "Cannot checkmate!", AppColors.cyan);
    } else {
      isWhiteTurn = !isWhiteTurn;
    }
  }

  Future<void> _saveResult(String winner) async {
    try {
      final game = Game(
        type: widget.gameType,
        player1Name: widget.p1,
        player2Name: widget.p2,
        winner: winner == "DRAW" ? null : winner,
        isDraw: winner == "DRAW",
        rounds: _moveHistory.length,
      );
      await db.saveGame(game);
      await db.updateOrCreatePlayer(widget.p1);
      await db.updateOrCreatePlayer(widget.p2);

      final bool isDraw = winner == "DRAW";
      await db.saveGameScore(GameScore(
        playerName: widget.p1,
        gameId: widget.gameType.index,
        wins: (!isDraw && winner == widget.p1) ? 1 : 0,
        losses: (!isDraw && winner == widget.p2) ? 1 : 0,
        draws: isDraw ? 1 : 0,
        totalPoints: isDraw ? 1 : (winner == widget.p1 ? 3 : 0),
      ));
      await db.saveGameScore(GameScore(
        playerName: widget.p2,
        gameId: widget.gameType.index,
        wins: (!isDraw && winner == widget.p2) ? 1 : 0,
        losses: (!isDraw && winner == widget.p1) ? 1 : 0,
        draws: isDraw ? 1 : 0,
        totalPoints: isDraw ? 1 : (winner == widget.p2 ? 3 : 0),
      ));
    } catch (e) {
      debugPrint('Database error: $e');
    }
  }

  void _showGameOverDialog() {
    String winner = isWhiteTurn ? widget.p2 : widget.p1;
    showResultDialog(
      title: "CHECKMATE",
      message: "$winner WINS!",
      color: AppColors.pink,
    );
  }

  void _showDrawDialog(String title, String msg, Color color) {
    showResultDialog(
      title: title,
      message: msg,
      color: color,
      isDraw: true,
    );
  }

  @override
  void onRematch() {
    _resetBoard();
  }

  void _showOSDialog(String title, String msg, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppColors.bg.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: color),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 4),
          ),
          content: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotionDialog(int row, int col, bool isWhite) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppColors.bg.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cyan),
          ),
          title: const Text(
            "PROMOTION",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _promotionPiece('Q', isWhite, ctx, row, col),
              _promotionPiece('R', isWhite, ctx, row, col),
              _promotionPiece('B', isWhite, ctx, row, col),
              _promotionPiece('N', isWhite, ctx, row, col),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promotionPiece(String piece, bool isWhite, BuildContext ctx, int promotionRow, int promotionCol) {
    String p = isWhite ? piece : piece.toLowerCase();
    Color color = isWhite ? Colors.white : AppColors.pink;
    IconData icon;
    switch (piece) {
      case 'Q': icon = Icons.workspace_premium_rounded; break;
      case 'R': icon = Icons.castle_rounded; break;
      case 'B': icon = Icons.explore_outlined; break;
      case 'N': icon = Icons.psychology_alt_rounded; break;
      default: icon = Icons.circle;
    }
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        board[promotionRow][promotionCol] = p;
        board[promotionRow - (isWhiteTurn ? 1 : -1)][promotionCol] = '';
        HapticFeedback.mediumImpact();
        String notation = _getMoveNotation(
          promotionRow - (isWhiteTurn ? 1 : -1),
          promotionCol,
          promotionRow,
          promotionCol,
          p, true, false, false,
        );
        _moveHistory.add(MoveRecord(
          notation: notation,
          fromRow: promotionRow - (isWhiteTurn ? 1 : -1),
          fromCol: promotionCol,
          toRow: promotionRow,
          toCol: promotionCol,
          piece: p,
          captured: true,
          isWhite: isWhiteTurn,
          promotion: piece,
          castle: null,
        ));
        _halfMoveClock = 0;
        _finishMove(_isCheckmate(!isWhiteTurn));
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  void _stepReview(int delta) {
    setState(() {
      _reviewIndex = (_reviewIndex + delta).clamp(-1, _moveHistory.length - 1);
      if (_reviewIndex == -1) {
        board = List.generate(8, (r) => List.from(_initialBoard[r]));
      } else {
        board = List.generate(8, (r) => List.from(_initialBoard[r]));
        for (int i = 0; i <= _reviewIndex; i++) {
          var move = _moveHistory[i];
          board[move.toRow][move.toCol] = move.piece;
          if (move.fromRow != move.toRow || move.fromCol != move.toCol) {
            board[move.fromRow][move.fromCol] = '';
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color turnColor = isWhiteTurn ? Colors.white : AppColors.pink;
    bool inCheck = _isKingInCheck(isWhiteTurn, board);
    List<Position> legalMoves = [];
    if (selectedRow != null && selectedCol != null && !isGameOver && !_isReviewMode) {
      legalMoves = _getLegalMoves(selectedRow!, selectedCol!);
    }

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
              const SizedBox(height: 10),
              _buildCapturedPieces(),
              const SizedBox(height: 10),
              buildScoreDashboard(),
              const SizedBox(height: 20),
              _buildTurnIndicator(turnColor, inCheck),
              Expanded(child: _buildBoard(legalMoves)),
              const Text(
                "SYSTEM STATUS: ROYAL_PROTOCOL_ACTIVE",
                style: TextStyle(color: Colors.white10, fontSize: 10, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              SizedBox(height: 100, child: _buildMoveHistory()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapturedPieces() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              spacing: 2,
              children: capturedByWhite.map((p) => _getSmallPieceIcon(p, true)).toList(),
            ),
          ),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 2,
              children: capturedByBlack.map((p) => _getSmallPieceIcon(p, false)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSmallPieceIcon(String p, bool isCaptureByWhite) {
    IconData icon;
    switch (p.toLowerCase()) {
      case 'p': icon = Icons.circle; break;
      case 'r': icon = Icons.castle_rounded; break;
      case 'n': icon = Icons.psychology_alt_rounded; break;
      case 'b': icon = Icons.explore_outlined; break;
      case 'q': icon = Icons.workspace_premium_rounded; break;
      default: icon = Icons.circle;
    }
    return Icon(icon, size: 12, color: Colors.white38);
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            _isReviewMode ? "REVIEW MODE" : "CHESS ROYAL",
            style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2),
          ),
          const Spacer(),
          if (_isReviewMode)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.cyan),
              onPressed: () => setState(() {
                _isReviewMode = false;
                _reviewIndex = -1;
              }),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white24),
              onPressed: _resetBoard,
            ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(Color color, bool inCheck) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: inCheck ? AppColors.checkRed.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: inCheck ? AppColors.checkRed : color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _isReviewMode
            ? "MOVE ${_reviewIndex + 1}/${_moveHistory.length}"
            : inCheck
                ? "KING IN CHECK"
                : "${isWhiteTurn ? widget.p1 : widget.p2}'S TURN",
        style: TextStyle(
          color: inCheck ? AppColors.checkRed : color,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildBoard(List<Position> legalMoves) {
    bool whiteCheck = _isKingInCheck(true, board);
    bool blackCheck = _isKingInCheck(false, board);

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double boardSize = constraints.maxWidth;
          return Center(
            child: Container(
              width: boardSize - 24,
              height: boardSize - 24,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.glassBase,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    int r = index ~/ 8;
                    int c = index % 8;
                    bool isDark = (r + c) % 2 != 0;
                    bool isSelected = selectedRow != null && selectedCol != null && selectedRow == r && selectedCol == c;
                    bool isLegalMove = legalMoves.any((m) => m.row == r && m.col == c);
                    bool isKingAlert = (board[r][c] == 'K' && whiteCheck) || (board[r][c] == 'k' && blackCheck);
                    bool isMoveFrom = _moveHistory.any((m) => m.toRow == r && m.toCol == c);

                    return GestureDetector(
                      onTap: () => _handleTap(r, c),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isKingAlert
                              ? AppColors.checkRed.withValues(alpha: 0.4)
                              : isMoveFrom
                                  ? AppColors.cyan.withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF1A1F26) : const Color(0xFF252A32)),
                          border: isSelected ? Border.all(color: AppColors.cyan, width: 2) : null,
                        ),
                        child: Stack(
                          children: [
                            if (isLegalMove && board[r][c].isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                                ),
                              ),
                            if (isLegalMove)
                              Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (isSelected)
                              Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            Center(child: _getPieceIcon(board[r][c])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoveHistory() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.glassBase.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Text("MOVES", style: TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ),
          if (_isReviewMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.cyan.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.skip_previous, size: 16, color: Colors.white70), onPressed: () => _stepReview(-_reviewIndex - 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white70), onPressed: () => _stepReview(-1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70), onPressed: () => _stepReview(1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  IconButton(icon: const Icon(Icons.skip_next, size: 16, color: Colors.white70), onPressed: () => _stepReview(_moveHistory.length - _reviewIndex - 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: (_moveHistory.length / 2).ceil(),
              itemBuilder: (context, index) {
                int moveNum = index + 1;
                String whiteMove = '';
                String blackMove = '';
                if (index * 2 < _moveHistory.length) whiteMove = _moveHistory[index * 2].notation;
                if (index * 2 + 1 < _moveHistory.length) blackMove = _moveHistory[index * 2 + 1].notation;
                bool isWhiteHighlight = index * 2 == _reviewIndex;
                bool isBlackHighlight = index * 2 + 1 == _reviewIndex;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  color: isWhiteHighlight ? AppColors.cyan.withValues(alpha: 0.2) : (isBlackHighlight ? AppColors.pink.withValues(alpha: 0.2) : null),
                  child: Row(
                    children: [
                      SizedBox(width: 20, child: Text("$moveNum.", style: const TextStyle(color: Colors.white38, fontSize: 9))),
                      Expanded(child: Text(whiteMove, style: TextStyle(color: isWhiteHighlight ? AppColors.cyan : Colors.white, fontSize: 10))),
                      Expanded(child: Text(blackMove, style: TextStyle(color: isBlackHighlight ? AppColors.pink : Colors.white, fontSize: 10))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPieceIcon(String p) {
    if (p.isEmpty) return const SizedBox();
    final color = _isWhite(p) ? Colors.white : AppColors.pink;
    IconData icon;
    switch (p.toLowerCase()) {
      case 'p': icon = Icons.person_outline; break;
      case 'r': icon = Icons.castle_rounded; break;
      case 'n': icon = Icons.psychology_alt_rounded; break;
      case 'b': icon = Icons.explore_outlined; break;
      case 'q': icon = Icons.workspace_premium_rounded; break;
      case 'k': icon = Icons.military_tech_rounded; break;
      default: return const SizedBox();
    }
    return Icon(icon, color: color, size: 24, shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]);
  }
}

class Position {
  final int row;
  final int col;
  Position(this.row, this.col);
}

class MoveRecord {
  final String notation;
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final String piece;
  final bool captured;
  final bool isWhite;
  final String? promotion;
  final String? castle;

  MoveRecord({
    required this.notation,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.piece,
    required this.captured,
    required this.isWhite,
    this.promotion,
    this.castle,
  });
}

class ChessLaunchDialog extends StatefulWidget {
  const ChessLaunchDialog({super.key});

  @override
  State<ChessLaunchDialog> createState() => _ChessLaunchDialogState();
}

class _ChessLaunchDialogState extends State<ChessLaunchDialog> {
  final p1Controller = TextEditingController(text: "Player White");
  final p2Controller = TextEditingController(text: "Player Black");

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
        title: const NeonText(text: "INITIALIZE CHESS", color: AppColors.amber, fontSize: 14),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassInput(controller: p1Controller, hint: "Player White", accentColor: Colors.white),
            const SizedBox(height: 15),
            GlassInput(controller: p2Controller, hint: "Player Black", accentColor: Colors.white54),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, 2),
              icon: const Icon(Icons.help_outline_rounded,
                  size: 16, color: AppColors.amber),
              label: const Text(
                'HOW TO PLAY',
                style: TextStyle(
                    color: AppColors.amber, fontSize: 10, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 10),
            GlassButton(
              label: "LAUNCH",
              color: AppColors.amber,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, slideUpRoute(page: ChessGame(p1: p1Controller.text, p2: p2Controller.text)));
              },
            ),
          ],
        ),
      ),
    );
  }
}

void showChessDialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const ChessLaunchDialog());
}