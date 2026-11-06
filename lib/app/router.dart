import 'package:go_router/go_router.dart';

import '../state/settings_provider.dart';
import '../ui/screens/air_screen.dart';
import '../ui/screens/climate_screen.dart';
import '../ui/screens/consent_screen.dart';
import '../ui/screens/overview_screen.dart';
import '../ui/screens/risks_screen.dart';
import '../ui/screens/settings_screen.dart';

/// Rotas nomeadas do app.
class Routes {
  Routes._();

  static const consent = 'consent';
  static const overview = 'overview';
  static const climate = 'climate';
  static const air = 'air';
  static const risks = 'risks';
  static const settings = 'settings';
}

GoRouter buildRouter(SettingsProvider settings) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: settings,
    redirect: (context, state) {
      final atConsent = state.matchedLocation == '/consent';
      if (!settings.consentGiven && !atConsent) return '/consent';
      if (settings.consentGiven && atConsent) return '/';
      return null;
    },
    routes: [
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
            path: 'settings',
            name: Routes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
