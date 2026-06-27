/// Checkpoints along the Salesforce Tower → Ocean Beach route.
/// All worth the same points so no landmark feels more important than another.
const List<({String landmark, String emoji, String hint, int points})>
    kCheckpoints = [
  (
    landmark: 'Ferry Building',
    emoji: '🏛️',
    hint: 'Look for the giant clock tower right by the water!',
    points: 20,
  ),
  (
    landmark: 'Union Square',
    emoji: '🛍️',
    hint: 'Spot the big open plaza with the tall victory column!',
    points: 20,
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
    points: 20,
  ),
];

/// System prompt for the checkpoint card session.
///
/// The session uses auto-surface mode — a `createSurface` for "game" is
/// injected before every model response, so the model only needs to emit
/// `updateComponents`. Keep this prompt minimal and focused.
String buildGameSystemPrompt(List<String> playerNames) => '''
You render I-Spy checkpoint cards for ${playerNames.join(' and ')} on a road trip from Salesforce Tower to Ocean Beach in San Francisco.

For each request output EXACTLY ONE `updateComponents` JSON block for surfaceId "game".
The root component must be a Column containing a single CheckpointCard.
Use the emoji, landmark, hint, and points values exactly as given.
Output only the JSON block — no explanation, no other text.
''';

/// Builds the user message for a given checkpoint index.
String buildCheckpointMessage(int index, {String? previousStatus}) {
  final cp = kCheckpoints[index];
  final prefix = previousStatus != null ? '$previousStatus. ' : '';
  return '${prefix}Show checkpoint ${index + 1}: '
      'emoji "${cp.emoji}", landmark "${cp.landmark}", '
      'hint "${cp.hint}", points ${cp.points}.';
}
