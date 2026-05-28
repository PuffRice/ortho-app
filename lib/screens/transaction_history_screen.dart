import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/category_icons.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';
import '../services/user_identity.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _searchController = TextEditingController();

  Future<_TransactionHistoryData>? _historyFuture;
  String _query = '';
  String? _type;
  String? _accountId;
  String? _categoryId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Transactions'),
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
                      AppColors.primaryViolet.withOpacity(0.35),
                      AppColors.primaryDeep.withOpacity(0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          FutureBuilder<_TransactionHistoryData>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _buildLoadError(snapshot.error);
              }
              return _buildContent(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_TransactionHistoryData data) {
    final filteredTransactions = _filteredTransactions(data);
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _buildSearchField(),
          const SizedBox(height: 14),
          _buildFilters(data),
          const SizedBox(height: 18),
          _buildResultSummary(filteredTransactions.length),
          const SizedBox(height: 12),
          if (filteredTransactions.isEmpty)
            _buildEmptyState()
          else
            for (final transaction in filteredTransactions) ...[
              _buildTransactionTile(transaction, data),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search transactions',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                  });
                },
                icon: const Icon(Icons.close, color: AppColors.textMuted),
              ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryViolet),
        ),
      ),
    );
  }

  Widget _buildFilters(_TransactionHistoryData data) {
    final categories = _type == null
        ? data.categories
        : data.categories.where((category) => category.type == _type).toList();
    final selectedCategoryId = categories.any(
      (category) => category.categoryId == _categoryId,
    )
        ? _categoryId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildTypeFilter(),
            _buildAccountFilter(data.accounts),
            _buildCategoryFilter(categories, selectedCategoryId),
            _buildDateRangeFilter(),
            _buildResetButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String?>(
        initialValue: _type,
        items: const [
          DropdownMenuItem(value: null, child: Text('All types')),
          DropdownMenuItem(value: 'income', child: Text('Income')),
          DropdownMenuItem(value: 'expense', child: Text('Expense')),
        ],
        onChanged: (value) {
          setState(() {
            _type = value;
            _categoryId = null;
          });
        },
        decoration: _filterDecoration('Type'),
        dropdownColor: AppColors.bgCard,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
    );
  }

  Widget _buildAccountFilter(List<AccountEntity> accounts) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String?>(
        initialValue: _accountId,
        items: [
          const DropdownMenuItem(value: null, child: Text('All accounts')),
          ...accounts.map(
            (account) => DropdownMenuItem(
              value: account.accountId,
              child: Text(account.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _accountId = value;
          });
        },
        decoration: _filterDecoration('Account'),
        dropdownColor: AppColors.bgCard,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
    );
  }

  Widget _buildCategoryFilter(
    List<CategoryEntity> categories,
    String? selectedCategoryId,
  ) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String?>(
        initialValue: selectedCategoryId,
        items: [
          const DropdownMenuItem(value: null, child: Text('All categories')),
          ...categories.map(
            (category) => DropdownMenuItem(
              value: category.categoryId,
              child: Text(category.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _categoryId = value;
          });
        },
        decoration: _filterDecoration('Category'),
        dropdownColor: AppColors.bgCard,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    final label = _dateRange == null
        ? 'Any date'
        : '${_formatShortDate(_dateRange!.start)} - ${_formatShortDate(_dateRange!.end)}';
    return InkWell(
      onTap: _pickDateRange,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        constraints: const BoxConstraints(minWidth: 178),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.date_range,
              color: AppColors.textMuted,
              size: 19,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      height: 56,
      child: TextButton.icon(
        onPressed: _hasActiveFilters ? _resetFilters : null,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Reset'),
        style: TextButton.styleFrom(
          foregroundColor:
              _hasActiveFilters ? AppColors.accentCoral : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildResultSummary(int count) {
    return Text(
      '$count ${count == 1 ? 'transaction' : 'transactions'}',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTransactionTile(
    TransactionEntity transaction,
    _TransactionHistoryData data,
  ) {
    final category = data.categoryById[transaction.categoryId];
    final account = data.accountById[transaction.accountId];
    final isPositive = transaction.type == 'income';
    final color = category?.color != null
        ? Color(category!.color!)
        : isPositive
            ? AppColors.incomePositive
            : AppColors.expenseNegative;
    final note = transaction.note?.trim();
    final title = note == null || note.isEmpty
        ? category?.name ?? transaction.type
        : note;
    final amount = _formatSignedMoney(
      isPositive ? transaction.amount : -transaction.amount,
      transaction.currency,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CategoryIcons.iconForName(category?.icon),
              color: color,
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
                  '${category?.name ?? transaction.type} | ${account?.name ?? 'Account'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(transaction.date),
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
            amount,
            style: TextStyle(
              color: isPositive
                  ? AppColors.incomePositive
                  : AppColors.expenseNegative,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'No transactions match these filters.',
        style: TextStyle(color: AppColors.textMuted),
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
              'Unable to load transactions.',
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

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryViolet),
      ),
    );
  }

  Future<_TransactionHistoryData> _loadHistory() async {
    final profile = await UserIdentityService.instance.getProfile();
    final cqrs = await CqrsService.create();
    final transactions =
        await cqrs.bus.query<GetTransactionsQuery, List<TransactionEntity>>(
      GetTransactionsQuery(userId: profile.userId, limit: 1000),
    );
    final accounts =
        await cqrs.bus.query<GetAccountsQuery, List<AccountEntity>>(
      GetAccountsQuery(userId: profile.userId),
    );
    final categories =
        await cqrs.bus.query<GetCategoriesQuery, List<CategoryEntity>>(
      GetCategoriesQuery(userId: profile.userId),
    );

    return _TransactionHistoryData(
      transactions: transactions,
      accounts: accounts,
      categories: categories,
    );
  }

  List<TransactionEntity> _filteredTransactions(_TransactionHistoryData data) {
    final normalizedQuery = _query.trim().toLowerCase();
    final rangeStart = _dateRange?.start;
    final rangeEnd = _dateRange == null
        ? null
        : DateTime(
            _dateRange!.end.year,
            _dateRange!.end.month,
            _dateRange!.end.day,
            23,
            59,
            59,
            999,
          );

    return data.transactions.where((transaction) {
      if (_type != null && transaction.type != _type) {
        return false;
      }
      if (_accountId != null && transaction.accountId != _accountId) {
        return false;
      }
      if (_categoryId != null && transaction.categoryId != _categoryId) {
        return false;
      }
      if (rangeStart != null && transaction.date.isBefore(rangeStart)) {
        return false;
      }
      if (rangeEnd != null && transaction.date.isAfter(rangeEnd)) {
        return false;
      }
      if (normalizedQuery.isEmpty) {
        return true;
      }

      final category = data.categoryById[transaction.categoryId];
      final account = data.accountById[transaction.accountId];
      final searchable = [
        transaction.note,
        transaction.type,
        transaction.currency,
        transaction.amount.toStringAsFixed(2),
        category?.name,
        account?.name,
      ].whereType<String>().join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryViolet,
              onPrimary: Colors.white,
              surface: AppColors.bgSecondary,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.bgSecondary,
          ),
          child: child!,
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dateRange = picked;
    });
  }

  Future<void> _reload() async {
    final next = _loadHistory();
    setState(() {
      _historyFuture = next;
    });
    await next;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _type = null;
      _accountId = null;
      _categoryId = null;
      _dateRange = null;
    });
  }

  bool get _hasActiveFilters {
    return _query.trim().isNotEmpty ||
        _type != null ||
        _accountId != null ||
        _categoryId != null ||
        _dateRange != null;
  }

  String _formatSignedMoney(double amount, String currency) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign$currency ${amount.abs().toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(dateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );
    return '$time | $date';
  }

  String _formatShortDate(DateTime dateTime) {
    return MaterialLocalizations.of(context).formatShortDate(dateTime);
  }
}

class _TransactionHistoryData {
  const _TransactionHistoryData({
    required this.transactions,
    required this.accounts,
    required this.categories,
  });

  final List<TransactionEntity> transactions;
  final List<AccountEntity> accounts;
  final List<CategoryEntity> categories;

  Map<String, AccountEntity> get accountById {
    return {for (final account in accounts) account.accountId: account};
  }

  Map<String, CategoryEntity> get categoryById {
    return {for (final category in categories) category.categoryId: category};
  }
}
