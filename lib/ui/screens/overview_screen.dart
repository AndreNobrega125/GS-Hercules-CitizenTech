import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/models/territory_snapshot.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_banner.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TerritoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          button: true,
          label: 'Município atual: ${state.territory.label}. Toque para trocar.',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.pushNamed(Routes.territory),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      state.territory.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: state.load,
          ),
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings),
            onPressed: () => context.goNamed(Routes.settings),
          ),
        ],
      ),
      body: switch (state.status) {
        LoadStatus.loading when state.snapshot == null =>
          const Center(child: CircularProgressIndicator()),
        LoadStatus.error => _ErrorView(onRetry: state.load),
        _ => _Content(snapshot: state.snapshot!),
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Sem conexão e sem dados salvos. Conecte-se e tente novamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.snapshot});

  final TerritorySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final today = snapshot.forecast?.firstOrNull;
    final lastAir = snapshot.air?.lastWhere(
      (a) => a.pm25 != null,
      orElse: () => snapshot.air!.last,
    );
    final warnings = snapshot.warnings;
    final alerts = context.watch<TerritoryProvider>().alerts;
    final stamp = snapshot.updatedAt == null
        ? ''
        : DateFormat('dd/MM HH:mm').format(snapshot.updatedAt!);

    return RefreshIndicator(
      onRefresh: () => context.read<TerritoryProvider>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (alerts.isNotEmpty)
            AlertBanner(
              alerts: alerts,
              onTap: () => context.pushNamed(Routes.alerts),
            ),
          if (snapshot.usedCache)
            _Tile(
              icon: Icons.cloud_off,
              title: 'Modo offline',
              body: 'Mostrando dados salvos em $stamp.',
            ),
          _Tile(
            icon: Icons.thermostat,
            title: 'Clima hoje',
            onTap: () => context.goNamed(Routes.climate),
            body: today == null
                ? 'Sem dados de clima.'
                : '${today.tempMin?.round()}° a ${today.tempMax?.round()}° · '
                    'chuva ${today.rainMm?.toStringAsFixed(1)} mm',
          ),
          _Tile(
            icon: Icons.air,
            title: 'Qualidade do ar (PM2.5)',
            onTap: () => context.goNamed(Routes.air),
            body: lastAir?.pm25 == null
                ? 'Sem dados do ar.'
                : '${lastAir!.pm25!.toStringAsFixed(1)} µg/m³',
          ),
          _Tile(
            icon: Icons.warning_amber,
            title: 'Avisos oficiais (INMET)',
            onTap: () => context.goNamed(Routes.risks),
            body: warnings == null
                ? 'Sem dados de avisos.'
                : warnings.isEmpty
                    ? 'Nenhum aviso ativo para ${context.read<TerritoryProvider>().territory.name}.'
                    : '${warnings.length} aviso(s) ativo(s): '
                        '${warnings.map((w) => w.description).join(', ')}',
          ),
          _Tile(
            icon: Icons.notifications_active,
            title: 'Alertas',
            body: alerts.isEmpty
                ? 'Nenhum alerta no momento.'
                : '${alerts.length} alerta(s) com justificativa e confiança.',
            onTap: () => context.pushNamed(Routes.alerts),
          ),
          _Tile(
            icon: Icons.groups,
            title: 'População (IBGE)',
            body: snapshot.population == null
                ? 'Sem dados de população.'
                : NumberFormat.decimalPattern('pt_BR').format(snapshot.population),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Quando informado, o cartão abre o dashboard correspondente.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: onTap == null ? '$title: $body' : '$title: $body. Toque para abrir.',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: ExcludeSemantics(child: Icon(icon)),
          title: Text(title),
          subtitle: Text(body),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
