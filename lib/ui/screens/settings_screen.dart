import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/user_data_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Pede confirmação, desfaz o aceite e sai da conta; o roteador leva aos termos.
  Future<void> _reviewConsent(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final userData = context.read<UserDataProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rever os termos?'),
        content: const Text(
          'Você voltará à tela de consentimento e sairá da conta. '
          'Seus dados salvos neste aparelho continuam guardados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rever termos'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    userData.clear();
    await auth.logout();
    await settings.revokeConsent();
  }

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
                  onPressed: () {
                    context.read<UserDataProvider>().clear();
                    context.read<AuthProvider>().logout();
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Limiares de alerta'),
            subtitle: const Text('Chuva, calor e poluição do ar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(Routes.thresholds),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Ocorrências'),
            subtitle: const Text('Registros anônimos salvos neste aparelho'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(Routes.occurrences),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Rever termos de consentimento'),
            subtitle: const Text('Volta à tela de termos e sai da conta'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _reviewConsent(context),
          ),
          const SizedBox(height: 8),
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
