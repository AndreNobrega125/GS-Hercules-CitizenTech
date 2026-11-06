import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/territory.dart';
import '../../domain/alert_engine.dart';
import '../../data/models/city_boundary.dart';
import '../../data/models/official_warning.dart';
import '../../state/territory_provider.dart';
import '../widgets/empty_state.dart';

class RisksScreen extends StatelessWidget {
  const RisksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<TerritoryProvider>().snapshot;
    final warnings = snapshot?.warnings;

    return Scaffold(
      appBar: AppBar(title: const Text('Riscos oficiais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TerritoryMap(boundary: snapshot?.boundary),
          const SizedBox(height: 12),
          Text(
            'Avisos do INMET para São Paulo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (warnings == null)
            const EmptyState(
              icon: Icons.cloud_off,
              message: 'Sem dados de avisos. Volte e atualize.',
            )
          else if (warnings.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline,
              message: 'Nenhum aviso ativo para São Paulo agora.',
            )
          else
            for (var i = 0; i < warnings.length; i++)
              _WarningCard(
                warning: warnings[i],
                alertId: AlertEngine.officialId(i, warnings[i]),
              ),
          const SizedBox(height: 8),
          const Text(
            'Avisos oficiais apoiam, mas não substituem, a decisão humana. '
            'Em emergência, procure a Defesa Civil (199).',
          ),
        ],
      ),
    );
  }
}

class _TerritoryMap extends StatelessWidget {
  const _TerritoryMap({required this.boundary});

  final CityBoundary? boundary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Mapa do município de São Paulo com o contorno da cidade.',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 260,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(Territory.latitude, Territory.longitude),
              initialZoom: 9.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.fiap.radar_territorio',
              ),
              if (boundary != null)
                PolygonLayer(polygons: [
                  for (final ring in boundary!.rings)
                    Polygon(
                      points: ring,
                      color: scheme.primary.withValues(alpha: 0.2),
                      borderColor: scheme.primary,
                      borderStrokeWidth: 3,
                    ),
                ]),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warning, required this.alertId});

  final OfficialWarning warning;
  final String alertId;

  Color get _color {
    final hex = warning.colorHex.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    return value == null ? Colors.grey : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(Icons.warning_amber, color: _color),
        title: Text(warning.description),
        subtitle: Text('${warning.severity} · até ${warning.end}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warning.risks.isNotEmpty) ...[
            const Text('Riscos', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final r in warning.risks) Text('• $r'),
            const SizedBox(height: 8),
          ],
          if (warning.instructions.isNotEmpty) ...[
            const Text('Instruções', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final i in warning.instructions) Text('• $i'),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.fact_check),
              label: const Text('Ver justificativa e confiança'),
              onPressed: () => context.pushNamed(
                Routes.alertDetail,
                pathParameters: {'id': alertId},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
