import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/territory.dart';
import '../models/air_reading.dart';
import '../models/city_boundary.dart';
import '../models/locality.dart';
import '../models/official_warning.dart';
import '../models/territory_snapshot.dart';
import '../models/weather.dart';
import '../services/api_service.dart';

class _Fetched {
  const _Fetched(this.data, this.fromCache, this.savedAt);
  final Object data;
  final bool fromCache;
  final DateTime savedAt;
}

/// Busca os dados nas APIs e usa o cache local quando a rede falha.
class TerritoryRepository {
  TerritoryRepository(this._api, this._prefs);

  final ApiService _api;
  final SharedPreferences _prefs;

  Future<_Fetched?> _load(String key, Future<Object> Function() fetch) async {
    try {
      final data = await fetch();
      final now = DateTime.now();
      await _prefs.setString(
        'cache_$key',
        jsonEncode({'savedAt': now.toIso8601String(), 'data': data}),
      );
      return _Fetched(data, false, now);
    } catch (_) {
      final raw = _prefs.getString('cache_$key');
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _Fetched(
        map['data'] as Object,
        true,
        DateTime.parse(map['savedAt'] as String),
      );
    }
  }

  /// Estados (UFs), do cache quando offline. Lança se não houver nada.
  Future<List<UfInfo>> states() async {
    final f = await _load('states', _api.states);
    if (f == null) throw StateError('Sem dados de estados');
    return [for (final e in f.data as List) UfInfo.fromJson(e as Map<String, dynamic>)];
  }

  Future<List<Municipality>> municipalities(String uf) async {
    final f = await _load('municipalities_$uf', () => _api.municipalities(uf));
    if (f == null) throw StateError('Sem dados de municípios');
    return [
      for (final e in f.data as List)
        Municipality.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<TerritorySnapshot> load(Territory territory) async {
    final code = territory.ibgeCode;

    // O contorno vem primeiro: dele sai o ponto de referência do clima e do ar.
    final boundaryF = await _load('boundary_$code', () => _api.boundary(code));
    final boundary = boundaryF == null
        ? null
        : CityBoundary.fromGeoJson(boundaryF.data as Map<String, dynamic>);
    final center = boundary?.center;
    final lat = center?.latitude ?? territory.latitude;
    final lon = center?.longitude ?? territory.longitude;

    Future<_Fetched?> geo(
      String key,
      Future<Object> Function(double lat, double lon) fetch,
    ) {
      if (lat == null || lon == null) return Future.value();
      return _load('${key}_$code', () => fetch(lat, lon));
    }

    final results = await Future.wait([
      geo('forecast', _api.forecast),
      geo('history', _api.history),
      geo('air', _api.airQuality),
      _load('warnings_$code', () => _api.warnings(code)),
      _load('population_$code', () => _api.population(code)),
    ]);
    final forecast = results[0];
    final history = results[1];
    final air = results[2];
    final warnings = results[3];
    final population = results[4];

    final used = [...results, boundaryF].whereType<_Fetched>().toList();
    final oldest = used.isEmpty
        ? null
        : used.map((f) => f.savedAt).reduce((a, b) => a.isBefore(b) ? a : b);

    return TerritorySnapshot(
      forecast: forecast == null
          ? null
          : DailyWeather.listFromDaily(forecast.data as Map<String, dynamic>),
      history: history == null
          ? null
          : DailyWeather.listFromDaily(history.data as Map<String, dynamic>),
      air: air == null
          ? null
          : AirReading.listFromJson(air.data as Map<String, dynamic>),
      warnings: warnings == null
          ? null
          : [
              for (final w in warnings.data as List)
                OfficialWarning.fromJson(w as Map<String, dynamic>),
            ],
      population: population == null ? null : population.data as int,
      boundary: boundary,
      usedCache: used.any((f) => f.fromCache),
      updatedAt: oldest,
    );
  }
}
