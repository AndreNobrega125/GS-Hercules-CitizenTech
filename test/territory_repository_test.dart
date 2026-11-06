import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radar_territorio/core/territory.dart';
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
  when(() => api.forecast(any(), any())).thenAnswer((_) async => _daily);
  when(() => api.history(any(), any())).thenAnswer((_) async => _daily);
  when(() => api.airQuality(any(), any())).thenAnswer((_) async => _air);
  when(() => api.warnings(any())).thenAnswer((_) async => []);
  when(() => api.population(any())).thenAnswer((_) async => 11911337);
  when(() => api.boundary(any())).thenAnswer((_) async => _geo);
}

void _stubOffline(_MockApi api) {
  final boom = Exception('sem rede');
  when(() => api.forecast(any(), any())).thenThrow(boom);
  when(() => api.history(any(), any())).thenThrow(boom);
  when(() => api.airQuality(any(), any())).thenThrow(boom);
  when(() => api.warnings(any())).thenThrow(boom);
  when(() => api.population(any())).thenThrow(boom);
  when(() => api.boundary(any())).thenThrow(boom);
}

const _sp = Territory.saoPaulo;
const _rio = Territory(ibgeCode: '3304557', name: 'Rio de Janeiro', uf: 'RJ');

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
  setUpAll(() {
    registerFallbackValue(0.0);
    registerFallbackValue('');
  });

  test('online: carrega tudo sem usar cache', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _MockApi();
    _stubOnline(api);
    final repo = TerritoryRepository(api, await SharedPreferences.getInstance());

    final snap = await repo.load(_sp);

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
    await TerritoryRepository(online, prefs).load(_sp);

    final offline = _MockApi();
    _stubOffline(offline);

    final snap = await TerritoryRepository(offline, prefs).load(_sp);

    expect(snap.usedCache, isTrue);
    expect(snap.isEmpty, isFalse);
    expect(snap.population, 11911337);
    expect(snap.boundary, isNotNull);
  });

  test('sem rede e sem cache: snapshot vazio', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _MockApi();
    _stubOffline(api);
    final repo = TerritoryRepository(api, await SharedPreferences.getInstance());

    final snap = await repo.load(_sp);

    expect(snap.isEmpty, isTrue);
  });

  test('usa o centro do contorno para clima e ar do município escolhido', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _MockApi();
    _stubOnline(api);
    final repo = TerritoryRepository(api, await SharedPreferences.getInstance());

    await repo.load(_rio);

    // Centro da caixa do contorno de teste: (-23.55, -46.65).
    verify(() => api.forecast(any(that: closeTo(-23.55, 0.001)), any(that: closeTo(-46.65, 0.001))));
    verify(() => api.boundary('3304557'));
    verify(() => api.warnings('3304557'));
  });

  test('cache é separado por município', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final online = _MockApi();
    _stubOnline(online);
    await TerritoryRepository(online, prefs).load(_sp);

    final offline = _MockApi();
    _stubOffline(offline);
    final snap = await TerritoryRepository(offline, prefs).load(_rio);

    expect(snap.isEmpty, isTrue);
  });
}
