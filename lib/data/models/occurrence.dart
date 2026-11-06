enum OccurrenceType {
  flooding('Alagamento'),
  waste('Lixo ou resíduos'),
  water('Falta de água'),
  power('Falta de energia'),
  heatAir('Calor ou ar ruim'),
  other('Outro');

  const OccurrenceType(this.label);
  final String label;
}

/// Ocorrência registrada por um cidadão ou gestor. Não guarda nome nem contato.
class Occurrence {
  const Occurrence({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.description,
    required this.territoryName,
    required this.ibgeCode,
    this.neighborhood,
  });

  final String id;
  final DateTime createdAt;
  final OccurrenceType type;
  final String description;
  final String? neighborhood;
  final String territoryName;
  final String ibgeCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
        'description': description,
        'neighborhood': neighborhood,
        'territoryName': territoryName,
        'ibgeCode': ibgeCode,
      };

  factory Occurrence.fromJson(Map<String, dynamic> j) => Occurrence(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        type: OccurrenceType.values.byName(j['type'] as String),
        description: j['description'] as String,
        neighborhood: j['neighborhood'] as String?,
        territoryName: j['territoryName'] as String,
        ibgeCode: j['ibgeCode'] as String,
      );
}
