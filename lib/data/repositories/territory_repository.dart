import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/air_reading.dart';
import '../models/city_boundary.dart';
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

  Future<TerritorySnapshot> load() async {
    final results = await Future.wait([
      _load('forecast', _api.forecast),
      _load('history', _api.history),
      _load('air', _api.airQuality),
      _load('warnings', _api.warnings),
      _load('population', _api.population),
      _load('boundary', _api.boundary),
    ]);
    final forecast = results[0];
    final history = results[1];
    final air = results[2];
    final warnings = results[3];
    final population = results[4];
    final boundary = results[5];

    final used = results.whereType<_Fetched>().toList();
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
      boundary: boundary == null
          ? null
          : CityBoundary.fromGeoJson(boundary.data as Map<String, dynamic>),
      usedCache: used.any((f) => f.fromCache),
      updatedAt: oldest,
    );
  }
}
