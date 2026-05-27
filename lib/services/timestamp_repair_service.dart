import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/isar_models.dart';

class TimestampRepairService {
  TimestampRepairService({
    required Isar isar,
    SupabaseClient? client,
  })  : _isar = isar,
        _client = client;

  final Isar _isar;
  final SupabaseClient? _client;

  Future<void> repairLocal({required String userId}) async {
    await _isar.writeTxn(() async {
      await _repairLocalUser(userId);
      await _repairLocalAccounts(userId);
      await _repairLocalCategories(userId);
      await _repairLocalTransactions(userId);
      await _repairLocalTransfers(userId);
      await _repairLocalBudgets(userId);
      await _repairLocalRecurring(userId);
      await _repairLocalOutbox(userId);
    });
  }

  Future<void> repairRemote({required String userId}) async {
    final client = _client;
    if (client == null) {
      return;
    }

    await _repairRemoteTable(
      client: client,
      table: 'users',
      userId: userId,
      userColumn: 'id',
    );
    await _repairRemoteTable(client: client, table: 'accounts', userId: userId);
    await _repairRemoteTable(
        client: client, table: 'categories', userId: userId);
    await _repairRemoteTable(
      client: client,
      table: 'transactions',
      userId: userId,
    );
    await _repairRemoteTable(
        client: client, table: 'transfers', userId: userId);
    await _repairRemoteTable(client: client, table: 'budgets', userId: userId);
    await _repairRemoteTable(
      client: client,
      table: 'recurring_transactions',
      userId: userId,
    );
  }

  Future<void> _repairLocalUser(String userId) async {
    final user =
        await _isar.userEntitys.filter().userIdEqualTo(userId).findFirst();
    if (user == null) {
      return;
    }

    user
      ..createdAt = _repairDate(user.createdAt) ?? user.createdAt
      ..updatedAt = _repairDate(user.updatedAt) ?? user.updatedAt
      ..deletedAt = _repairNullableDate(user.deletedAt);
    await _isar.userEntitys.put(user);
  }

  Future<void> _repairLocalAccounts(String userId) async {
    final entries =
        await _isar.accountEntitys.filter().userIdEqualTo(userId).findAll();
    for (final entry in entries) {
      entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
    }
    await _isar.accountEntitys.putAll(entries);
  }

  Future<void> _repairLocalCategories(String userId) async {
    final entries =
        await _isar.categoryEntitys.filter().userIdEqualTo(userId).findAll();
    for (final entry in entries) {
      entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
    }
    await _isar.categoryEntitys.putAll(entries);
  }

  Future<void> _repairLocalTransactions(String userId) async {
    final entries =
        await _isar.transactionEntitys.filter().userIdEqualTo(userId).findAll();
    for (final entry in entries) {
      entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
    }
    await _isar.transactionEntitys.putAll(entries);
  }

  Future<void> _repairLocalTransfers(String userId) async {
    final entries =
        await _isar.transferEntitys.filter().userIdEqualTo(userId).findAll();
    for (final entry in entries) {
      entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
    }
    await _isar.transferEntitys.putAll(entries);
  }

  Future<void> _repairLocalBudgets(String userId) async {
    final entries =
        await _isar.budgetEntitys.filter().userIdEqualTo(userId).findAll();
    for (final entry in entries) {
      entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
    }
    await _isar.budgetEntitys.putAll(entries);
  }

  Future<void> _repairLocalRecurring(String userId) async {
    final entries = await _isar.recurringTransactionEntitys
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    for (final entry in entries) {
      entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
    }
    await _isar.recurringTransactionEntitys.putAll(entries);
  }

  Future<void> _repairLocalOutbox(String userId) async {
    final entries =
        await _isar.syncOutboxEntitys.filter().userIdEqualTo(userId).findAll();
    for (final entry in entries) {
      entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..lastAttemptAt = _repairNullableDate(entry.lastAttemptAt)
        ..payloadJson = _repairPayload(entry.payloadJson);
    }
    await _isar.syncOutboxEntitys.putAll(entries);
  }

  Future<void> _repairRemoteTable({
    required SupabaseClient client,
    required String table,
    required String userId,
    String userColumn = 'user_id',
  }) async {
    final rows = await client
        .from(table)
        .select('id, created_at, updated_at, deleted_at')
        .eq(userColumn, userId);

    for (final row in rows) {
      final update = <String, dynamic>{};
      _addRepairedRemoteDate(update, row, 'created_at');
      _addRepairedRemoteDate(update, row, 'updated_at');
      _addRepairedRemoteDate(update, row, 'deleted_at');
      if (update.isEmpty) {
        continue;
      }

      await client.from(table).update(update).eq('id', row['id']);
    }
  }

  void _addRepairedRemoteDate(
    Map<String, dynamic> update,
    Map<String, dynamic> row,
    String key,
  ) {
    final repaired = _repairDate(_parseDate(row[key]));
    if (repaired != null) {
      update[key] = repaired.toUtc().toIso8601String();
    }
  }

  String _repairPayload(String payloadJson) {
    final Object? payload;
    try {
      payload = jsonDecode(payloadJson);
    } on FormatException {
      return payloadJson;
    }

    if (payload is! Map<String, dynamic>) {
      return payloadJson;
    }

    var changed = false;
    for (final key in ['created_at', 'updated_at', 'deleted_at']) {
      final repaired = _repairDate(_parseDate(payload[key]));
      if (repaired != null) {
        payload[key] = repaired.toUtc().toIso8601String();
        changed = true;
      }
    }

    return changed ? jsonEncode(payload) : payloadJson;
  }

  DateTime? _repairDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final now = DateTime.now();
    if (!value.isAfter(now)) {
      return null;
    }

    final offset = now.timeZoneOffset;
    if (offset == Duration.zero) {
      return null;
    }

    final repaired = value.subtract(offset);
    return repaired.isAfter(now) ? null : repaired;
  }

  DateTime? _repairNullableDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _repairDate(value) ?? value;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
