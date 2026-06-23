import 'dart:convert';

import 'app_database.dart';
import '../models/local_models.dart';

class SyncOutboxWriter {
  SyncOutboxWriter(this._db);

  final AppDatabase _db;

  Future<void> enqueueInTxn({
    required String userId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    String action = 'upsert',
    required dynamic txn,
  }) async {
    final entry = SyncOutboxEntity()
      ..userId = userId
      ..entityType = entityType
      ..entityId = entityId
      ..status = 'pending'
      ..action = action
      ..payloadJson = jsonEncode(payload)
      ..createdAt = DateTime.now()
      ..attempts = 0;

    await _db.putSyncOutbox(entry, txn: txn);
  }

  Future<void> enqueue({
    required String userId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    String action = 'upsert',
  }) async {
    await _db.transaction((txn) async {
      await enqueueInTxn(
        userId: userId,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        action: action,
        txn: txn,
      );
    });
  }
}
