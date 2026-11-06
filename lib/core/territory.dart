/// Município monitorado pelo app, escolhido pelo usuário.
/// As coordenadas são opcionais: quando ausentes, saem do contorno do IBGE.
class Territory {
  const Territory({
    required this.ibgeCode,
    required this.name,
    required this.uf,
    this.latitude,
    this.longitude,
  });

  /// Território inicial do app.
  static const saoPaulo = Territory(
    ibgeCode: '3550308',
    name: 'São Paulo',
    uf: 'SP',
    latitude: -23.55,
    longitude: -46.63,
  );

  final String ibgeCode;
  final String name;
  final String uf;
  final double? latitude;
  final double? longitude;

  String get label => '$name - $uf';

  Map<String, dynamic> toJson() => {
        'ibgeCode': ibgeCode,
        'name': name,
        'uf': uf,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory Territory.fromJson(Map<String, dynamic> j) => Territory(
        ibgeCode: j['ibgeCode'] as String,
        name: j['name'] as String,
        uf: j['uf'] as String,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
      );
}
