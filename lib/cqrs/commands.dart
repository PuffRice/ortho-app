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
    this.logoBase64,
    this.now,
  });

  final String userId;
  final String name;
  final String type;
  final String currency;
  final double openingBalance;
  final String? accountId;
  final String? logoBase64;
  final DateTime? now;
}

class UpdateAccountCommand extends Command {
  const UpdateAccountCommand({
    required this.userId,
    required this.accountId,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    this.logoBase64,
    this.now,
  });

  final String userId;
  final String accountId;
  final String name;
  final String type;
  final String currency;
  final double openingBalance;
  final String? logoBase64;
  final DateTime? now;
}

class DeleteAccountCommand extends Command {
  const DeleteAccountCommand({
    required this.userId,
    required this.accountId,
    this.now,
  });

  final String userId;
  final String accountId;
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

class UpdateCategoryCommand extends Command {
  const UpdateCategoryCommand({
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.now,
  });

  final String userId;
  final String categoryId;
  final String name;
  final String type;
  final String? icon;
  final int? color;
  final int sortOrder;
  final DateTime? now;
}

class DeleteCategoryCommand extends Command {
  const DeleteCategoryCommand({
    required this.userId,
    required this.categoryId,
    this.now,
  });

  final String userId;
  final String categoryId;
  final DateTime? now;
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

class UpdateTransferCommand extends Command {
  const UpdateTransferCommand({
    required this.userId,
    required this.transferId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String userId;
  final String transferId;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String? note;
}

class DeleteTransferCommand extends Command {
  const DeleteTransferCommand({
    required this.userId,
    required this.transferId,
  });

  final String userId;
  final String transferId;
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

class UpsertPaymentCardCredentialCommand extends Command {
  const UpsertPaymentCardCredentialCommand({
    required this.userId,
    required this.bankName,
    required this.cardType,
    required this.network,
    required this.cardholderName,
    required this.cardNumber,
    required this.expiry,
    required this.hasNfc,
    this.cardCredentialId,
    this.bankLogoBase64,
    this.now,
  });

  final String userId;
  final String bankName;
  final String? bankLogoBase64;
  final String cardType;
  final String network;
  final String cardholderName;
  final String cardNumber;
  final String expiry;
  final bool hasNfc;
  final String? cardCredentialId;
  final DateTime? now;
}

class DeletePaymentCardCredentialCommand extends Command {
  const DeletePaymentCardCredentialCommand({
    required this.userId,
    required this.cardCredentialId,
    this.now,
  });

  final String userId;
  final String cardCredentialId;
  final DateTime? now;
}

class UpsertBankAccountCredentialCommand extends Command {
  const UpsertBankAccountCredentialCommand({
    required this.userId,
    required this.bankName,
    required this.branchName,
    required this.accountName,
    required this.accountNumber,
    required this.routingNumber,
    required this.swiftCode,
    this.bankCredentialId,
    this.bankLogoBase64,
    this.now,
  });

  final String userId;
  final String bankName;
  final String? bankLogoBase64;
  final String branchName;
  final String accountName;
  final String accountNumber;
  final String routingNumber;
  final String swiftCode;
  final String? bankCredentialId;
  final DateTime? now;
}

class DeleteBankAccountCredentialCommand extends Command {
  const DeleteBankAccountCredentialCommand({
    required this.userId,
    required this.bankCredentialId,
    this.now,
  });

  final String userId;
  final String bankCredentialId;
  final DateTime? now;
}
