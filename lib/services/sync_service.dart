import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/isar_models.dart';

class SyncService {
  SyncService._(this._isar, this._client);

  static SyncService? _instance;

  static SyncService? get instance => _instance;

  final Isar _isar;
  final SupabaseClient _client;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  List<ConnectivityResult>? _lastStatus;
  bool _isSyncing = false;

  static Future<SyncService> initialize({
    required Isar isar,
    required SupabaseClient client,
  }) async {
    _instance ??= SyncService._(isar, client);
    await _instance!._start();
    return _instance!;
  }

  Future<void> _start() async {
    _lastStatus = await _connectivity.checkConnectivity();
    if (_isOnline(_lastStatus)) {
      await _trySync();
    }
    _subscription ??= _connectivity.onConnectivityChanged.listen((status) {
      _lastStatus = status;
      if (_isOnline(status)) {
        _trySync();
      }
    });
  }

  void requestSync() {
    if (_isOnline(_lastStatus)) {
      _trySync();
    }
  }

  Future<void> _trySync() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    try {
      await syncPending();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncPending() async {
    final pending = await _isar.syncOutboxEntitys
        .filter()
        .statusEqualTo('pending')
        .sortByCreatedAt()
        .findAll();

    for (final entry in pending) {
      final table = _tableFor(entry.entityType);
      if (table == null) {
        await _markFailed(entry, 'Unknown entity type: ${entry.entityType}');
        continue;
      }

      try {
        final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
        await _client.from(table).upsert(payload, onConflict: 'id');
        await _markSynced(entry);
      } catch (error) {
        await _markFailed(entry, error.toString());
      }
    }
  }

  Future<void> _markSynced(SyncOutboxEntity entry) async {
    await _isar.writeTxn(() async {
      entry.status = 'synced';
      entry.lastAttemptAt = DateTime.now();
      entry.attempts += 1;
      entry.lastError = null;
      await _isar.syncOutboxEntitys.put(entry);
    });
  }

  Future<void> _markFailed(SyncOutboxEntity entry, String message) async {
    await _isar.writeTxn(() async {
      entry.status = 'pending';
      entry.lastAttemptAt = DateTime.now();
      entry.attempts += 1;
      entry.lastError = message;
      await _isar.syncOutboxEntitys.put(entry);
    });
  }

  bool _isOnline(List<ConnectivityResult>? status) {
    return status != null && status.any((entry) => entry != ConnectivityResult.none);
  }

  String? _tableFor(String entityType) {
    switch (entityType) {
      case 'users':
        return 'users';
      case 'accounts':
        return 'accounts';
      case 'categories':
        return 'categories';
      case 'transactions':
        return 'transactions';
      case 'transfers':
        return 'transfers';
      case 'budgets':
        return 'budgets';
      case 'recurring':
        return 'recurring_transactions';
      default:
        return null;
    }
  }
}
