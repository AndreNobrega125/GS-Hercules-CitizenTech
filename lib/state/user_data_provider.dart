import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/territory.dart';
import '../data/models/occurrence.dart';
import '../data/models/user_profile.dart';
import '../data/services/supabase_service.dart';

enum SyncStatus { ok, offline }

/// Dados do perfil ativo (favoritos e ocorrências), salvos só neste aparelho.
/// Toda chave leva o prefixo `u_<perfil>_`: um perfil nunca lê o outro.
class UserDataProvider extends ChangeNotifier {
  UserDataProvider(this._prefs, [UserProfile? user, this._remote]) {
    if (user != null) {
      _load(user);
      unawaited(sync());
    }
  }

  final SharedPreferences _prefs;
  final OccurrenceRemote? _remote;

  /// Última tentativa de sincronização: null = sem Supabase configurado.
  SyncStatus? syncStatus;
  String? _userId;
  List<Territory> _favorites = const [];
  List<Occurrence> _occurrences = const [];

  List<Territory> get favorites => _favorites;

  /// Mais recentes primeiro.
  List<Occurrence> get occurrences => _occurrences;

  String _k(String name) => 'u_${_userId}_$name';

  void useUser(UserProfile user) {
    _load(user);
    notifyListeners();
    unawaited(sync());
  }

  Set<String> _idSet(String name) =>
      (_prefs.getStringList(_k(name)) ?? const <String>[]).toSet();

  /// Envia ocorrências ainda não enviadas e traz as do servidor (se configurado).
  /// Falha de rede não perde nada: tenta de novo na próxima vez.
  Future<void> sync() async {
    final remote = _remote;
    final uid = _userId;
    if (remote == null || uid == null) return;
    try {
      final remoteList = await remote.fetch(uid);
      if (_userId != uid) return; // trocou de perfil durante a chamada
      final synced = _idSet('synced');
      final deleted = _idSet('deleted');
      final localIds = _occurrences.map((o) => o.id).toSet();
      final remoteIds = remoteList.map((o) => o.id).toSet();

      for (final o in _occurrences) {
        if (!remoteIds.contains(o.id)) await remote.upsert(uid, o);
        synced.add(o.id);
      }
      final incoming = remoteList
          .where((o) => !localIds.contains(o.id) && !deleted.contains(o.id));
      if (incoming.isNotEmpty) {
        _occurrences = [..._occurrences, ...incoming]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _save('occurrences', [for (final e in _occurrences) e.toJson()]);
      }
      synced.addAll(remoteIds);
      await _prefs.setStringList(_k('synced'), synced.toList());
      syncStatus = SyncStatus.ok;
    } catch (_) {
      syncStatus = SyncStatus.offline;
    }
    notifyListeners();
  }

  void clear() {
    _userId = null;
    _favorites = const [];
    _occurrences = const [];
    notifyListeners();
  }

  void _load(UserProfile user) {
    _userId = user.id;
    _favorites = _readList(
      'favorites',
      Territory.fromJson,
      user.defaultFavorites,
    );
    _occurrences = _readList('occurrences', Occurrence.fromJson, const []);
  }

  List<T> _readList<T>(
    String name,
    T Function(Map<String, dynamic>) parse,
    List<T> fallback,
  ) {
    final raw = _prefs.getString(_k(name));
    if (raw == null) return fallback;
    try {
      return [
        for (final e in jsonDecode(raw) as List) parse(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _save(String name, List<Map<String, dynamic>> data) =>
      _prefs.setString(_k(name), jsonEncode(data));

  bool isFavorite(String ibgeCode) =>
      _favorites.any((t) => t.ibgeCode == ibgeCode);

  Future<void> toggleFavorite(Territory t) async {
    if (_userId == null) return;
    _favorites = isFavorite(t.ibgeCode)
        ? _favorites.where((f) => f.ibgeCode != t.ibgeCode).toList()
        : [..._favorites, t];
    await _save('favorites', [for (final f in _favorites) f.toJson()]);
    notifyListeners();
  }

  Future<void> addOccurrence({
    required OccurrenceType type,
    required String description,
    required Territory territory,
    String? neighborhood,
  }) async {
    if (_userId == null) return;
    final now = DateTime.now();
    final hood = neighborhood?.trim() ?? '';
    final o = Occurrence(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      type: type,
      description: description.trim(),
      neighborhood: hood.isEmpty ? null : hood,
      territoryName: territory.label,
      ibgeCode: territory.ibgeCode,
    );
    _occurrences = [o, ..._occurrences];
    await _save('occurrences', [for (final e in _occurrences) e.toJson()]);
    notifyListeners();
    unawaited(sync());
  }

  Future<void> removeOccurrence(String id) async {
    if (_userId == null) return;
    _occurrences = _occurrences.where((o) => o.id != id).toList();
    // A chave pública não apaga no servidor: lembra o id para não trazer de volta.
    await _prefs.setStringList(_k('deleted'), (_idSet('deleted')..add(id)).toList());
    await _save('occurrences', [for (final e in _occurrences) e.toJson()]);
    notifyListeners();
  }
}
