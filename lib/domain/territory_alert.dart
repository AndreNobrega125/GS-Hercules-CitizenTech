enum AlertKind {
  rain('Chuva'),
  storm('Tempestade'),
  wind('Vento'),
  heat('Calor'),
  air('Qualidade do ar'),
  other('Outros');

  const AlertKind(this.label);
  final String label;
}

enum AlertSeverity {
  info('Informativo'),
  attention('Atenção'),
  high('Alto'),
  critical('Crítico');

  const AlertSeverity(this.label);
  final String label;
}

enum AlertConfidence {
  high('Alta'),
  medium('Média'),
  low('Baixa');

  const AlertConfidence(this.label);
  final String label;
}

enum AlertSource {
  official('Aviso oficial (INMET)'),
  rule('Regra do app'),
  statistic('Análise estatística');

  const AlertSource(this.label);
  final String label;
}

/// Alerta mostrado ao usuário, sempre com evidência, confiança e limitações.
class TerritoryAlert {
  const TerritoryAlert({
    required this.id,
    required this.kind,
    required this.severity,
    required this.source,
    required this.title,
    required this.summary,
    required this.evidence,
    required this.confidence,
    required this.confidenceReason,
    required this.limitations,
    required this.recommendations,
    this.leadDays,
    this.pastDate,
  });

  final String id;
  final AlertKind kind;
  final AlertSeverity severity;
  final AlertSource source;
  final String title;
  final String summary;

  /// Por que o alerta existe (dados e valores usados).
  final List<String> evidence;
  final AlertConfidence confidence;
  final String confidenceReason;

  /// Quando e por que o alerta pode estar errado ou incompleto.
  final List<String> limitations;
  final List<String> recommendations;

  /// Dias entre hoje e o evento previsto (só alertas com data prevista).
  final int? leadDays;

  /// Dia em que o evento aconteceu, quando é um alerta de data antiga
  /// (histórico dos últimos 7 dias). `null` nos alertas ativos.
  final DateTime? pastDate;

  bool get isPast => pastDate != null;
}
