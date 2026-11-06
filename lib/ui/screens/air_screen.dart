import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/models/air_reading.dart';
import '../../domain/air_level.dart';
import '../../domain/territory_alert.dart';
import '../../domain/trend.dart';
import '../../state/territory_provider.dart';
import '../widgets/chart_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/trend_chip.dart';

class AirScreen extends StatefulWidget {
  const AirScreen({super.key});

  @override
  State<AirScreen> createState() => _AirScreenState();
}

class _AirScreenState extends State<AirScreen> {
  int _hours = 72;

  @override
  Widget build(BuildContext context) {
    final air = context.watch<TerritoryProvider>().snapshot?.air;
    final now = DateTime.now();
    final past = (air ?? const <AirReading>[])
        .where((a) => a.pm25 != null && !a.time.isAfter(now))
        .toList();
    final last72 = past.length > _hours ? past.sublist(past.length - _hours) : past;

    return Scaffold(
      appBar: AppBar(title: const Text('Qualidade do ar')),
      body: last72.isEmpty
          ? const EmptyState(
              icon: Icons.air,
              message: 'Sem dados do ar. Volte à visão geral e atualize.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 24, label: Text('24 h')),
                    ButtonSegment(value: 48, label: Text('48 h')),
                    ButtonSegment(value: 72, label: Text('72 h')),
                  ],
                  selected: {_hours},
                  onSelectionChanged: (s) => setState(() => _hours = s.first),
                ),
                const SizedBox(height: 12),
                _Current(latest: last72.last, series: last72, hours: _hours),
                _PmChart(series: last72, hours: _hours),
                const _Limits(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Ver alertas do ar'),
                  onPressed: () => context.pushNamed(
                    Routes.alerts,
                    queryParameters: {'kind': AlertKind.air.name},
                  ),
                ),
              ],
            ),
    );
  }
}

class _Current extends StatelessWidget {
  const _Current({
    required this.latest,
    required this.series,
    required this.hours,
  });

  final AirReading latest;
  final List<AirReading> series;
  final int hours;

  @override
  Widget build(BuildContext context) {
    final level = AirLevel.fromPm25(latest.pm25!);
    final text = Theme.of(context).textTheme;
    final trend = trendOf(series.map((a) => a.pm25!).toList());
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: 'PM2.5 agora ${latest.pm25!.toStringAsFixed(1)} microgramas '
              'por metro cúbico, nível ${level.label}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PM2.5 agora', style: text.titleMedium),
              Text(
                '${latest.pm25!.toStringAsFixed(1)} µg/m³',
                style: text.displaySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      level.severity >= 2 ? Icons.warning_amber : Icons.info_outline,
                      size: 18,
                    ),
                    label: Text(level.label),
                  ),
                  TrendChip(label: 'Últimas $hours h', trend: trend),
                  if (latest.pm10 != null)
                    Chip(label: Text('PM10 ${latest.pm10!.toStringAsFixed(1)}')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PmChart extends StatelessWidget {
  const _PmChart({required this.series, required this.hours});

  final List<AirReading> series;
  final int hours;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = series.map((a) => a.pm25!).reduce((a, b) => a > b ? a : b);
    return ChartCard(
      title: 'PM2.5 nas últimas $hours horas (µg/m³)',
      caption: 'Linha tracejada: diretriz da OMS (15 µg/m³, média de 24 h).',
      summary: 'Máximo de ${max.toStringAsFixed(0)} microgramas por metro cúbico. '
          'Diretriz da OMS é 15.',
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < series.length; i++)
                  FlSpot(i.toDouble(), series[i].pm25!),
              ],
              color: scheme.primary,
              barWidth: 3,
              isCurved: true,
              dotData: const FlDotData(show: false),
            ),
          ],
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: AirLevel.guidelinePm25,
              color: scheme.error,
              strokeWidth: 2,
              dashArray: [6, 4],
            ),
          ]),
          minY: 0,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(),
            rightTitles: AxisTitles(),
            bottomTitles: AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}

class _Limits extends StatelessWidget {
  const _Limits();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Limitações: os valores vêm de um modelo atmosférico (Open-Meteo), '
          'não de uma estação de medição local, e podem diferir do que '
          'ocorre na sua rua. As faixas do app são apoio, baseadas na '
          'diretriz da OMS; não são classificação oficial. A decisão final '
          'é sempre humana.',
        ),
      ),
    );
  }
}
