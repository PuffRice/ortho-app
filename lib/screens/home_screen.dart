import 'dart:async';

import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/category_icons.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';
import '../services/local_db.dart';
import '../services/user_identity.dart';
import 'add_transaction_screen.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = false;
  bool _isAccountBalancesExpanded = false;
  Future<_HomeData>? _homeDataFuture;
  StreamSubscription<void>? _profileChangesSubscription;

  Future<_HomeData> get _homeData {
    return _homeDataFuture ??= _loadHomeData();
  }

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadHomeData();
    _profileChangesSubscription =
        UserIdentityService.instance.profileChanges.listen((_) {
      if (mounted) {
        _reloadHomeData();
      }
    });
  }

  @override
  void dispose() {
    _profileChangesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: -360,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 720,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryViolet.withOpacity(0.35),
                      AppColors.primaryDeep.withOpacity(0.0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<_HomeData>(
              future: _homeData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildLoadError(snapshot.error);
                }
                return _buildHomeContent(context, snapshot.data!);
              },
            ),
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
            Text(
              'Unable to load local data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: _reloadHomeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadWarning(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.accentCoral.withOpacity(0.10),
        border: Border.all(
          color: AppColors.accentCoral.withOpacity(0.24),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, _HomeData data) {
    return RefreshIndicator(
      onRefresh: () async {
        final next = _loadHomeData();
        setState(() {
          _homeDataFuture = next;
        });
        await next;
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(data.displayName),
              if (data.loadWarning != null) ...[
                const SizedBox(height: 14),
                _buildLoadWarning(data.loadWarning!),
              ],
              const SizedBox(height: 24),
              _buildActiveBalanceCard(
                data.activeBalanceLabel,
                data.accountBalances,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      icon: Icons.arrow_downward,
                      iconColor: AppColors.incomePositive,
                      label: 'Inflow this month',
                      amount: data.inflowLabel,
                      change: data.inflowChangeLabel,
                      changeColor: AppColors.incomePositive,
                      onTap: () => _openTransactionHistory('income'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildFinancialCard(
                      icon: Icons.arrow_upward,
                      iconColor: AppColors.expenseNegative,
                      label: 'Outflow this month',
                      amount: data.outflowLabel,
                      change: data.outflowChangeLabel,
                      changeColor: AppColors.expenseNegative,
                      onTap: () => _openTransactionHistory('expense'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildTransactionHeader(),
              const SizedBox(height: 16),
              if (data.transactions.isEmpty)
                _buildEmptyTransactions()
              else
                for (final transaction in data.transactions) ...[
                  _buildTransactionItem(
                    transaction: transaction.transaction,
                    description: transaction.description,
                    time: MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay.fromDateTime(transaction.date),
                    ),
                    date: MaterialLocalizations.of(context)
                        .formatMediumDate(transaction.date),
                    amount: transaction.amountLabel,
                    category: transaction.categoryName,
                    categoryIcon: transaction.categoryIcon,
                    categoryColor: transaction.categoryColor,
                    isPositive: transaction.isPositive,
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<_HomeData> _loadHomeData() async {
    final profile = await UserIdentityService.instance.getProfile();
    final db = await LocalDb.instance.open();
    final user = await db.getUserByUserId(profile.userId);
    final cqrs = await CqrsService.create();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);

    final accounts = await _loadSection<List<AccountEntity>>(
      () => cqrs.bus.query<GetAccountsQuery, List<AccountEntity>>(
        GetAccountsQuery(userId: profile.userId),
      ),
      fallback: const <AccountEntity>[],
      label: 'accounts',
    );
    final categories = await _loadSection<List<CategoryEntity>>(
      () => cqrs.bus.query<GetCategoriesQuery, List<CategoryEntity>>(
        GetCategoriesQuery(userId: profile.userId),
      ),
      fallback: const <CategoryEntity>[],
      label: 'categories',
    );
    final recentTransactions = await _loadSection<List<TransactionEntity>>(
      () => cqrs.bus.query<GetTransactionsQuery, List<TransactionEntity>>(
        GetTransactionsQuery(userId: profile.userId, limit: 5),
      ),
      fallback: const <TransactionEntity>[],
      label: 'recent transactions',
    );
    final monthTransactions = await _loadSection<List<TransactionEntity>>(
      () => cqrs.bus.query<GetTransactionsQuery, List<TransactionEntity>>(
        GetTransactionsQuery(
          userId: profile.userId,
          start: monthStart,
          end: nextMonthStart.subtract(const Duration(milliseconds: 1)),
        ),
      ),
      fallback: const <TransactionEntity>[],
      label: 'monthly transactions',
    );
    final previousMonthTransactions =
        await _loadSection<List<TransactionEntity>>(
      () => cqrs.bus.query<GetTransactionsQuery, List<TransactionEntity>>(
        GetTransactionsQuery(
          userId: profile.userId,
          start: previousMonthStart,
          end: monthStart.subtract(const Duration(milliseconds: 1)),
        ),
      ),
      fallback: const <TransactionEntity>[],
      label: 'previous month transactions',
    );
    final failedSections = <String>[
      if (accounts.failed) accounts.label,
      if (categories.failed) categories.label,
      if (recentTransactions.failed) recentTransactions.label,
      if (monthTransactions.failed) monthTransactions.label,
      if (previousMonthTransactions.failed) previousMonthTransactions.label,
    ];

    final categoryById = <String, CategoryEntity>{
      for (final category in categories.value) category.categoryId: category,
    };
    final currency = _firstCurrency(accounts.value);
    final activeBalance = _sumAccountBalances(accounts.value);
    final inflow = _sumTransactions(monthTransactions.value, 'income');
    final outflow = _sumTransactions(monthTransactions.value, 'expense');
    final previousInflow =
        _sumTransactions(previousMonthTransactions.value, 'income');
    final previousOutflow =
        _sumTransactions(previousMonthTransactions.value, 'expense');

    return _HomeData(
      displayName: user?.displayName ?? profile.displayName,
      activeBalanceLabel: _formatMoney(activeBalance, currency),
      accountBalances: accounts.value
          .map(_accountBalanceView)
          .whereType<_AccountBalanceViewData>()
          .toList(),
      inflowLabel: _formatMoney(inflow, currency),
      outflowLabel: _formatMoney(outflow, currency),
      inflowChangeLabel: _formatChange(inflow, previousInflow),
      outflowChangeLabel: _formatChange(outflow, previousOutflow),
      loadWarning: failedSections.isEmpty
          ? null
          : 'Some local data could not be loaded: ${failedSections.join(', ')}.',
      transactions: recentTransactions.value
          .map((transaction) => _safeTransactionView(transaction, categoryById))
          .whereType<_TransactionViewData>()
          .toList(),
    );
  }

  Future<_SectionLoad<T>> _loadSection<T>(
    Future<T> Function() loader, {
    required T fallback,
    required String label,
  }) async {
    try {
      return _SectionLoad(value: await loader(), label: label);
    } catch (_) {
      return _SectionLoad(value: fallback, label: label, failed: true);
    }
  }

  String _firstCurrency(List<AccountEntity> accounts) {
    for (final account in accounts) {
      try {
        return account.currency;
      } catch (_) {
        continue;
      }
    }
    return 'BDT';
  }

  double _sumAccountBalances(List<AccountEntity> accounts) {
    var total = 0.0;
    for (final account in accounts) {
      try {
        total += account.currentBalance;
      } catch (_) {
        continue;
      }
    }
    return total;
  }

  _AccountBalanceViewData? _accountBalanceView(AccountEntity account) {
    try {
      return _AccountBalanceViewData(
        name: account.name,
        balanceLabel: _formatMoney(account.currentBalance, account.currency),
      );
    } catch (_) {
      return null;
    }
  }

  double _sumTransactions(List<TransactionEntity> transactions, String type) {
    var total = 0.0;
    for (final transaction in transactions) {
      try {
        if (transaction.type == type) {
          total += transaction.amount;
        }
      } catch (_) {
        continue;
      }
    }
    return total;
  }

  _TransactionViewData? _safeTransactionView(
    TransactionEntity transaction,
    Map<String, CategoryEntity> categoryById,
  ) {
    try {
      return _transactionView(transaction, categoryById);
    } catch (_) {
      return null;
    }
  }

  _TransactionViewData _transactionView(
    TransactionEntity transaction,
    Map<String, CategoryEntity> categoryById,
  ) {
    final category = categoryById[transaction.categoryId];
    final isPositive = transaction.type == 'income';
    final signedAmount = isPositive ? transaction.amount : -transaction.amount;
    final categoryName = category?.name ?? transaction.type;
    return _TransactionViewData(
      transaction: transaction,
      description: _transactionDescription(transaction, categoryName),
      date: transaction.date,
      amountLabel: _formatSignedMoney(signedAmount, transaction.currency),
      categoryName: categoryName,
      categoryIcon: _categoryIcon(category?.icon),
      categoryColor: _categoryColor(category, isPositive),
      isPositive: isPositive,
    );
  }

  String _transactionDescription(
    TransactionEntity transaction,
    String categoryName,
  ) {
    final note = transaction.note?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }
    return categoryName;
  }

  String _formatMoney(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  String _formatSignedMoney(double amount, String currency) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign${_transactionCurrencyLabel(currency)} ${amount.abs().toStringAsFixed(2)}';
  }

  String _transactionCurrencyLabel(String currency) {
    return currency == 'BDT' ? 'Tk.' : currency;
  }

  String _formatChange(double current, double previous) {
    if (previous == 0) {
      return current == 0 ? '0.0%' : '+100.0%';
    }
    final change = ((current - previous) / previous.abs()) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  IconData _categoryIcon(String? iconName) {
    return CategoryIcons.iconForName(iconName);
  }

  Color _categoryColor(CategoryEntity? category, bool isPositive) {
    if (category?.color != null) {
      return Color(category!.color!);
    }
    return isPositive ? AppColors.incomePositive : AppColors.expenseNegative;
  }

  void _reloadHomeData() {
    setState(() {
      _homeDataFuture = _loadHomeData();
    });
  }

  void _openTransactionHistory([String? type]) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: RouteSettings(arguments: type),
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const TransactionHistoryScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.08, 0.02),
            end: Offset.zero,
          ).animate(curvedAnimation);
          final scaleAnimation = Tween<double>(
            begin: 0.985,
            end: 1,
          ).animate(curvedAnimation);

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openTransactionEditor(TransactionEntity transaction) async {
    final updated = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return AddTransactionScreen(initialTransaction: transaction);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.06, 0.04),
            end: Offset.zero,
          ).animate(curvedAnimation);

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
      ),
    );
    if (updated == true && mounted) {
      _reloadHomeData();
    }
  }

  Widget _buildHeader(String displayName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryViolet.withOpacity(0.75),
                  width: 2,
                ),
                color: Colors.transparent,
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child:
                    Icon(Icons.person, color: AppColors.textPrimary, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  displayName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.notifications_none,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  Widget _buildActiveBalanceCard(
    String activeBalanceLabel,
    List<_AccountBalanceViewData> accountBalances,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.25),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/card-bg-ortho.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.77),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A145A).withOpacity(0.42),
                      const Color(0xFF3B1B7A).withOpacity(0.42),
                      const Color(0xFF20113F).withOpacity(0.40),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildActiveBalanceCardContent(
                activeBalanceLabel,
                accountBalances,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBalanceCardContent(
    String activeBalanceLabel,
    List<_AccountBalanceViewData> accountBalances,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Active Balance',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isBalanceVisible = !_isBalanceVisible;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Icon(
                            _isBalanceVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isBalanceVisible ? activeBalanceLabel : '********',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isAccountBalancesExpanded = !_isAccountBalancesExpanded;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: const AlignmentDirectional(-2, 1),
                    end: const AlignmentDirectional(1, -1),
                    colors: [
                      AppColors.primaryViolet.withValues(alpha: 1),
                      AppColors.accentCoral.withValues(alpha: 1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCoral.withOpacity(0.24),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  _isAccountBalancesExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.wallet,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topRight,
          child: _isAccountBalancesExpanded
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _buildAccountBalancesPanel(accountBalances),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildAccountBalancesPanel(
    List<_AccountBalanceViewData> accountBalances,
  ) {
    final visibleBalances = _isBalanceVisible
        ? accountBalances
        : accountBalances
            .map(
              (account) => _AccountBalanceViewData(
                name: account.name,
                balanceLabel: '****',
              ),
            )
            .toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.085),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.primaryViolet.withOpacity(0.24),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Accounts',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${visibleBalances.length}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (visibleBalances.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No accounts yet',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              for (final account in visibleBalances) ...[
                _buildAccountBalanceRow(account),
                if (account != visibleBalances.last) const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBalanceRow(_AccountBalanceViewData account) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withOpacity(0.10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.incomePositive,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              account.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            account.balanceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
    required String change,
    required Color changeColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.055),
            border: Border.all(
              color: AppColors.primaryPurple.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withOpacity(0.2),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: changeColor.withOpacity(0.15),
                    ),
                    child: Text(
                      change,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transaction History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: _openTransactionHistory,
          child: Text(
            'View all',
            style: TextStyle(
              color: AppColors.accentCoral,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.055),
      ),
      child: const Text(
        'No transactions yet.',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildTransactionItem({
    required TransactionEntity? transaction,
    required String description,
    required String time,
    required String date,
    required String amount,
    required String category,
    required IconData categoryIcon,
    required Color categoryColor,
    bool isPositive = false,
  }) {
    final amountColor =
        isPositive ? AppColors.incomePositive : AppColors.expenseNegative;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: transaction == null
            ? null
            : () => _openTransactionEditor(transaction),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.055),
          ),
          height: 74,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: categoryColor.withOpacity(0.18),
                ),
                child: Center(
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$time | $date',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.displayName,
    required this.activeBalanceLabel,
    required this.accountBalances,
    required this.inflowLabel,
    required this.outflowLabel,
    required this.inflowChangeLabel,
    required this.outflowChangeLabel,
    required this.loadWarning,
    required this.transactions,
  });

  final String displayName;
  final String activeBalanceLabel;
  final List<_AccountBalanceViewData> accountBalances;
  final String inflowLabel;
  final String outflowLabel;
  final String inflowChangeLabel;
  final String outflowChangeLabel;
  final String? loadWarning;
  final List<_TransactionViewData> transactions;
}

class _AccountBalanceViewData {
  const _AccountBalanceViewData({
    required this.name,
    required this.balanceLabel,
  });

  final String name;
  final String balanceLabel;
}

class _SectionLoad<T> {
  const _SectionLoad({
    required this.value,
    required this.label,
    this.failed = false,
  });

  final T value;
  final String label;
  final bool failed;
}

class _TransactionViewData {
  const _TransactionViewData({
    required this.transaction,
    required this.description,
    required this.date,
    required this.amountLabel,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.isPositive,
  });

  final TransactionEntity? transaction;
  final String description;
  final DateTime date;
  final String amountLabel;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final bool isPositive;
}
