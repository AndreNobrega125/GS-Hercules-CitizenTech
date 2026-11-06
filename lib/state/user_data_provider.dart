import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/territory.dart';
import '../data/models/occurrence.dart';
import '../data/models/user_profile.dart';

/// Dados do perfil ativo (favoritos e ocorrências), salvos só neste aparelho.
/// Toda chave leva o prefixo `u_<perfil>_`: um perfil nunca lê o outro.
class UserDataProvider extends ChangeNotifier {
  UserDataProvider(this._prefs, [UserProfile? user]) {
    if (user != null) _load(user);
  }

  final SharedPreferences _prefs;
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
  }

  Future<void> removeOccurrence(String id) async {
    if (_userId == null) return;
    _occurrences = _occurrences.where((o) => o.id != id).toList();
    await _save('occurrences', [for (final e in _occurrences) e.toJson()]);
    notifyListeners();
  }
}
