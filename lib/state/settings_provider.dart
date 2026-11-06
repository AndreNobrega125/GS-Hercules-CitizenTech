import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências globais (tema e consentimento), persistidas localmente.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs)
      : _themeMode = ThemeMode.values.byName(
          _prefs.getString(_kThemeMode) ?? ThemeMode.system.name,
        ),
        _highContrast = _prefs.getBool(_kHighContrast) ?? false,
        _consentGiven = _prefs.getBool(_kConsent) ?? false;

  static const _kThemeMode = 'theme_mode';
  static const _kHighContrast = 'high_contrast';
  static const _kConsent = 'consent_given';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  bool _highContrast;
  bool _consentGiven;

  ThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;
  bool get consentGiven => _consentGiven;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    await _prefs.setBool(_kHighContrast, value);
    notifyListeners();
  }

  Future<void> giveConsent() async {
    _consentGiven = true;
    await _prefs.setBool(_kConsent, true);
    notifyListeners();
  }
}
