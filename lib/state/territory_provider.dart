import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/territory.dart';
import '../data/models/territory_snapshot.dart';
import '../data/repositories/territory_repository.dart';
import '../domain/alert_engine.dart';
import '../domain/territory_alert.dart';

enum LoadStatus { loading, ready, error }

/// Estado global dos dados do território, compartilhado entre as telas.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider(this.repository, this._prefs)
      : _territory = _readSaved(_prefs);

  static const _kTerritory = 'territory';

  final TerritoryRepository repository;
  final SharedPreferences _prefs;

  Territory _territory;
  LoadStatus _status = LoadStatus.loading;
  TerritorySnapshot? _snapshot;
  List<TerritoryAlert> _alerts = const [];

  Territory get territory => _territory;
  LoadStatus get status => _status;
  TerritorySnapshot? get snapshot => _snapshot;

  /// Alertas ordenados do mais grave para o menos grave.
  List<TerritoryAlert> get alerts => _alerts;

  TerritoryAlert? alertById(String id) {
    for (final a in _alerts) {
      if (a.id == id) return a;
    }
    return null;
  }

  static Territory _readSaved(SharedPreferences prefs) {
    final raw = prefs.getString(_kTerritory);
    if (raw == null) return Territory.saoPaulo;
    try {
      return Territory.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Territory.saoPaulo;
    }
  }

  /// Troca o município monitorado, salva a escolha e recarrega os dados.
  Future<void> changeTerritory(Territory next) async {
    if (next.ibgeCode == _territory.ibgeCode) return;
    _territory = next;
    _snapshot = null;
    _alerts = const [];
    await _prefs.setString(_kTerritory, jsonEncode(next.toJson()));
    await load();
  }

  Future<void> load() async {
    final requested = _territory;
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final snap = await repository.load(requested);
      // Descarta o resultado se o usuário trocou de município no meio da carga.
      if (requested.ibgeCode != _territory.ibgeCode) return;
      _snapshot = snap;
      _alerts = AlertEngine.generate(snap);
      _status = snap.isEmpty ? LoadStatus.error : LoadStatus.ready;
    } catch (_) {
      if (requested.ibgeCode != _territory.ibgeCode) return;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
