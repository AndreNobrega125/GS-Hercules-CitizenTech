import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radar_territorio/core/territory.dart';
import 'package:radar_territorio/data/repositories/auth_repository.dart';
import 'package:radar_territorio/data/repositories/territory_repository.dart';
import 'package:radar_territorio/data/services/api_service.dart';
import 'package:radar_territorio/state/auth_provider.dart';
import 'package:radar_territorio/state/territory_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

void main() {
  const repo = AuthRepository();

  test('credenciais corretas devolvem o perfil; e-mail ignora caixa e espaços', () {
    final p = repo.authenticate('  Gestora.SP@radar.demo ', 'gestor123');
    expect(p?.id, 'sp');
    expect(p?.home.uf, 'SP');
  });

  test('senha errada ou e-mail desconhecido são negados', () {
    expect(repo.authenticate('gestora.sp@radar.demo', 'errada'), isNull);
    expect(repo.authenticate('outro@radar.demo', 'gestor123'), isNull);
    expect(repo.authenticate('', ''), isNull);
  });

  test('sessão guarda só o id e sobrevive à reabertura; logout limpa', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthProvider(prefs);
    expect(auth.loggedIn, isFalse);

    expect(await auth.login('gestor.rj@radar.demo', 'x'), isFalse);
    expect(await auth.login('gestor.rj@radar.demo', 'gestor123'), isTrue);
    expect(prefs.getString('session_user'), 'rj');
    expect(prefs.getKeys().any((k) => (prefs.get(k) ?? '') == 'gestor123'), isFalse);

    expect(AuthProvider(prefs).user?.id, 'rj');
    await auth.logout();
    expect(AuthProvider(prefs).loggedIn, isFalse);
  });

  test('município escolhido é isolado por perfil', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = _MockApi();
    final boom = Exception('sem rede');
    registerFallbackValue(0.0);
    when(() => api.forecast(any(), any())).thenThrow(boom);
    when(() => api.history(any(), any())).thenThrow(boom);
    when(() => api.airQuality(any(), any())).thenThrow(boom);
    when(() => api.warnings(any())).thenThrow(boom);
    when(() => api.population(any())).thenThrow(boom);
    when(() => api.boundary(any())).thenThrow(boom);
    final sp = repo.byId('sp')!;
    final rj = repo.byId('rj')!;

    final provider = TerritoryProvider(TerritoryRepository(api, prefs), prefs, sp);
    expect(provider.territory.name, 'São Paulo');
    await provider.changeTerritory(
      const Territory(ibgeCode: '3509502', name: 'Campinas', uf: 'SP'),
    );

    await provider.useUser(rj);
    expect(provider.territory.name, 'Rio de Janeiro');

    await provider.useUser(sp);
    expect(provider.territory.name, 'Campinas');
  });
}
