import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../data/models/weather.dart';
import '../../domain/territory_alert.dart';
import '../../domain/trend.dart';
import '../../state/territory_provider.dart';
import '../widgets/chart_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/trend_chip.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<TerritoryProvider>().snapshot;
    final forecast = snapshot?.forecast;
    final all = snapshot?.history;
    final history = (all != null && all.length > _days)
        ? all.sublist(all.length - _days)
        : all;

    return Scaffold(
      appBar: AppBar(title: const Text('Clima')),
      body: (forecast == null || forecast.isEmpty)
          ? const EmptyState(
              icon: Icons.cloud_off,
              message: 'Sem dados de clima. Volte à visão geral e atualize.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 dias')),
                    ButtonSegment(value: 14, label: Text('14 dias')),
                    ButtonSegment(value: 30, label: Text('30 dias')),
                  ],
                  selected: {_days},
                  onSelectionChanged: (s) => setState(() => _days = s.first),
                ),
                const SizedBox(height: 12),
                _Trends(history: history, forecast: forecast, days: _days),
                _RainChart(forecast: forecast),
                _TempChart(history: history, forecast: forecast, days: _days),
                OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Ver alertas de chuva'),
                  onPressed: () => context.pushNamed(
                    Routes.alerts,
                    queryParameters: {'kind': AlertKind.rain.name},
                  ),
                ),
              ],
            ),
    );
  }
}

class _Trends extends StatelessWidget {
  const _Trends({
    required this.history,
    required this.forecast,
    required this.days,
  });

  final List<DailyWeather>? history;
  final List<DailyWeather> forecast;
  final int days;

  @override
  Widget build(BuildContext context) {
    final rain = (history ?? []).map((d) => d.rainMm).whereType<double>();
    final temp = (history ?? []).map((d) => d.tempMax).whereType<double>();
    final rainNext = forecast.map((d) => d.rainMm ?? 0).fold<double>(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        children: [
          TrendChip(label: 'Chuva ($days dias)', trend: trendOf(rain.toList())),
          TrendChip(label: 'Temperatura ($days dias)', trend: trendOf(temp.toList())),
          Chip(
            avatar: const Icon(Icons.water_drop, size: 18),
            label: Text('Próx. 7 dias: ${rainNext.toStringAsFixed(0)} mm'),
          ),
        ],
      ),
    );
  }
}

class _RainChart extends StatelessWidget {
  const _RainChart({required this.forecast});

  final List<DailyWeather> forecast;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final label = DateFormat('E', 'pt_BR');
    final total = forecast.fold<double>(0, (a, d) => a + (d.rainMm ?? 0));
    return ChartCard(
      title: 'Chuva prevista (mm por dia)',
      caption: 'Previsão do Open-Meteo. Incerteza cresce nos dias finais.',
      summary: 'Total de ${total.toStringAsFixed(0)} milímetros em '
          '${forecast.length} dias.',
      child: BarChart(
        BarChartData(
          barGroups: [
            for (var i = 0; i < forecast.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: forecast[i].rainMm ?? 0,
                  color: color,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ]),
          ],
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                minIncluded: false,
                maxIncluded: false,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(label.format(forecast[v.toInt()].date)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TempChart extends StatelessWidget {
  const _TempChart({
    required this.history,
    required this.forecast,
    required this.days,
  });

  final List<DailyWeather>? history;
  final List<DailyWeather> forecast;
  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final past = history ?? const <DailyWeather>[];

    List<FlSpot> spots(List<DailyWeather> days, int offset) => [
          for (var i = 0; i < days.length; i++)
            if (days[i].tempMax != null)
              FlSpot((offset + i).toDouble(), days[i].tempMax!),
        ];

    LineChartBarData line(List<FlSpot> s, Color c, {bool dashed = false}) =>
        LineChartBarData(
          spots: s,
          color: c,
          isCurved: true,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          dashArray: dashed ? [6, 4] : null,
        );

    return ChartCard(
      title: 'Temperatura máxima (°C)',
      caption: 'Linha cheia: últimos $days dias. Tracejada: previsão.',
      summary: 'Histórico de ${past.length} dias seguido de '
          '${forecast.length} dias de previsão.',
      child: LineChart(
        LineChartData(
          lineBarsData: [
            if (past.isNotEmpty) line(spots(past, 0), scheme.primary),
            line(spots(forecast, past.length), scheme.tertiary, dashed: true),
          ],
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(),
            rightTitles: AxisTitles(),
            bottomTitles: AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                minIncluded: false,
                maxIncluded: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
