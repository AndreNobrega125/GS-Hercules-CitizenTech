/// Aviso meteorológico oficial do INMET.
class OfficialWarning {
  const OfficialWarning({
    this.id = '',
    required this.description,
    required this.severity,
    required this.colorHex,
    required this.start,
    required this.end,
    required this.risks,
    required this.instructions,
  });

  final String id;
  final String description;
  final String severity;
  final String colorHex;
  final String start;
  final String end;
  final List<String> risks;
  final List<String> instructions;

  factory OfficialWarning.fromJson(Map<String, dynamic> j) {
    List<String> strings(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];
    return OfficialWarning(
      id: (j['id_aviso'] ?? j['id'] ?? '').toString(),
      description: (j['descricao'] ?? '').toString(),
      severity: (j['severidade'] ?? '').toString(),
      colorHex: (j['aviso_cor'] ?? '#888888').toString(),
      start: (j['inicio'] ?? '').toString(),
      end: (j['fim'] ?? '').toString(),
      risks: strings(j['riscos']),
      instructions: strings(j['instrucoes']),
    );
  }
}
