import 'package:intl/intl.dart';

import '../data/models/official_warning.dart';
import '../data/models/territory_snapshot.dart';
import '../data/models/weather.dart';
import 'air_level.dart';
import 'stats.dart';
import 'territory_alert.dart';

/// Limiares das regras próprias do app (valores padrão; ajustáveis depois).
class AlertThresholds {
  const AlertThresholds({
    this.rainAttentionMm = 30,
    this.rainHighMm = 50,
    this.pm25Attention = 25,
    this.pm25High = 50,
    this.heatAttentionC = 34,
    this.heatHighC = 37,
  });

  final double rainAttentionMm;
  final double rainHighMm;
  final double pm25Attention;
  final double pm25High;
  final double heatAttentionC;
  final double heatHighC;

  static const defaults = AlertThresholds();

  Map<String, dynamic> toJson() => {
        'rainAttentionMm': rainAttentionMm,
        'rainHighMm': rainHighMm,
        'pm25Attention': pm25Attention,
        'pm25High': pm25High,
        'heatAttentionC': heatAttentionC,
        'heatHighC': heatHighC,
      };

  factory AlertThresholds.fromJson(Map<String, dynamic> j) {
    double v(String k, double d) => (j[k] as num?)?.toDouble() ?? d;
    return AlertThresholds(
      rainAttentionMm: v('rainAttentionMm', 30),
      rainHighMm: v('rainHighMm', 50),
      pm25Attention: v('pm25Attention', 25),
      pm25High: v('pm25High', 50),
      heatAttentionC: v('heatAttentionC', 34),
      heatHighC: v('heatHighC', 37),
    );
  }
}

/// Gera os alertas a partir dos avisos oficiais e de regras sobre os dados.
/// Nunca toma ação: só informa. A decisão final é sempre humana.
class AlertEngine {
  const AlertEngine._();

  static String officialId(int index, OfficialWarning w) =>
      'inmet-${w.id.isEmpty ? index : w.id}';

  static List<TerritoryAlert> generate(
    TerritorySnapshot snapshot, {
    AlertThresholds thresholds = const AlertThresholds(),
    DateTime? now,
  }) {
    final alerts = <TerritoryAlert>[
      ..._official(snapshot.warnings ?? const []),
      ..._rain(snapshot, thresholds),
      ..._heat(snapshot, thresholds),
      ..._air(snapshot, thresholds, now ?? DateTime.now()),
      ..._tempAnomaly(snapshot),
      ..._tempTrend(snapshot),
      ..._airProjection(snapshot, thresholds, now ?? DateTime.now()),
    ];
    alerts.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      return bySeverity != 0
          ? bySeverity
          : a.confidence.index.compareTo(b.confidence.index);
    });
    return alerts;
  }

  // ---------------------------------------------------------------- oficiais

  static AlertKind kindOf(String description) {
    final d = description.toLowerCase();
    if (d.contains('tempestade')) return AlertKind.storm;
    if (d.contains('chuva')) return AlertKind.rain;
    if (d.contains('vento')) return AlertKind.wind;
    if (d.contains('calor')) return AlertKind.heat;
    return AlertKind.other;
  }

  static AlertSeverity severityOf(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('grande perigo')) return AlertSeverity.critical;
    if (s.contains('potencial')) return AlertSeverity.attention;
    if (s.contains('perigo')) return AlertSeverity.high;
    return AlertSeverity.info;
  }

  static Iterable<TerritoryAlert> _official(List<OfficialWarning> warnings) sync* {
    for (var i = 0; i < warnings.length; i++) {
      final w = warnings[i];
      yield TerritoryAlert(
        id: officialId(i, w),
        kind: kindOf(w.description),
        severity: severityOf(w.severity),
        source: AlertSource.official,
        title: w.description,
        summary: '${w.severity} · válido até ${w.end}',
        evidence: [
          'Aviso emitido pelo INMET com severidade "${w.severity}".',
          if (w.start.isNotEmpty) 'Vigência: ${w.start} até ${w.end}.',
          ...w.risks.take(2),
        ],
        confidence: AlertConfidence.high,
        confidenceReason:
            'Emitido por órgão oficial, com prazo de validade definido.',
        limitations: const [
          'O aviso vale para uma área ampla; nem todo bairro é atingido do mesmo modo.',
          'O INMET pode alterar ou encerrar o aviso a qualquer momento.',
          'Este app não substitui os canais oficiais da Defesa Civil.',
        ],
        recommendations: w.instructions,
      );
    }
  }

  // ------------------------------------------------------------------ regras

  static AlertConfidence _byHorizon(int daysAhead) => daysAhead <= 1
      ? AlertConfidence.high
      : daysAhead <= 3
          ? AlertConfidence.medium
          : AlertConfidence.low;

  static String _horizonText(int daysAhead) => daysAhead == 0
      ? 'Previsão para hoje.'
      : 'Previsão para daqui a $daysAhead dia(s); a incerteza cresce com o prazo.';

  static Iterable<TerritoryAlert> _rain(
    TerritorySnapshot s,
    AlertThresholds t,
  ) sync* {
    final days = s.forecast ?? const [];
    final fmt = DateFormat('dd/MM');
    for (var i = 0; i < days.length; i++) {
      final mm = days[i].rainMm ?? 0;
      if (mm < t.rainAttentionMm) continue;
      final ahead = days[i].date.difference(days.first.date).inDays;
      yield TerritoryAlert(
        id: 'rule-rain-${DateFormat('yyyyMMdd').format(days[i].date)}',
        kind: AlertKind.rain,
        severity: mm >= t.rainHighMm ? AlertSeverity.high : AlertSeverity.attention,
        source: AlertSource.rule,
        title: 'Chuva forte prevista em ${fmt.format(days[i].date)}',
        summary: '${mm.toStringAsFixed(0)} mm previstos no dia',
        evidence: [
          'Previsão do Open-Meteo: ${mm.toStringAsFixed(1)} mm em ${fmt.format(days[i].date)}.',
          'Limiares do app: atenção a partir de ${t.rainAttentionMm.toStringAsFixed(0)} mm, '
              'alto a partir de ${t.rainHighMm.toStringAsFixed(0)} mm por dia.',
        ],
        confidence: _byHorizon(ahead),
        confidenceReason: _horizonText(ahead),
        limitations: const [
          'Modelo global com resolução de alguns quilômetros: não capta chuva localizada por bairro.',
          'O total diário não diz a que horas a chuva cai.',
          'Os limiares são do app e não substituem os critérios da Defesa Civil.',
        ],
        recommendations: const [
          'Orientação geral: evite áreas sujeitas a alagamento e acompanhe os avisos da Defesa Civil (199).',
        ],
      );
    }
  }

  static Iterable<TerritoryAlert> _heat(
    TerritorySnapshot s,
    AlertThresholds t,
  ) sync* {
    final days = (s.forecast ?? const []).take(4).toList();
    if (days.isEmpty) return;
    var worst = 0;
    for (var i = 1; i < days.length; i++) {
      if ((days[i].tempMax ?? -100) > (days[worst].tempMax ?? -100)) worst = i;
    }
    final max = days[worst].tempMax;
    if (max == null || max < t.heatAttentionC) return;
    final fmt = DateFormat('dd/MM');
    final ahead = days[worst].date.difference(days.first.date).inDays;
    yield TerritoryAlert(
      id: 'rule-heat',
      kind: AlertKind.heat,
      severity: max >= t.heatHighC ? AlertSeverity.high : AlertSeverity.attention,
      source: AlertSource.rule,
      title: 'Calor intenso previsto em ${fmt.format(days[worst].date)}',
      summary: 'Máxima de ${max.toStringAsFixed(0)} °C',
      evidence: [
        'Previsão do Open-Meteo: máxima de ${max.toStringAsFixed(1)} °C em ${fmt.format(days[worst].date)}.',
        'Limiares do app: atenção a partir de ${t.heatAttentionC.toStringAsFixed(0)} °C, '
            'alto a partir de ${t.heatHighC.toStringAsFixed(0)} °C.',
      ],
      confidence: _byHorizon(ahead),
      confidenceReason: _horizonText(ahead),
      limitations: const [
        'A temperatura é do modelo para a região, não de um ponto específico da cidade.',
        'Ilhas de calor urbanas podem deixar alguns locais mais quentes que a previsão.',
      ],
      recommendations: const [
        'Orientação geral: hidrate-se e evite exposição ao sol nas horas mais quentes.',
      ],
    );
  }

  static Iterable<TerritoryAlert> _air(
    TerritorySnapshot s,
    AlertThresholds t,
    DateTime now,
  ) sync* {
    final readings = (s.air ?? const [])
        .where((a) => a.pm25 != null && !a.time.isAfter(now))
        .toList();
    if (readings.isEmpty) return;
    final pm = readings.last.pm25!;
    if (pm < t.pm25Attention) return;
    yield TerritoryAlert(
      id: 'rule-air',
      kind: AlertKind.air,
      severity: pm >= t.pm25High ? AlertSeverity.high : AlertSeverity.attention,
      source: AlertSource.rule,
      title: 'Ar com muita poluição (PM2.5)',
      summary: '${pm.toStringAsFixed(1)} µg/m³ agora',
      evidence: [
        'PM2.5 mais recente: ${pm.toStringAsFixed(1)} µg/m³.',
        'Diretriz da OMS (média de 24 h): ${AirLevel.guidelinePm25.toStringAsFixed(0)} µg/m³.',
        'Limiares do app: atenção a partir de ${t.pm25Attention.toStringAsFixed(0)}, '
            'alto a partir de ${t.pm25High.toStringAsFixed(0)} µg/m³.',
      ],
      confidence: AlertConfidence.medium,
      confidenceReason: 'Dado de modelo atmosférico, não de estação de medição.',
      limitations: const [
        'O valor é horário e a diretriz da OMS é de média de 24 horas.',
        'O modelo pode diferir do ar que você respira em um ponto específico.',
      ],
      recommendations: const [
        'Orientação geral: pessoas sensíveis devem reduzir esforço físico ao ar livre.',
      ],
    );
  }

  // ------------------------------------------------------------ estatísticas

  static const _statLimit =
      'É estatística simples (não é aprendizado de máquina) sobre poucos dados.';

  /// Dia previsto muito acima do padrão dos últimos 30 dias (z-score ≥ 2).
  static Iterable<TerritoryAlert> _tempAnomaly(TerritorySnapshot s) sync* {
    final base = [
      for (final d in s.history ?? const <DailyWeather>[]) ?d.tempMax,
    ];
    final days = (s.forecast ?? const []).take(4).toList();
    if (base.length < 15 || days.isEmpty) return;

    var bestIndex = -1;
    var bestZ = 0.0;
    for (var i = 0; i < days.length; i++) {
      final t = days[i].tempMax;
      if (t == null) continue;
      final z = zScore(t, base);
      if (z != null && z > bestZ) {
        bestZ = z;
        bestIndex = i;
      }
    }
    if (bestIndex < 0 || bestZ < 2) return;
    final day = days[bestIndex];
    final avg = mean(base);
    // Evita alarme por diferença pequena quando a série quase não varia.
    if (day.tempMax! - avg < 3) return;

    final ahead = day.date.difference(days.first.date).inDays;
    final fmt = DateFormat('dd/MM');
    yield TerritoryAlert(
      id: 'stat-temp-anomaly',
      kind: AlertKind.heat,
      severity: AlertSeverity.attention,
      source: AlertSource.statistic,
      title: 'Temperatura fora do padrão em ${fmt.format(day.date)}',
      summary: 'Máxima de ${day.tempMax!.toStringAsFixed(0)} °C, '
          '${bestZ.toStringAsFixed(1)} desvios acima do normal recente',
      evidence: [
        'Média das máximas dos últimos ${base.length} dias: ${avg.toStringAsFixed(1)} °C '
            '(desvio padrão ${stdDev(base).toStringAsFixed(1)} °C).',
        'Previsto para ${fmt.format(day.date)}: ${day.tempMax!.toStringAsFixed(1)} °C.',
        'Z-score = (previsto - média) / desvio padrão = ${bestZ.toStringAsFixed(2)}; '
            'o alerta dispara a partir de 2,0 e com pelo menos 3 °C acima da média.',
      ],
      confidence: ahead <= 3 ? AlertConfidence.medium : AlertConfidence.low,
      confidenceReason:
          'Base de ${base.length} dias e previsão para daqui a $ahead dia(s). '
          'Confiança limitada à média.',
      limitations: const [
        _statLimit,
        'Compara com os últimos 30 dias, não com a média histórica da estação do ano.',
        'A previsão de temperatura tem erro que cresce com o prazo.',
      ],
      recommendations: const [
        'Orientação geral: acompanhe a previsão e reforce a hidratação em grupos sensíveis.',
      ],
    );
  }

  /// Tendência de aquecimento nos últimos 30 dias (regressão linear).
  static Iterable<TerritoryAlert> _tempTrend(TerritorySnapshot s) sync* {
    final series = [
      for (final d in s.history ?? const <DailyWeather>[]) ?d.tempMax,
    ];
    final fit = linearFit(series, minPoints: 20);
    if (fit == null) return;
    final change = fit.slope * (fit.n - 1);
    if (change < 3 || fit.r2 < 0.3) return;

    yield TerritoryAlert(
      id: 'stat-temp-trend',
      kind: AlertKind.heat,
      severity: AlertSeverity.info,
      source: AlertSource.statistic,
      title: 'Temperatura em alta nos últimos ${fit.n} dias',
      summary: '+${change.toStringAsFixed(1)} °C no período '
          '(${(fit.slope).toStringAsFixed(2)} °C por dia)',
      evidence: [
        'Regressão linear das temperaturas máximas diárias (${fit.n} dias).',
        'Inclinação: ${fit.slope.toStringAsFixed(2)} °C/dia; variação ajustada: '
            '+${change.toStringAsFixed(1)} °C.',
        'R² = ${fit.r2.toStringAsFixed(2)} (0 = reta não explica nada; 1 = explica tudo).',
      ],
      confidence: fit.r2 >= 0.6 ? AlertConfidence.medium : AlertConfidence.low,
      confidenceReason:
          'R² de ${fit.r2.toStringAsFixed(2)} em ${fit.n} pontos: '
          '${fit.r2 >= 0.6 ? 'a reta explica boa parte da variação' : 'a reta explica pouco da variação'}.',
      limitations: const [
        _statLimit,
        'Um mês não separa tendência de mudança normal de estação.',
        'Uma onda de calor curta pode puxar a reta e não indicar mudança duradoura.',
      ],
      recommendations: const [
        'Apenas informativo: use junto com a previsão dos próximos dias.',
      ],
    );
  }

  /// Projeta o PM2.5 das próximas 12 h (Holt) quando a tendência é de piora.
  static Iterable<TerritoryAlert> _airProjection(
    TerritorySnapshot s,
    AlertThresholds t,
    DateTime now,
  ) sync* {
    final readings = (s.air ?? const [])
        .where((a) => a.pm25 != null && !a.time.isAfter(now))
        .toList();
    if (readings.length < 24) return;
    final recent = [
      for (final r in readings.sublist(readings.length - 24)) r.pm25!,
    ];
    final current = recent.last;
    final projected = holtForecast(recent, 12);
    final fit = linearFit(recent);
    if (projected == null || fit == null) return;
    // Se já está acima do limiar, a regra normal de ar cobre o caso.
    if (current >= t.pm25Attention) return;
    if (projected < t.pm25Attention || fit.slope <= 0) return;

    yield TerritoryAlert(
      id: 'stat-air-forecast',
      kind: AlertKind.air,
      severity:
          projected >= t.pm25High ? AlertSeverity.high : AlertSeverity.attention,
      source: AlertSource.statistic,
      title: 'Ar pode piorar nas próximas 12 h (PM2.5)',
      summary: 'De ${current.toStringAsFixed(1)} para cerca de '
          '${projected.toStringAsFixed(1)} µg/m³',
      evidence: [
        'PM2.5 atual: ${current.toStringAsFixed(1)} µg/m³; últimas 24 h em alta '
            '(${fit.slope.toStringAsFixed(2)} µg/m³ por hora).',
        'Projeção por suavização exponencial dupla (Holt, α=0,5 e β=0,3) para 12 h: '
            '${projected.toStringAsFixed(1)} µg/m³.',
        'R² da tendência das 24 h = ${fit.r2.toStringAsFixed(2)}. '
            'Limiar de atenção do app: ${t.pm25Attention.toStringAsFixed(0)} µg/m³.',
      ],
      confidence: fit.r2 >= 0.6 ? AlertConfidence.medium : AlertConfidence.low,
      confidenceReason:
          'Projeção a partir de 24 leituras; R² de ${fit.r2.toStringAsFixed(2)}. '
          'Nunca é alta: o ar muda com vento e chuva.',
      limitations: const [
        _statLimit,
        'Não considera vento, chuva, queimadas nem o ciclo diário do trânsito.',
        'Os dados vêm de modelo atmosférico, não de estação de medição.',
      ],
      recommendations: const [
        'Orientação geral: pessoas sensíveis podem antecipar atividades ao ar livre.',
      ],
    );
  }
}
