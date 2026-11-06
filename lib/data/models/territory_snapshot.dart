import 'air_reading.dart';
import 'official_warning.dart';
import 'weather.dart';

/// Retrato dos dados do território num momento.
/// Cada parte é nula quando não houve rede nem cache para ela.
class TerritorySnapshot {
  const TerritorySnapshot({
    this.forecast,
    this.history,
    this.air,
    this.warnings,
    this.population,
    this.usedCache = false,
    this.updatedAt,
  });

  final List<DailyWeather>? forecast;
  final List<DailyWeather>? history;
  final List<AirReading>? air;
  final List<OfficialWarning>? warnings;
  final int? population;

  /// Alguma parte veio do cache local (sem conexão ou falha da API).
  final bool usedCache;

  /// Data do dado mais antigo usado.
  final DateTime? updatedAt;

  bool get isEmpty =>
      forecast == null &&
      history == null &&
      air == null &&
      warnings == null &&
      population == null;
}
