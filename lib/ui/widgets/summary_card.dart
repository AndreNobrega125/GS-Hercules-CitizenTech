import 'package:flutter/material.dart';

/// Cartão de destaque da visão geral: um número grande, um título e uma
/// legenda. Sempre tem ícone e texto além da cor, e abre o dashboard ao toque.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      button: onTap != null,
      excludeSemantics: true,
      label: '$title: $value. $caption.${onTap == null ? '' : ' Toque para abrir.'}',
      child: Card(
        color: background,
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: foreground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleSmall?.copyWith(color: foreground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: text.headlineMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(caption, style: text.bodySmall?.copyWith(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
