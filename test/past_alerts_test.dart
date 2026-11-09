import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/data/models/air_reading.dart';
import 'package:radar_territorio/data/models/territory_snapshot.dart';
import 'package:radar_territorio/data/models/weather.dart';
import 'package:radar_territorio/domain/alert_engine.dart';
import 'package:radar_territorio/domain/territory_alert.dart';

void main() {
  // "Hoje" fixo: 10/11/2026 às 15h.
  final now = DateTime(2026, 11, 10, 15);
  DateTime day(int ago) => DateTime(2026, 11, 10 - ago);

  DailyWeather w(int ago, {double rain = 0, double max = 25}) => DailyWeather(
        date: day(ago),
        tempMax: max,
        tempMin: 18,
        rainMm: rain,
      );

  test('chuva forte nos últimos 7 dias vira alerta de data antiga', () {
    final snap = TerritorySnapshot(history: [w(3, rain: 55), w(2, rain: 5)]);

    final past = AlertEngine.generatePast(snap, now: now);

    expect(past, hasLength(1));
    final a = past.single;
    expect(a.isPast, isTrue);
    expect(a.pastDate, day(3));
    expect(a.kind, AlertKind.rain);
    expect(a.severity, AlertSeverity.high); // 55 mm >= 50 mm
    expect(a.title, contains('07/11'));
    expect(a.title, contains('data antiga'));
    expect(a.summary, contains('há 3 dia(s)'));
    expect(a.limitations.first, contains('data antiga'));
  });

  test('dia fora da janela de 7 dias e o dia de hoje não entram', () {
    final snap = TerritorySnapshot(history: [
      w(8, rain: 80), // 8 dias atrás: fora
      w(0, rain: 80), // hoje: ainda não é "antigo"
      w(7, rain: 80), // 7 dias atrás: dentro
    ]);

    final past = AlertEngine.generatePast(snap, now: now);

    expect(past.map((a) => a.pastDate), [day(7)]);
  });

  test('calor e ar viram alertas antigos; ordem do mais recente ao mais antigo', () {
    final snap = TerritorySnapshot(
      history: [w(5, max: 38), w(2, rain: 40)],
      air: [
        AirReading(time: DateTime(2026, 11, 8, 9), pm25: 30),
        AirReading(time: DateTime(2026, 11, 8, 14), pm25: 55),
        AirReading(time: DateTime(2026, 11, 9, 9), pm25: 10),
      ],
    );

    final past = AlertEngine.generatePast(snap, now: now);

    expect(past.map((a) => a.id), [
      'past-air-20261108',
      'past-rain-20261108',
      'past-heat-20261105',
    ]);
    final air = past.first;
    expect(air.severity, AlertSeverity.high); // pico de 55 >= 50
    expect(air.summary, contains('55.0'));
  });

  test('usa os limiares do perfil', () {
    final snap = TerritorySnapshot(history: [w(2, rain: 20)]);

    expect(AlertEngine.generatePast(snap, now: now), isEmpty);
    expect(
      AlertEngine.generatePast(
        snap,
        thresholds: const AlertThresholds(rainAttentionMm: 10, rainHighMm: 30),
        now: now,
      ),
      hasLength(1),
    );
  });

  test('alertas ativos nunca são marcados como data antiga', () {
    final snap = TerritorySnapshot(
      forecast: [DailyWeather(date: now, tempMax: 25, tempMin: 18, rainMm: 60)],
    );

    final active = AlertEngine.generate(snap, now: now);

    expect(active, isNotEmpty);
    expect(active.every((a) => !a.isPast), isTrue);
  });

  test('sem histórico nem ar: nenhum alerta antigo', () {
    expect(AlertEngine.generatePast(const TerritorySnapshot(), now: now), isEmpty);
  });
}
