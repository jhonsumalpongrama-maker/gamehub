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

enum SeaBattlePhase { p1Placement, p1ToP2Transition, p2Placement, battle, battleTransition }

enum ShipType { carrier, battleship, cruiser, submarine, destroyer }

class ShipDefinition {
  final ShipType type;
  final String name;
  final int size;
  final Color color;

  const ShipDefinition(this.type, this.name, this.size, this.color);

  static const List<ShipDefinition> fleet = [
    ShipDefinition(ShipType.carrier, 'CARRIER', 5, Color(0xFF00FBFF)),
    ShipDefinition(ShipType.battleship, 'BATTLESHIP', 4, Color(0xFF00C8FF)),
    ShipDefinition(ShipType.cruiser, 'CRUISER', 3, Color(0xFF00A0FF)),
    ShipDefinition(ShipType.submarine, 'SUBMARINE', 3, Color(0xFF0070FF)),
    ShipDefinition(ShipType.destroyer, 'DESTROYER', 2, Color(0xFF0050FF)),
  ];
}

class ShipPlacement {
  final ShipType type;
  final List<int> cells;
  bool isHorizontal;
  bool isSunk;

  ShipPlacement(this.type, this.cells, this.isHorizontal) : isSunk = false;
}

class SeaBattlePage extends BaseGameWidget {
  const SeaBattlePage({super.key, required super.p1, required super.p2})
      : super(gameType: GameType.seaBattle);

  @override
  State<SeaBattlePage> createState() => _SeaBattlePageState();
}

class _SeaBattlePageState extends BaseGameState<SeaBattlePage> {
  SeaBattlePhase phase = SeaBattlePhase.p1Placement;
  List<ShipPlacement> p1Ships = [];
  List<ShipPlacement> p2Ships = [];
  Set<int> p1Guesses = {};
  Set<int> p2Guesses = {};
  bool isPlayer1Turn = true;
  bool isProcessing = false;
  bool isP1Horizontal = true;
  ShipType? selectedShip;
  bool? lastHitWasSunk;
  String? sunkShipName;

  int _movesWithoutCapture = 0;

  @override
  void initState() {
    super.initState();
    _initShips();
  }

  void _initShips() {
    p1Ships = ShipDefinition.fleet.map((def) => ShipPlacement(def.type, [], true)).toList();
    p2Ships = ShipDefinition.fleet.map((def) => ShipPlacement(def.type, [], true)).toList();
  }

  void _resetGame() {
    setState(() {
      phase = SeaBattlePhase.p1Placement;
      _initShips();
      p1Guesses.clear();
      p2Guesses.clear();
      isPlayer1Turn = true;
      isProcessing = false;
      isP1Horizontal = true;
      selectedShip = null;
      lastHitWasSunk = null;
      sunkShipName = null;
      _movesWithoutCapture = 0;
      p1Wins = 0;
      p2Wins = 0;
      draws = 0;
    });
  }

  bool _canPlaceShip(int startCell, int size, bool horizontal, List<ShipPlacement> ships) {
    int row = startCell ~/ 10;
    int col = startCell % 10;

    if (horizontal) {
      if (col + size > 10) return false;
    } else {
      if (row + size > 10) return false;
    }

    List<int> cells = [];
    for (int i = 0; i < size; i++) {
      int cell = horizontal ? row * 10 + col + i : (row + i) * 10 + col;
      cells.add(cell);
    }

    for (int cell in cells) {
      if (_isAdjacentToShip(cell, ships)) return false;
    }

    return true;
  }

  bool _isAdjacentToShip(int cell, List<ShipPlacement> ships) {
    int row = cell ~/ 10;
    int col = cell % 10;

    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        int adjRow = row + dr;
        int adjCol = col + dc;
        if (adjRow < 0 || adjRow >= 10 || adjCol < 0 || adjCol >= 10) continue;
        int adjCell = adjRow * 10 + adjCol;
        for (var ship in ships) {
          if (ship.cells.contains(adjCell) && !ship.cells.contains(cell)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _placeShip(int startCell) {
    if (selectedShip == null) return;

    List<ShipPlacement> currentShips = phase == SeaBattlePhase.p1Placement ? p1Ships : p2Ships;
    ShipDefinition def = ShipDefinition.fleet.firstWhere((d) => d.type == selectedShip);

    if (!_canPlaceShip(startCell, def.size, isP1Horizontal, currentShips)) return;

    int row = startCell ~/ 10;
    int col = startCell % 10;
    List<int> cells = [];
    for (int i = 0; i < def.size; i++) {
      int cell = isP1Horizontal ? row * 10 + col + i : (row + i) * 10 + col;
      cells.add(cell);
    }

    setState(() {
      ShipPlacement ship = currentShips.firstWhere((s) => s.type == selectedShip);
      ship.cells.clear();
      ship.cells.addAll(cells);
      ship.isHorizontal = isP1Horizontal;
      selectedShip = null;
    });
  }

  void _removeShip(ShipType type) {
    List<ShipPlacement> currentShips = phase == SeaBattlePhase.p1Placement ? p1Ships : p2Ships;
    setState(() {
      ShipPlacement ship = currentShips.firstWhere((s) => s.type == type);
      ship.cells.clear();
    });
  }

  bool _allShipsPlaced(List<ShipPlacement> ships) {
    return ships.every((s) => s.cells.isNotEmpty);
  }

  void _confirmPlacement() {
    if (phase == SeaBattlePhase.p1Placement) {
      setState(() => phase = SeaBattlePhase.p1ToP2Transition);
    } else if (phase == SeaBattlePhase.p2Placement) {
      setState(() {
        phase = SeaBattlePhase.battle;
        isPlayer1Turn = true;
      });
    }
  }

  void _startP2Placement() {
    setState(() {
      phase = SeaBattlePhase.p2Placement;
      isP1Horizontal = true;
      selectedShip = null;
    });
  }

  void _attack(int cell) async {
    final currentGuesses = isPlayer1Turn ? p1Guesses : p2Guesses;
    if (currentGuesses.contains(cell) || isProcessing) return;

    setState(() {
      isProcessing = true;
      if (isPlayer1Turn) {
        p1Guesses.add(cell);
      } else {
        p2Guesses.add(cell);
      }
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    List<ShipPlacement> enemyShips = isPlayer1Turn ? p2Ships : p1Ships;
    bool isHit = enemyShips.any((s) => s.cells.contains(cell));

    ShipPlacement? hitShip;
    for (var ship in enemyShips) {
      if (ship.cells.contains(cell)) {
        hitShip = ship;
        break;
      }
    }

    bool shipSunk = false;
    if (hitShip != null) {
      bool allCellsHit = hitShip.cells.every((c) =>
        (isPlayer1Turn ? p1Guesses : p2Guesses).contains(c)
      );
      if (allCellsHit) {
        shipSunk = true;
        hitShip.isSunk = true;
        sunkShipName = ShipDefinition.fleet.firstWhere((d) => d.type == hitShip!.type).name;
        _movesWithoutCapture = 0;
      }
    }

    setState(() {
      isProcessing = false;
      lastHitWasSunk = shipSunk ? true : (isHit ? false : null);
      _movesWithoutCapture++;
    });

    if (shipSunk) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        lastHitWasSunk = null;
        sunkShipName = null;
      });
    } else if (isHit) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    bool p1FleetDestroyed = p1Ships.every((s) =>
      s.cells.every((c) => p2Guesses.contains(c))
    );
    bool p2FleetDestroyed = p2Ships.every((s) =>
      s.cells.every((c) => p1Guesses.contains(c))
    );

    if (p2FleetDestroyed) {
      p1Wins++;
      await saveP1Win();
      if (mounted) _showWinDialog(isPlayer1: true);
    } else if (p1FleetDestroyed) {
      p2Wins++;
      await saveP2Win();
      if (mounted) _showWinDialog(isPlayer1: false);
    } else if (_movesWithoutCapture >= 80) {
      draws++;
      await saveDraw();
      if (mounted) _showDrawDialog();
    } else {
      setState(() {
        phase = SeaBattlePhase.battleTransition;
      });
    }
  }

  void _confirmBattleTransition() {
    setState(() {
      isPlayer1Turn = !isPlayer1Turn;
      phase = SeaBattlePhase.battle;
    });
  }

  void _showWinDialog({required bool isPlayer1}) {
    String winner = isPlayer1 ? widget.p1 : widget.p2;
    Color winColor = isPlayer1 ? AppColors.cyan : AppColors.pink;
    showResultDialog(
      title: "VICTORY",
      message: "$winner VICTORIOUS\nEnemy fleet neutralized",
      color: winColor,
    );
  }

  void _showDrawDialog() {
    showResultDialog(
      title: "DRAW",
      message: "Naval supremacy unresolved",
      color: AppColors.amber,
      isDraw: true,
    );
  }

  @override
  void onRematch() {
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              (isPlayer1Turn ? AppColors.cyan : AppColors.pink).withValues(alpha: 0.05),
              AppColors.bg,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 10),
                  buildScoreDashboard(),
                  const SizedBox(height: 10),
                  if (phase == SeaBattlePhase.battle) ...[
                    _buildBattleHeader(),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "YOUR FLEET",
                            style: TextStyle(
                              color: isPlayer1Turn ? AppColors.cyan : AppColors.pink,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                          Expanded(child: isPlayer1Turn ? _buildBattleGrid() : _buildEnemyGrid()),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "ATTACK",
                            style: TextStyle(
                              color: isPlayer1Turn ? AppColors.cyan : AppColors.pink,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                          Expanded(child: isPlayer1Turn ? _buildEnemyGrid() : _buildBattleGrid()),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildPlacementHeader(),
                    Expanded(child: _buildPlacementGrid()),
                    _buildShipSelector(),
                    _buildPlacementControls(),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
              if (phase == SeaBattlePhase.p1ToP2Transition) _buildTransitionOverlay(),
              if (phase == SeaBattlePhase.battleTransition) _buildBattleTransitionOverlay(),
              if (lastHitWasSunk != null) _buildSunkBanner(),
              if (phase == SeaBattlePhase.battle) _buildBattleControls(),
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            phase == SeaBattlePhase.battle ? "SEA BATTLE OS" : "DEPLOYMENT PHASE",
            style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white38),
            onPressed: _resetGame,
          ),
        ],
      ),
    );
  }

  Widget _buildBattleHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        isPlayer1Turn ? "${widget.p1} - SELECT TARGET" : "${widget.p2} - SELECT TARGET",
        style: TextStyle(
          color: isPlayer1Turn ? AppColors.cyan : AppColors.pink,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildPlacementHeader() {
    String playerName = phase == SeaBattlePhase.p1Placement ? widget.p1 : widget.p2;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(
            "$playerName - DEPLOY YOUR FLEET",
            style: TextStyle(
              color: phase == SeaBattlePhase.p1Placement ? AppColors.cyan : AppColors.pink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => isP1Horizontal = true),
                icon: Icon(Icons.arrow_forward, size: 16, color: isP1Horizontal ? Colors.white : Colors.white38),
                label: Text("HORIZONTAL", style: TextStyle(color: isP1Horizontal ? Colors.white : Colors.white38, fontSize: 10)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => isP1Horizontal = false),
                icon: Icon(Icons.arrow_downward, size: 16, color: !isP1Horizontal ? Colors.white : Colors.white38),
                label: Text("VERTICAL", style: TextStyle(color: !isP1Horizontal ? Colors.white : Colors.white38, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipSelector() {
    List<ShipPlacement> currentShips = phase == SeaBattlePhase.p1Placement ? p1Ships : p2Ships;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: currentShips.length,
        itemBuilder: (context, index) {
          ShipPlacement ship = currentShips[index];
          ShipDefinition def = ShipDefinition.fleet[index];
          bool isPlaced = ship.cells.isNotEmpty;
          bool isSelected = selectedShip == ship.type;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isSelected) {
                  selectedShip = null;
                } else {
                  selectedShip = ship.type;
                }
              });
            },
            onLongPress: isPlaced ? () {
              HapticFeedback.lightImpact();
              _removeShip(ship.type);
            } : null,
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? def.color.withValues(alpha: 0.3) : AppColors.glassBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPlaced ? AppColors.green.withValues(alpha: 0.5) : (isSelected ? def.color : AppColors.glassBorder),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      def.size,
                      (i) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isPlaced ? AppColors.green : def.color.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${def.size}",
                    style: TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ],
              ),
            ).animate(target: isPlaced ? 1 : 0).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 200.ms,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlacementControls() {
    List<ShipPlacement> currentShips = phase == SeaBattlePhase.p1Placement ? p1Ships : p2Ships;
    bool allPlaced = _allShipsPlaced(currentShips);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassButton(
        label: allPlaced ? "CONFIRM FORMATION" : "PLACE ALL SHIPS",
        color: phase == SeaBattlePhase.p1Placement ? AppColors.cyan : AppColors.pink,
        enabled: allPlaced,
        onPressed: _confirmPlacement,
      ),
    );
  }

  Widget _buildPlacementGrid() {
    List<ShipPlacement> currentShips = phase == SeaBattlePhase.p1Placement ? p1Ships : p2Ships;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          bool hasShip = false;
          ShipType? shipType;
          for (var ship in currentShips) {
            if (ship.cells.contains(index)) {
              hasShip = true;
              shipType = ship.type;
              break;
            }
          }

          bool isHovered = false;
          if (selectedShip != null) {
            ShipDefinition def = ShipDefinition.fleet.firstWhere((d) => d.type == selectedShip);
            int row = index ~/ 10;
            int col = index % 10;
            int startRow = index ~/ 10;
            int startCol = index % 10;
            if (isP1Horizontal) {
              isHovered = col >= startCol && col < startCol + def.size && row == startRow;
            } else {
              isHovered = row >= startRow && row < startRow + def.size && col == startCol;
            }
          }

          return GestureDetector(
            onTap: () {
              if (selectedShip != null) {
                _placeShip(index);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: hasShip
                    ? (ShipDefinition.fleet.firstWhere((d) => d.type == shipType).color.withValues(alpha: 0.3))
                    : (isHovered ? AppColors.cyan.withValues(alpha: 0.3) : AppColors.glassBase),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: hasShip
                      ? ShipDefinition.fleet.firstWhere((d) => d.type == shipType).color
                      : (isHovered ? AppColors.cyan : AppColors.glassBorder),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBattleGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          bool hasShip = p1Ships.any((s) => s.cells.contains(index));
          bool wasHit = hasShip && p2Guesses.contains(index);
          bool wasMiss = !hasShip && p2Guesses.contains(index);

          return Container(
            decoration: BoxDecoration(
              color: wasHit
                  ? AppColors.pink.withValues(alpha: 0.2)
                  : (wasMiss
                      ? AppColors.glassBase
                      : (hasShip ? AppColors.cyan.withValues(alpha: 0.15) : AppColors.glassBase)),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: wasHit ? AppColors.pink : (hasShip ? AppColors.cyan : AppColors.glassBorder)),
            ),
            child: Center(
              child: wasHit
                  ? Icon(Icons.close, color: AppColors.pink, size: 14).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 200.ms,
                    )
                  : (wasMiss
                      ? Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnemyGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          final enemyShips = isPlayer1Turn ? p2Ships : p1Ships;
          final myGuesses = isPlayer1Turn ? p1Guesses : p2Guesses;
          bool wasHit = enemyShips.any((s) => s.cells.contains(index)) && myGuesses.contains(index);
          bool wasMiss = !enemyShips.any((s) => s.cells.contains(index)) && myGuesses.contains(index);

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _attack(index);
            },
            child: Container(
              decoration: BoxDecoration(
                color: wasHit ? AppColors.cyan.withValues(alpha: 0.2) : AppColors.glassBase,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: wasHit ? AppColors.cyan : AppColors.glassBorder),
              ),
              child: Center(
                child: wasHit
                    ? Icon(Icons.close, color: AppColors.cyan, size: 14)
                    : (wasMiss
                        ? Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBattleControls() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.glassBase,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            isPlayer1Turn ? "${widget.p1}'S TURN" : "${widget.p2}'S TURN",
            style: TextStyle(
              color: isPlayer1Turn ? AppColors.cyan : AppColors.pink,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransitionOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vpn_key_outlined, color: AppColors.cyan, size: 80),
            const SizedBox(height: 30),
            Text(
              "PASS DEVICE TO ${widget.p2}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "HIDDEN FROM VIEW",
              style: TextStyle(color: Colors.white38, letterSpacing: 2),
            ),
            const SizedBox(height: 60),
            GlassButton(
              label: "I AM ${widget.p2.toUpperCase()}",
              color: AppColors.pink,
              onPressed: _startP2Placement,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleTransitionOverlay() {
    String nextPlayer = isPlayer1Turn ? widget.p2 : widget.p1;
    Color nextColor = isPlayer1Turn ? AppColors.pink : AppColors.cyan;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vpn_key_outlined, color: nextColor, size: 80),
            const SizedBox(height: 30),
            Text(
              "PASS DEVICE TO $nextPlayer",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "HIDDEN FROM VIEW",
              style: TextStyle(color: Colors.white38, letterSpacing: 2),
            ),
            const SizedBox(height: 60),
            GlassButton(
              label: "I AM ${nextPlayer.toUpperCase()}",
              color: nextColor,
              onPressed: _confirmBattleTransition,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunkBanner() {
    return Positioned(
      top: 150,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.checkRed.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: AppColors.checkRed.withValues(alpha: 0.5), blurRadius: 20),
            ],
          ),
          child: Text(
            "SHIP SUNK! $sunkShipName",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ).animate().fadeIn(duration: 200.ms).then().shimmer(
          duration: 1000.ms,
          color: Colors.white24,
        ).then().fadeOut(delay: 1000.ms),
      ),
    );
  }
}

class SeaBattleLaunchDialog extends StatefulWidget {
  const SeaBattleLaunchDialog({super.key});

  @override
  State<SeaBattleLaunchDialog> createState() => _SeaBattleLaunchDialogState();
}

class _SeaBattleLaunchDialogState extends State<SeaBattleLaunchDialog> {
  final p1Controller = TextEditingController(text: "Fleet A");
  final p2Controller = TextEditingController(text: "Fleet B");

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
          text: "INITIALIZE SEA BATTLE",
          color: AppColors.cyan,
          fontSize: 14,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassInput(
              controller: p1Controller,
              hint: "Fleet A",
              accentColor: AppColors.cyan,
            ),
            const SizedBox(height: 15),
            GlassInput(
              controller: p2Controller,
              hint: "Fleet B",
              accentColor: AppColors.pink,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, 1),
              icon: const Icon(Icons.help_outline_rounded,
                  size: 16, color: AppColors.cyan),
              label: const Text(
                'HOW TO PLAY',
                style: TextStyle(
                    color: AppColors.cyan, fontSize: 10, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 10),
            GlassButton(
              label: "LAUNCH",
              color: AppColors.cyan,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  slideUpRoute(
                    page: SeaBattlePage(p1: p1Controller.text, p2: p2Controller.text),
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

void showSeaBattleDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const SeaBattleLaunchDialog(),
  );
}