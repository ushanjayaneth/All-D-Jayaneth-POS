import 'package:flutter/material.dart';
import '../services/firebase_sync_service.dart';
import '../data/pos_repository.dart';

class SyncProvider extends ChangeNotifier {
  final PosRepository _repo = PosRepository();
  final FirebaseSyncService _syncService = FirebaseSyncService.instance;

  SyncStatus get status => _syncService.syncStatus.value;
  String get statusMessage => _syncService.statusMessage.value;
  bool get isOnline => status == SyncStatus.ok || status == SyncStatus.syncing;

  SyncProvider() {
    _syncService.syncStatus.addListener(_onStatusChanged);
    _syncService.statusMessage.addListener(_onStatusChanged);
    initSync();
  }

  void _onStatusChanged() {
    notifyListeners();
  }

  Future<void> initSync() async {
    final settings = await _repo.getSettings();
    if (settings.firebaseRtdbUrl != null && settings.firebaseRtdbUrl!.isNotEmpty) {
      _syncService.startPeriodicSync(settings.firebaseRtdbUrl);
    }
  }

  Future<void> triggerSyncNow() async {
    final settings = await _repo.getSettings();
    if (settings.firebaseRtdbUrl != null && settings.firebaseRtdbUrl!.isNotEmpty) {
      await _syncService.syncAll(settings.firebaseRtdbUrl!);
    }
  }

  @override
  void dispose() {
    _syncService.syncStatus.removeListener(_onStatusChanged);
    _syncService.statusMessage.removeListener(_onStatusChanged);
    super.dispose();
  }
}
