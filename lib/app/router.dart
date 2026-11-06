import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';

import '../state/auth_provider.dart';
import '../state/settings_provider.dart';
import '../ui/screens/air_screen.dart';
import '../ui/screens/alert_detail_screen.dart';
import '../ui/screens/alerts_screen.dart';
import '../ui/screens/climate_screen.dart';
import '../ui/screens/consent_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/overview_screen.dart';
import '../ui/screens/risks_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/territory_picker_screen.dart';

/// Rotas nomeadas do app.
class Routes {
  Routes._();

  static const consent = 'consent';
  static const login = 'login';
  static const overview = 'overview';
  static const climate = 'climate';
  static const air = 'air';
  static const risks = 'risks';
  static const alerts = 'alerts';
  static const alertDetail = 'alert-detail';
  static const settings = 'settings';
  static const territory = 'territory';
}

GoRouter buildRouter(SettingsProvider settings, AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([settings, auth]),
    // Deny-by-default: sem consentimento vai ao termo; sem sessão, ao login.
    redirect: (context, state) {
      final at = state.matchedLocation;
      if (!settings.consentGiven) return at == '/consent' ? null : '/consent';
      if (!auth.loggedIn) return at == '/login' ? null : '/login';
      if (at == '/consent' || at == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: Routes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/consent',
        name: Routes.consent,
        builder: (_, _) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/',
        name: Routes.overview,
        builder: (_, _) => const OverviewScreen(),
        routes: [
          GoRoute(
            path: 'climate',
            name: Routes.climate,
            builder: (_, _) => const ClimateScreen(),
          ),
          GoRoute(
            path: 'air',
            name: Routes.air,
            builder: (_, _) => const AirScreen(),
          ),
          GoRoute(
            path: 'risks',
            name: Routes.risks,
            builder: (_, _) => const RisksScreen(),
          ),
          GoRoute(
            path: 'alerts',
            name: Routes.alerts,
            builder: (_, state) =>
                AlertsScreen(initialKind: state.uri.queryParameters['kind']),
            routes: [
              GoRoute(
                path: ':id',
                name: Routes.alertDetail,
                builder: (_, state) =>
                    AlertDetailScreen(alertId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'territory',
            name: Routes.territory,
            builder: (_, _) => const TerritoryPickerScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: Routes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
