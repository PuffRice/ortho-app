import 'cqrs_bus.dart';

class CreateUserCommand extends Command {
  const CreateUserCommand({
    required this.userId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.now,
  });

  final String userId;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime? now;
}

class CreateAccountCommand extends Command {
  const CreateAccountCommand({
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    this.accountId,
    this.now,
  });

  final String userId;
  final String name;
  final String type;
  final String currency;
  final double openingBalance;
  final String? accountId;
  final DateTime? now;
}

class CreateCategoryCommand extends Command {
  const CreateCategoryCommand({
    required this.userId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.categoryId,
  });

  final String userId;
  final String name;
  final String type;
  final String? icon;
  final int? color;
  final int sortOrder;
  final String? categoryId;
}

class CreateTransactionCommand extends Command {
  const CreateTransactionCommand({
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    this.note,
    this.isRecurring = false,
    this.transactionId,
  });

  final String userId;
  final String accountId;
  final String categoryId;
  final String type;
  final double amount;
  final String currency;
  final DateTime date;
  final String? note;
  final bool isRecurring;
  final String? transactionId;
}

class UpdateTransactionCommand extends Command {
  const UpdateTransactionCommand({
    required this.userId,
    required this.transactionId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    this.note,
    this.isRecurring = false,
  });

  final String userId;
  final String transactionId;
  final String accountId;
  final String categoryId;
  final String type;
  final double amount;
  final String currency;
  final DateTime date;
  final String? note;
  final bool isRecurring;
}

class DeleteTransactionCommand extends Command {
  const DeleteTransactionCommand({
    required this.userId,
    required this.transactionId,
  });

  final String userId;
  final String transactionId;
}

class CreateTransferCommand extends Command {
  const CreateTransferCommand({
    required this.userId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
    this.transferId,
  });

  final String userId;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String? note;
  final String? transferId;
}

class CreateBudgetCommand extends Command {
  const CreateBudgetCommand({
    required this.userId,
    required this.period,
    required this.amount,
    required this.startDate,
    this.categoryId,
    this.endDate,
    this.budgetId,
  });

  final String userId;
  final String period;
  final double amount;
  final DateTime startDate;
  final String? categoryId;
  final DateTime? endDate;
  final String? budgetId;
}

class CreateRecurringTransactionCommand extends Command {
  const CreateRecurringTransactionCommand({
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.interval,
    required this.nextRunAt,
    this.isActive = true,
    this.recurringId,
  });

  final String userId;
  final String accountId;
  final String categoryId;
  final String type;
  final double amount;
  final String interval;
  final DateTime nextRunAt;
  final bool isActive;
  final String? recurringId;
}
