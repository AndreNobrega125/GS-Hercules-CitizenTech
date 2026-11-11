import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorio/core/territory.dart';
import 'package:radar_territorio/data/models/occurrence.dart';
import 'package:radar_territorio/data/models/user_profile.dart';
import 'package:radar_territorio/data/repositories/auth_repository.dart';
import 'package:radar_territorio/data/services/supabase_service.dart';
import 'package:radar_territorio/state/user_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements OccurrenceRemote {
  final Map<String, List<Occurrence>> db = {};
  bool down = false;

  @override
  Future<void> upsert(String profileId, Occurrence o) async {
    if (down) throw Exception('sem rede');
    db.putIfAbsent(profileId, () => []).add(o);
  }

  @override
  Future<List<Occurrence>> fetch(String profileId) async {
    if (down) throw Exception('sem rede');
    return List.of(db[profileId] ?? const []);
  }
}

void main() {
  late SharedPreferences prefs;
  late UserProfile user;
  late Territory sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    user = AuthRepository.accounts.first.profile;
    sp = Territory.saoPaulo;
  });

  test('sem Supabase: tudo continua local e sem status de sync', () async {
    final data = UserDataProvider(prefs, user);
    await data.addOccurrence(
        type: OccurrenceType.waste, description: 'Lixo na rua', territory: sp);
    expect(data.occurrences, hasLength(1));
    expect(data.syncStatus, isNull);
  });

  test('offline guarda local e envia quando a rede volta', () async {
    final remote = _FakeRemote()..down = true;
    final data = UserDataProvider(prefs, user, remote);
    await data.addOccurrence(
        type: OccurrenceType.flooding, description: 'Rua alagada', territory: sp);
    await data.sync();
    expect(data.syncStatus, SyncStatus.offline);
    expect(data.occurrences, hasLength(1));
    expect(remote.db, isEmpty);

    remote.down = false;
    await data.sync();
    expect(data.syncStatus, SyncStatus.ok);
    expect(remote.db[user.id], hasLength(1));
  });

  test('traz do servidor o que não existe no aparelho e não repete', () async {
    final remote = _FakeRemote();
    final a = UserDataProvider(prefs, user, remote);
    await a.addOccurrence(
        type: OccurrenceType.power, description: 'Sem luz', territory: sp);
    await a.sync();

    // Outro aparelho (prefs vazio) do mesmo perfil.
    SharedPreferences.setMockInitialValues({});
    final prefs2 = await SharedPreferences.getInstance();
    final b = UserDataProvider(prefs2, user, remote);
    await b.sync();
    await b.sync();
    expect(b.occurrences, hasLength(1));
    expect(remote.db[user.id], hasLength(1));
  });

  test('apagar no aparelho não traz de volta do servidor', () async {
    final remote = _FakeRemote();
    final data = UserDataProvider(prefs, user, remote);
    await data.addOccurrence(
        type: OccurrenceType.water, description: 'Sem água', territory: sp);
    await data.sync();
    await data.removeOccurrence(data.occurrences.single.id);
    await data.sync();
    expect(data.occurrences, isEmpty);
  });
}
