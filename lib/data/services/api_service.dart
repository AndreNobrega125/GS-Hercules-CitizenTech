import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// Acesso às APIs públicas (IBGE, Open-Meteo e INMET).
/// Cada método devolve JSON bruto (ou já filtrado), pronto para cache.
class ApiService {
  ApiService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final Dio _dio;

  static final _day = DateFormat('yyyy-MM-dd');
  static const _dailyVars = 'temperature_2m_max,temperature_2m_min,precipitation_sum';

  // ------------------------------------------------------- localidades (IBGE)

  Future<List<dynamic>> states() async {
    final r = await _dio.get<List<dynamic>>(
      'https://servicodados.ibge.gov.br/api/v1/localidades/estados',
      queryParameters: {'orderBy': 'nome'},
    );
    return r.data!;
  }

  Future<List<dynamic>> municipalities(String uf) async {
    final r = await _dio.get<List<dynamic>>(
      'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$uf/municipios',
      queryParameters: {'orderBy': 'nome'},
    );
    return r.data!;
  }

  /// Contorno do município (malha do IBGE, GeoJSON).
  Future<Map<String, dynamic>> boundary(String ibgeCode) async {
    final r = await _dio.get<String>(
      'https://servicodados.ibge.gov.br/api/v3/malhas/municipios/'
      '$ibgeCode?formato=application/vnd.geo+json',
      options: Options(responseType: ResponseType.plain),
    );
    return jsonDecode(r.data!) as Map<String, dynamic>;
  }

  /// População estimada (SIDRA, tabela 6579). Devolve o número de habitantes.
  Future<int> population(String ibgeCode) async {
    final r = await _dio.get<List<dynamic>>(
      'https://apisidra.ibge.gov.br/values/t/6579/n6/$ibgeCode/v/9324/p/last',
    );
    // O item 0 é o cabeçalho; o item 1 traz o valor em "V".
    return int.parse((r.data![1] as Map<String, dynamic>)['V'].toString());
  }

  // ------------------------------------------------------------- Open-Meteo

  Future<Map<String, dynamic>> forecast(double lat, double lon) async {
    final r = await _dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'daily': _dailyVars,
        'timezone': 'auto',
        'forecast_days': 7,
      },
    );
    return r.data!;
  }

  /// Histórico dos últimos 30 dias (termina anteontem, pois o arquivo atrasa).
  Future<Map<String, dynamic>> history(double lat, double lon) async {
    final end = DateTime.now().subtract(const Duration(days: 2));
    final start = end.subtract(const Duration(days: 29));
    final r = await _dio.get<Map<String, dynamic>>(
      'https://archive-api.open-meteo.com/v1/archive',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'start_date': _day.format(start),
        'end_date': _day.format(end),
        'daily': _dailyVars,
        'timezone': 'auto',
      },
    );
    return r.data!;
  }

  Future<Map<String, dynamic>> airQuality(double lat, double lon) async {
    final r = await _dio.get<Map<String, dynamic>>(
      'https://air-quality-api.open-meteo.com/v1/air-quality',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'hourly': 'pm2_5,pm10',
        'past_days': 7,
        'timezone': 'auto',
      },
    );
    return r.data!;
  }

  // ------------------------------------------------------------------ INMET

  /// Avisos ativos do INMET filtrados pelo código IBGE do município.
  /// A resposta completa é grande (~600 KB), por isso filtramos aqui.
  Future<List<Map<String, dynamic>>> warnings(String ibgeCode) async {
    final r = await _dio.get<Map<String, dynamic>>(
      'https://apiprevmet3.inmet.gov.br/avisos/ativos',
    );
    final result = <Map<String, dynamic>>[];
    for (final value in r.data!.values) {
      if (value is! List) continue;
      for (final item in value) {
        final geocodes = (item as Map<String, dynamic>)['geocodes'];
        if (geocodes is String &&
            geocodes.split(',').map((e) => e.trim()).contains(ibgeCode)) {
          result.add(item);
        }
      }
    }
    return result;
  }
}
