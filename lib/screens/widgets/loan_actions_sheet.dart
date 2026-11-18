import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../cqrs/commands.dart';
import '../../models/local_models.dart';
import '../../services/cqrs_service.dart';
import '../../utils/date_time_utils.dart';

/// Bottom sheet for an existing loan: shows its status and offers recording a
/// repayment ("settle") or deleting the loan. A repayment is recorded as a
/// regular income or expense transaction and also reduces the outstanding loan.
Future<bool> showLoanActionsSheet({
  required BuildContext context,
  required LoanEntity loan,
  required String accountName,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.bgSecondary,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final isGiven = loan.direction == LoanDirection.given;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            18 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppColors.primaryViolet.withValues(alpha: 0.24),
                    child: Icon(
                      isGiven
                          ? Icons.handshake_outlined
                          : Icons.account_balance_outlined,
                      color: AppColors.primaryViolet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGiven
                              ? 'Loan to ${loan.counterparty}'
                              : 'Loan from ${loan.counterparty}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGiven
                              ? 'Money you lent from ${accountName == '' ? 'an account' : accountName}'
                              : 'Money you borrowed into ${accountName == '' ? 'an account' : accountName}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _loanStatRow('Amount', _moneyLabel(loan.amount, loan.currency)),
              _loanStatRow(
                  'Settled', _moneyLabel(loan.settledAmount, loan.currency)),
              _loanStatRow(
                'Outstanding',
                loan.isSettled
                    ? 'Settled'
                    : _moneyLabel(loan.outstandingAmount, loan.currency),
                highlighted: !loan.isSettled,
              ),
              _loanStatRow('Date', AppDateTime.formatMediumDate(
                sheetContext,
                loan.date,
              )),
              if (loan.note?.trim().isNotEmpty == true)
                _loanStatRow('Note', loan.note!.trim()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loan.isSettled
                      ? null
                      : () async {
                          final updated = await _recordRepayment(
                            sheetContext,
                            loan,
                          );
                          if (updated == true && sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(true);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isGiven ? 'Record repayment received' : 'Record repayment made',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirmed = await _confirmDeleteLoan(
                      sheetContext,
                      loan,
                    );
                    if (confirmed == true && sheetContext.mounted) {
                      Navigator.of(sheetContext).pop(true);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete loan'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return changed ?? false;
}

/// `true` when the user saved a repayment in the dialog.
Future<bool?> _recordRepayment(BuildContext context, LoanEntity loan) {
  final controller = TextEditingController(
    text: loan.outstandingAmount.toStringAsFixed(2),
  );
  final isGiven = loan.direction == LoanDirection.given;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(
          isGiven ? 'Repayment received' : 'Repayment made',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText:
                'Amount (${_moneyLabel(loan.outstandingAmount, loan.currency)} outstanding)',
            labelStyle: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid repayment amount.'),
                  ),
                );
                return;
              }
              try {
                final cqrs = await CqrsService.create();
                await cqrs.bus.execute(
                  SettleLoanCommand(
                    userId: loan.userId,
                    loanId: loan.loanId,
                    amount: amount,
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to record: $error')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<bool?> _confirmDeleteLoan(BuildContext context, LoanEntity loan) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text(
          'Delete loan?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This removes the loan record locally and syncs the deletion. '
          'Balances and totals are not affected.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final cqrs = await CqrsService.create();
                await cqrs.bus.execute(
                  DeleteLoanCommand(
                    userId: loan.userId,
                    loanId: loan.loanId,
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $error')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      );
    },
  );
}

String _moneyLabel(double amount, String currency) {
  final symbol = currency == 'BDT' ? 'Tk.' : currency;
  return '$symbol ${amount.toStringAsFixed(2)}';
}

Widget _loanStatRow(String label, String value, {bool highlighted = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlighted
                ? AppColors.accentCoral
                : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
