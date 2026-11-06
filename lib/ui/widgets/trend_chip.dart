import 'package:flutter/material.dart';

import '../../domain/trend.dart';

/// Indicador de tendência com ícone e texto (nunca só cor).
class TrendChip extends StatelessWidget {
  const TrendChip({super.key, required this.label, required this.trend});

  final String label;
  final Trend trend;

  @override
  Widget build(BuildContext context) {
    final (icon, word) = switch (trend) {
      Trend.rising => (Icons.trending_up, 'em alta'),
      Trend.falling => (Icons.trending_down, 'em queda'),
      Trend.stable => (Icons.trending_flat, 'estável'),
    };
    return Semantics(
      label: '$label: $word',
      excludeSemantics: true,
      child: Chip(avatar: Icon(icon, size: 18), label: Text('$label $word')),
    );
  }
}
