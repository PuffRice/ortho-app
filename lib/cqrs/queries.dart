import 'cqrs_bus.dart';
import '../models/isar_models.dart';

class GetAccountsQuery extends Query<List<AccountEntity>> {
  const GetAccountsQuery({required this.userId});

  final String userId;
}

class GetCategoriesQuery extends Query<List<CategoryEntity>> {
  const GetCategoriesQuery({required this.userId, this.type});

  final String userId;
  final String? type;
}

class GetTransactionsQuery extends Query<List<TransactionEntity>> {
  const GetTransactionsQuery({
    required this.userId,
    this.start,
    this.end,
    this.type,
    this.accountId,
    this.categoryId,
    this.limit = 200,
  });

  final String userId;
  final DateTime? start;
  final DateTime? end;
  final String? type;
  final String? accountId;
  final String? categoryId;
  final int limit;
}

class GetBudgetsQuery extends Query<List<BudgetEntity>> {
  const GetBudgetsQuery({required this.userId});

  final String userId;
}

class GetRecurringQuery extends Query<List<RecurringTransactionEntity>> {
  const GetRecurringQuery({required this.userId});

  final String userId;
}

class GetTransfersQuery extends Query<List<TransferEntity>> {
  const GetTransfersQuery({required this.userId, this.start, this.end});

  final String userId;
  final DateTime? start;
  final DateTime? end;
}

class GetSummaryQuery extends Query<SummaryCacheEntity?> {
  const GetSummaryQuery({
    required this.userId,
    required this.period,
    required this.startDate,
  });

  final String userId;
  final String period; // weekly, monthly, yearly, lifetime
  final DateTime startDate;
}
