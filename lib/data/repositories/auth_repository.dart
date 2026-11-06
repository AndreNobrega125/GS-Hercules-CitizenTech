import '../../core/territory.dart';
import '../models/user_profile.dart';

/// Conta de demonstração. A senha é pública e vale só para este protótipo.
class DemoAccount {
  const DemoAccount(this.password, this.profile);

  final String password;
  final UserProfile profile;
}

/// Login SIMULADO e local, para demonstrar perfis e dados por usuário.
/// Não é segurança real: não há servidor, hash nem recuperação de senha.
class AuthRepository {
  const AuthRepository();

  static const _sp = Territory.saoPaulo;
  static const _rio = Territory(
    ibgeCode: '3304557',
    name: 'Rio de Janeiro',
    uf: 'RJ',
  );
  static const _campinas = Territory(
    ibgeCode: '3509502',
    name: 'Campinas',
    uf: 'SP',
  );
  static const _santos = Territory(
    ibgeCode: '3548500',
    name: 'Santos',
    uf: 'SP',
  );
  static const _niteroi = Territory(
    ibgeCode: '3303302',
    name: 'Niterói',
    uf: 'RJ',
  );

  static const accounts = [
    DemoAccount(
      'gestor123',
      UserProfile(
        id: 'sp',
        name: 'Gestora de São Paulo',
        role: 'Gestão municipal e estadual (SP)',
        email: 'gestora.sp@radar.demo',
        home: _sp,
        defaultFavorites: [_campinas, _santos],
      ),
    ),
    DemoAccount(
      'gestor123',
      UserProfile(
        id: 'rj',
        name: 'Gestor do Rio de Janeiro',
        role: 'Gestão municipal e comparação entre estados',
        email: 'gestor.rj@radar.demo',
        home: _rio,
        defaultFavorites: [_niteroi, _sp],
      ),
    ),
  ];

  /// Devolve o perfil se e-mail e senha conferem; `null` caso contrário.
  UserProfile? authenticate(String email, String password) {
    final mail = email.trim().toLowerCase();
    for (final a in accounts) {
      if (a.profile.email == mail && a.password == password) return a.profile;
    }
    return null;
  }

  UserProfile? byId(String? id) {
    for (final a in accounts) {
      if (a.profile.id == id) return a.profile;
    }
    return null;
  }
}
