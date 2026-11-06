import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../domain/alert_engine.dart';
import '../../state/territory_provider.dart';

/// Formulário para ajustar os limiares das regras de alerta do perfil.
class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  static String _s(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    _c = _controllersFor(context.read<TerritoryProvider>().thresholds);
  }

  Map<String, TextEditingController> _controllersFor(AlertThresholds t) => {
        'rainA': TextEditingController(text: _s(t.rainAttentionMm)),
        'rainH': TextEditingController(text: _s(t.rainHighMm)),
        'pmA': TextEditingController(text: _s(t.pm25Attention)),
        'pmH': TextEditingController(text: _s(t.pm25High)),
        'heatA': TextEditingController(text: _s(t.heatAttentionC)),
        'heatH': TextEditingController(text: _s(t.heatHighC)),
      };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    await context.read<TerritoryProvider>().setThresholds(
          Validators.thresholdsFrom(
            rainAttention: _c['rainA']!.text,
            rainHigh: _c['rainH']!.text,
            pm25Attention: _c['pmA']!.text,
            pm25High: _c['pmH']!.text,
            heatAttention: _c['heatA']!.text,
            heatHigh: _c['heatH']!.text,
          ),
        );
    messenger.showSnackBar(
      const SnackBar(content: Text('Limiares salvos. Alertas recalculados.')),
    );
  }

  void _reset() {
    final d = AlertThresholds.defaults;
    _c['rainA']!.text = _s(d.rainAttentionMm);
    _c['rainH']!.text = _s(d.rainHighMm);
    _c['pmA']!.text = _s(d.pm25Attention);
    _c['pmH']!.text = _s(d.pm25High);
    _c['heatA']!.text = _s(d.heatAttentionC);
    _c['heatH']!.text = _s(d.heatHighC);
    _formKey.currentState?.validate();
  }

  Widget _field(
    String key,
    String label,
    String unit,
    ({double min, double max}) range, {
    String? Function(String?)? extra,
    bool last = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          border: const OutlineInputBorder(),
        ),
        validator: (v) =>
            Validators.number(v, label: label, min: range.min, max: range.max) ??
            extra?.call(v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Limiares de alerta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Os alertas por regra usam estes valores. Eles são do app, não '
              'critérios oficiais: ajuste conforme a realidade do seu município.',
            ),
            const SizedBox(height: 16),
            Text('Chuva em 1 dia', style: text.titleMedium),
            const SizedBox(height: 8),
            _field('rainA', 'Atenção', 'mm', Validators.rainRange),
            _field(
              'rainH',
              'Alto',
              'mm',
              Validators.rainRange,
              extra: (v) => Validators.highAboveAttention(v, _c['rainA']!.text),
            ),
            Text('Calor (temperatura máxima)', style: text.titleMedium),
            const SizedBox(height: 8),
            _field('heatA', 'Atenção', '°C', Validators.heatRange),
            _field(
              'heatH',
              'Alto',
              '°C',
              Validators.heatRange,
              extra: (v) => Validators.highAboveAttention(v, _c['heatA']!.text),
            ),
            Text('Poluição do ar (PM2.5)', style: text.titleMedium),
            const SizedBox(height: 8),
            _field('pmA', 'Atenção', 'µg/m³', Validators.pm25Range),
            _field(
              'pmH',
              'Alto',
              'µg/m³',
              Validators.pm25Range,
              extra: (v) => Validators.highAboveAttention(v, _c['pmA']!.text),
              last: true,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
              onPressed: _save,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restaurar padrão'),
              onPressed: _reset,
            ),
          ],
        ),
      ),
    );
  }
}
