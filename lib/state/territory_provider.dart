import 'package:flutter/foundation.dart';

import '../data/models/territory_snapshot.dart';
import '../data/repositories/territory_repository.dart';

enum LoadStatus { loading, ready, error }

/// Estado global dos dados do território, compartilhado entre as telas.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider(this._repository);

  final TerritoryRepository _repository;

  LoadStatus _status = LoadStatus.loading;
  TerritorySnapshot? _snapshot;

  LoadStatus get status => _status;
  TerritorySnapshot? get snapshot => _snapshot;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final snap = await _repository.load();
      _snapshot = snap;
      _status = snap.isEmpty ? LoadStatus.error : LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
