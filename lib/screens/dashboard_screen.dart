import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/category_icons.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';
import '../services/user_identity.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedType = 'expense';
  String? _selectedCategoryId;
  Future<_DashboardData>? _dashboardFuture;

  Future<_DashboardData> get _dashboardData {
    return _dashboardFuture ??= _loadDashboardData();
  }

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
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
                      AppColors.primaryDeep.withOpacity(0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<_DashboardData>(
              future: _dashboardData,
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
              'Unable to load dashboard.',
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

  Widget _buildContent(_DashboardData data) {
    final typeData = data.forType(_selectedType, _selectedCategoryId);
    final typeColor = _selectedType == 'income'
        ? AppColors.incomePositive
        : AppColors.expenseNegative;

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildTypeToggle(),
          const SizedBox(height: 20),
          _buildSummaryStrip(typeData, typeColor),
          const SizedBox(height: 22),
          _buildMonthlySection(data, typeData, typeColor),
          const SizedBox(height: 22),
          _buildTopCategories(typeData, typeColor),
          if (_selectedType == 'expense') ...[
            const SizedBox(height: 22),
            _buildBudgetSection(data),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Monthly movement, categories, and budgets',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTypeButton('expense', 'Expense')),
          Expanded(child: _buildTypeButton('income', 'Income')),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label) {
    final selected = _selectedType == type;
    final color =
        type == 'income' ? AppColors.incomePositive : AppColors.expenseNegative;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategoryId = null;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.92),
                    AppColors.primaryViolet.withOpacity(0.84),
                  ],
                )
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(_TypeDashboardData data, Color typeColor) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Total ${_selectedType == 'income' ? 'income' : 'expense'}',
            value: _formatMoney(data.total, data.currency),
            icon: _selectedType == 'income'
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: typeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            label: 'This month',
            value: _formatMoney(data.thisMonthTotal, data.currency),
            icon: Icons.calendar_month_rounded,
            color: AppColors.primaryViolet,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySection(
    _DashboardData dashboard,
    _TypeDashboardData typeData,
    Color typeColor,
  ) {
    final categories = dashboard.categoriesForType(_selectedType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Monthly history',
          _selectedCategoryId == null
              ? 'All categories'
              : dashboard.categoryName(_selectedCategoryId),
        ),
        const SizedBox(height: 12),
        _buildCategoryFilters(categories),
        const SizedBox(height: 14),
        Container(
          height: 260,
          padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
          decoration: _surfaceDecoration(radius: 22),
          child: typeData.months.every((month) => month.total == 0)
              ? _buildEmptyState(
                  'No ${_selectedType} history yet.',
                  key: ValueKey(_monthlyChartKey),
                )
              : BarChart(
                  _barChartData(typeData.months, typeColor),
                  key: ValueKey(_monthlyChartKey),
                ),
        ),
      ],
    );
  }

  String get _monthlyChartKey {
    return '$_selectedType:${_selectedCategoryId ?? 'all'}';
  }

  Widget _buildCategoryFilters(List<CategoryEntity> categories) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(null, 'All'),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _buildCategoryChip(category.categoryId, category.name),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? categoryId, String label) {
    final selected = _selectedCategoryId == categoryId;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategoryId = categoryId;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryViolet.withOpacity(0.28)
              : Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primaryViolet.withOpacity(0.72)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  BarChartData _barChartData(List<_MonthPoint> months, Color color) {
    final maxTotal = months.fold<double>(
      0,
      (maxValue, month) => math.max(maxValue, month.total),
    );
    final maxY = maxTotal <= 0 ? 1.0 : maxTotal * 1.22;

    return BarChartData(
      maxY: maxY,
      minY: 0,
      alignment: BarChartAlignment.spaceBetween,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withOpacity(0.06),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= months.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  months[index].label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: AppColors.bgSecondary,
          tooltipRoundedRadius: 12,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              _formatMoney(
                  months[groupIndex].total, months[groupIndex].currency),
              const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
      ),
      barGroups: [
        for (var index = 0; index < months.length; index++)
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: months[index].total,
                width: 15,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    color.withOpacity(0.54),
                    color,
                    AppColors.primaryViolet.withOpacity(0.92),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTopCategories(_TypeDashboardData typeData, Color typeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Top 5 categories',
          'Share of total ${_selectedType == 'income' ? 'income' : 'expense'}',
        ),
        const SizedBox(height: 12),
        if (typeData.topCategories.isEmpty)
          _buildFramedEmptyState('No category totals yet.')
        else
          for (final category in typeData.topCategories) ...[
            _buildCategoryRankRow(category, typeColor),
            if (category != typeData.topCategories.last)
              const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildCategoryRankRow(_CategoryTotal category, Color fallbackColor) {
    final color = category.color ?? fallbackColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category.icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: category.percent.clamp(0, 1),
                    color: color,
                    backgroundColor: Colors.white.withOpacity(0.08),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(category.amount, category.currency),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(category.percent * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(_DashboardData data) {
    final budgets = data.activeBudgetStatuses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Budgets', 'Active expense limits'),
        const SizedBox(height: 12),
        if (budgets.isEmpty)
          _buildFramedEmptyState('No active budgets yet.')
        else
          for (final budget in budgets) ...[
            _buildBudgetRow(budget),
            if (budget != budgets.last) const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildBudgetRow(_BudgetStatus budget) {
    final progress = budget.progress.clamp(0, 1).toDouble();
    final color = budget.progress >= 1
        ? AppColors.expenseNegative
        : budget.progress >= 0.75
            ? AppColors.accentOrange
            : AppColors.incomePositive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(budget.icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget.statusLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(budget.progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              color: color,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatMoney(budget.spent, budget.currency)} spent',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_formatMoney(budget.amount, budget.currency)} limit',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, {Key? key}) {
    return Center(
      key: key,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFramedEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(radius: 18),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _surfaceDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryDeep.withOpacity(0.10),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  Future<_DashboardData> _loadDashboardData() async {
    final profile = await UserIdentityService.instance.getProfile();
    final cqrs = await CqrsService.create();
    final transactions =
        await cqrs.bus.query<GetTransactionsQuery, List<TransactionEntity>>(
      GetTransactionsQuery(userId: profile.userId, limit: 5000),
    );
    final categories =
        await cqrs.bus.query<GetCategoriesQuery, List<CategoryEntity>>(
      GetCategoriesQuery(userId: profile.userId),
    );
    final budgets = await cqrs.bus.query<GetBudgetsQuery, List<BudgetEntity>>(
      GetBudgetsQuery(userId: profile.userId),
    );
    return _DashboardData(
      transactions: transactions,
      categories: categories,
      budgets: budgets,
    );
  }

  Future<void> _reload() async {
    final next = _loadDashboardData();
    setState(() {
      _dashboardFuture = next;
    });
    await next;
  }

  String _formatMoney(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}

class _DashboardData {
  const _DashboardData({
    required this.transactions,
    required this.categories,
    required this.budgets,
  });

  final List<TransactionEntity> transactions;
  final List<CategoryEntity> categories;
  final List<BudgetEntity> budgets;

  _TypeDashboardData forType(String type, String? categoryId) {
    final categoryById = _categoryById;
    final filtered = transactions.where((transaction) {
      if (transaction.type != type) {
        return false;
      }
      if (categoryId != null && transaction.categoryId != categoryId) {
        return false;
      }
      return true;
    }).toList();
    final allTypeTransactions =
        transactions.where((transaction) => transaction.type == type).toList();
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    final currency = _firstCurrency(filtered.isEmpty ? transactions : filtered);
    final total = _sum(filtered);
    final thisMonthTotal = _sum(
      filtered.where((transaction) {
        return !transaction.date.isBefore(thisMonthStart) &&
            transaction.date.isBefore(nextMonthStart);
      }),
    );

    return _TypeDashboardData(
      currency: currency,
      total: total,
      thisMonthTotal: thisMonthTotal,
      months: _monthlyPoints(type, categoryId, currency),
      topCategories: _topCategories(allTypeTransactions, categoryById, type),
    );
  }

  List<CategoryEntity> categoriesForType(String type) {
    return categories.where((category) => category.type == type).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  String categoryName(String? categoryId) {
    if (categoryId == null) {
      return 'All categories';
    }
    return _categoryById[categoryId]?.name ?? 'Category';
  }

  List<_BudgetStatus> get activeBudgetStatuses {
    final now = DateTime.now();
    final categoryById = _categoryById;
    final statuses = <_BudgetStatus>[];
    for (final budget in budgets) {
      if (budget.startDate.isAfter(now)) {
        continue;
      }
      if (budget.endDate != null && budget.endDate!.isBefore(now)) {
        continue;
      }
      final window = _budgetWindow(budget, now);
      final spent = _sum(transactions.where((transaction) {
        if (transaction.type != 'expense') {
          return false;
        }
        if (budget.categoryId != null &&
            transaction.categoryId != budget.categoryId) {
          return false;
        }
        return !transaction.date.isBefore(window.start) &&
            !transaction.date.isAfter(window.end);
      }));
      final category = categoryById[budget.categoryId];
      final progress = budget.amount <= 0 ? 0.0 : spent / budget.amount;
      statuses.add(
        _BudgetStatus(
          name: category?.name ?? 'Overall expense',
          icon: CategoryIcons.iconForName(category?.icon),
          amount: budget.amount,
          spent: spent,
          progress: progress,
          currency: _firstCurrency(transactions),
          statusLabel: _budgetStatusLabel(progress),
        ),
      );
    }
    statuses.sort((a, b) => b.progress.compareTo(a.progress));
    return statuses;
  }

  List<_MonthPoint> _monthlyPoints(
    String type,
    String? categoryId,
    String currency,
  ) {
    final now = DateTime.now();
    final months = <_MonthPoint>[];
    for (var index = 5; index >= 0; index--) {
      final start = DateTime(now.year, now.month - index);
      final end = DateTime(start.year, start.month + 1);
      final total = _sum(transactions.where((transaction) {
        if (transaction.type != type) {
          return false;
        }
        if (categoryId != null && transaction.categoryId != categoryId) {
          return false;
        }
        return !transaction.date.isBefore(start) &&
            transaction.date.isBefore(end);
      }));
      months.add(
        _MonthPoint(
          label: _monthLabel(start.month),
          total: total,
          currency: currency,
        ),
      );
    }
    return months;
  }

  List<_CategoryTotal> _topCategories(
    List<TransactionEntity> typeTransactions,
    Map<String?, CategoryEntity> categoryById,
    String type,
  ) {
    final totals = <String, double>{};
    for (final transaction in typeTransactions) {
      totals[transaction.categoryId] =
          (totals[transaction.categoryId] ?? 0) + transaction.amount;
    }
    final total = _sum(typeTransactions);
    final currency = _firstCurrency(typeTransactions);
    final rows = <_CategoryTotal>[];
    for (final entry in totals.entries) {
      final category = categoryById[entry.key];
      rows.add(
        _CategoryTotal(
          name: category?.name ?? type,
          amount: entry.value,
          percent: total <= 0 ? 0 : entry.value / total,
          currency: currency,
          icon: CategoryIcons.iconForName(category?.icon),
          color: category?.color == null ? null : Color(category!.color!),
        ),
      );
    }
    rows.sort((a, b) => b.amount.compareTo(a.amount));
    return rows.take(5).toList();
  }

  Map<String?, CategoryEntity> get _categoryById {
    return {for (final category in categories) category.categoryId: category};
  }

  static double _sum(Iterable<TransactionEntity> items) {
    var total = 0.0;
    for (final item in items) {
      total += item.amount;
    }
    return total;
  }

  static String _firstCurrency(List<TransactionEntity> transactions) {
    for (final transaction in transactions) {
      return transaction.currency;
    }
    return 'BDT';
  }

  static _DateWindow _budgetWindow(BudgetEntity budget, DateTime now) {
    var start = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
    );
    DateTime next;
    while (true) {
      next = _addPeriod(start, budget.period);
      if (next.isAfter(now)) {
        break;
      }
      start = next;
    }
    var end = next.subtract(const Duration(milliseconds: 1));
    if (budget.endDate != null && budget.endDate!.isBefore(end)) {
      end = budget.endDate!;
    }
    return _DateWindow(start: start, end: end);
  }

  static DateTime _addPeriod(DateTime start, String period) {
    if (period == 'weekly') {
      return start.add(const Duration(days: 7));
    }
    if (period == 'yearly') {
      return DateTime(start.year + 1, start.month, start.day);
    }
    return DateTime(start.year, start.month + 1, start.day);
  }

  static String _budgetStatusLabel(double progress) {
    if (progress >= 1) {
      return 'Over budget';
    }
    if (progress >= 0.75) {
      return 'Watch closely';
    }
    return 'On track';
  }

  static String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }
}

class _TypeDashboardData {
  const _TypeDashboardData({
    required this.currency,
    required this.total,
    required this.thisMonthTotal,
    required this.months,
    required this.topCategories,
  });

  final String currency;
  final double total;
  final double thisMonthTotal;
  final List<_MonthPoint> months;
  final List<_CategoryTotal> topCategories;
}

class _MonthPoint {
  const _MonthPoint({
    required this.label,
    required this.total,
    required this.currency,
  });

  final String label;
  final double total;
  final String currency;
}

class _CategoryTotal {
  const _CategoryTotal({
    required this.name,
    required this.amount,
    required this.percent,
    required this.currency,
    required this.icon,
    required this.color,
  });

  final String name;
  final double amount;
  final double percent;
  final String currency;
  final IconData icon;
  final Color? color;
}

class _BudgetStatus {
  const _BudgetStatus({
    required this.name,
    required this.icon,
    required this.amount,
    required this.spent,
    required this.progress,
    required this.currency,
    required this.statusLabel,
  });

  final String name;
  final IconData icon;
  final double amount;
  final double spent;
  final double progress;
  final String currency;
  final String statusLabel;
}

class _DateWindow {
  const _DateWindow({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}
