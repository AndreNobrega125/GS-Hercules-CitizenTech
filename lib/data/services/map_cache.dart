import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';

/// Um tile do mapa (zoom z, coluna x, linha y).
typedef MapTile = ({int z, int x, int y});

/// Mapa offline: estende a validade dos tiles já vistos e baixa de antemão
/// uma quantidade PEQUENA de tiles do município atual (ação do usuário).
class MapCache {
  MapCache._();

  static const urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgent = 'br.com.fiap.radar_territorio';

  /// Por quanto tempo um tile salvo vale (o servidor dá ~7 dias; offline isso
  /// deixaria o mapa em branco).
  static const freshAge = Duration(days: 30);

  /// Limite de tiles por download: respeita a política de uso do OpenStreetMap
  /// (nada de download em massa).
  static const maxTiles = 80;

  /// Prepara o cache de tiles. Chamar uma vez, antes de mostrar qualquer mapa.
  static void init() {
    BuiltInMapCachingProvider.getOrCreateInstance(
      overrideFreshAge: freshAge,
      maxCacheSize: 200 * 1000 * 1000,
    );
  }

  /// Tiles que cobrem [bounds], do menos para o mais detalhado, sem passar de
  /// [limit] no total (para no último zoom que ainda cabe).
  static List<MapTile> plan(
    LatLngBounds bounds, {
    int limit = maxTiles,
    int minZoom = 6,
    int maxZoom = 13,
  }) {
    final tiles = <MapTile>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final x0 = _x(bounds.west, z);
      final x1 = _x(bounds.east, z);
      final y0 = _y(bounds.north, z);
      final y1 = _y(bounds.south, z);
      final count = (x1 - x0 + 1) * (y1 - y0 + 1);
      if (tiles.length + count > limit) break;
      for (var x = x0; x <= x1; x++) {
        for (var y = y0; y <= y1; y++) {
          tiles.add((z: z, x: x, y: y));
        }
      }
    }
    return tiles;
  }

  static int _x(double lon, int z) =>
      (((lon + 180) / 360) * (1 << z)).floor().clamp(0, (1 << z) - 1);

  static int _y(double lat, int z) {
    final rad = lat.clamp(-85.0511, 85.0511) * math.pi / 180;
    final v = (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2;
    return (v * (1 << z)).floor().clamp(0, (1 << z) - 1);
  }

  static String urlOf(MapTile t) => urlTemplate
      .replaceFirst('{z}', '${t.z}')
      .replaceFirst('{x}', '${t.x}')
      .replaceFirst('{y}', '${t.y}');

  /// Baixa os tiles de [bounds] para o cache. Devolve quantos foram salvos.
  /// [onProgress] recebe (feitos, total). Falhas isoladas são ignoradas.
  static Future<int> prefetch(
    LatLngBounds bounds, {
    void Function(int done, int total)? onProgress,
    Dio? dio,
  }) async {
    final cache = BuiltInMapCachingProvider.getOrCreateInstance(
      overrideFreshAge: freshAge,
      maxCacheSize: 200 * 1000 * 1000,
    );
    if (!cache.isSupported) return 0;
    final client = dio ??
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.bytes,
          headers: {'User-Agent': userAgent},
        ));
    final tiles = plan(bounds);
    var saved = 0;
    for (var i = 0; i < tiles.length; i++) {
      final url = urlOf(tiles[i]);
      try {
        final r = await client.get<List<int>>(url);
        await cache.putTile(
          url: url,
          metadata: CachedMapTileMetadata(
            staleAt: DateTime.timestamp().add(freshAge),
            lastModified: null,
            etag: null,
          ),
          bytes: Uint8List.fromList(r.data!),
        );
        saved++;
      } catch (_) {
        // Um tile que falha não impede os outros.
      }
      onProgress?.call(i + 1, tiles.length);
      // Pausa curta para não sobrecarregar o servidor de mapas.
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return saved;
  }
}
