import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:radar_territorio/data/services/map_cache.dart';

void main() {
  // Caixa aproximada do município de São Paulo.
  final sp = LatLngBounds(const LatLng(-24.0, -46.83), const LatLng(-23.36, -46.36));

  test('plano de tiles cobre a caixa e respeita o limite', () {
    final tiles = MapCache.plan(sp);
    expect(tiles, isNotEmpty);
    expect(tiles.length, lessThanOrEqualTo(MapCache.maxTiles));
    // Todos os níveis começam no zoom mínimo e ficam dentro dos limites do mapa.
    expect(tiles.first.z, 6);
    for (final t in tiles) {
      expect(t.x, inInclusiveRange(0, (1 << t.z) - 1));
      expect(t.y, inInclusiveRange(0, (1 << t.z) - 1));
    }
  });

  test('um município muito grande para no zoom que ainda cabe', () {
    final big = LatLngBounds(const LatLng(-10, -60), const LatLng(0, -50));
    final tiles = MapCache.plan(big);
    expect(tiles.length, lessThanOrEqualTo(MapCache.maxTiles));
    final maxZ = tiles.map((t) => t.z).reduce((a, b) => a > b ? a : b);
    expect(maxZ, lessThan(13));
  });

  test('URL do tile segue o padrão do OpenStreetMap', () {
    expect(
      MapCache.urlOf((z: 9, x: 232, y: 358)),
      'https://tile.openstreetmap.org/9/232/358.png',
    );
  });

  test('coordenada conhecida cai no tile certo (São Paulo, zoom 9)', () {
    final p = LatLngBounds(const LatLng(-23.55, -46.63), const LatLng(-23.55, -46.63));
    final t = MapCache.plan(p, minZoom: 9, maxZoom: 9).single;
    expect((t.x, t.y), (189, 290));
  });
}
