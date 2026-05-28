import 'dart:convert';

import 'package:isar/isar.dart';

import '../models/isar_models.dart';
import 'cqrs_bus.dart';
import 'commands.dart';
import 'queries.dart';
import 'utils.dart';
import '../services/sync_mapper.dart';
import '../services/sync_outbox.dart';
import '../services/sync_service.dart';

class CreateUserHandler implements CommandHandler<CreateUserCommand> {
  CreateUserHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(CreateUserCommand command) async {
    final now = command.now ?? DateTime.now();
    await _isar.writeTxn(() async {
      final existing = await _isar.userEntitys
          .filter()
          .userIdEqualTo(command.userId)
          .findFirst();
      if (existing != null) {
        existing.email = command.email;
        existing.displayName = command.displayName;
        if (command.photoUrl != null) {
          existing.photoUrl = command.photoUrl;
        }
        existing.updatedAt = now;
        await _isar.userEntitys.put(existing);
        await _outboxWriter.enqueueInTxn(
          userId: command.userId,
          entityType: 'users',
          entityId: existing.userId,
          payload: SyncPayloadMapper.user(existing),
        );
        return;
      }

      final user = UserEntity()
        ..userId = command.userId
        ..email = command.email
        ..displayName = command.displayName
        ..photoUrl = command.photoUrl
        ..createdAt = now
        ..updatedAt = now;

      await _isar.userEntitys.put(user);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'users',
        entityId: user.userId,
        payload: SyncPayloadMapper.user(user),
      );
    });
    SyncService.instance?.requestSync();
  }
}

class CreateAccountHandler implements CommandHandler<CreateAccountCommand> {
  CreateAccountHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(CreateAccountCommand command) async {
    final now = command.now ?? DateTime.now();
    final account = AccountEntity()
      ..userId = command.userId
      ..accountId = command.accountId ?? generateId()
      ..name = command.name
      ..type = command.type
      ..currency = command.currency
      ..openingBalance = command.openingBalance
      ..currentBalance = command.openingBalance
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.accountEntitys.put(account);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'accounts',
        entityId: account.accountId,
        payload: SyncPayloadMapper.account(account),
      );
    });
    SyncService.instance?.requestSync();
  }
}

class UpdateAccountHandler implements CommandHandler<UpdateAccountCommand> {
  UpdateAccountHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(UpdateAccountCommand command) async {
    final now = command.now ?? DateTime.now();
    AccountEntity? account;

    await _isar.writeTxn(() async {
      account = await _isar.accountEntitys
          .filter()
          .userIdEqualTo(command.userId)
          .accountIdEqualTo(command.accountId)
          .findFirst();

      if (account == null) {
        return;
      }

      final openingDelta = command.openingBalance - account!.openingBalance;
      account!
        ..name = command.name
        ..type = command.type
        ..currency = command.currency
        ..openingBalance = command.openingBalance
        ..currentBalance = account!.currentBalance + openingDelta
        ..updatedAt = now;

      await _isar.accountEntitys.put(account!);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'accounts',
        entityId: account!.accountId,
        payload: SyncPayloadMapper.account(account!),
      );
    });

    if (account != null) {
      SyncService.instance?.requestSync();
    }
  }
}

class DeleteAccountHandler implements CommandHandler<DeleteAccountCommand> {
  DeleteAccountHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(DeleteAccountCommand command) async {
    final now = command.now ?? DateTime.now();
    AccountEntity? account;

    await _isar.writeTxn(() async {
      account = await _isar.accountEntitys
          .filter()
          .userIdEqualTo(command.userId)
          .accountIdEqualTo(command.accountId)
          .findFirst();

      if (account == null) {
        return;
      }

      account!
        ..deletedAt = now
        ..updatedAt = now;

      await _isar.accountEntitys.put(account!);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'accounts',
        entityId: account!.accountId,
        payload: SyncPayloadMapper.account(account!),
      );
    });

    if (account != null) {
      SyncService.instance?.requestSync();
    }
  }
}

class CreateCategoryHandler implements CommandHandler<CreateCategoryCommand> {
  CreateCategoryHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(CreateCategoryCommand command) async {
    final now = DateTime.now();
    final category = CategoryEntity()
      ..userId = command.userId
      ..categoryId = command.categoryId ?? generateId()
      ..name = command.name
      ..type = command.type
      ..icon = command.icon
      ..color = command.color
      ..sortOrder = command.sortOrder
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.categoryEntitys.put(category);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'categories',
        entityId: category.categoryId,
        payload: SyncPayloadMapper.category(category),
      );
    });
    SyncService.instance?.requestSync();
  }
}

class UpdateCategoryHandler implements CommandHandler<UpdateCategoryCommand> {
  UpdateCategoryHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(UpdateCategoryCommand command) async {
    final now = command.now ?? DateTime.now();
    CategoryEntity? category;

    await _isar.writeTxn(() async {
      category = await _isar.categoryEntitys
          .filter()
          .userIdEqualTo(command.userId)
          .categoryIdEqualTo(command.categoryId)
          .findFirst();

      if (category == null) {
        return;
      }

      category!
        ..name = command.name
        ..type = command.type
        ..icon = command.icon
        ..color = command.color
        ..sortOrder = command.sortOrder
        ..updatedAt = now;

      await _isar.categoryEntitys.put(category!);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'categories',
        entityId: category!.categoryId,
        payload: SyncPayloadMapper.category(category!),
      );
    });

    if (category != null) {
      SyncService.instance?.requestSync();
    }
  }
}

class DeleteCategoryHandler implements CommandHandler<DeleteCategoryCommand> {
  DeleteCategoryHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(DeleteCategoryCommand command) async {
    final now = command.now ?? DateTime.now();
    CategoryEntity? category;

    await _isar.writeTxn(() async {
      category = await _isar.categoryEntitys
          .filter()
          .userIdEqualTo(command.userId)
          .categoryIdEqualTo(command.categoryId)
          .findFirst();

      if (category == null) {
        return;
      }

      category!
        ..deletedAt = now
        ..updatedAt = now;

      await _isar.categoryEntitys.put(category!);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'categories',
        entityId: category!.categoryId,
        payload: SyncPayloadMapper.category(category!),
      );
    });

    if (category != null) {
      SyncService.instance?.requestSync();
    }
  }
}

class CreateTransactionHandler
    implements CommandHandler<CreateTransactionCommand> {
  CreateTransactionHandler(this._isar, this._summaryWriter, this._outboxWriter);

  final Isar _isar;
  final SummaryCacheWriter _summaryWriter;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(CreateTransactionCommand command) async {
    final now = DateTime.now();
    final transaction = TransactionEntity()
      ..userId = command.userId
      ..accountId = command.accountId
      ..categoryId = command.categoryId
      ..transactionId = command.transactionId ?? generateId()
      ..type = command.type
      ..amount = command.amount
      ..currency = command.currency
      ..date = command.date
      ..note = command.note
      ..isRecurring = command.isRecurring
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.transactionEntitys.put(transaction);
      await _updateAccountBalance(
        _isar,
        command.userId,
        command.accountId,
        _deltaFor(command.type, command.amount),
      );
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'transactions',
        entityId: transaction.transactionId,
        payload: SyncPayloadMapper.transaction(transaction),
      );
    });

    await _summaryWriter.rebuildForDate(command.userId, command.date);
    SyncService.instance?.requestSync();
  }
}

class UpdateTransactionHandler
    implements CommandHandler<UpdateTransactionCommand> {
  UpdateTransactionHandler(this._isar, this._summaryWriter, this._outboxWriter);

  final Isar _isar;
  final SummaryCacheWriter _summaryWriter;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(UpdateTransactionCommand command) async {
    TransactionEntity? existing;
    DateTime? previousDate;

    await _isar.writeTxn(() async {
      existing = await _isar.transactionEntitys
          .filter()
          .userIdEqualTo(command.userId)
          .transactionIdEqualTo(command.transactionId)
          .findFirst();

      if (existing == null) {
        return;
      }

      final oldDelta = _deltaFor(existing!.type, existing!.amount);
      final newDelta = _deltaFor(command.type, command.amount);
      previousDate = existing!.date;

      if (existing!.accountId == command.accountId) {
        await _updateAccountBalance(
          _isar,
          command.userId,
          command.accountId,
          newDelta - oldDelta,
        );
      } else {
        await _updateAccountBalance(
          _isar,
          command.userId,
          existing!.accountId,
          -oldDelta,
        );
        await _updateAccountBalance(
          _isar,
          command.userId,
          command.accountId,
          newDelta,
        );
      }

      existing!
        ..accountId = command.accountId
        ..categoryId = command.categoryId
        ..type = command.type
        ..amount = command.amount
        ..currency = command.currency
        ..date = command.date
        ..note = command.note
        ..isRecurring = command.isRecurring
        ..updatedAt = DateTime.now();

      await _isar.transactionEntitys.put(existing!);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'transactions',
        entityId: existing!.transactionId,
        payload: SyncPayloadMapper.transaction(existing!),
      );
    });

    if (existing == null || previousDate == null) {
      return;
    }

    await _summaryWriter.rebuildForDate(command.userId, previousDate!);
    if (previousDate != command.date) {
      await _summaryWriter.rebuildForDate(command.userId, command.date);
    }
    SyncService.instance?.requestSync();
  }
}

class DeleteTransactionHandler
    implements CommandHandler<DeleteTransactionCommand> {
  DeleteTransactionHandler(this._isar, this._summaryWriter, this._outboxWriter);

  final Isar _isar;
  final SummaryCacheWriter _summaryWriter;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(DeleteTransactionCommand command) async {
    TransactionEntity? existing;
    DateTime? previousDate;

    await _isar.writeTxn(() async {
      existing = await _isar.transactionEntitys
          .filter()
          .userIdEqualTo(command.userId)
          .transactionIdEqualTo(command.transactionId)
          .findFirst();

      if (existing == null) {
        return;
      }

      previousDate = existing!.date;
      existing!
        ..deletedAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await _isar.transactionEntitys.put(existing!);
      await _updateAccountBalance(
        _isar,
        command.userId,
        existing!.accountId,
        -_deltaFor(existing!.type, existing!.amount),
      );
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'transactions',
        entityId: existing!.transactionId,
        payload: SyncPayloadMapper.transaction(existing!),
      );
    });

    if (previousDate != null) {
      await _summaryWriter.rebuildForDate(command.userId, previousDate!);
    }
    SyncService.instance?.requestSync();
  }
}

class CreateTransferHandler implements CommandHandler<CreateTransferCommand> {
  CreateTransferHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(CreateTransferCommand command) async {
    final now = DateTime.now();
    final transfer = TransferEntity()
      ..userId = command.userId
      ..fromAccountId = command.fromAccountId
      ..toAccountId = command.toAccountId
      ..transferId = command.transferId ?? generateId()
      ..amount = command.amount
      ..date = command.date
      ..note = command.note
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.transferEntitys.put(transfer);
      await _updateAccountBalance(
        _isar,
        command.userId,
        command.fromAccountId,
        -command.amount,
      );
      await _updateAccountBalance(
        _isar,
        command.userId,
        command.toAccountId,
        command.amount,
      );
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'transfers',
        entityId: transfer.transferId,
        payload: SyncPayloadMapper.transfer(transfer),
      );
    });
    SyncService.instance?.requestSync();
  }
}

class CreateBudgetHandler implements CommandHandler<CreateBudgetCommand> {
  CreateBudgetHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(CreateBudgetCommand command) async {
    final now = DateTime.now();
    final budget = BudgetEntity()
      ..userId = command.userId
      ..categoryId = command.categoryId
      ..budgetId = command.budgetId ?? generateId()
      ..period = command.period
      ..amount = command.amount
      ..startDate = command.startDate
      ..endDate = command.endDate
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.budgetEntitys.put(budget);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'budgets',
        entityId: budget.budgetId,
        payload: SyncPayloadMapper.budget(budget),
      );
    });
    SyncService.instance?.requestSync();
  }
}

class CreateRecurringTransactionHandler
    implements CommandHandler<CreateRecurringTransactionCommand> {
  CreateRecurringTransactionHandler(this._isar, this._outboxWriter);

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(CreateRecurringTransactionCommand command) async {
    final now = DateTime.now();
    final recurring = RecurringTransactionEntity()
      ..userId = command.userId
      ..accountId = command.accountId
      ..categoryId = command.categoryId
      ..recurringId = command.recurringId ?? generateId()
      ..type = command.type
      ..amount = command.amount
      ..interval = command.interval
      ..nextRunAt = command.nextRunAt
      ..isActive = command.isActive
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.recurringTransactionEntitys.put(recurring);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'recurring',
        entityId: recurring.recurringId,
        payload: SyncPayloadMapper.recurring(recurring),
      );
    });
    SyncService.instance?.requestSync();
  }
}

class GetAccountsHandler
    implements QueryHandler<GetAccountsQuery, List<AccountEntity>> {
  GetAccountsHandler(this._isar);

  final Isar _isar;

  @override
  Future<List<AccountEntity>> handle(GetAccountsQuery query) {
    return _isar.accountEntitys
        .filter()
        .userIdEqualTo(query.userId)
        .deletedAtIsNull()
        .findAll();
  }
}

class GetCategoriesHandler
    implements QueryHandler<GetCategoriesQuery, List<CategoryEntity>> {
  GetCategoriesHandler(this._isar);

  final Isar _isar;

  @override
  Future<List<CategoryEntity>> handle(GetCategoriesQuery query) async {
    var builder = _isar.categoryEntitys
        .filter()
        .userIdEqualTo(query.userId)
        .deletedAtIsNull();
    if (query.type != null) {
      builder = builder.typeEqualTo(query.type!);
    }
    return builder.findAll();
  }
}

class GetTransactionsHandler
    implements QueryHandler<GetTransactionsQuery, List<TransactionEntity>> {
  GetTransactionsHandler(this._isar);

  final Isar _isar;

  @override
  Future<List<TransactionEntity>> handle(GetTransactionsQuery query) async {
    var builder = _isar.transactionEntitys
        .filter()
        .userIdEqualTo(query.userId)
        .deletedAtIsNull();

    if (query.accountId != null) {
      builder = builder.accountIdEqualTo(query.accountId!);
    }
    if (query.categoryId != null) {
      builder = builder.categoryIdEqualTo(query.categoryId!);
    }
    if (query.type != null) {
      builder = builder.typeEqualTo(query.type!);
    }
    if (query.start != null) {
      builder = builder.dateGreaterThan(query.start!, include: true);
    }
    if (query.end != null) {
      builder = builder.dateLessThan(query.end!, include: true);
    }

    return builder.sortByDateDesc().limit(query.limit).findAll();
  }
}

class GetBudgetsHandler
    implements QueryHandler<GetBudgetsQuery, List<BudgetEntity>> {
  GetBudgetsHandler(this._isar);

  final Isar _isar;

  @override
  Future<List<BudgetEntity>> handle(GetBudgetsQuery query) {
    return _isar.budgetEntitys
        .filter()
        .userIdEqualTo(query.userId)
        .deletedAtIsNull()
        .findAll();
  }
}

class GetRecurringHandler
    implements
        QueryHandler<GetRecurringQuery, List<RecurringTransactionEntity>> {
  GetRecurringHandler(this._isar);

  final Isar _isar;

  @override
  Future<List<RecurringTransactionEntity>> handle(GetRecurringQuery query) {
    return _isar.recurringTransactionEntitys
        .filter()
        .userIdEqualTo(query.userId)
        .deletedAtIsNull()
        .findAll();
  }
}

class GetTransfersHandler
    implements QueryHandler<GetTransfersQuery, List<TransferEntity>> {
  GetTransfersHandler(this._isar);

  final Isar _isar;

  @override
  Future<List<TransferEntity>> handle(GetTransfersQuery query) async {
    var builder = _isar.transferEntitys
        .filter()
        .userIdEqualTo(query.userId)
        .deletedAtIsNull();
    if (query.start != null) {
      builder = builder.dateGreaterThan(query.start!, include: true);
    }
    if (query.end != null) {
      builder = builder.dateLessThan(query.end!, include: true);
    }
    return builder.sortByDateDesc().findAll();
  }
}

class GetSummaryHandler
    implements QueryHandler<GetSummaryQuery, SummaryCacheEntity?> {
  GetSummaryHandler(this._isar, this._summaryWriter);

  final Isar _isar;
  final SummaryCacheWriter _summaryWriter;

  @override
  Future<SummaryCacheEntity?> handle(GetSummaryQuery query) async {
    final key = _summaryWriter.summaryKey(
      query.userId,
      query.period,
      query.startDate,
    );

    final existing = await _isar.summaryCacheEntitys
        .filter()
        .summaryKeyEqualTo(key)
        .findFirst();

    if (existing != null) {
      return existing;
    }

    await _summaryWriter.rebuildForRange(
      query.userId,
      query.period,
      query.startDate,
      _summaryWriter.periodEnd(query.period, query.startDate),
    );

    return _isar.summaryCacheEntitys
        .filter()
        .summaryKeyEqualTo(key)
        .findFirst();
  }
}

class SummaryCacheWriter {
  SummaryCacheWriter(this._isar);

  final Isar _isar;

  String summaryKey(String userId, String period, DateTime startDate) {
    return '$userId:$period:${startDate.millisecondsSinceEpoch}';
  }

  DateTime? periodEnd(String period, DateTime startDate) {
    switch (period) {
      case 'weekly':
        return startDate
            .add(const Duration(days: 7))
            .subtract(const Duration(milliseconds: 1));
      case 'monthly':
        return DateTime(startDate.year, startDate.month + 1, 1)
            .subtract(const Duration(milliseconds: 1));
      case 'yearly':
        return DateTime(startDate.year + 1, 1, 1)
            .subtract(const Duration(milliseconds: 1));
      case 'lifetime':
      default:
        return null;
    }
  }

  Future<void> rebuildForDate(String userId, DateTime date) async {
    await rebuildForRange(userId, 'weekly', _weekStart(date), _weekEnd(date));
    await rebuildForRange(
        userId, 'monthly', _monthStart(date), _monthEnd(date));
    await rebuildForRange(userId, 'yearly', _yearStart(date), _yearEnd(date));
    await rebuildForRange(
        userId, 'lifetime', DateTime.fromMillisecondsSinceEpoch(0), null);
  }

  Future<void> rebuildForRange(
    String userId,
    String period,
    DateTime startDate,
    DateTime? endDate,
  ) async {
    final transactions = await _loadTransactions(userId, startDate, endDate);
    double income = 0;
    double expense = 0;
    final categoryTotals = <String, double>{};

    for (final tx in transactions) {
      if (tx.type == 'income') {
        income += tx.amount;
        categoryTotals[tx.categoryId] =
            (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
      } else if (tx.type == 'expense') {
        expense += tx.amount;
        categoryTotals[tx.categoryId] =
            (categoryTotals[tx.categoryId] ?? 0) - tx.amount;
      }
    }

    final summary = SummaryCacheEntity()
      ..summaryKey = summaryKey(userId, period, startDate)
      ..userId = userId
      ..period = period
      ..startDate = startDate
      ..endDate = endDate
      ..totalIncome = income
      ..totalExpense = expense
      ..net = income - expense
      ..byCategoryJson = jsonEncode(categoryTotals);

    await _isar.writeTxn(() async {
      final existing = await _isar.summaryCacheEntitys
          .filter()
          .summaryKeyEqualTo(summary.summaryKey)
          .findFirst();

      if (existing != null) {
        summary.id = existing.id;
      }

      await _isar.summaryCacheEntitys.put(summary);
    });
  }

  Future<List<TransactionEntity>> _loadTransactions(
    String userId,
    DateTime startDate,
    DateTime? endDate,
  ) {
    var builder = _isar.transactionEntitys
        .filter()
        .userIdEqualTo(userId)
        .deletedAtIsNull()
        .not()
        .typeEqualTo('transfer')
        .dateGreaterThan(startDate, include: true);

    if (endDate != null) {
      builder = builder.dateLessThan(endDate, include: true);
    }

    return builder.findAll();
  }

  DateTime _weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime _weekEnd(DateTime date) {
    return _weekStart(date)
        .add(const Duration(days: 7))
        .subtract(const Duration(milliseconds: 1));
  }

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _monthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }

  DateTime _yearStart(DateTime date) => DateTime(date.year, 1, 1);

  DateTime _yearEnd(DateTime date) {
    return DateTime(date.year + 1, 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }
}

Future<void> _updateAccountBalance(
  Isar isar,
  String userId,
  String accountId,
  double delta,
) async {
  final account = await isar.accountEntitys
      .filter()
      .userIdEqualTo(userId)
      .accountIdEqualTo(accountId)
      .findFirst();
  if (account == null) {
    return;
  }

  account.currentBalance += delta;
  account.updatedAt = DateTime.now();
  await isar.accountEntitys.put(account);
}

double _deltaFor(String type, double amount) {
  if (type == 'income') {
    return amount;
  }
  if (type == 'expense') {
    return -amount;
  }
  return 0;
}
