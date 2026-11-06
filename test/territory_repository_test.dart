import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radar_territorio/data/repositories/territory_repository.dart';
import 'package:radar_territorio/data/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

const _daily = {
  'daily': {
    'time': ['2026-11-05', '2026-11-06'],
    'temperature_2m_max': [26.9, 26.8],
    'temperature_2m_min': [20.8, 19.4],
    'precipitation_sum': [3.1, 1.5],
  },
};

const _air = {
  'hourly': {
    'time': ['2026-11-05T00:00'],
    'pm2_5': [39.7],
    'pm10': [40.3],
  },
};

void _stubOnline(_MockApi api) {
  when(api.forecast).thenAnswer((_) async => _daily);
  when(api.history).thenAnswer((_) async => _daily);
  when(api.airQuality).thenAnswer((_) async => _air);
  when(api.warnings).thenAnswer((_) async => []);
  when(api.population).thenAnswer((_) async => 11911337);
  when(api.boundary).thenAnswer((_) async => _geo);
}

const _geo = {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-46.7, -23.6],
            [-46.6, -23.6],
            [-46.6, -23.5],
            [-46.7, -23.6],
          ],
        ],
      },
    },
  ],
};

void main() {
  test('online: carrega tudo sem usar cache', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _MockApi();
    _stubOnline(api);
    final repo = TerritoryRepository(api, await SharedPreferences.getInstance());

    final snap = await repo.load();

    expect(snap.usedCache, isFalse);
    expect(snap.forecast!.length, 2);
    expect(snap.air!.first.pm25, 39.7);
    expect(snap.warnings, isEmpty);
    expect(snap.population, 11911337);
    expect(snap.boundary!.rings.single.first.latitude, -23.6);
  });

  test('offline: usa o cache salvo na última carga', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final online = _MockApi();
    _stubOnline(online);
    await TerritoryRepository(online, prefs).load();

    final offline = _MockApi();
    when(offline.forecast).thenThrow(Exception('sem rede'));
    when(offline.history).thenThrow(Exception('sem rede'));
    when(offline.airQuality).thenThrow(Exception('sem rede'));
    when(offline.warnings).thenThrow(Exception('sem rede'));
    when(offline.population).thenThrow(Exception('sem rede'));
    when(offline.boundary).thenThrow(Exception('sem rede'));

    final snap = await TerritoryRepository(offline, prefs).load();

    expect(snap.usedCache, isTrue);
    expect(snap.isEmpty, isFalse);
    expect(snap.population, 11911337);
    expect(snap.boundary, isNotNull);
  });

  test('sem rede e sem cache: snapshot vazio', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _MockApi();
    when(api.forecast).thenThrow(Exception('sem rede'));
    when(api.history).thenThrow(Exception('sem rede'));
    when(api.airQuality).thenThrow(Exception('sem rede'));
    when(api.warnings).thenThrow(Exception('sem rede'));
    when(api.population).thenThrow(Exception('sem rede'));
    when(api.boundary).thenThrow(Exception('sem rede'));
    final repo = TerritoryRepository(api, await SharedPreferences.getInstance());

    final snap = await repo.load();

    expect(snap.isEmpty, isTrue);
  });
}
