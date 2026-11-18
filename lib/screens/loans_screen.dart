import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../cqrs/queries.dart';
import '../models/local_models.dart';
import '../services/cqrs_service.dart';
import '../services/user_identity.dart';
import '../utils/date_time_utils.dart';
import 'add_transaction_screen.dart';
import 'widgets/loan_actions_sheet.dart';

/// Loans log: all loans ever recorded, with outstanding/settled status and
/// actions (repay, delete). Recording a new loan opens the Add Transaction
/// screen preselected on the "Loan" type.
class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

enum _LoanFilter { all, given, taken }

class _LoansScreenState extends State<LoansScreen> {
  Future<_LoansData>? _loansFuture;
  _LoanFilter _filter = _LoanFilter.all;

  @override
  void initState() {
    super.initState();
    _loansFuture = _loadLoans();
  }

  Future<_LoansData> _loadLoans() async {
    final profile = await UserIdentityService.instance.getProfile();
    final cqrs = await CqrsService.create();
    final loans = await cqrs.bus.query<GetLoansQuery, List<LoanEntity>>(
      GetLoansQuery(userId: profile.userId),
    );
    final accounts = await cqrs.bus.query<GetAccountsQuery, List<AccountEntity>>(
      GetAccountsQuery(userId: profile.userId),
    );
    return _LoansData(loans: loans, accounts: accounts);
  }

  Future<void> _reload() async {
    final next = _loadLoans();
    setState(() {
      _loansFuture = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Loans'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordLoan,
        backgroundColor: AppColors.primaryViolet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.handshake_outlined, size: 20),
        label: const Text('Record loan'),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -320,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 640,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryViolet.withValues(alpha: 0.3),
                      AppColors.primaryDeep.withValues(alpha: 0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          FutureBuilder<_LoansData>(
            future: _loansFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _buildLoadError(snapshot.error);
              }
              return _buildContent(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to load loans.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _reload,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(_LoansData data) {
    final outstandingGiven = _sumOutstanding(data.loans, LoanDirection.given);
    final outstandingTaken = _sumOutstanding(data.loans, LoanDirection.taken);
    final currency = _displayCurrency(data);
    final filteredLoans = _filterLoans(data.loans);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          _buildSummaryCards(
            lentOutstanding: outstandingGiven,
            borrowedOutstanding: outstandingTaken,
            currency: currency,
          ),
          const SizedBox(height: 14),
          _buildFilterChips(),
          const SizedBox(height: 14),
          if (filteredLoans.isEmpty)
            _buildEmptyState()
          else
            for (final loan in filteredLoans) ...[
              _buildLoanTile(loan, data),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required double lentOutstanding,
    required double borrowedOutstanding,
    required String currency,
  }) {
    final label = _currencyLabel(currency);
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.handshake_outlined,
            label: 'You lent (outstanding)',
            amount: '$label ${lentOutstanding.toStringAsFixed(2)}',
            color: AppColors.expenseNegative,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.account_balance_outlined,
            label: 'You borrowed (outstanding)',
            amount: '$label ${borrowedOutstanding.toStringAsFixed(2)}',
            color: AppColors.incomePositive,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildFilterChip(_LoanFilter.all, 'All'),
        _buildFilterChip(_LoanFilter.given, 'Lent'),
        _buildFilterChip(_LoanFilter.taken, 'Borrowed'),
      ],
    );
  }

  Widget _buildFilterChip(_LoanFilter value, String label) {
    final isSelected = _filter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
      showCheckmark: false,
      selectedColor: AppColors.primaryViolet,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      side: BorderSide(
        color: isSelected
            ? AppColors.primaryViolet
            : Colors.white.withValues(alpha: 0.14),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLoanTile(LoanEntity loan, _LoansData data) {
    final isGiven = loan.direction == LoanDirection.given;
    final account = data.accountById[loan.accountId];
    final note = loan.note?.trim();
    final title = note == null || note.isEmpty
        ? (isGiven
            ? 'Loan to ${loan.counterparty}'
            : 'Loan from ${loan.counterparty}')
        : note;
    final status = loan.isSettled
        ? 'Settled'
        : 'Outstanding ${_currencyLabel(loan.currency)} '
            '${loan.outstandingAmount.toStringAsFixed(2)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLoanActions(loan, data),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: loan.isSettled
                ? Colors.white.withValues(alpha: 0.055)
                : AppColors.accentOrange.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: loan.isSettled
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.accentOrange.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGiven
                      ? Icons.handshake_outlined
                      : Icons.account_balance_outlined,
                  color: AppColors.accentOrange,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${isGiven ? 'Lent to' : 'Borrowed from'} '
                      '${loan.counterparty} | ${account?.name ?? 'Account'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppDateTime.formatMediumDate(context, loan.date)} · $status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _signedAmountLabel(loan),
                style: TextStyle(
                  color: isGiven
                      ? AppColors.expenseNegative
                      : AppColors.incomePositive,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _filter == _LoanFilter.all
            ? 'No loans yet. Record one with the button below.'
            : _filter == _LoanFilter.given
                ? 'You have not lent money yet.'
                : 'You have not borrowed money yet.',
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Future<void> _recordLoan() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AddTransactionScreen(initialType: 'loan'),
      ),
    );
    if (updated == true && mounted) {
      await _reload();
    }
  }

  Future<void> _openLoanActions(LoanEntity loan, _LoansData data) async {
    if (!mounted) {
      return;
    }
    final accountName = data.accountById[loan.accountId]?.name ?? 'Account';
    final changed = await showLoanActionsSheet(
      context: context,
      loan: loan,
      accountName: accountName,
    );
    if (changed && mounted) {
      await _reload();
    }
  }

  List<LoanEntity> _filterLoans(List<LoanEntity> loans) {
    final Iterable<LoanEntity> filtered;
    switch (_filter) {
      case _LoanFilter.given:
        filtered = loans.where((loan) => loan.direction == LoanDirection.given);
        break;
      case _LoanFilter.taken:
        filtered = loans.where((loan) => loan.direction == LoanDirection.taken);
        break;
      case _LoanFilter.all:
        filtered = loans;
        break;
    }
    return filtered.toList()
      ..sort((a, b) {
        final settledFirst = (a.isSettled ? 1 : 0) - (b.isSettled ? 1 : 0);
        if (settledFirst != 0) {
          return settledFirst;
        }
        return b.date.compareTo(a.date);
      });
  }

  double _sumOutstanding(List<LoanEntity> loans, LoanDirection direction) {
    var total = 0.0;
    for (final loan in loans) {
      if (loan.direction == direction) {
        total += loan.outstandingAmount;
      }
    }
    return total;
  }

  String _displayCurrency(_LoansData data) {
    for (final account in data.accounts) {
      return account.currency;
    }
    return 'BDT';
  }

  String _currencyLabel(String currency) {
    return currency == 'BDT' ? 'Tk.' : currency;
  }

  String _signedAmountLabel(LoanEntity loan) {
    final isGiven = loan.direction == LoanDirection.given;
    final sign = isGiven ? '-' : '+';
    return '$sign${_currencyLabel(loan.currency)} '
        '${loan.amount.toStringAsFixed(2)}';
  }
}

class _LoansData {
  const _LoansData({required this.loans, required this.accounts});

  final List<LoanEntity> loans;
  final List<AccountEntity> accounts;

  Map<String, AccountEntity> get accountById {
    return {for (final account in accounts) account.accountId: account};
  }
}
