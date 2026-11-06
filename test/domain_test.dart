import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/domain/air_level.dart';
import 'package:radar_territorio/domain/trend.dart';

void main() {
  group('trendOf', () {
    test('detecta alta', () {
      expect(trendOf([1, 1, 1, 1, 5, 5, 5, 5]), Trend.rising);
    });

    test('detecta queda', () {
      expect(trendOf([5, 5, 5, 5, 1, 1, 1, 1]), Trend.falling);
    });

    test('série quase constante é estável', () {
      expect(trendOf([10, 10.2, 9.9, 10.1, 10, 10.1]), Trend.stable);
    });

    test('poucos pontos não afirmam tendência', () {
      expect(trendOf([1, 9]), Trend.stable);
    });
  });

  group('AirLevel', () {
    test('respeita os limites das faixas', () {
      expect(AirLevel.fromPm25(15), AirLevel.withinGuideline);
      expect(AirLevel.fromPm25(15.1), AirLevel.attention);
      expect(AirLevel.fromPm25(25), AirLevel.attention);
      expect(AirLevel.fromPm25(50), AirLevel.high);
      expect(AirLevel.fromPm25(50.1), AirLevel.veryHigh);
    });
  });
}
