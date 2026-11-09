import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../domain/territory_alert.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_style.dart';
import '../widgets/empty_state.dart';

/// Lista de alertas com filtros por tipo e por origem.
/// [initialKind] vem do parâmetro de rota (`?kind=rain`).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, this.initialKind});

  final String? initialKind;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late AlertKind? _kind = AlertKind.values
      .where((k) => k.name == widget.initialKind)
      .firstOrNull;
  AlertSource? _source;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TerritoryProvider>();
    final all = provider.alerts;
    final past = provider.pastAlerts;
    bool matches(TerritoryAlert a) =>
        (_kind == null || a.kind == _kind) &&
        (_source == null || a.source == _source);
    final shown = all.where(matches).toList();
    final shownPast = past.where(matches).toList();
    final kinds = [...all, ...past].map((a) => a.kind).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Os alertas apoiam, mas não substituem, a decisão humana.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Todos os tipos'),
                selected: _kind == null,
                onSelected: (_) => setState(() => _kind = null),
              ),
              for (final k in kinds)
                ChoiceChip(
                  avatar: Icon(AlertStyle.kindIcon(k), size: 18),
                  label: Text(k.label),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<AlertSource?>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: null, label: Text('Todas')),
              ButtonSegment(value: AlertSource.official, label: Text('Oficiais')),
              ButtonSegment(value: AlertSource.rule, label: Text('Regras')),
              ButtonSegment(value: AlertSource.statistic, label: Text('Estatística')),
            ],
            selected: {_source},
            onSelectionChanged: (s) => setState(() => _source = s.first),
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty && shownPast.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline,
              message: 'Nenhum alerta para este filtro.',
            )
          else ...[
            if (shown.isEmpty)
              const EmptyState(
                icon: Icons.check_circle_outline,
                message: 'Nenhum alerta ativo para este filtro.',
              )
            else
              for (final a in shown) _AlertTile(alert: a),
            if (shownPast.isNotEmpty) ...[
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'Datas antigas (últimos 7 dias)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Eventos que já passaram. Não são alertas ativos: servem '
                'só como histórico para consulta.',
              ),
              const SizedBox(height: 8),
              for (final a in shownPast) _AlertTile(alert: a),
            ],
          ],
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) {
    final style = AlertStyle.of(context, alert.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label: '${alert.isPast ? 'Data antiga. ' : ''}'
            '${alert.severity.label}: ${alert.title}. ${alert.summary}. '
            'Confiança ${alert.confidence.label}. Toque para ver detalhes.',
        excludeSemantics: true,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: style.background,
            child: Icon(AlertStyle.kindIcon(alert.kind), color: style.foreground),
          ),
          title: Text(alert.title),
          subtitle: Text(
            '${alert.severity.label} · '
            '${alert.isPast ? 'Data antiga' : alert.source.label}\n${alert.summary}',
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(
            Routes.alertDetail,
            pathParameters: {'id': alert.id},
          ),
        ),
      ),
    );
  }
}
