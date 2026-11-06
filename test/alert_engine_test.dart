import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/data/models/air_reading.dart';
import 'package:radar_territorio/data/models/official_warning.dart';
import 'package:radar_territorio/data/models/territory_snapshot.dart';
import 'package:radar_territorio/data/models/weather.dart';
import 'package:radar_territorio/domain/alert_engine.dart';
import 'package:radar_territorio/domain/territory_alert.dart';

DailyWeather _day(int offset, {double? rain, double? tMax}) => DailyWeather(
      date: DateTime(2026, 11, 5).add(Duration(days: offset)),
      tempMax: tMax ?? 25,
      tempMin: 18,
      rainMm: rain ?? 0,
    );

OfficialWarning _warning(String description, String severity) => OfficialWarning(
      id: '7',
      description: description,
      severity: severity,
      colorHex: '#FFFE00',
      start: '05/11/2026',
      end: '06/11/2026',
      risks: const ['Risco de queda de galhos'],
      instructions: const ['Evite abrigo sob árvores'],
    );

void main() {
  final now = DateTime(2026, 11, 5, 12);

  test('aviso oficial vira alerta com confiança alta e limitações', () {
    final alerts = AlertEngine.generate(
      TerritorySnapshot(warnings: [_warning('Tempestade', 'Perigo Potencial')]),
      now: now,
    );

    expect(alerts, hasLength(1));
    final a = alerts.single;
    expect(a.id, 'inmet-7');
    expect(a.kind, AlertKind.storm);
    expect(a.severity, AlertSeverity.attention);
    expect(a.source, AlertSource.official);
    expect(a.confidence, AlertConfidence.high);
    expect(a.limitations, isNotEmpty);
    expect(a.recommendations, ['Evite abrigo sob árvores']);
  });

  test('severidade do INMET é mapeada corretamente', () {
    expect(AlertEngine.severityOf('Perigo Potencial'), AlertSeverity.attention);
    expect(AlertEngine.severityOf('Perigo'), AlertSeverity.high);
    expect(AlertEngine.severityOf('Grande Perigo'), AlertSeverity.critical);
    expect(AlertEngine.severityOf('Outro'), AlertSeverity.info);
  });

  test('chuva abaixo do limiar não gera alerta', () {
    final alerts = AlertEngine.generate(
      TerritorySnapshot(forecast: [_day(0, rain: 29.9)]),
      now: now,
    );
    expect(alerts, isEmpty);
  });

  test('chuva forte: severidade e confiança dependem do limiar e do prazo', () {
    final alerts = AlertEngine.generate(
      TerritorySnapshot(forecast: [
        _day(0, rain: 35),
        _day(2, rain: 60),
        _day(5, rain: 31),
      ]),
      now: now,
    );

    final byId = {for (final a in alerts) a.id: a};
    expect(byId['rule-rain-20261105']!.severity, AlertSeverity.attention);
    expect(byId['rule-rain-20261105']!.confidence, AlertConfidence.high);
    expect(byId['rule-rain-20261107']!.severity, AlertSeverity.high);
    expect(byId['rule-rain-20261107']!.confidence, AlertConfidence.medium);
    expect(byId['rule-rain-20261110']!.confidence, AlertConfidence.low);
    // O mais grave vem primeiro.
    expect(alerts.first.id, 'rule-rain-20261107');
  });

  test('ar ruim gera alerta; ar bom, não', () {
    AirReading r(double pm) => AirReading(time: DateTime(2026, 11, 5, 10), pm25: pm);

    final bad = AlertEngine.generate(TerritorySnapshot(air: [r(40)]), now: now);
    expect(bad.single.kind, AlertKind.air);
    expect(bad.single.confidence, AlertConfidence.medium);

    final good = AlertEngine.generate(TerritorySnapshot(air: [r(10)]), now: now);
    expect(good, isEmpty);
  });

  test('leitura de ar no futuro é ignorada', () {
    final future = AirReading(time: DateTime(2026, 11, 6), pm25: 90);
    final alerts = AlertEngine.generate(TerritorySnapshot(air: [future]), now: now);
    expect(alerts, isEmpty);
  });

  test('calor intenso gera um único alerta no dia mais quente', () {
    final alerts = AlertEngine.generate(
      TerritorySnapshot(forecast: [
        _day(0, tMax: 33),
        _day(1, tMax: 38),
        _day(2, tMax: 35),
      ]),
      now: now,
    );
    expect(alerts.single.id, 'rule-heat');
    expect(alerts.single.severity, AlertSeverity.high);
  });
}
