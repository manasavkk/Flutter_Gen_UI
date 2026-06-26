import 'dart:async';

/// Broadcasts "I Spy It!" taps from CheckpointCard widgets to the page.
///
/// GenUI's UserActionEvent routes through the LLM, which isn't what we want
/// here — we need immediate Flutter-side handling (points, who-found-it sheet,
/// fact generation). This lightweight broadcast stream decouples the catalog
/// widget from the page without requiring InheritedWidget or Provider.
class SpottedNotifier {
  SpottedNotifier._();

  static final StreamController<Map<String, dynamic>> _ctrl =
      StreamController.broadcast();

  /// Listen to this in the page to handle spotted events.
  static Stream<Map<String, dynamic>> get stream => _ctrl.stream;

  /// Called from CheckpointCard when the "I Spy It!" button is tapped.
  static void notify(Map<String, dynamic> context) => _ctrl.add(context);
}
