@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/core/territory.dart';
import 'package:radar_territorio/data/models/occurrence.dart';
import 'package:radar_territorio/data/services/supabase_service.dart';

/// Teste real contra o Supabase (precisa de rede e do --dart-define-from-file).
/// Grava UMA linha com profile_id `teste-automatico`; a chave pública não apaga,
/// então remova a linha depois no Table Editor.
void main() {
  test('grava e lê de volta uma ocorrência no Supabase real', skip: SupabaseConfig.enabled
      ? null
      : 'rode com --dart-define-from-file=supabase.json', () async {
    final remote = SupabaseService();
    final id = 'teste-${DateTime.now().microsecondsSinceEpoch}';
    final o = Occurrence(
      id: id,
      createdAt: DateTime.now(),
      type: OccurrenceType.other,
      description: 'Teste automático de conexão (pode apagar)',
      territoryName: Territory.saoPaulo.label,
      ibgeCode: Territory.saoPaulo.ibgeCode,
    );

    await remote.upsert('teste-automatico', o);
    final back = await remote.fetch('teste-automatico');
    expect(back.map((e) => e.id), contains(id));

    // Reenviar o mesmo id não duplica (ignore-duplicates).
    await remote.upsert('teste-automatico', o);
    final again = await remote.fetch('teste-automatico');
    expect(again.where((e) => e.id == id), hasLength(1));

    // ignore: avoid_print
    print('GRAVAÇÃO E LEITURA OK: id $id está no banco.');
  });
}
