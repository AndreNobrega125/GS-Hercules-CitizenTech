import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Eixos dos gráficos com a fonte do tema (pequena, cor de texto secundário),
/// em vez do estilo padrão do fl_chart, que ficava grande e cortava rótulos.
class ChartAxis {
  const ChartAxis._();

  static TextStyle? style(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// Altura reservada para um rótulo de uma linha, acompanhando a fonte do usuário.
  static double labelHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) + 14;

  /// Eixo vertical com valores inteiros, sem os extremos para não sobrepor.
  static SideTitles left(BuildContext context) => SideTitles(
        showTitles: true,
        reservedSize: MediaQuery.textScalerOf(context).scale(12) * 2.4 + 8,
        minIncluded: false,
        maxIncluded: false,
        getTitlesWidget: (value, meta) => SideTitleWidget(
          meta: meta,
          child: Text(meta.formattedValue, style: style(context)),
        ),
      );

  /// Eixo horizontal com um rótulo por posição, vindo de [label].
  static SideTitles bottom(
    BuildContext context,
    String Function(int index) label,
  ) =>
      SideTitles(
        showTitles: true,
        reservedSize: labelHeight(context),
        interval: 1,
        getTitlesWidget: (value, meta) => SideTitleWidget(
          meta: meta,
          child: Text(label(value.toInt()), style: style(context)),
        ),
      );
}
