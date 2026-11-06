/// Faixas de referência do app para PM2.5 (µg/m³), a partir da diretriz da
/// OMS de 2021 (média de 24 h: 15 µg/m³). São faixas de apoio, não oficiais.
enum AirLevel {
  withinGuideline('Dentro da diretriz', 0),
  attention('Atenção', 1),
  high('Alto', 2),
  veryHigh('Muito alto', 3);

  const AirLevel(this.label, this.severity);

  final String label;
  final int severity;

  static const guidelinePm25 = 15.0;

  static AirLevel fromPm25(double pm25) {
    if (pm25 <= guidelinePm25) return withinGuideline;
    if (pm25 <= 25) return attention;
    if (pm25 <= 50) return high;
    return veryHigh;
  }
}
