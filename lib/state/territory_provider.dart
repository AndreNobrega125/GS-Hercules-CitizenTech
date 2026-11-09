import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/territory.dart';
import '../data/models/territory_snapshot.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/territory_repository.dart';
import '../domain/alert_engine.dart';
import '../domain/territory_alert.dart';

enum LoadStatus { loading, ready, error }

/// Estado global dos dados do território, compartilhado entre as telas.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider(this.repository, this._prefs, [UserProfile? user])
      : _userId = user?.id,
        _territory = _readSaved(_prefs, user),
        _thresholds = _readThresholds(_prefs, user?.id);

  final TerritoryRepository repository;
  final SharedPreferences _prefs;

  /// Cada perfil guarda o próprio município (isolamento por dono).
  String? _userId;
  String get _key => 'u_${_userId}_territory';

  Territory _territory;
  AlertThresholds _thresholds;
  LoadStatus _status = LoadStatus.loading;
  TerritorySnapshot? _snapshot;
  List<TerritoryAlert> _alerts = const [];
  List<TerritoryAlert> _pastAlerts = const [];

  Territory get territory => _territory;

  /// Limiares de alerta do perfil ativo.
  AlertThresholds get thresholds => _thresholds;
  LoadStatus get status => _status;
  TerritorySnapshot? get snapshot => _snapshot;

  /// Alertas ordenados do mais grave para o menos grave.
  List<TerritoryAlert> get alerts => _alerts;

  /// Alertas de datas antigas (últimos 7 dias), do mais recente ao mais antigo.
  /// Não são alertas ativos e não entram no indicador de benefício social.
  List<TerritoryAlert> get pastAlerts => _pastAlerts;

  TerritoryAlert? alertById(String id) {
    for (final a in [..._alerts, ..._pastAlerts]) {
      if (a.id == id) return a;
    }
    return null;
  }

  static Territory _readSaved(SharedPreferences prefs, UserProfile? user) {
    if (user == null) return Territory.saoPaulo;
    final raw = prefs.getString('u_${user.id}_territory');
    if (raw == null) return user.home;
    try {
      return Territory.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return user.home;
    }
  }

  static AlertThresholds _readThresholds(SharedPreferences prefs, String? id) {
    final raw = id == null ? null : prefs.getString('u_${id}_thresholds');
    if (raw == null) return AlertThresholds.defaults;
    try {
      return AlertThresholds.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AlertThresholds.defaults;
    }
  }

  /// Salva os limiares do perfil e recalcula os alertas com os dados atuais.
  Future<void> setThresholds(AlertThresholds next) async {
    _thresholds = next;
    if (_userId != null) {
      await _prefs.setString(
        'u_${_userId}_thresholds',
        jsonEncode(next.toJson()),
      );
    }
    final snap = _snapshot;
    if (snap != null) {
      _alerts = AlertEngine.generate(snap, thresholds: next);
      _pastAlerts = AlertEngine.generatePast(snap, thresholds: next);
    }
    notifyListeners();
  }

  /// Troca o perfil ativo: abre o último município dele (ou o inicial) e recarrega.
  Future<void> useUser(UserProfile user) async {
    _userId = user.id;
    _territory = _readSaved(_prefs, user);
    _thresholds = _readThresholds(_prefs, user.id);
    _snapshot = null;
    _alerts = const [];
    _pastAlerts = const [];
    await load();
  }

  /// Troca o município monitorado, salva a escolha e recarrega os dados.
  Future<void> changeTerritory(Territory next) async {
    if (next.ibgeCode == _territory.ibgeCode) return;
    _territory = next;
    _snapshot = null;
    _alerts = const [];
    _pastAlerts = const [];
    if (_userId != null) {
      await _prefs.setString(_key, jsonEncode(next.toJson()));
    }
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
      _alerts = AlertEngine.generate(snap, thresholds: _thresholds);
      _pastAlerts = AlertEngine.generatePast(snap, thresholds: _thresholds);
      _status = snap.isEmpty ? LoadStatus.error : LoadStatus.ready;
    } catch (_) {
      if (requested.ibgeCode != _territory.ibgeCode) return;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
