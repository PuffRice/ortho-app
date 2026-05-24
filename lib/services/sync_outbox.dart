import 'dart:convert';

import 'package:isar/isar.dart';

import '../models/isar_models.dart';

class SyncOutboxWriter {
  SyncOutboxWriter(this._isar);

  final Isar _isar;

  Future<void> enqueueInTxn({
    required String userId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    String action = 'upsert',
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

    await _isar.syncOutboxEntitys.put(entry);
  }

  Future<void> enqueue({
    required String userId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    String action = 'upsert',
  }) async {
    await _isar.writeTxn(() async {
      await enqueueInTxn(
        userId: userId,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        action: action,
      );
    });
  }
}
