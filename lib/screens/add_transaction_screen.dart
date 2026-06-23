import 'package:financetracker/config/app_colors.dart';
import 'package:financetracker/config/category_icons.dart';
import 'package:flutter/material.dart';

import '../cqrs/commands.dart';
import '../cqrs/queries.dart';
import '../models/local_models.dart';
import '../services/cqrs_service.dart';
import '../services/user_identity.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialTransaction,
  });

  final TransactionEntity? initialTransaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;

  String _type = 'expense';
  DateTime _date = DateTime.now();
  bool _saving = false;
  Future<CqrsService>? _cqrsFuture;
  Future<UserIdentityProfile>? _profileFuture;
  UserIdentityProfile? _profile;

  Future<CqrsService> get _cqrs {
    return _cqrsFuture ??= CqrsService.create();
  }

  Future<UserIdentityProfile> get _profileLoad {
    return _profileFuture ??=
        UserIdentityService.instance.getProfile().then((profile) {
      _profile = profile;
      return profile;
    });
  }

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initialTransaction = widget.initialTransaction;
    if (initialTransaction != null) {
      _type = initialTransaction.type;
      _date = initialTransaction.date;
      _selectedAccountId = initialTransaction.accountId;
      _selectedCategoryId = initialTransaction.categoryId;
      _amountController.text = initialTransaction.amount.toStringAsFixed(2);
      _noteController.text = initialTransaction.note ?? '';
    }
    _cqrsFuture = CqrsService.create();
    _profileFuture = UserIdentityService.instance.getProfile().then((profile) {
      _profile = profile;
      return profile;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050711),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050711),
        elevation: 0,
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final cqrs = await _cqrs;
                      if (mounted) {
                        await _confirmDelete(cqrs);
                      }
                    },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
        ],
      ),
      body: FutureBuilder<CqrsService>(
        future: _cqrs,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<UserIdentityProfile>(
            future: _profileLoad,
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return _buildForm(context, snapshot.data!);
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, CqrsService cqrs) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            _buildTypeChip('expense', 'Expense'),
            const SizedBox(width: 12),
            _buildTypeChip('income', 'Income'),
            const SizedBox(width: 12),
            _buildTypeChip('transfer', 'Transfer'),
          ],
        ),
        const SizedBox(height: 20),
        if (_type == 'transfer') ...[
          _buildTransferIntro(),
          const SizedBox(height: 20),
        ],
        _buildAmountField(),
        const SizedBox(height: 20),
        _buildAccountPicker(
          cqrs,
          label: _type == 'transfer' ? 'From account' : 'Account',
        ),
        const SizedBox(height: 16),
        if (_type == 'transfer')
          _buildTransferDestinationPicker(cqrs)
        else
          _buildCategoryPicker(cqrs),
        const SizedBox(height: 16),
        _buildField(
          controller: _noteController,
          label: 'Note (optional)',
        ),
        const SizedBox(height: 16),
        _buildDatePicker(context),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(cqrs),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryViolet, AppColors.accentOrange],
                begin: Alignment.bottomLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Update' : 'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _type == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _type = value;
          _selectedCategoryId = null;
          if (value != 'transfer') {
            _selectedToAccountId = null;
          }
        });
      },
      showCheckmark: false,
      selectedColor: AppColors.primaryViolet,
      backgroundColor: const Color(0xFF101323),
      side: BorderSide(
        color: isSelected
            ? AppColors.primaryViolet
            : Colors.white.withOpacity(0.14),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTransferIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryViolet.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryViolet.withOpacity(0.45),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryViolet,
            child: Icon(Icons.swap_horiz_rounded, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move money between accounts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose where the money comes from and where it goes.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryViolet),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'BDT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.only(bottom: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () => _pickTransactionDateTime(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryViolet.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primaryViolet,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date & Time',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(context, _date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTransactionDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
    if (pickedDate == null || !mounted) {
      return;
    }

    final initialTime = TimeOfDay.fromDateTime(_date);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
    if (!mounted) {
      return;
    }

    final selectedTime = pickedTime ?? initialTime;
    setState(() {
      _date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(dateTime);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );
    return '$dateLabel, $timeLabel';
  }

  Widget _buildAccountPicker(CqrsService cqrs, {required String label}) {
    final userId = _profile?.userId;
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<AccountEntity>>(
      future: cqrs.bus.query(GetAccountsQuery(userId: userId)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final accounts = snapshot.data!;
        final selectedAccountId = accounts.any(
          (account) => account.accountId == _selectedAccountId,
        )
            ? _selectedAccountId
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            if (accounts.isEmpty)
              _buildEmptySelectionBox('No accounts yet')
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: accounts
                    .map(
                      (account) => _buildAccountOption(
                        account,
                        selectedAccountId == account.accountId,
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAccountOption(AccountEntity account, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAccountId = account.accountId;
          if (_selectedToAccountId == account.accountId) {
            _selectedToAccountId = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minWidth: 142),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryViolet.withOpacity(0.22)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryViolet
                : Colors.white.withOpacity(0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryViolet : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${account.type} - ${account.currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferDestinationPicker(CqrsService cqrs) {
    final userId = _profile?.userId;
    if (userId == null) return const SizedBox.shrink();
    return FutureBuilder<List<AccountEntity>>(
      future: cqrs.bus.query(GetAccountsQuery(userId: userId)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final accounts = snapshot.data!;
        final destinations = accounts
            .where((account) => account.accountId != _selectedAccountId)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_downward_rounded,
                    color: AppColors.primaryViolet, size: 18),
                const SizedBox(width: 8),
                const Text('To account',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            if (destinations.isEmpty)
              _buildEmptySelectionBox('Add another account to make a transfer')
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: destinations
                    .map(
                      (account) => _buildDestinationAccountOption(
                        account,
                        _selectedToAccountId == account.accountId,
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDestinationAccountOption(AccountEntity account, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedToAccountId = account.accountId),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minWidth: 142),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryViolet.withOpacity(0.22)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryViolet
                : Colors.white.withOpacity(0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryViolet : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${account.type} - ${account.currentBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker(CqrsService cqrs) {
    final userId = _profile?.userId;
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<CategoryEntity>>(
      future: cqrs.bus.query(
        GetCategoriesQuery(userId: userId, type: _type),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!;
        final selectedCategory = _categoryById(
          categories,
          _selectedCategoryId,
        );

        return DropdownButtonFormField<CategoryEntity>(
          initialValue: selectedCategory,
          selectedItemBuilder: (context) {
            return categories
                .map((category) => _buildCategoryOption(category))
                .toList();
          },
          items: categories
              .map(
                (category) => DropdownMenuItem<CategoryEntity>(
                  value: category,
                  child: _buildCategoryOption(category),
                ),
              )
              .toList(),
          onChanged: categories.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedCategoryId = value?.categoryId;
                  });
                },
          decoration: _buildSelectDecoration('Category'),
          iconEnabledColor: Colors.white70,
          dropdownColor: const Color(0xFF0F0F19),
          style: const TextStyle(color: Colors.white),
        );
      },
    );
  }

  Widget _buildCategoryOption(CategoryEntity category) {
    final color = _categoryColor(category);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.22),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _categoryIcon(category.icon),
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            category.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySelectionBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Color _categoryColor(CategoryEntity category) {
    final value = category.color;
    if (value == null) {
      return AppColors.primaryViolet;
    }
    return Color(value);
  }

  IconData _categoryIcon(String? iconName) {
    return CategoryIcons.iconForName(iconName);
  }

  InputDecoration _buildSelectDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryViolet),
      ),
    );
  }

  Future<void> _save(CqrsService cqrs) async {
    final profile = _profile;
    if (profile == null) {
      _showError('User profile not ready yet.');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    final accounts =
        await cqrs.bus.query<GetAccountsQuery, List<AccountEntity>>(
      GetAccountsQuery(userId: profile.userId),
    );
    final categories = _type == 'transfer'
        ? const <CategoryEntity>[]
        : await cqrs.bus.query<GetCategoriesQuery, List<CategoryEntity>>(
            GetCategoriesQuery(userId: profile.userId, type: _type),
          );
    final account = _accountById(accounts, _selectedAccountId);
    final category = _categoryById(categories, _selectedCategoryId);
    final currency = widget.initialTransaction?.currency ?? 'BDT';

    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount.');
      return;
    }
    if (account == null || (_type != 'transfer' && category == null)) {
      _showError('Account and category are required.');
      return;
    }
    final toAccount = _accountById(accounts, _selectedToAccountId);
    if (_type == 'transfer' &&
        (toAccount == null || toAccount.accountId == account.accountId)) {
      _showError('Choose a different destination account.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await cqrs.bus.execute(
        CreateUserCommand(
          userId: profile.userId,
          email: profile.email,
          displayName: profile.displayName,
          now: DateTime.now(),
        ),
      );

      await cqrs.bus.execute(
        _type == 'transfer'
            ? CreateTransferCommand(
                userId: profile.userId,
                fromAccountId: account.accountId,
                toAccountId: toAccount!.accountId,
                amount: amount,
                date: _date,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              )
            : _isEditing
            ? UpdateTransactionCommand(
                userId: profile.userId,
                transactionId: widget.initialTransaction!.transactionId,
                accountId: account.accountId,
                categoryId: category!.categoryId,
                type: _type,
                amount: amount,
                currency: currency,
                date: _date,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
                isRecurring: widget.initialTransaction!.isRecurring,
              )
            : CreateTransactionCommand(
                userId: profile.userId,
                accountId: account.accountId,
                categoryId: category!.categoryId,
                type: _type,
                amount: amount,
                currency: currency,
                date: _date,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      _showError('Failed to save: $error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(CqrsService cqrs) async {
    final profile = _profile;
    final transaction = widget.initialTransaction;
    if (profile == null || transaction == null) {
      _showError('Transaction is not ready yet.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text(
            'Delete transaction?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'This will remove it locally and sync the deletion.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _saving = true;
    });
    try {
      await cqrs.bus.execute(
        DeleteTransactionCommand(
          userId: profile.userId,
          transactionId: transaction.transactionId,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      _showError('Failed to delete: $error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  AccountEntity? _accountById(List<AccountEntity> accounts, String? accountId) {
    if (accountId == null) {
      return null;
    }
    for (final account in accounts) {
      if (account.accountId == accountId) {
        return account;
      }
    }
    return null;
  }

  CategoryEntity? _categoryById(
    List<CategoryEntity> categories,
    String? categoryId,
  ) {
    if (categoryId == null) {
      return null;
    }
    for (final category in categories) {
      if (category.categoryId == categoryId) {
        return category;
      }
    }
    return null;
  }
}
