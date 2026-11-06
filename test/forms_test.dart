import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/core/territory.dart';
import 'package:radar_territorio/core/validators.dart';
import 'package:radar_territorio/data/models/occurrence.dart';
import 'package:radar_territorio/data/repositories/auth_repository.dart';
import 'package:radar_territorio/domain/alert_engine.dart';
import 'package:radar_territorio/state/user_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('validação numérica dos limiares', () {
    test('aceita vírgula e ponto', () {
      expect(Validators.parseNumber('30,5'), 30.5);
      expect(Validators.parseNumber('30.5'), 30.5);
    });
    test('rejeita vazio, texto e fora da faixa', () {
      String? v(String? t) =>
          Validators.number(t, label: 'Chuva', min: 5, max: 300);
      expect(v(''), contains('Informe'));
      expect(v('abc'), contains('números'));
      expect(v('4'), contains('entre'));
      expect(v('301'), contains('entre'));
      expect(v('30'), isNull);
    });
    test('nível alto precisa superar o de atenção', () {
      expect(Validators.highAboveAttention('20', '30'), isNotNull);
      expect(Validators.highAboveAttention('30', '30'), isNotNull);
      expect(Validators.highAboveAttention('50', '30'), isNull);
    });
  });

  group('validação da ocorrência', () {
    test('descrição: tamanho mínimo e máximo', () {
      expect(Validators.description(''), isNotNull);
      expect(Validators.description('curto'), isNotNull);
      expect(Validators.description('a' * 281), isNotNull);
      expect(Validators.description('Rua alagada após a chuva forte'), isNull);
    });
    test('bloqueia e-mail, telefone, CPF e CEP', () {
      expect(Validators.description('me chame em fulano@mail.com ok'), isNotNull);
      expect(Validators.description('ligue 11 98888-7777 por favor'), isNotNull);
      expect(Validators.neighborhood('CEP 01310100'), isNotNull);
      expect(Validators.neighborhood(''), isNull);
    });
  });

  test('limiares viram JSON e voltam iguais', () {
    const t = AlertThresholds(rainAttentionMm: 20, heatHighC: 40);
    final back = AlertThresholds.fromJson(t.toJson());
    expect(back.rainAttentionMm, 20);
    expect(back.heatHighC, 40);
    expect(back.pm25High, 50);
  });

  group('dados por perfil', () {
    const repo = AuthRepository();
    const cidade = Territory(ibgeCode: '3509502', name: 'Campinas', uf: 'SP');

    test('favoritos iniciais vêm do perfil e persistem', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final p = UserDataProvider(prefs, repo.byId('rj'));
      expect(p.favorites.map((f) => f.name), ['Niterói', 'São Paulo']);

      await p.toggleFavorite(cidade);
      expect(
        UserDataProvider(prefs, repo.byId('rj')).isFavorite('3509502'),
        isTrue,
      );
    });

    test('ocorrência salva e um perfil não vê a do outro', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final sp = UserDataProvider(prefs, repo.byId('sp'));
      await sp.addOccurrence(
        type: OccurrenceType.flooding,
        description: '  Rua alagada perto da praça  ',
        territory: cidade,
        neighborhood: '  ',
      );
      expect(sp.occurrences.single.description, 'Rua alagada perto da praça');
      expect(sp.occurrences.single.neighborhood, isNull);

      final rj = UserDataProvider(prefs, repo.byId('rj'));
      expect(rj.occurrences, isEmpty);
      expect(
        UserDataProvider(prefs, repo.byId('sp')).occurrences,
        hasLength(1),
      );

      await sp.removeOccurrence(sp.occurrences.single.id);
      expect(UserDataProvider(prefs, repo.byId('sp')).occurrences, isEmpty);
    });

    test('sem sessão nada é gravado', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final p = UserDataProvider(prefs);
      await p.toggleFavorite(cidade);
      expect(p.favorites, isEmpty);
      expect(prefs.getKeys(), isEmpty);
    });
  });
}
