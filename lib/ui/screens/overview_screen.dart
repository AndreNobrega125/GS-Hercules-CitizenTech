import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/models/territory_snapshot.dart';
import '../../data/models/weather.dart';
import '../../domain/air_level.dart';
import '../../domain/social_indicator.dart';
import '../../domain/territory_alert.dart';
import '../../state/territory_provider.dart';
import '../widgets/alert_banner.dart';
import '../widgets/alert_style.dart';
import '../widgets/summary_card.dart';

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
    final social = SocialIndicator.from(snapshot.population, alerts);
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
          _SummaryGrid(
            today: today,
            pm25: lastAir?.pm25,
            alerts: alerts,
            pastCount: context.watch<TerritoryProvider>().pastAlerts.length,
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
          if (social != null)
            _Tile(
              icon: Icons.volunteer_activism,
              title: 'Benefício social',
              body: social.hasAlerts
                  ? '${NumberFormat.decimalPattern('pt_BR').format(social.population)} '
                      'pessoas com alerta ativo (${social.alertCount} alerta(s))'
                      '${social.maxLeadDays == null ? '' : ', com até ${social.maxLeadDays} dia(s) de antecedência'}. '
                      'Estimativa: o alerta vale para o município inteiro; '
                      'nem todos são atingidos do mesmo modo.'
                  : 'Nenhum alerta ativo: ninguém precisa de ação agora.',
            ),
          _Tile(
            icon: Icons.edit_note,
            title: 'Ocorrências',
            body: 'Registre problemas do seu território, de forma anônima.',
            onTap: () => context.pushNamed(Routes.occurrences),
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

/// Quatro cartões de destaque: temperatura, chuva, ar e alertas ativos.
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.today,
    required this.pm25,
    required this.alerts,
    required this.pastCount,
  });

  final DailyWeather? today;
  final double? pm25;
  final List<TerritoryAlert> alerts;
  final int pastCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final temp = SummaryCard(
      icon: Icons.thermostat,
      title: 'Temperatura hoje',
      value: today?.tempMax == null ? '—' : '${today!.tempMax!.round()}°C',
      caption: today?.tempMin == null
          ? 'Sem dados de clima'
          : 'Mínima de ${today!.tempMin!.round()}°C',
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      onTap: () => context.goNamed(Routes.climate),
    );

    final rain = SummaryCard(
      icon: Icons.water_drop,
      title: 'Chuva hoje',
      value: today?.rainMm == null
          ? '—'
          : '${today!.rainMm!.toStringAsFixed(1)} mm',
      caption: 'Previsão do dia',
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      onTap: () => context.goNamed(Routes.climate),
    );

    final level = pm25 == null ? null : AirLevel.fromPm25(pm25!);
    final airColors = switch (level?.severity) {
      null || 0 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      1 => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _ => (scheme.errorContainer, scheme.onErrorContainer),
    };
    final air = SummaryCard(
      icon: Icons.air,
      title: 'Qualidade do ar',
      value: pm25 == null ? '—' : '${pm25!.toStringAsFixed(1)} µg/m³',
      caption: level == null ? 'Sem dados do ar' : 'PM2.5 · ${level.label}',
      background: airColors.$1,
      foreground: airColors.$2,
      onTap: () => context.goNamed(Routes.air),
    );

    final top = alerts.isEmpty ? null : alerts.first;
    final topStyle = top == null ? null : AlertStyle.of(context, top.severity);
    final past = pastCount == 0 ? '' : ' · $pastCount de datas antigas';
    final alert = SummaryCard(
      icon: topStyle?.icon ?? Icons.check_circle_outline,
      title: 'Alertas ativos',
      value: '${alerts.length}',
      caption: top == null
          ? 'Nenhum alerta agora$past'
          : 'Mais alto: ${top.severity.label}$past',
      background: topStyle?.background ?? scheme.secondaryContainer,
      foreground: topStyle?.foreground ?? scheme.onSecondaryContainer,
      onTap: () => context.pushNamed(Routes.alerts),
    );

    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          row(temp, alert),
          const SizedBox(height: 12),
          row(rain, air),
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
