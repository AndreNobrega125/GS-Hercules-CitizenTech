import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/core/theme/app_theme.dart';

/// Razão de contraste WCAG 2.x entre duas cores opacas.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final themes = {
    'claro': AppTheme.light(),
    'escuro': AppTheme.dark(),
    'alto contraste': AppTheme.highContrast(),
  };

  for (final entry in themes.entries) {
    final s = entry.value.colorScheme;

    // Texto: WCAG AA exige 4,5:1.
    final textPairs = {
      'texto na tela': (s.onSurface, s.surface),
      'texto no cartão': (s.onSurface, s.surfaceContainerHighest),
      'texto secundário no cartão': (s.onSurfaceVariant, s.surfaceContainerHighest),
      // Cor que o tema realmente aplica aos TextButton.
      'botão de texto no cartão': (
        entry.value.textButtonTheme.style!.foregroundColor!.resolve({})!,
        s.surfaceContainerHighest,
      ),
      'botão preenchido': (s.onPrimary, s.primary),
      'alerta informativo': (s.onSecondaryContainer, s.secondaryContainer),
      'alerta de atenção': (s.onTertiaryContainer, s.tertiaryContainer),
      'alerta alto/crítico': (s.onErrorContainer, s.errorContainer),
    };
    for (final p in textPairs.entries) {
      test('${entry.key}: ${p.key} >= 4,5:1', () {
        final ratio = contrast(p.value.$1, p.value.$2);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: ratio.toStringAsFixed(2));
      });
    }

    // Elementos gráficos (linhas dos gráficos, ícones): WCAG pede 3:1.
    final graphicPairs = {
      'linha primária do gráfico': (s.primary, s.surfaceContainerHighest),
      'linha de previsão do gráfico': (s.tertiary, s.surfaceContainerHighest),
      'linha da diretriz OMS': (s.error, s.surfaceContainerHighest),
    };
    for (final p in graphicPairs.entries) {
      test('${entry.key}: ${p.key} >= 3:1', () {
        final ratio = contrast(p.value.$1, p.value.$2);
        expect(ratio, greaterThanOrEqualTo(3.0), reason: ratio.toStringAsFixed(2));
      });
    }
  }
}
