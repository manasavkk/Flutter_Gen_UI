import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Builds the catalog of widgets the model is allowed to generate.
Catalog buildCatalog() => BasicCatalogItems.asCatalog().copyWith(
  newItems: [checkpointCard, funFactCard],
);

/// A road-trip I-Spy checkpoint card — content only, no button.
/// Player buttons are rendered by Flutter outside the surface.
final checkpointCard = CatalogItem(
  name: 'CheckpointCard',
  dataSchema: Schema.fromMap({
    'type': 'object',
    'properties': {
      'emoji': {'type': 'string'},
      'landmark': {'type': 'string'},
      'hint': {'type': 'string'},
      'points': {'type': 'integer'},
      'checkpoint_id': {'type': 'string'},
    },
    'required': ['emoji', 'landmark', 'hint', 'points', 'checkpoint_id'],
  }),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    final emoji = (data['emoji'] as String?) ?? '📍';
    final landmark = (data['landmark'] as String?) ?? '';
    final hint = (data['hint'] as String?) ?? '';
    final points = (data['points'] as int?) ?? 10;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2855), Color(0xFF251050)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.25), width: 1.5),
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
              Text(emoji, style: const TextStyle(fontSize: 56)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                ),
                child: Text(
                  '+$points pts',
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
            landmark,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  },
);

/// Fun fact card revealed after a landmark is spotted.
final funFactCard = CatalogItem(
  name: 'FunFactCard',
  dataSchema: Schema.fromMap({
    'type': 'object',
    'properties': {
      'emoji': {'type': 'string'},
      'landmark': {'type': 'string'},
      'fact': {'type': 'string'},
    },
    'required': ['emoji', 'landmark', 'fact'],
  }),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    final emoji = (data['emoji'] as String?) ?? '✨';
    final landmark = (data['landmark'] as String?) ?? '';
    final fact = (data['fact'] as String?) ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2218),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  landmark,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fact,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  },
);
