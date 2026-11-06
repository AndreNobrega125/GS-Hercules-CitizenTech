import 'package:flutter/material.dart';

/// Cartão padrão dos dashboards: título, legenda curta e um gráfico.
/// [summary] é lido por leitores de tela no lugar do gráfico.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.summary,
    required this.child,
    this.caption,
    this.height = 200,
  });

  final String title;
  final String summary;
  final String? caption;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, style: text.bodySmall),
            ],
            const SizedBox(height: 16),
            Semantics(
              label: '$title. $summary',
              excludeSemantics: true,
              child: SizedBox(height: height, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
