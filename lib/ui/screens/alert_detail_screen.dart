import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/territory_alert.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_style.dart';
import '../widgets/empty_state.dart';

/// Detalhe de um alerta: evidência, confiança, limitações e aviso humano.
/// O [alertId] vem do parâmetro de rota (`/alerts/:id`).
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    final alert = context.watch<TerritoryProvider>().alertById(alertId);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: alert == null
          ? const EmptyState(
              icon: Icons.search_off,
              message: 'Este alerta não está mais ativo.',
            )
          : _Detail(alert: alert),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = AlertStyle.of(context, alert.severity);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(alert.title, style: text.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              backgroundColor: style.background,
              avatar: Icon(style.icon, size: 18, color: style.foreground),
              label: Text(
                alert.severity.label,
                style: TextStyle(color: style.foreground),
              ),
            ),
            Chip(label: Text(alert.source.label)),
          ],
        ),
        const SizedBox(height: 16),
        _Section(title: 'Por que este alerta', items: alert.evidence),
        _Section(
          title: 'Nível de confiança: ${alert.confidence.label}',
          items: [alert.confidenceReason],
        ),
        _Section(title: 'Limitações', items: alert.limitations),
        if (alert.recommendations.isNotEmpty)
          _Section(title: 'Orientações', items: alert.recommendations),
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Este alerta apoia, mas não substitui, a decisão humana. '
              'Nenhuma ação é tomada automaticamente. Em emergência, '
              'procure a Defesa Civil (199) ou os bombeiros (193).',
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $i'),
              ),
          ],
        ),
      ),
    );
  }
}
