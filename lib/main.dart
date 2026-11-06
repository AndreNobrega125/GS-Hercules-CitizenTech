import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/territory_repository.dart';
import 'data/services/api_service.dart';
import 'state/settings_provider.dart';
import 'state/territory_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = TerritoryRepository(ApiService(), prefs);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => TerritoryProvider(repository)..load(),
        ),
      ],
      child: const RadarApp(),
    ),
  );
}

class RadarApp extends StatefulWidget {
  const RadarApp({super.key});

  @override
  State<RadarApp> createState() => _RadarAppState();
}

class _RadarAppState extends State<RadarApp> {
  late final _router = buildRouter(context.read<SettingsProvider>());

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp.router(
      title: 'Radar do Território',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: settings.themeMode,
      theme: settings.highContrast ? AppTheme.highContrast() : AppTheme.light(),
      darkTheme: AppTheme.dark(),
    );
  }
}
