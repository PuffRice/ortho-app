import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/local_models.dart';
import 'app_database.dart';

class TimestampRepairService {
  TimestampRepairService({
    required AppDatabase db,
    SupabaseClient? client,
  })  : _db = db,
        _client = client;

  final AppDatabase _db;
  final SupabaseClient? _client;

  Future<void> repairLocal({required String userId}) async {
    final user = await _db.getUserByUserId(userId);
    if (user != null) await _db.putUser(_repairUser(user));
    for (final entry in await _db.getAccounts(userId: userId, deletedOnly: false)) { await _db.putAccount(_repairAccount(entry)); }
    for (final entry in await _db.getCategories(userId: userId, deletedOnly: false)) { await _db.putCategory(_repairCategory(entry)); }
    for (final entry in await _db.getTransactions(userId: userId, limit: 1000000)) { await _db.putTransaction(_repairTransaction(entry)); }
    for (final entry in await _db.getTransfers(userId: userId)) { await _db.putTransfer(_repairTransfer(entry)); }
    for (final entry in await _db.getBudgets(userId: userId)) { await _db.putBudget(_repairBudget(entry)); }
    for (final entry in await _db.getRecurringTransactions(userId: userId)) { await _db.putRecurring(_repairRecurring(entry)); }
    for (final entry in await _db.getSyncOutboxEntries(userId: userId)) {
        entry.createdAt = _repairDate(entry.createdAt) ?? entry.createdAt;
        entry.lastAttemptAt = _repairNullableDate(entry.lastAttemptAt);
        entry.payloadJson = _repairPayload(entry.payloadJson);
        await _db.putSyncOutbox(entry);
    }
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

  UserEntity _repairUser(UserEntity user) {
    user
      ..createdAt = _repairDate(user.createdAt) ?? user.createdAt
      ..updatedAt = _repairDate(user.updatedAt) ?? user.updatedAt
      ..deletedAt = _repairNullableDate(user.deletedAt);
    return user;
  }

  AccountEntity _repairAccount(AccountEntity entry) {
      return entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
  }

  CategoryEntity _repairCategory(CategoryEntity entry) {
      return entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
  }

  TransactionEntity _repairTransaction(TransactionEntity entry) {
      return entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
  }

  TransferEntity _repairTransfer(TransferEntity entry) {
      return entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
  }

  BudgetEntity _repairBudget(BudgetEntity entry) {
      return entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
  }

  RecurringTransactionEntity _repairRecurring(RecurringTransactionEntity entry) {
      return entry
        ..createdAt = _repairDate(entry.createdAt) ?? entry.createdAt
        ..updatedAt = _repairDate(entry.updatedAt) ?? entry.updatedAt
        ..deletedAt = _repairNullableDate(entry.deletedAt);
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
