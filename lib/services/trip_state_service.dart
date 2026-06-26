import 'package:supabase_flutter/supabase_flutter.dart';

class TripState {
  const TripState({
    this.passengerType,
    this.passengerName,
    this.currentCity = 'San Francisco',
  });

  final String? passengerType;
  final String? passengerName;
  final String currentCity;

  factory TripState.fromMap(Map<String, dynamic> map) => TripState(
        passengerType: map['passenger_type'] as String?,
        passengerName: map['passenger_name'] as String?,
        currentCity: (map['current_city'] as String?) ?? 'San Francisco',
      );
}

class TripStateService {
  TripStateService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Stream<TripState> get stream => _client
      .from('trip_state')
      .stream(primaryKey: ['id'])
      .eq('id', 1)
      .map(
        (rows) => rows.isEmpty
            ? const TripState()
            : TripState.fromMap(rows.first),
      );

  Future<void> updatePassenger({
    required String passengerType,
    required String passengerName,
  }) async {
    await _client.from('trip_state').update({
      'passenger_type': passengerType,
      'passenger_name': passengerName,
    }).eq('id', 1);
  }

  Future<void> reset() async {
    await _client.from('trip_state').update({
      'passenger_type': null,
      'passenger_name': null,
    }).eq('id', 1);
  }
}
