import 'package:latlong2/latlong.dart';

/// Contorno do município (anéis externos), vindo da malha do IBGE.
class CityBoundary {
  const CityBoundary(this.rings);

  final List<List<LatLng>> rings;

  /// Lê um GeoJSON `FeatureCollection` com `Polygon` ou `MultiPolygon`.
  factory CityBoundary.fromGeoJson(Map<String, dynamic> json) {
    final rings = <List<LatLng>>[];
    List<LatLng> ring(List<dynamic> coords) => [
          for (final c in coords)
            LatLng(
              ((c as List)[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ),
        ];

    for (final feature in json['features'] as List) {
      final geometry = (feature as Map<String, dynamic>)['geometry']
          as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List;
      switch (geometry['type']) {
        case 'Polygon':
          rings.add(ring(coords.first as List));
        case 'MultiPolygon':
          for (final polygon in coords) {
            rings.add(ring((polygon as List).first as List));
          }
      }
    }
    return CityBoundary(rings);
  }
}
