import 'package:flutter/material.dart';

import '../../domain/territory_alert.dart';
import 'alert_style.dart';

/// Faixa de destaque com o alerta mais grave e a contagem total.
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.alerts, required this.onTap});

  final List<TerritoryAlert> alerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final top = alerts.first;
    final style = AlertStyle.of(context, top.severity);
    final others = alerts.length - 1;
    final text = '${top.title} · ${top.severity.label}'
        '${others > 0 ? ' (+$others alerta(s))' : ''}';
    return Semantics(
      button: true,
      label: 'Alerta: $text. Toque para ver os alertas.',
      excludeSemantics: true,
      child: Card(
        color: style.background,
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(style.icon, color: style.foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: style.foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Apoio à decisão: a decisão final é sempre humana.',
                        style: TextStyle(color: style.foreground),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: style.foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
