import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui_template/prompt.dart';
import 'package:genui_template/services/leaderboard_service.dart';

// ─── Route timing ─────────────────────────────────────────────────────────────
// Seconds AFTER "Start Ride" when cp2–cp5 appear.
// cp1 is pre-loaded before the ride starts.
const List<int> _kRideArrival = [
  0,   // cp1 — pre-loaded, not used by timer
  20,  // cp2 appears 20 s after ride start
  40,  // cp3
  60,  // cp4
  78,  // cp5
];
const int _kTotal = 90; // journey ends this many seconds after ride start

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Onboarding ──────────────────────────────────────────────────────────────
  final List<TextEditingController> _nameCtrl = [TextEditingController()];
  bool _journeyStarted = false;
  bool _rideStarted = false; // timer only begins after user taps "Start Ride"

  // ── Players ──────────────────────────────────────────────────────────────────
  List<String> _players = [];
  Map<String, int> _scores = {};


  // ── Checkpoint state ─────────────────────────────────────────────────────────
  int _shownIndex = -1;      // which checkpoint is currently displayed
  int _nextToShow = 0;       // which checkpoint to show next (prevents double-show)
  bool _currentSpotted = false;
  String? _spottedBy;

  // ── Leaderboard ───────────────────────────────────────────────────────────────
  final _leaderboard = LeaderboardService();
  List<PlayerScore> _liveScores = [];
  StreamSubscription<List<PlayerScore>>? _leaderboardSub;

  // ── Timer ─────────────────────────────────────────────────────────────────────
  Timer? _timer;
  int _elapsed = 0;

  bool get _journeyComplete => _rideStarted && _elapsed >= _kTotal;
  double get _progress => (_elapsed / _kTotal).clamp(0.0, 1.0);
  String get _elapsedLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    for (final c in _nameCtrl) c.dispose();
    _leaderboardSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // ─── Journey start ────────────────────────────────────────────────────────────

  void _startJourney() {
    final names =
        _nameCtrl.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return;

    setState(() {
      _players = names;
      _scores = {for (final n in names) n: 0};
      _journeyStarted = true;
      _elapsed = 0;
      _shownIndex = -1;
      _nextToShow = 0;
      _currentSpotted = false;
      _spottedBy = null;
    });

    _leaderboard.resetScores(names);
    _leaderboardSub = _leaderboard.watchScores().listen(
      (s) { if (mounted) setState(() => _liveScores = s); },
    );

    // Show first checkpoint immediately — no AI call needed.
    _sendCheckpoint(0, previousStatus: null);
    // Timer begins only when user presses "Start Ride"
  }

  void _startRide() {
    setState(() {
      _rideStarted = true;
      _elapsed = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      _maybeRevealNext();
      if (_elapsed >= _kTotal) _timer?.cancel();
    });
  }

  void _maybeRevealNext() {
    // _nextToShow is the index of the checkpoint we haven't shown yet
    if (_nextToShow >= kCheckpoints.length) return;
    if (_elapsed >= _kRideArrival[_nextToShow]) {
      _sendCheckpoint(_nextToShow, previousStatus: null);
    }
  }

  /// Advances the displayed checkpoint. No AI call — renders directly from kCheckpoints.
  void _sendCheckpoint(int index, {required String? previousStatus}) {
    if (index >= kCheckpoints.length) return;
    setState(() {
      _shownIndex = index;
      _nextToShow = index + 1;
      _currentSpotted = false;
      _spottedBy = null;
    });
  }

  // ─── Spot handling ────────────────────────────────────────────────────────────

  void _onPlayerSpotted(String playerName) {
    if (_currentSpotted) return; // already claimed
    if (_shownIndex < 0) return;

    final cp = kCheckpoints[_shownIndex];

    setState(() {
      _currentSpotted = true;
      _spottedBy = playerName;
      _scores[playerName] = (_scores[playerName] ?? 0) + cp.points;
    });

    _leaderboard.upsertScore(playerName, _scores[playerName]!);

    // Queue the next checkpoint after a short celebration delay
    if (_nextToShow < kCheckpoints.length) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && !_journeyComplete) {
          _sendCheckpoint(
            _nextToShow,
            previousStatus: '${cp.landmark} spotted by $playerName',
          );
        }
      });
    }
  }

  void _resetJourney() {
    _timer?.cancel();
    _leaderboardSub?.cancel();
    setState(() {
      _journeyStarted = false;
      _rideStarted = false;
      _scores = {};
      _liveScores = [];
      _elapsed = 0;
      _shownIndex = -1;
      _nextToShow = 0;
      _currentSpotted = false;
      _spottedBy = null;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_journeyStarted) return _buildOnboarding();
    if (_journeyComplete) return _buildWinnerBoard();
    return _buildGame();
  }

  // ─── Onboarding ──────────────────────────────────────────────────────────────

  Widget _buildOnboarding() {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚗', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  "Who's on this\nroad trip?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                _routeChip(),
                const SizedBox(height: 30),
                StatefulBuilder(
                  builder: (ctx, inner) => Column(
                    children: [
                      ...List.generate(_nameCtrl.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl[i],
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Player ${i + 1} name…',
                                hintStyle: const TextStyle(color: Colors.white30),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.07),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          if (i > 0) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                _nameCtrl.removeAt(i).dispose();
                                inner(() {});
                              },
                              child: const Icon(Icons.remove_circle_outline,
                                  color: Colors.white30),
                            ),
                          ],
                        ]),
                      )),
                      if (_nameCtrl.length < 4)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              _nameCtrl.add(TextEditingController());
                              inner(() {});
                            },
                            icon: const Icon(Icons.add, color: Colors.white38, size: 18),
                            label: const Text('Add player',
                                style: TextStyle(color: Colors.white38)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _startJourney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                    ),
                    child: const Text("Let's Go! 🚀",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _routeChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('📍', style: TextStyle(fontSize: 13)),
      const SizedBox(width: 8),
      Text(
        'Salesforce Tower  →  Ocean Beach',
        style: const TextStyle(color: Color(0xFF8888AA), fontSize: 13),
      ),
    ]),
  );

  // ─── Game screen ──────────────────────────────────────────────────────────────

  Widget _buildGame() {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: Row(
        children: [
          _buildHud(),
          const VerticalDivider(width: 1, color: Colors.white12),
          Expanded(child: _buildGamePanel()),
        ],
      ),
    );
  }

  // ─── HUD ──────────────────────────────────────────────────────────────────────

  Widget _buildHud() {
    return Container(
      width: 200,
      color: const Color(0xFF0D0D18),
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hudDot(_journeyComplete ? 'ARRIVED' : 'ON ROUTE',
              _journeyComplete ? Colors.amberAccent : const Color(0xFF00FF88)),
          const SizedBox(height: 28),
          const Text('SAN FRANCISCO',
              style: TextStyle(color: Color(0xFF8888AA), fontSize: 9, letterSpacing: 2.5)),
          const SizedBox(height: 6),
          const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('45', style: TextStyle(color: Colors.white, fontSize: 52,
                fontWeight: FontWeight.w200, height: 1)),
            Padding(padding: EdgeInsets.only(bottom: 7, left: 4),
                child: Text('mph', style: TextStyle(color: Color(0xFF8888AA), fontSize: 12))),
          ]),
          const SizedBox(height: 24),
          const Text('PROGRESS', style: TextStyle(
              color: Color(0xFF8888AA), fontSize: 9, letterSpacing: 2)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white12,
              color: Colors.cyanAccent,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_elapsedLabel,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
            Text('${(_progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 28),
          Container(height: 1, color: Colors.white.withOpacity(0.07)),
          const SizedBox(height: 18),
          const Text('SCORES', style: TextStyle(
              color: Color(0xFF8888AA), fontSize: 9, letterSpacing: 2)),
          const SizedBox(height: 10),
          for (final e in (_scores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${e.value} pts', style: const TextStyle(
                      color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          const Spacer(),
          if (!_rideStarted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('🚗 Start Ride',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: _resetJourney,
            child: Text('← End journey',
                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _hudDot(String label, Color color) => Row(children: [
    Container(width: 7, height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(color: color, fontSize: 9,
        letterSpacing: 2, fontWeight: FontWeight.w600)),
  ]);

  // ─── Game panel ───────────────────────────────────────────────────────────────

  Widget _buildGamePanel() {
    return Column(
      children: [
        _buildTopBanner(),
        Expanded(child: _buildCardArea()),
        _buildLeaderboardBar(),
      ],
    );
  }

  Widget _buildTopBanner() {
    if (_shownIndex < 0) {
      return _staticBanner('⏳', 'Loading your first checkpoint…',
          Colors.white38, Colors.transparent);
    }
    if (!_rideStarted) {
      return _staticBanner('✅', 'First checkpoint ready — press Start Ride when set!',
          Colors.cyanAccent, Colors.cyanAccent.withOpacity(0.05));
    }
    final cpNum = _shownIndex + 1;
    final total = kCheckpoints.length;
    if (_currentSpotted) {
      return _staticBanner('🎉',
          '$_spottedBy spotted it! +${kCheckpoints[_shownIndex].points} pts',
          Colors.amberAccent, Colors.amberAccent.withOpacity(0.06));
    }
    // Countdown when next checkpoint is <5 s away
    if (_nextToShow < kCheckpoints.length) {
      final secsUntilNext = _kRideArrival[_nextToShow] - _elapsed;
      if (secsUntilNext > 0 && secsUntilNext <= 5) {
        return _staticBanner('⏱️',
            'Next landmark in $secsUntilNext second${secsUntilNext == 1 ? '' : 's'}…',
            Colors.orangeAccent, Colors.orangeAccent.withOpacity(0.07));
      }
    }
    return _PulsingBanner(
      icon: '👀',
      text: 'Checkpoint $cpNum of $total — can you see it?',
    );
  }

  Widget _staticBanner(String icon, String text, Color textColor, Color bg) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: bg,
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: textColor, fontSize: 13,
              fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _buildCardArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Checkpoint card — rendered directly from kCheckpoints for instant load
          if (_shownIndex < 0)
            _waitingWidget('Get ready…')
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _currentSpotted
                  ? _buildSpottedOverlay()
                  : _buildCheckpointCard(_shownIndex),
            ),

          const SizedBox(height: 20),

          // Per-player spot buttons (only while ride is running and card not yet spotted)
          if (_rideStarted && _shownIndex >= 0 && !_currentSpotted)
            _buildPlayerButtons(),
        ],
      ),
    );
  }

  /// Renders a checkpoint card directly from the hardcoded data — instant, no AI.
  Widget _buildCheckpointCard(int index) {
    final cp = kCheckpoints[index];
    return Container(
        key: ValueKey('cp_$index'),
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2855), Color(0xFF251050)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Colors.cyanAccent.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cp.emoji, style: const TextStyle(fontSize: 56)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.amberAccent.withOpacity(0.4)),
                  ),
                  child: Text(
                    '+${cp.points} pts',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              cp.landmark,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cp.hint,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
    );
  }

  Widget _waitingWidget(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 14)),
    ),
  );

  Widget _buildSpottedOverlay() => Container(
    key: const ValueKey('spotted'),
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: const Color(0xFF0A2A10),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.greenAccent.withOpacity(0.4), width: 1.5),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🎉', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text('$_spottedBy spotted it!',
          style: const TextStyle(color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('+${kCheckpoints[_shownIndex].points} pts',
          style: const TextStyle(color: Colors.greenAccent, fontSize: 18,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Next checkpoint coming up…',
          style: TextStyle(color: Colors.white38, fontSize: 13)),
    ]),
  );

  Widget _buildPlayerButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _players.map((name) => SizedBox(
        width: (_players.length == 1)
            ? double.infinity
            : (MediaQuery.of(context).size.width - 200 - 48 - 12) / 2,
        child: ElevatedButton(
          onPressed: () => _onPlayerSpotted(name),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent.withOpacity(0.12),
            foregroundColor: Colors.cyanAccent,
            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.4)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text('👀  $name saw it!',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      )).toList(),
    );
  }

  // ─── Leaderboard bar ─────────────────────────────────────────────────────────

  Widget _buildLeaderboardBar() {
    final scores = _liveScores.isNotEmpty
        ? _liveScores
        : (_scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .map((e) => PlayerScore(name: e.key, score: e.value))
            .toList();

    if (scores.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        const Text('🏆', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        const Text('LEADERBOARD', style: TextStyle(color: Color(0xFF8888AA),
            fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700)),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            children: scores.asMap().entries.map((entry) {
              final i = entry.key;
              final ps = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (i == 0) const Text('👑 ', style: TextStyle(fontSize: 13)),
                  Text(ps.name, style: TextStyle(
                      color: i == 0 ? Colors.amberAccent : Colors.white70,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text('${ps.score} pts', style: TextStyle(
                      color: i == 0 ? Colors.amberAccent : Colors.white38,
                      fontSize: 12)),
                ]),
              );
            }).toList(),
          ),
        ),
        if (_liveScores.isNotEmpty)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: Color(0xFF00FF88), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Text('LIVE', style: TextStyle(color: Color(0xFF00FF88),
                fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          ]),
      ]),
    );
  }

  // ─── Winner board ─────────────────────────────────────────────────────────────

  Widget _buildWinnerBoard() {
    final sorted = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = kCheckpoints.fold(0, (sum, cp) => sum + cp.points);
    final topScore = sorted.isNotEmpty ? sorted.first.value : 0;
    final isTie = sorted.length > 1 && sorted[1].value == topScore;

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isTie ? '🤝' : '🏁', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(isTie ? "It's a Tie!" : 'Journey Complete!',
                    style: TextStyle(
                        color: isTie ? Colors.cyanAccent : Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
                const SizedBox(height: 6),
                Text('Salesforce Tower → Ocean Beach',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                const SizedBox(height: 40),
                ...sorted.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final isTopScore = e.value == topScore;
                  final isTiedPlayer = isTie && isTopScore;
                  // In a tie, all tied players get the same highlight; otherwise rank normally
                  final isHighlighted = isTiedPlayer || (!isTie && i == 0);
                  final medal = isTiedPlayer
                      ? '🤝'
                      : (i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '🎖️');
                  final highlightColor = isTiedPlayer ? Colors.cyanAccent : Colors.amberAccent;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + i * 100),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? highlightColor.withOpacity(0.1)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHighlighted
                            ? highlightColor.withOpacity(0.4)
                            : Colors.white12,
                      ),
                    ),
                    child: Row(children: [
                      Text(medal, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(e.key,
                            style: TextStyle(
                                color: isHighlighted ? highlightColor : Colors.white,
                                fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${e.value} pts',
                            style: TextStyle(
                                color: isHighlighted ? highlightColor : Colors.white60,
                                fontSize: 22, fontWeight: FontWeight.w800)),
                        Text('of $total possible',
                            style: const TextStyle(color: Colors.white30, fontSize: 11)),
                      ]),
                    ]),
                  );
                }),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _resetJourney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                    ),
                    child: const Text('Play Again 🚗',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing banner ───────────────────────────────────────────────────────────

class _PulsingBanner extends StatefulWidget {
  const _PulsingBanner({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  State<_PulsingBanner> createState() => _PulsingBannerState();
}

class _PulsingBannerState extends State<_PulsingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.cyanAccent.withOpacity(0.07),
      child: Row(children: [
        Text(widget.icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(widget.text, style: const TextStyle(
            color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}
