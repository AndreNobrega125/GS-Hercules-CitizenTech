import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(user.name),
                subtitle: Text('${user.role}\n${user.email}'),
                isThreeLine: true,
                trailing: TextButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Tema', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
              ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Alto contraste'),
            subtitle: const Text('Aplica no tema claro'),
            value: settings.highContrast,
            onChanged: settings.setHighContrast,
          ),
        ],
      ),
    );
  }
}
