import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:radar_territorio/core/theme/app_theme.dart';
import 'package:radar_territorio/app/router.dart';
import 'package:radar_territorio/data/repositories/territory_repository.dart';
import 'package:radar_territorio/data/services/api_service.dart';
import 'package:radar_territorio/state/auth_provider.dart';
import 'package:radar_territorio/state/settings_provider.dart';
import 'package:radar_territorio/state/territory_provider.dart';
import 'package:radar_territorio/state/user_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _daily() => {
      'daily': {
        'time': [
          for (var i = 0; i < 7; i++)
            DateTime.now().add(Duration(days: i)).toIso8601String().substring(0, 10),
        ],
        'temperature_2m_max': [for (var i = 0; i < 7; i++) 35.0 + i],
        'temperature_2m_min': [for (var i = 0; i < 7; i++) 20.0],
        'precipitation_sum': [for (var i = 0; i < 7; i++) 40.0 + i],
      },
    };

Map<String, dynamic> _air() => {
      'hourly': {
        'time': [
          for (var h = 0; h < 48; h++)
            DateTime.now()
                .subtract(Duration(hours: 48 - h))
                .toIso8601String()
                .substring(0, 16),
        ],
        'pm2_5': [for (var h = 0; h < 48; h++) 30.0 + h * 0.2],
        'pm10': [for (var h = 0; h < 48; h++) 40.0],
      },
    };

const _geo = {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-46.7, -23.6],
            [-46.6, -23.6],
            [-46.6, -23.5],
            [-46.7, -23.6],
          ],
        ],
      },
    },
  ],
};

Future<GoRouterHandle> _boot(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
}) async {
  SharedPreferences.setMockInitialValues({
    'consent_given': true,
    'session_user': 'sp',
  });
  final prefs = await SharedPreferences.getInstance();
  final api = _MockApi();
  registerFallbackValue(0.0);
  when(() => api.forecast(any(), any())).thenAnswer((_) async => _daily());
  when(() => api.history(any(), any())).thenAnswer((_) async => _daily());
  when(() => api.airQuality(any(), any())).thenAnswer((_) async => _air());
  when(() => api.warnings(any())).thenAnswer((_) async => []);
  when(() => api.population(any())).thenAnswer((_) async => 12000000);
  when(() => api.boundary(any())).thenAnswer((_) async => _geo);
  when(() => api.states()).thenAnswer((_) async => [
        {'sigla': 'SP', 'nome': 'São Paulo'},
        {'sigla': 'RJ', 'nome': 'Rio de Janeiro'},
      ]);
  when(() => api.municipalities(any())).thenAnswer((_) async => [
        {'id': 3550308, 'nome': 'São Paulo'},
        {'id': 3509502, 'nome': 'Campinas'},
      ]);

  final auth = AuthProvider(prefs);
  final settings = SettingsProvider(prefs);
  final territory =
      TerritoryProvider(TerritoryRepository(api, prefs), prefs, auth.user);
  final router = buildRouter(settings, auth);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => UserDataProvider(prefs, auth.user)),
        ChangeNotifierProvider.value(value: territory),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          platformBrightness: brightness,
        ),
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    ),
  );
  territory.load();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  return GoRouterHandle(router);
}

class GoRouterHandle {
  GoRouterHandle(this.router);
  final GoRouter router;
  void go(String path) => router.go(path);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  const phone = Size(360, 640);
  const tablet = Size(800, 1100);
  const paths = [
    '/',
    '/climate',
    '/air',
    '/alerts',
    '/occurrences',
    '/occurrences/new',
    '/thresholds',
    '/settings',
    '/territory',
  ];

  for (final entry in {
    'celular 360x640': phone,
    'tablet 800x1100': tablet,
  }.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('sem overflow: ${entry.key}, fonte ${scale}x', (tester) async {
        final h = await _boot(tester, size: entry.value, textScale: scale);
        for (final p in paths) {
          h.go(p);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: 'rota $p');
        }
      });
    }
  }

  for (final b in Brightness.values) {
    testWidgets('alvos de toque e rótulos (${b.name})', (tester) async {
      final handle = tester.ensureSemantics();
      final h = await _boot(tester, size: phone, brightness: b);
      for (final p in ['/', '/alerts', '/settings', '/occurrences/new']) {
        h.go(p);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline),
            reason: 'tap target em $p');
        await expectLater(tester, meetsGuideline(textContrastGuideline),
            reason: 'contraste em $p');
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline),
            reason: 'rótulo em $p');
      }
      handle.dispose();
    });
  }
}
