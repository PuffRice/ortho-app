import 'dart:convert';

import 'cqrs_bus.dart';
import '../models/isar_models.dart';
import 'commands.dart';
import 'queries.dart';
import 'utils.dart';
import '../services/app_database.dart';
import '../services/sync_mapper.dart';
import '../services/sync_outbox.dart';
import '../services/sync_service.dart';

class CreateUserHandler implements CommandHandler<CreateUserCommand> {
  CreateUserHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(CreateUserCommand command) async {
    final now = command.now ?? DateTime.now();
    await _db.transaction((txn) async {
      final existing = await _db.getUserByUserId(command.userId);
      if (existing != null) {
        existing
          ..email = command.email
          ..displayName = command.displayName
          ..photoUrl = command.photoUrl ?? existing.photoUrl
          ..updatedAt = now;
        await _db.putUser(existing, txn: txn);
        await _outboxWriter.enqueueInTxn(
          userId: command.userId,
          entityType: 'users',
          entityId: existing.userId,
          payload: SyncPayloadMapper.user(existing),
          txn: txn,
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

      await _db.putUser(user, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'users',
        entityId: user.userId,
        payload: SyncPayloadMapper.user(user),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class CreateAccountHandler implements CommandHandler<CreateAccountCommand> {
  CreateAccountHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
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
      ..logoBase64 = command.logoBase64
      ..openingBalance = command.openingBalance
      ..currentBalance = command.openingBalance
      ..createdAt = now
      ..updatedAt = now;

    await _db.transaction((txn) async {
      await _db.putAccount(account, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'accounts',
        entityId: account.accountId,
        payload: SyncPayloadMapper.account(account),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class UpdateAccountHandler implements CommandHandler<UpdateAccountCommand> {
  UpdateAccountHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(UpdateAccountCommand command) async {
    final now = command.now ?? DateTime.now();
    AccountEntity? account;

    await _db.transaction((txn) async {
      account = await _db.getAccountByUserAndAccountId(
        command.userId,
        command.accountId,
      );

      if (account == null) {
        return;
      }

      final openingDelta = command.openingBalance - account!.openingBalance;
      account!
        ..name = command.name
        ..type = command.type
        ..currency = command.currency
        ..logoBase64 = command.logoBase64
        ..openingBalance = command.openingBalance
        ..currentBalance = account!.currentBalance + openingDelta
        ..updatedAt = now;

      await _db.putAccount(account!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'accounts',
        entityId: account!.accountId,
        payload: SyncPayloadMapper.account(account!),
        txn: txn,
      );
    });

    if (account != null) {
      SyncService.instance?.requestSync();
    }
  }
}

class DeleteAccountHandler implements CommandHandler<DeleteAccountCommand> {
  DeleteAccountHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(DeleteAccountCommand command) async {
    final now = command.now ?? DateTime.now();
    AccountEntity? account;

    await _db.transaction((txn) async {
      account = await _db.getAccountByUserAndAccountId(
        command.userId,
        command.accountId,
      );

      if (account == null) {
        return;
      }

      account!
        ..deletedAt = now
        ..updatedAt = now;

      await _db.putAccount(account!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'accounts',
        entityId: account!.accountId,
        payload: SyncPayloadMapper.account(account!),
        txn: txn,
      );
    });

    if (account != null) {
      SyncService.instance?.requestSync();
    }
  }
}

class CreateCategoryHandler implements CommandHandler<CreateCategoryCommand> {
  CreateCategoryHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
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

    await _db.transaction((txn) async {
      await _db.putCategory(category, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'categories',
        entityId: category.categoryId,
        payload: SyncPayloadMapper.category(category),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class UpdateCategoryHandler implements CommandHandler<UpdateCategoryCommand> {
  UpdateCategoryHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(UpdateCategoryCommand command) async {
    final now = command.now ?? DateTime.now();
    CategoryEntity? category;

    await _db.transaction((txn) async {
      category = await _db.getCategoryByUserAndCategoryId(
        command.userId,
        command.categoryId,
      );

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

      await _db.putCategory(category!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'categories',
        entityId: category!.categoryId,
        payload: SyncPayloadMapper.category(category!),
        txn: txn,
      );
    });

    if (category != null) {
      SyncService.instance?.requestSync();
    }
  }
}

class DeleteCategoryHandler implements CommandHandler<DeleteCategoryCommand> {
  DeleteCategoryHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(DeleteCategoryCommand command) async {
    final now = command.now ?? DateTime.now();
    CategoryEntity? category;

    await _db.transaction((txn) async {
      category = await _db.getCategoryByUserAndCategoryId(
        command.userId,
        command.categoryId,
      );

      if (category == null) {
        return;
      }

      category!
        ..deletedAt = now
        ..updatedAt = now;

      await _db.putCategory(category!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'categories',
        entityId: category!.categoryId,
        payload: SyncPayloadMapper.category(category!),
        txn: txn,
      );
    });

    if (category != null) {
      SyncService.instance?.requestSync();
    }
  }
}

class CreateTransactionHandler
    implements CommandHandler<CreateTransactionCommand> {
  CreateTransactionHandler(this._db, this._summaryWriter, this._outboxWriter);

  final AppDatabase _db;
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

    await _db.transaction((txn) async {
      await _db.putTransaction(transaction, txn: txn);
      await _updateAccountBalance(
        command.userId,
        command.accountId,
        _deltaFor(command.type, command.amount),
        txn,
      );
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'transactions',
        entityId: transaction.transactionId,
        payload: SyncPayloadMapper.transaction(transaction),
        txn: txn,
      );
    });

    await _summaryWriter.rebuildForDate(command.userId, command.date);
    SyncService.instance?.requestSync();
  }

  Future<void> _updateAccountBalance(
    String userId,
    String accountId,
    double delta,
    dynamic txn,
  ) async {
    final account = await _db.getAccountByUserAndAccountId(userId, accountId);
    if (account == null) return;
    account.currentBalance += delta;
    account.updatedAt = DateTime.now();
    await _db.putAccount(account, txn: txn);
  }

  double _deltaFor(String type, double amount) {
    return type == 'income' ? amount : (type == 'expense' ? -amount : 0);
  }
}

class UpdateTransactionHandler
    implements CommandHandler<UpdateTransactionCommand> {
  UpdateTransactionHandler(this._db, this._summaryWriter, this._outboxWriter);

  final AppDatabase _db;
  final SummaryCacheWriter _summaryWriter;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(UpdateTransactionCommand command) async {
    TransactionEntity? existing;
    DateTime? previousDate;

    await _db.transaction((txn) async {
      existing = await _db.getTransactionByUserAndTransactionId(
        command.userId,
        command.transactionId,
      );

      if (existing == null) {
        return;
      }

      final oldDelta = _deltaFor(existing!.type, existing!.amount);
      final newDelta = _deltaFor(command.type, command.amount);
      previousDate = existing!.date;

      if (existing!.accountId == command.accountId) {
        await _updateAccountBalance(
          command.userId,
          command.accountId,
          newDelta - oldDelta,
          txn,
        );
      } else {
        await _updateAccountBalance(command.userId, existing!.accountId, -oldDelta, txn);
        await _updateAccountBalance(command.userId, command.accountId, newDelta, txn);
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

      await _db.putTransaction(existing!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'transactions',
        entityId: existing!.transactionId,
        payload: SyncPayloadMapper.transaction(existing!),
        txn: txn,
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

  Future<void> _updateAccountBalance(
    String userId,
    String accountId,
    double delta,
    dynamic txn,
  ) async {
    final account = await _db.getAccountByUserAndAccountId(userId, accountId);
    if (account == null) return;
    account.currentBalance += delta;
    account.updatedAt = DateTime.now();
    await _db.putAccount(account, txn: txn);
  }

  double _deltaFor(String type, double amount) {
    return type == 'income' ? amount : (type == 'expense' ? -amount : 0);
  }
}

class DeleteTransactionHandler
    implements CommandHandler<DeleteTransactionCommand> {
  DeleteTransactionHandler(this._db, this._summaryWriter, this._outboxWriter);

  final AppDatabase _db;
  final SummaryCacheWriter _summaryWriter;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(DeleteTransactionCommand command) async {
    TransactionEntity? existing;
    DateTime? previousDate;

    await _db.transaction((txn) async {
      existing = await _db.getTransactionByUserAndTransactionId(
        command.userId,
        command.transactionId,
      );

      if (existing == null) {
        return;
      }

      previousDate = existing!.date;
      existing!
        ..deletedAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await _db.putTransaction(existing!, txn: txn);
      await _updateAccountBalance(
        command.userId,
        existing!.accountId,
        -_deltaFor(existing!.type, existing!.amount),
        txn,
      );
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'transactions',
        entityId: existing!.transactionId,
        payload: SyncPayloadMapper.transaction(existing!),
        txn: txn,
      );
    });

    if (previousDate != null) {
      await _summaryWriter.rebuildForDate(command.userId, previousDate!);
    }
    SyncService.instance?.requestSync();
  }

  Future<void> _updateAccountBalance(
    String userId,
    String accountId,
    double delta,
    dynamic txn,
  ) async {
    final account = await _db.getAccountByUserAndAccountId(userId, accountId);
    if (account == null) return;
    account.currentBalance += delta;
    account.updatedAt = DateTime.now();
    await _db.putAccount(account, txn: txn);
  }

  double _deltaFor(String type, double amount) {
    return type == 'income' ? amount : (type == 'expense' ? -amount : 0);
  }
}

class CreateTransferHandler implements CommandHandler<CreateTransferCommand> {
  CreateTransferHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
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

    await _db.transaction((txn) async {
      await _db.putTransfer(transfer, txn: txn);
      await _updateAccountBalance(command.userId, command.fromAccountId, -command.amount, txn);
      await _updateAccountBalance(command.userId, command.toAccountId, command.amount, txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'transfers',
        entityId: transfer.transferId,
        payload: SyncPayloadMapper.transfer(transfer),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }

  Future<void> _updateAccountBalance(
    String userId,
    String accountId,
    double delta,
    dynamic txn,
  ) async {
    final account = await _db.getAccountByUserAndAccountId(userId, accountId);
    if (account == null) return;
    account.currentBalance += delta;
    account.updatedAt = DateTime.now();
    await _db.putAccount(account, txn: txn);
  }
}

class CreateBudgetHandler implements CommandHandler<CreateBudgetCommand> {
  CreateBudgetHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
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

    await _db.transaction((txn) async {
      await _db.putBudget(budget, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'budgets',
        entityId: budget.budgetId,
        payload: SyncPayloadMapper.budget(budget),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class CreateRecurringTransactionHandler
    implements CommandHandler<CreateRecurringTransactionCommand> {
  CreateRecurringTransactionHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
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

    await _db.transaction((txn) async {
      await _db.putRecurring(recurring, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'recurring',
        entityId: recurring.recurringId,
        payload: SyncPayloadMapper.recurring(recurring),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class UpsertPaymentCardCredentialHandler
    implements CommandHandler<UpsertPaymentCardCredentialCommand> {
  UpsertPaymentCardCredentialHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(UpsertPaymentCardCredentialCommand command) async {
    final now = command.now ?? DateTime.now();
    PaymentCardCredentialEntity? credential;
    await _db.transaction((txn) async {
      if (command.cardCredentialId != null) {
        credential = await _db.getPaymentCardCredentialByUserAndId(
          command.userId,
          command.cardCredentialId!,
        );
      }
      credential ??= PaymentCardCredentialEntity()
        ..userId = command.userId
        ..cardCredentialId = command.cardCredentialId ?? generateId()
        ..createdAt = now;

      credential!
        ..bankName = command.bankName
        ..bankLogoBase64 = command.bankLogoBase64
        ..cardType = command.cardType
        ..network = command.network
        ..cardholderName = command.cardholderName
        ..cardNumber = command.cardNumber
        ..expiry = command.expiry
        ..hasNfc = command.hasNfc
        ..updatedAt = now
        ..deletedAt = null;

      await _db.putPaymentCardCredential(credential!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'payment_card_credentials',
        entityId: credential!.cardCredentialId,
        payload: SyncPayloadMapper.paymentCardCredential(credential!),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class DeletePaymentCardCredentialHandler
    implements CommandHandler<DeletePaymentCardCredentialCommand> {
  DeletePaymentCardCredentialHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(DeletePaymentCardCredentialCommand command) async {
    final now = command.now ?? DateTime.now();
    PaymentCardCredentialEntity? credential;
    await _db.transaction((txn) async {
      credential = await _db.getPaymentCardCredentialByUserAndId(
        command.userId,
        command.cardCredentialId,
      );
      if (credential == null) {
        return;
      }
      credential!
        ..deletedAt = now
        ..updatedAt = now;
      await _db.putPaymentCardCredential(credential!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'payment_card_credentials',
        entityId: credential!.cardCredentialId,
        payload: SyncPayloadMapper.paymentCardCredential(credential!),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class UpsertBankAccountCredentialHandler
    implements CommandHandler<UpsertBankAccountCredentialCommand> {
  UpsertBankAccountCredentialHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(UpsertBankAccountCredentialCommand command) async {
    final now = command.now ?? DateTime.now();
    BankAccountCredentialEntity? credential;
    await _db.transaction((txn) async {
      if (command.bankCredentialId != null) {
        credential = await _db.getBankAccountCredentialByUserAndId(
          command.userId,
          command.bankCredentialId!,
        );
      }
      credential ??= BankAccountCredentialEntity()
        ..userId = command.userId
        ..bankCredentialId = command.bankCredentialId ?? generateId()
        ..createdAt = now;

      credential!
        ..bankName = command.bankName
        ..bankLogoBase64 = command.bankLogoBase64
        ..branchName = command.branchName
        ..accountName = command.accountName
        ..accountNumber = command.accountNumber
        ..routingNumber = command.routingNumber
        ..swiftCode = command.swiftCode
        ..updatedAt = now
        ..deletedAt = null;

      await _db.putBankAccountCredential(credential!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'bank_account_credentials',
        entityId: credential!.bankCredentialId,
        payload: SyncPayloadMapper.bankAccountCredential(credential!),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class DeleteBankAccountCredentialHandler
    implements CommandHandler<DeleteBankAccountCredentialCommand> {
  DeleteBankAccountCredentialHandler(this._db, this._outboxWriter);

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  @override
  Future<void> handle(DeleteBankAccountCredentialCommand command) async {
    final now = command.now ?? DateTime.now();
    BankAccountCredentialEntity? credential;
    await _db.transaction((txn) async {
      credential = await _db.getBankAccountCredentialByUserAndId(
        command.userId,
        command.bankCredentialId,
      );
      if (credential == null) {
        return;
      }
      credential!
        ..deletedAt = now
        ..updatedAt = now;
      await _db.putBankAccountCredential(credential!, txn: txn);
      await _outboxWriter.enqueueInTxn(
        userId: command.userId,
        entityType: 'bank_account_credentials',
        entityId: credential!.bankCredentialId,
        payload: SyncPayloadMapper.bankAccountCredential(credential!),
        txn: txn,
      );
    });
    SyncService.instance?.requestSync();
  }
}

class GetAccountsHandler
    implements QueryHandler<GetAccountsQuery, List<AccountEntity>> {
  GetAccountsHandler(this._db);

  final AppDatabase _db;

  @override
  Future<List<AccountEntity>> handle(GetAccountsQuery query) {
    return _db.getAccounts(userId: query.userId);
  }
}

class GetCategoriesHandler
    implements QueryHandler<GetCategoriesQuery, List<CategoryEntity>> {
  GetCategoriesHandler(this._db);

  final AppDatabase _db;

  @override
  Future<List<CategoryEntity>> handle(GetCategoriesQuery query) {
    return _db.getCategories(userId: query.userId, type: query.type);
  }
}

class GetTransactionsHandler
    implements QueryHandler<GetTransactionsQuery, List<TransactionEntity>> {
  GetTransactionsHandler(this._db);

  final AppDatabase _db;

  @override
  Future<List<TransactionEntity>> handle(GetTransactionsQuery query) {
    return _db.getTransactions(
      userId: query.userId,
      accountId: query.accountId,
      categoryId: query.categoryId,
      type: query.type,
      start: query.start,
      end: query.end,
      limit: query.limit,
    );
  }
}

class GetBudgetsHandler
    implements QueryHandler<GetBudgetsQuery, List<BudgetEntity>> {
  GetBudgetsHandler(this._db);

  final AppDatabase _db;

  @override
  Future<List<BudgetEntity>> handle(GetBudgetsQuery query) {
    return _db.getBudgets(userId: query.userId);
  }
}

class GetRecurringHandler
    implements
        QueryHandler<GetRecurringQuery, List<RecurringTransactionEntity>> {
  GetRecurringHandler(this._db);

  final AppDatabase _db;

  @override
  Future<List<RecurringTransactionEntity>> handle(GetRecurringQuery query) {
    return _db.getRecurringTransactions(userId: query.userId);
  }
}

class GetTransfersHandler
    implements QueryHandler<GetTransfersQuery, List<TransferEntity>> {
  GetTransfersHandler(this._db);

  final AppDatabase _db;

  @override
  Future<List<TransferEntity>> handle(GetTransfersQuery query) {
    return _db.getTransfers(
      userId: query.userId,
      start: query.start,
      end: query.end,
    );
  }
}

class GetSummaryHandler
    implements QueryHandler<GetSummaryQuery, SummaryCacheEntity?> {
  GetSummaryHandler(this._db, this._summaryWriter);

  final AppDatabase _db;
  final SummaryCacheWriter _summaryWriter;

  @override
  Future<SummaryCacheEntity?> handle(GetSummaryQuery query) async {
    final key = _summaryWriter.summaryKey(
      query.userId,
      query.period,
      query.startDate,
    );

    final existing = await _db.getSummaryByKey(key);
    if (existing != null) {
      return existing;
    }

    await _summaryWriter.rebuildForRange(
      query.userId,
      query.period,
      query.startDate,
      _summaryWriter.periodEnd(query.period, query.startDate),
    );

    return _db.getSummaryByKey(key);
  }
}

class GetPaymentCardCredentialsHandler
    implements
        QueryHandler<GetPaymentCardCredentialsQuery,
            List<PaymentCardCredentialEntity>> {
  GetPaymentCardCredentialsHandler(this._db);

  final AppDatabase _db;

  @override
  Future<List<PaymentCardCredentialEntity>> handle(
    GetPaymentCardCredentialsQuery query,
  ) {
    return _db.getPaymentCardCredentials(userId: query.userId);
  }
}

class GetBankAccountCredentialsHandler
    implements
        QueryHandler<GetBankAccountCredentialsQuery,
            List<BankAccountCredentialEntity>> {
  GetBankAccountCredentialsHandler(this._db);

  final AppDatabase _db;

  @override
  Future<List<BankAccountCredentialEntity>> handle(
    GetBankAccountCredentialsQuery query,
  ) {
    return _db.getBankAccountCredentials(userId: query.userId);
  }
}

class SummaryCacheWriter {
  SummaryCacheWriter(this._db);

  final AppDatabase _db;

  String summaryKey(String userId, String period, DateTime startDate) {
    return '$userId:$period:${startDate.millisecondsSinceEpoch}';
  }

  Future<void> rebuildForDate(String userId, DateTime date) async {
    await rebuildForRange(userId, 'weekly', _weekStart(date), _weekEnd(date));
    await rebuildForRange(userId, 'monthly', _monthStart(date), _monthEnd(date));
    await rebuildForRange(userId, 'yearly', _yearStart(date), _yearEnd(date));
    await rebuildForRange(
      userId,
      'lifetime',
      DateTime.fromMillisecondsSinceEpoch(0),
      null,
    );
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

    await _db.putSummaryCache(summary);
  }

  Future<List<TransactionEntity>> _loadTransactions(
    String userId,
    DateTime startDate,
    DateTime? endDate,
  ) {
    return _db.getTransactions(
      userId: userId,
      start: startDate,
      end: endDate,
      type: 'income',
    ).then((income) async {
      final expense = await _db.getTransactions(
        userId: userId,
        start: startDate,
        end: endDate,
        type: 'expense',
      );
      return [...income, ...expense];
    });
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

  DateTime _monthEnd(DateTime date) =>
      _monthStart(DateTime(date.year, date.month + 1, 1))
          .subtract(const Duration(milliseconds: 1));

  DateTime _yearStart(DateTime date) => DateTime(date.year, 1, 1);

  DateTime _yearEnd(DateTime date) =>
      DateTime(date.year + 1, 1, 1).subtract(const Duration(milliseconds: 1));

  DateTime periodEnd(String period, DateTime startDate) {
    switch (period) {
      case 'weekly':
        return _weekEnd(startDate);
      case 'monthly':
        return _monthEnd(startDate);
      case 'yearly':
        return _yearEnd(startDate);
      default:
        return DateTime.now();
    }
  }
}
