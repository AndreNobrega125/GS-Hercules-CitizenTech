import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/data/models/air_reading.dart';
import 'package:radar_territorio/data/models/territory_snapshot.dart';
import 'package:radar_territorio/data/models/weather.dart';
import 'package:radar_territorio/domain/alert_engine.dart';
import 'package:radar_territorio/domain/stats.dart';
import 'package:radar_territorio/domain/territory_alert.dart';

DailyWeather _day(DateTime start, int i, double tMax) => DailyWeather(
      date: start.add(Duration(days: i)),
      tempMax: tMax,
      tempMin: 15,
      rainMm: 0,
    );

void main() {
  group('linearFit', () {
    test('reta perfeita: inclinação, intercepto e R² = 1', () {
      final fit = linearFit([1, 3, 5, 7, 9, 11])!;
      expect(fit.slope, closeTo(2, 1e-9));
      expect(fit.intercept, closeTo(1, 1e-9));
      expect(fit.r2, closeTo(1, 1e-9));
      expect(fit.predict(6), closeTo(13, 1e-9));
    });
    test('série constante: R² = 0 e inclinação 0', () {
      final fit = linearFit([4, 4, 4, 4, 4, 4])!;
      expect(fit.slope, 0);
      expect(fit.r2, 0);
    });
    test('ruído sem tendência tem R² baixo', () {
      final fit = linearFit([5, 1, 6, 2, 5, 1, 6, 2])!;
      expect(fit.r2, lessThan(0.1));
    });
    test('poucos pontos: sem ajuste', () {
      expect(linearFit([1, 2, 3]), isNull);
    });
  });

  group('zScore', () {
    final base = [for (var i = 0; i < 20; i++) 20.0 + (i.isEven ? 1 : -1)];
    test('valor típico fica perto de zero e outlier fica alto', () {
      expect(zScore(20, base)!.abs(), lessThan(0.1));
      expect(zScore(30, base)!, greaterThan(5));
    });
    test('base curta ou constante não gera z', () {
      expect(zScore(30, [20, 21, 22]), isNull);
      expect(zScore(30, List.filled(20, 20.0)), isNull);
    });
  });

  group('holtForecast', () {
    test('série crescente projeta valor acima do último', () {
      final v = [for (var i = 0; i < 24; i++) 10.0 + i];
      expect(holtForecast(v, 12)!, greaterThan(v.last));
    });
    test('série constante projeta o mesmo valor', () {
      expect(holtForecast(List.filled(24, 8.0), 12)!, closeTo(8, 1e-6));
    });
    test('nunca devolve valor negativo', () {
      final v = [for (var i = 0; i < 24; i++) 30.0 - i * 1.2];
      expect(holtForecast(v, 48)!, greaterThanOrEqualTo(0));
    });
  });

  group('alertas estatísticos', () {
    final start = DateTime(2026, 10, 7);
    final now = DateTime(2026, 11, 5, 12);
    final forecastStart = DateTime(2026, 11, 5);

    // 30 dias de histórico estável, entre 24 e 26 °C.
    final stable = [
      for (var i = 0; i < 30; i++) _day(start, i, 24.0 + (i % 3)),
    ];

    test('dia previsto muito acima do padrão gera anomalia', () {
      final alerts = AlertEngine.generate(
        TerritorySnapshot(
          history: stable,
          forecast: [_day(forecastStart, 0, 25), _day(forecastStart, 1, 33)],
        ),
        now: now,
      );
      final a = alerts.firstWhere((e) => e.id == 'stat-temp-anomaly');
      expect(a.source, AlertSource.statistic);
      expect(a.limitations, isNotEmpty);
      expect(a.confidence, isNot(AlertConfidence.high));
    });

    test('previsão normal não gera anomalia', () {
      final alerts = AlertEngine.generate(
        TerritorySnapshot(history: stable, forecast: [_day(forecastStart, 0, 25)]),
        now: now,
      );
      expect(alerts.where((e) => e.id == 'stat-temp-anomaly'), isEmpty);
    });

    test('temperatura subindo no mês gera tendência informativa', () {
      final rising = [
        for (var i = 0; i < 30; i++) _day(start, i, 20.0 + i * 0.3),
      ];
      final alerts = AlertEngine.generate(
        TerritorySnapshot(history: rising),
        now: now,
      );
      final a = alerts.firstWhere((e) => e.id == 'stat-temp-trend');
      expect(a.severity, AlertSeverity.info);
      expect(a.evidence.join(' '), contains('R²'));
    });

    test('mês estável não gera tendência', () {
      final alerts = AlertEngine.generate(
        TerritorySnapshot(history: stable),
        now: now,
      );
      expect(alerts.where((e) => e.id == 'stat-temp-trend'), isEmpty);
    });

    AirReading hour(int h, double pm) => AirReading(
          time: DateTime(2026, 11, 4, 12).add(Duration(hours: h)),
          pm25: pm,
        );

    test('PM2.5 subindo e ainda abaixo do limiar gera projeção', () {
      final air = [for (var h = 0; h < 24; h++) hour(h, 8.0 + h * 0.7)];
      final alerts = AlertEngine.generate(TerritorySnapshot(air: air), now: now);
      final a = alerts.firstWhere((e) => e.id == 'stat-air-forecast');
      expect(a.kind, AlertKind.air);
      expect(a.confidence, isNot(AlertConfidence.high));
    });

    test('PM2.5 estável ou caindo não gera projeção', () {
      final flat = [for (var h = 0; h < 24; h++) hour(h, 10.0)];
      final falling = [for (var h = 0; h < 24; h++) hour(h, 24.0 - h * 0.8)];
      for (final air in [flat, falling]) {
        final alerts =
            AlertEngine.generate(TerritorySnapshot(air: air), now: now);
        expect(alerts.where((e) => e.id == 'stat-air-forecast'), isEmpty);
      }
    });

    test('poucas leituras não geram projeção', () {
      final air = [for (var h = 0; h < 10; h++) hour(h, 8.0 + h * 2)];
      final alerts = AlertEngine.generate(TerritorySnapshot(air: air), now: now);
      expect(alerts.where((e) => e.id == 'stat-air-forecast'), isEmpty);
    });
  });
}
