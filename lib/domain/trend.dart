enum Trend { rising, falling, stable }

/// Compara a média da segunda metade da série com a da primeira.
/// Mudança relativa acima de [tolerance] conta como alta ou queda.
Trend trendOf(List<double> values, {double tolerance = 0.1}) {
  if (values.length < 4) return Trend.stable;
  final half = values.length ~/ 2;
  double mean(Iterable<double> v) => v.reduce((a, b) => a + b) / v.length;
  final first = mean(values.take(half));
  final last = mean(values.skip(values.length - half));
  final base = first.abs() < 1.0 ? 1.0 : first.abs();
  final change = (last - first) / base;
  if (change > tolerance) return Trend.rising;
  if (change < -tolerance) return Trend.falling;
  return Trend.stable;
}
