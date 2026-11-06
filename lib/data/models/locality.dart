/// Estado (UF) da API de localidades do IBGE.
class UfInfo {
  const UfInfo({required this.sigla, required this.nome});

  final String sigla;
  final String nome;

  factory UfInfo.fromJson(Map<String, dynamic> j) =>
      UfInfo(sigla: j['sigla'] as String, nome: j['nome'] as String);
}

/// Município da API de localidades do IBGE.
class Municipality {
  const Municipality({required this.ibgeCode, required this.nome});

  final String ibgeCode;
  final String nome;

  factory Municipality.fromJson(Map<String, dynamic> j) => Municipality(
        ibgeCode: (j['id'] as num).toInt().toString(),
        nome: j['nome'] as String,
      );
}
