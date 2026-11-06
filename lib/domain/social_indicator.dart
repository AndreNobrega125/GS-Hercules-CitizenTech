import 'territory_alert.dart';

/// Indicador de benefício social: quantas pessoas o município inclui quando
/// há alertas ativos e com quanta antecedência eles chegam.
class SocialIndicator {
  const SocialIndicator({
    required this.population,
    required this.alertCount,
    this.maxLeadDays,
  });

  /// Habitantes do município (IBGE). Alertas valem para o município inteiro.
  final int population;
  final int alertCount;

  /// Maior antecedência entre os alertas previstos, em dias.
  final int? maxLeadDays;

  bool get hasAlerts => alertCount > 0;

  /// `null` sem população conhecida. Sem alertas, ninguém está "coberto".
  static SocialIndicator? from(int? population, List<TerritoryAlert> alerts) {
    if (population == null) return null;
    final leads = [for (final a in alerts) ?a.leadDays];
    return SocialIndicator(
      population: alerts.isEmpty ? 0 : population,
      alertCount: alerts.length,
      maxLeadDays: leads.isEmpty ? null : leads.reduce((a, b) => a > b ? a : b),
    );
  }
}
