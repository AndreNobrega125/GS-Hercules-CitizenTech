import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/main.dart';
import 'package:provider/provider.dart';
import 'package:radar_territorio/state/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sem consentimento, o app abre na tela de consentimento',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(prefs),
        child: const RadarApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Li e concordo'), findsOneWidget);
  });
}
