import 'dart:convert';

import 'package:isar/isar.dart';

import '../models/isar_models.dart';

class LocalUserMigration {
  const LocalUserMigration(this._isar);

  static const legacyUserIds = ['local_user', 'local-user', 'localUser'];

  final Isar _isar;

  Future<void> migrateTo(String userId) async {
    final legacyIds = legacyUserIds.where((id) => id != userId).toList();
    if (legacyIds.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      for (final legacyId in legacyIds) {
        if (!await _hasLegacyRows(legacyId)) {
          continue;
        }

        await _migrateUser(legacyId, userId);
        await _migrateAccounts(legacyId, userId);
        await _migrateCategories(legacyId, userId);
        await _migrateTransactions(legacyId, userId);
        await _migrateTransfers(legacyId, userId);
        await _migrateBudgets(legacyId, userId);
        await _migrateRecurring(legacyId, userId);
        await _migrateSummaryCache(legacyId, userId);
        await _migrateOutbox(legacyId, userId);
      }
    });
  }

  Future<bool> _hasLegacyRows(String userId) async {
    if ((await _isar.userEntitys.filter().userIdEqualTo(userId).count()) > 0) {
      return true;
    }
    if ((await _isar.accountEntitys.filter().userIdEqualTo(userId).count()) >
        0) {
      return true;
    }
    if ((await _isar.categoryEntitys.filter().userIdEqualTo(userId).count()) >
        0) {
      return true;
    }
    if ((await _isar.transactionEntitys
            .filter()
            .userIdEqualTo(userId)
            .count()) >
        0) {
      return true;
    }
    if ((await _isar.transferEntitys.filter().userIdEqualTo(userId).count()) >
        0) {
      return true;
    }
    if ((await _isar.budgetEntitys.filter().userIdEqualTo(userId).count()) >
        0) {
      return true;
    }
    if ((await _isar.recurringTransactionEntitys
            .filter()
            .userIdEqualTo(userId)
            .count()) >
        0) {
      return true;
    }
    if ((await _isar.summaryCacheEntitys.filter().userIdEqualTo(userId).count()) >
        0) {
      return true;
    }
    return (await _isar.syncOutboxEntitys.filter().userIdEqualTo(userId).count()) >
        0;
  }

  Future<void> _migrateUser(String fromUserId, String toUserId) async {
    final legacyUser = await _isar.userEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .findFirst();
    if (legacyUser == null) {
      return;
    }

    final currentUser = await _isar.userEntitys
        .filter()
        .userIdEqualTo(toUserId)
        .findFirst();
    if (currentUser != null) {
      await _isar.userEntitys.delete(legacyUser.id);
      return;
    }

    legacyUser
      ..userId = toUserId
      ..updatedAt = DateTime.now();
    await _isar.userEntitys.put(legacyUser);
  }

  Future<void> _migrateAccounts(String fromUserId, String toUserId) async {
    final entries = await _isar.accountEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();
    for (final entry in entries) {
      entry.userId = toUserId;
    }
    await _isar.accountEntitys.putAll(entries);
  }

  Future<void> _migrateCategories(String fromUserId, String toUserId) async {
    final entries = await _isar.categoryEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();
    for (final entry in entries) {
      entry.userId = toUserId;
    }
    await _isar.categoryEntitys.putAll(entries);
  }

  Future<void> _migrateTransactions(String fromUserId, String toUserId) async {
    final entries = await _isar.transactionEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();
    for (final entry in entries) {
      entry.userId = toUserId;
    }
    await _isar.transactionEntitys.putAll(entries);
  }

  Future<void> _migrateTransfers(String fromUserId, String toUserId) async {
    final entries = await _isar.transferEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();
    for (final entry in entries) {
      entry.userId = toUserId;
    }
    await _isar.transferEntitys.putAll(entries);
  }

  Future<void> _migrateBudgets(String fromUserId, String toUserId) async {
    final entries = await _isar.budgetEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();
    for (final entry in entries) {
      entry.userId = toUserId;
    }
    await _isar.budgetEntitys.putAll(entries);
  }

  Future<void> _migrateRecurring(String fromUserId, String toUserId) async {
    final entries = await _isar.recurringTransactionEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();
    for (final entry in entries) {
      entry.userId = toUserId;
    }
    await _isar.recurringTransactionEntitys.putAll(entries);
  }

  Future<void> _migrateSummaryCache(String fromUserId, String toUserId) async {
    await _isar.summaryCacheEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .deleteAll();
    await _isar.summaryCacheEntitys
        .filter()
        .userIdEqualTo(toUserId)
        .deleteAll();
  }

  Future<void> _migrateOutbox(String fromUserId, String toUserId) async {
    final entries = await _isar.syncOutboxEntitys
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();
    for (final entry in entries) {
      entry
        ..userId = toUserId
        ..payloadJson = _migratePayload(entry.payloadJson, fromUserId, toUserId);
      if (entry.entityType == 'users' && entry.entityId == fromUserId) {
        entry.entityId = toUserId;
      }
    }
    await _isar.syncOutboxEntitys.putAll(entries);
  }

  String _migratePayload(String payloadJson, String fromUserId, String toUserId) {
    final Object? payload;
    try {
      payload = jsonDecode(payloadJson);
    } on FormatException {
      return payloadJson;
    }

    if (payload is! Map<String, dynamic>) {
      return payloadJson;
    }

    if (payload['id'] == fromUserId) {
      payload['id'] = toUserId;
    }
    if (payload['user_id'] == fromUserId) {
      payload['user_id'] = toUserId;
    }

    return jsonEncode(payload);
  }
}
