import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerScore {
  const PlayerScore({required this.name, required this.score});
  final String name;
  final int score;
}

/// Syncs player scores to Supabase `scores` table and polls for live updates.
///
/// All Supabase operations are best-effort — failures are silently ignored so
/// the app works fully offline if the table doesn't exist or auth fails.
class LeaderboardService {
  LeaderboardService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  /// Upserts a single player's score.
  Future<void> upsertScore(String playerName, int score) async {
    try {
      await _client.from('scores').upsert(
        {'player_name': playerName, 'score': score},
        onConflict: 'player_name',
      );
    } catch (_) {}
  }

  /// Resets all players to 0 at the start of a new journey.
  Future<void> resetScores(List<String> playerNames) async {
    for (final name in playerNames) {
      await upsertScore(name, 0);
    }
  }

  /// Polls Supabase every 3 seconds for the latest leaderboard.
  Stream<List<PlayerScore>> watchScores() => Stream.periodic(
    const Duration(seconds: 3),
  ).asyncMap((_) => _fetchScores());

  Future<List<PlayerScore>> _fetchScores() async {
    try {
      final data = await _client
          .from('scores')
          .select()
          .order('score', ascending: false);
      return (data as List)
          .map(
            (row) => PlayerScore(
              name: row['player_name'] as String,
              score: row['score'] as int,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
