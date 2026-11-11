import 'package:dio/dio.dart';

import '../models/occurrence.dart';

/// Configuração do Supabase, lida em tempo de build (`--dart-define-from-file=supabase.json`).
/// Sem os valores, o app funciona só com dados locais.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;
}

/// Contrato de sincronização das ocorrências (permite trocar por um falso nos testes).
abstract class OccurrenceRemote {
  Future<void> upsert(String profileId, Occurrence o);
  Future<List<Occurrence>> fetch(String profileId);
}

/// Acesso à API REST (PostgREST) do Supabase com a chave pública (anon/publishable).
/// A proteção dos dados é feita pelo RLS no banco (ver `supabase/schema.sql`).
class SupabaseService implements OccurrenceRemote {
  SupabaseService({String? url, String? anonKey, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: '${url ?? SupabaseConfig.url}/rest/v1',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'apikey': anonKey ?? SupabaseConfig.anonKey,
                'Content-Type': 'application/json',
              },
            ));

  final Dio _dio;

  @override
  Future<void> upsert(String profileId, Occurrence o) async {
    await _dio.post<void>(
      '/occurrences',
      data: {
        'id': o.id,
        'profile_id': profileId,
        'created_at': o.createdAt.toUtc().toIso8601String(),
        'type': o.type.name,
        'description': o.description,
        'neighborhood': o.neighborhood,
        'territory_name': o.territoryName,
        'ibge_code': o.ibgeCode,
      },
      options: Options(headers: {'Prefer': 'resolution=ignore-duplicates'}),
      queryParameters: {'on_conflict': 'id'},
    );
  }

  @override
  Future<List<Occurrence>> fetch(String profileId) async {
    final r = await _dio.get<List<dynamic>>(
      '/occurrences',
      queryParameters: {
        'profile_id': 'eq.$profileId',
        'select': '*',
        'order': 'created_at.desc',
        'limit': 200,
      },
    );
    return [
      for (final e in r.data!)
        Occurrence(
          id: (e as Map<String, dynamic>)['id'] as String,
          createdAt: DateTime.parse(e['created_at'] as String).toLocal(),
          type: OccurrenceType.values.byName(e['type'] as String),
          description: e['description'] as String,
          neighborhood: e['neighborhood'] as String?,
          territoryName: e['territory_name'] as String,
          ibgeCode: e['ibge_code'] as String,
        ),
    ];
  }
}
