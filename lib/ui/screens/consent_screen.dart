import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/settings_provider.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text('Radar do Território', style: text.headlineMedium),
              ),
              const SizedBox(height: 16),
              Text(
                'Este app apoia gestores e cidadãos de qualquer município do Brasil com '
                'indicadores e alertas. Os alertas apoiam, mas não substituem, '
                'a decisão humana.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Privacidade: ocorrências registradas ficam apenas neste '
                'aparelho e sem dados que identifiquem você.',
                style: text.bodyLarge,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.read<SettingsProvider>().giveConsent(),
                  child: const Text('Li e concordo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
