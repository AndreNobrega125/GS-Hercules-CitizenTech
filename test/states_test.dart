import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:radar_territorio/app/router.dart';
import 'package:radar_territorio/core/theme/app_theme.dart';
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
        'temperature_2m_max': [for (var i = 0; i < 7; i++) 26.0 + i],
        'temperature_2m_min': [for (var i = 0; i < 7; i++) 18.0],
        'precipitation_sum': [for (var i = 0; i < 7; i++) 1.0],
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
        'pm2_5': [for (var h = 0; h < 48; h++) 10.0],
        'pm10': [for (var h = 0; h < 48; h++) 15.0],
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

void _online(_MockApi api) {
  when(() => api.forecast(any(), any())).thenAnswer((_) async => _daily());
  when(() => api.history(any(), any())).thenAnswer((_) async => _daily());
  when(() => api.airQuality(any(), any())).thenAnswer((_) async => _air());
  when(() => api.warnings(any())).thenAnswer((_) async => []);
  when(() => api.population(any())).thenAnswer((_) async => 12000000);
  when(() => api.boundary(any())).thenAnswer((_) async => _geo);
}

void _offline(_MockApi api) {
  final boom = Exception('sem rede');
  when(() => api.forecast(any(), any())).thenThrow(boom);
  when(() => api.history(any(), any())).thenThrow(boom);
  when(() => api.airQuality(any(), any())).thenThrow(boom);
  when(() => api.warnings(any())).thenThrow(boom);
  when(() => api.population(any())).thenThrow(boom);
  when(() => api.boundary(any())).thenThrow(boom);
}

/// Sobe o app já logado (perfil `sp`) com a API simulada recebida.
Future<TerritoryProvider> _boot(
  WidgetTester tester,
  SharedPreferences prefs,
  _MockApi api, {
  String path = '/',
}) async {
  final auth = AuthProvider(prefs);
  final settings = SettingsProvider(prefs);
  final territory =
      TerritoryProvider(TerritoryRepository(api, prefs), prefs, auth.user);
  final router = buildRouter(settings, auth);
  router.go(path);

  tester.view.physicalSize = const Size(400, 900);
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
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
      ),
    ),
  );
  unawaited(territory.load());
  await tester.pump();
  return territory;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() async {
    registerFallbackValue(0.0);
    registerFallbackValue('');
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  Future<SharedPreferences> prefsLogged([Map<String, Object> extra = const {}]) {
    SharedPreferences.setMockInitialValues({
      'consent_given': true,
      'session_user': 'sp',
      ...extra,
    });
    return SharedPreferences.getInstance();
  }

  testWidgets('carregando: mostra o indicador de progresso', (tester) async {
    final prefs = await prefsLogged();
    final api = _MockApi();
    final never = Completer<Map<String, dynamic>>();
    when(() => api.forecast(any(), any())).thenAnswer((_) => never.future);
    when(() => api.history(any(), any())).thenAnswer((_) => never.future);
    when(() => api.airQuality(any(), any())).thenAnswer((_) => never.future);
    when(() => api.warnings(any())).thenAnswer((_) async => []);
    when(() => api.population(any())).thenAnswer((_) async => 1);
    when(() => api.boundary(any())).thenAnswer((_) async => _geo);

    await _boot(tester, prefs, api);
    await _settle(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('erro: sem rede e sem cache mostra mensagem e permite tentar de novo',
      (tester) async {
    final prefs = await prefsLogged();
    final api = _MockApi();
    _offline(api);

    await _boot(tester, prefs, api);
    await _settle(tester);

    expect(find.textContaining('Sem conexão e sem dados salvos'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);

    // A rede volta: o botão recarrega e a visão geral aparece.
    _online(api);
    await tester.tap(find.text('Tentar de novo'));
    await _settle(tester);

    expect(find.text('Tentar de novo'), findsNothing);
    expect(find.text('Temperatura hoje'), findsOneWidget);
  });

  testWidgets('offline com cache: mostra "Modo offline" e os dados salvos',
      (tester) async {
    final prefs = await prefsLogged();
    // 1ª carga com rede grava o cache no aparelho.
    final online = _MockApi();
    _online(online);
    await TerritoryRepository(online, prefs).load(
      (await _readTerritory(prefs)),
    );

    // App aberto sem rede: usa o que foi salvo.
    final api = _MockApi();
    _offline(api);
    await _boot(tester, prefs, api);
    await _settle(tester);

    expect(find.text('Modo offline'), findsOneWidget);
    expect(find.text('Temperatura hoje'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('lista vazia: clima, ar e riscos mostram mensagem em vez de tela em branco',
      (tester) async {
    final prefs = await prefsLogged();
    final api = _MockApi();
    _offline(api);
    final territory = await _boot(tester, prefs, api, path: '/climate');
    await _settle(tester);
    expect(territory.status, LoadStatus.error);

    expect(find.textContaining('Sem dados de clima'), findsOneWidget);

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/air');
    await _settle(tester);
    expect(find.textContaining('Sem dados do ar'), findsOneWidget);

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/risks');
    await _settle(tester);
    expect(find.textContaining('Sem dados de avisos'), findsOneWidget);
  });

  testWidgets('lista vazia: ocorrências sem registros orienta o usuário',
      (tester) async {
    final prefs = await prefsLogged();
    final api = _MockApi();
    _online(api);
    await _boot(tester, prefs, api, path: '/occurrences');
    await _settle(tester);

    expect(find.textContaining('Nenhuma ocorrência registrada'), findsOneWidget);
  });

  testWidgets('datas antigas: chuva dos últimos 7 dias aparece marcada na lista e no detalhe',
      (tester) async {
    final prefs = await prefsLogged();
    final api = _MockApi();
    _online(api);
    // Histórico termina anteontem (o arquivo atrasa), com chuva forte há 3 dias.
    final d3 = DateTime.now().subtract(const Duration(days: 3));
    final d2 = DateTime.now().subtract(const Duration(days: 2));
    String iso(DateTime d) => d.toIso8601String().substring(0, 10);
    when(() => api.history(any(), any())).thenAnswer((_) async => {
          'daily': {
            'time': [iso(d3), iso(d2)],
            'temperature_2m_max': [26.0, 26.0],
            'temperature_2m_min': [18.0, 18.0],
            'precipitation_sum': [60.0, 2.0],
          },
        });
    final territory = await _boot(tester, prefs, api, path: '/alerts');
    await _settle(tester);

    expect(territory.pastAlerts, hasLength(1));
    expect(find.text('Datas antigas (últimos 7 dias)'), findsOneWidget);
    expect(find.textContaining('data antiga'), findsWidgets);

    final id = territory.pastAlerts.single.id;
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/alerts/$id');
    await _settle(tester);
    expect(find.textContaining('Não é um alerta ativo'), findsOneWidget);
    expect(find.text('Data antiga'), findsOneWidget);
  });

  testWidgets('visão geral: cartões de temperatura, chuva, ar e alertas', (tester) async {
    final prefs = await prefsLogged();
    final api = _MockApi();
    _online(api);
    await _boot(tester, prefs, api);
    await _settle(tester);

    for (final t in ['Temperatura hoje', 'Chuva hoje', 'Qualidade do ar', 'Alertas ativos']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.textContaining('Mínima de 18°C'), findsOneWidget);
  });

  testWidgets('configurações: "Rever termos" volta à tela de consentimento',
      (tester) async {
    final prefs = await prefsLogged();
    final api = _MockApi();
    _online(api);
    await _boot(tester, prefs, api, path: '/settings');
    await _settle(tester);

    await tester.tap(find.text('Rever termos de consentimento'));
    await _settle(tester);
    expect(find.text('Rever os termos?'), findsOneWidget);

    await tester.tap(find.text('Rever termos'));
    await _settle(tester);

    expect(find.text('Li e concordo'), findsOneWidget);
    expect(prefs.getBool('consent_given'), isFalse);
    expect(prefs.getString('session_user'), isNull);
  });

  testWidgets('lista vazia: alerta inexistente avisa que não está mais ativo',
      (tester) async {
    final prefs = await prefsLogged();
    final api = _MockApi();
    _online(api);
    await _boot(tester, prefs, api, path: '/alerts/nao-existe');
    await _settle(tester);

    expect(find.textContaining('não está mais ativo'), findsOneWidget);
  });
}

Future<dynamic> _readTerritory(SharedPreferences prefs) async {
  // Perfil `sp` abre em São Paulo, como o provider faz.
  return TerritoryProvider(
    TerritoryRepository(_MockApi(), prefs),
    prefs,
    AuthProvider(prefs).user,
  ).territory;
}
