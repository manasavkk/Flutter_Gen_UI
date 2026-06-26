/// Fallback prompt (used by conversation.dart when no custom prompt is given).
const String systemPrompt = '''
You are an in-car AI co-pilot. Generate a clean welcome interface.
''';

/// Checkpoint data for the Salesforce Tower → Ocean Beach route.
const List<({String landmark, String emoji, String hint, int points})>
    kCheckpoints = [
  (
    landmark: 'Ferry Building',
    emoji: '🏛️',
    hint: 'Look for the giant clock tower right by the water!',
    points: 10,
  ),
  (
    landmark: 'Union Square',
    emoji: '🛍️',
    hint: 'Spot the big open plaza with the tall victory column!',
    points: 15,
  ),
  (
    landmark: 'City Hall',
    emoji: '⭐',
    hint: 'Can you see the massive golden dome shining in the sky?',
    points: 20,
  ),
  (
    landmark: 'Painted Ladies',
    emoji: '🏠',
    hint: 'Find the row of colourful Victorian houses facing the park!',
    points: 20,
  ),
  (
    landmark: 'Golden Gate Park Windmills',
    emoji: '💨',
    hint: 'Look for the giant old windmill right next to the beach!',
    points: 25,
  ),
];

/// System prompt for the sequential one-card-at-a-time checkpoint game.
String buildGameSystemPrompt(List<String> playerNames) => '''
You are an I-Spy road trip game host for ${playerNames.join(' and ')} driving from Salesforce Tower to Ocean Beach in San Francisco.

CRITICAL FORMAT RULE: Every component must have its own unique "id". Children arrays must contain ONLY id strings — never inline objects.
''';

/// Builds the user message for a checkpoint.
/// Includes the full surface + component spec in every message — this is what
/// reliably triggers CreateSurface from the model (same pattern as working prompts).
String buildCheckpointMessage(int index, String? previousStatus) {
  final cp = kCheckpoints[index];
  final prefix = previousStatus != null ? '$previousStatus. ' : '';
  return '''${prefix}Generate a surface with surface id "game". Components:
- id "root": Column, children: ["card"]
- id "card": CheckpointCard — emoji "${cp.emoji}", landmark "${cp.landmark}", hint "${cp.hint}", points ${cp.points}, checkpoint_id "cp${index + 1}"''';
}

/// System prompt for the fun-fact session.
String buildFactSystemPrompt() => '''
You generate fun fact widgets about San Francisco landmarks for kids.

CRITICAL FORMAT RULE: Every component must have its own unique "id". Children arrays must contain ONLY id strings — never inline objects.

For each request, generate a surface with surface id "facts":
- id "root": Column, children: ["fact1"]
- id "fact1": FunFactCard — use the landmark and emoji I give you, write one amazing surprising kid-friendly fact (make them say "WOAH really?!")
''';
