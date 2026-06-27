import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_template/catalog.dart';
import 'package:genui_template/model/model_client.dart';

/// The catalog ID registered by BasicCatalogItems — required for CreateSurface.
const _kCatalogId = 'https://a2ui.org/specification/v0_9/basic_catalog.json';

/// Owns the GenUI pipeline for a single screen and disposes it as a unit.
///
/// When [autoSurfaceId] is provided the session operates in **auto-surface
/// mode**: before every model response we inject a synthetic `createSurface`
/// message so that the surface already exists by the time the model emits
/// `updateComponents`. The model is then prompted with `updateOnly` so it
/// never has to worry about creating surfaces — it just fills in components.
/// This is the reliable pattern for models that consistently emit
/// `updateComponents` without a preceding `createSurface`.
class GenUiSession {
  GenUiSession({
    required ModelClient Function({required String systemPrompt})
        modelClientBuilder,
    String? systemPromptText,
    String? autoSurfaceId,
  }) : _autoSurfaceId = autoSurfaceId {
    final catalog = buildCatalog();
    _controller = SurfaceController(catalogs: [catalog]);

    // In auto-surface mode use updateOnly so the system prompt tells the model
    // to only emit updateComponents — we handle createSurface ourselves.
    final promptBuilder = autoSurfaceId != null
        ? PromptBuilder.custom(
            catalog: catalog,
            allowedOperations: SurfaceOperations.updateOnly(dataModel: false),
            systemPromptFragments: [systemPromptText ?? ''],
          )
        : PromptBuilder.chat(
            catalog: catalog,
            systemPromptFragments: [systemPromptText ?? ''],
          );

    _modelClient = modelClientBuilder(
      systemPrompt: promptBuilder.systemPromptJoined(),
    );

    _transport = A2uiTransportAdapter(
      onSend: (message) async {
        // Auto-inject createSurface before the model response so that the
        // model's updateComponents always lands on an existing surface.
        if (_autoSurfaceId != null) {
          _transport.addChunk(
            '```json\n'
            '{"type":"createSurface",'
            '"surfaceId":"$_autoSurfaceId",'
            '"catalogId":"$_kCatalogId",'
            '"sendDataModel":true}\n'
            '```\n',
          );
        }
        await _modelClient
            .sendMessage(_promptFor(message))
            .forEach(_transport.addChunk);
      },
    );

    _conversation = Conversation(
      controller: _controller,
      transport: _transport,
    );
  }

  final String? _autoSurfaceId;
  late final SurfaceController _controller;
  late final ModelClient _modelClient;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;

  ValueListenable<String> get a2uiSource => _modelClient.latestResponse;
  ValueListenable<ConversationState> get conversationState =>
      _conversation.state;
  Stream<ConversationEvent> get events => _conversation.events;

  void sendMessage(String text) =>
      _conversation.sendRequest(ChatMessage.user(text));

  static String _promptFor(ChatMessage message) {
    if (message.text.trim().isNotEmpty) return message.text;
    return message.parts.uiInteractionParts
        .map((part) => part.interaction)
        .join('\n');
  }

  SurfaceContext contextFor(String surfaceId) =>
      _conversation.controller.contextFor(surfaceId);

  void dispose() {
    _conversation.dispose();
    _transport.dispose();
    _controller.dispose();
    _modelClient.dispose();
  }
}
