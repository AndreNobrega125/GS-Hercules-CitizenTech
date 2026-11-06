import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';

/// Sessão do usuário. Só o id do perfil é salvo; a senha nunca é guardada.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._prefs, [this._repo = const AuthRepository()])
      : _user = _repo.byId(_prefs.getString(_kSession));

  static const _kSession = 'session_user';

  final SharedPreferences _prefs;
  final AuthRepository _repo;
  UserProfile? _user;

  UserProfile? get user => _user;
  bool get loggedIn => _user != null;

  /// Tenta entrar. Devolve `true` se deu certo.
  Future<bool> login(String email, String password) async {
    final profile = _repo.authenticate(email, password);
    if (profile == null) return false;
    _user = profile;
    await _prefs.setString(_kSession, profile.id);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _user = null;
    await _prefs.remove(_kSession);
    notifyListeners();
  }
}
