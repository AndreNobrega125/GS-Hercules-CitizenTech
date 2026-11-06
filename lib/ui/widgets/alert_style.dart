import 'package:flutter/material.dart';

import '../../domain/territory_alert.dart';

/// Aparência de um alerta: sempre ícone + texto, além da cor.
class AlertStyle {
  const AlertStyle({required this.background, required this.foreground, required this.icon});

  final Color background;
  final Color foreground;
  final IconData icon;

  factory AlertStyle.of(BuildContext context, AlertSeverity severity) {
    final s = Theme.of(context).colorScheme;
    return switch (severity) {
      AlertSeverity.info => AlertStyle(
          background: s.secondaryContainer,
          foreground: s.onSecondaryContainer,
          icon: Icons.info_outline,
        ),
      AlertSeverity.attention => AlertStyle(
          background: s.tertiaryContainer,
          foreground: s.onTertiaryContainer,
          icon: Icons.warning_amber,
        ),
      AlertSeverity.high || AlertSeverity.critical => AlertStyle(
          background: s.errorContainer,
          foreground: s.onErrorContainer,
          icon: Icons.report,
        ),
    };
  }

  static IconData kindIcon(AlertKind kind) => switch (kind) {
        AlertKind.rain => Icons.water_drop,
        AlertKind.storm => Icons.thunderstorm,
        AlertKind.wind => Icons.air,
        AlertKind.heat => Icons.wb_sunny,
        AlertKind.air => Icons.masks,
        AlertKind.other => Icons.notifications_active,
      };
}
