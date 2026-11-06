import 'dart:math' as math;

/// Reta ajustada por mínimos quadrados: y = intercept + slope * x (x = 0, 1, 2…).
class LinearFit {
  const LinearFit({
    required this.slope,
    required this.intercept,
    required this.r2,
    required this.n,
  });

  final double slope;
  final double intercept;

  /// Coeficiente de determinação (0 a 1): quanto da variação a reta explica.
  final double r2;
  final int n;

  double predict(double x) => intercept + slope * x;
}

double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

/// Desvio padrão amostral (n - 1).
double stdDev(List<double> v) {
  final m = mean(v);
  final ss = v.fold<double>(0, (s, x) => s + (x - m) * (x - m));
  return math.sqrt(ss / (v.length - 1));
}

/// Regressão linear simples sobre a série. `null` se houver menos de [minPoints]
/// pontos. Série constante tem R² = 0 (a reta não explica variação alguma).
LinearFit? linearFit(List<double> y, {int minPoints = 5}) {
  final n = y.length;
  if (n < minPoints) return null;
  final xMean = (n - 1) / 2;
  final yMean = mean(y);
  var sxy = 0.0;
  var sxx = 0.0;
  var syy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = i - xMean;
    final dy = y[i] - yMean;
    sxy += dx * dy;
    sxx += dx * dx;
    syy += dy * dy;
  }
  final slope = sxy / sxx;
  final r2 = syy == 0 ? 0.0 : (sxy * sxy) / (sxx * syy);
  return LinearFit(
    slope: slope,
    intercept: yMean - slope * xMean,
    r2: r2,
    n: n,
  );
}

/// Quantos desvios padrão [value] está acima (+) ou abaixo (-) da média da
/// [baseline]. `null` se a base for curta ([minPoints]) ou quase constante.
double? zScore(double value, List<double> baseline, {int minPoints = 15}) {
  if (baseline.length < minPoints) return null;
  final sd = stdDev(baseline);
  if (sd < 1e-9) return null;
  return (value - mean(baseline)) / sd;
}

/// Previsão por suavização exponencial dupla (Holt): nível + tendência.
/// Projeta [steps] passos à frente. `null` se a série tiver menos de 4 pontos.
double? holtForecast(
  List<double> v,
  int steps, {
  double alpha = 0.5,
  double beta = 0.3,
}) {
  if (v.length < 4) return null;
  var level = v[0];
  var trend = v[1] - v[0];
  for (var i = 1; i < v.length; i++) {
    final prev = level;
    level = alpha * v[i] + (1 - alpha) * (level + trend);
    trend = beta * (level - prev) + (1 - beta) * trend;
  }
  return math.max(0.0, level + steps * trend);
}
