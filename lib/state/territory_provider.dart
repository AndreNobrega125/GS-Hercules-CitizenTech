import 'package:flutter/foundation.dart';

import '../data/models/territory_snapshot.dart';
import '../data/repositories/territory_repository.dart';
import '../domain/alert_engine.dart';
import '../domain/territory_alert.dart';

enum LoadStatus { loading, ready, error }

/// Estado global dos dados do território, compartilhado entre as telas.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider(this._repository);

  final TerritoryRepository _repository;

  LoadStatus _status = LoadStatus.loading;
  TerritorySnapshot? _snapshot;
  List<TerritoryAlert> _alerts = const [];

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

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final snap = await _repository.load();
      _snapshot = snap;
      _alerts = AlertEngine.generate(snap);
      _status = snap.isEmpty ? LoadStatus.error : LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
