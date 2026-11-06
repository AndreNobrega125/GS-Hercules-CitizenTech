import '../domain/alert_engine.dart';

/// Regras de validação dos formulários (puras, sem Flutter, fáceis de testar).
class Validators {
  Validators._();

  /// Converte "12,5" ou "12.5" em número; `null` se não for número.
  static double? parseNumber(String? v) =>
      double.tryParse((v ?? '').trim().replaceAll(',', '.'));

  static String? number(
    String? v, {
    required String label,
    required double min,
    required double max,
  }) {
    if ((v ?? '').trim().isEmpty) return 'Informe $label.';
    final n = parseNumber(v);
    if (n == null) return 'Use apenas números (ex.: 30 ou 30,5).';
    if (n < min || n > max) {
      return '$label deve ficar entre ${_fmt(min)} e ${_fmt(max)}.';
    }
    return null;
  }

  /// O nível "alto" precisa ser maior que o de "atenção".
  static String? highAboveAttention(String? high, String? attention) {
    final h = parseNumber(high);
    final a = parseNumber(attention);
    if (h == null || a == null) return null;
    return h > a ? null : 'O nível alto deve ser maior que o de atenção.';
  }

  static String? description(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Descreva o que está acontecendo.';
    if (text.length < 10) return 'Escreva pelo menos 10 caracteres.';
    if (text.length > 280) return 'Use no máximo 280 caracteres.';
    return personalData(text);
  }

  static String? neighborhood(String? v) {
    final text = (v ?? '').trim();
    if (text.length > 60) return 'Use no máximo 60 caracteres.';
    return text.isEmpty ? null : personalData(text);
  }

  /// Bloqueia e-mail e sequências longas de dígitos (telefone, CPF, CEP).
  static String? personalData(String text) {
    const msg = 'Não escreva e-mail, telefone, CPF ou CEP: o registro é anônimo.';
    if (text.contains('@')) return msg;
    final digits = RegExp(r'\d').allMatches(text).length;
    if (digits >= 8) return msg;
    return null;
  }

  static String _fmt(double n) =>
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString();

  /// Faixas aceitas para os limiares de alerta.
  static const rainRange = (min: 5.0, max: 300.0);
  static const pm25Range = (min: 5.0, max: 500.0);
  static const heatRange = (min: 25.0, max: 50.0);

  /// Monta os limiares a partir dos textos já validados.
  static AlertThresholds thresholdsFrom({
    required String rainAttention,
    required String rainHigh,
    required String pm25Attention,
    required String pm25High,
    required String heatAttention,
    required String heatHigh,
  }) =>
      AlertThresholds(
        rainAttentionMm: parseNumber(rainAttention)!,
        rainHighMm: parseNumber(rainHigh)!,
        pm25Attention: parseNumber(pm25Attention)!,
        pm25High: parseNumber(pm25High)!,
        heatAttentionC: parseNumber(heatAttention)!,
        heatHighC: parseNumber(heatHigh)!,
      );
}
