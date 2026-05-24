import 'package:flutter/material.dart';

import '../cqrs/commands.dart';
import '../cqrs/queries.dart';
import '../cqrs/utils.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const String localUserId = 'local-user';

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _accountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');

  String _type = 'expense';
  DateTime _date = DateTime.now();
  bool _saving = false;
  late Future<CqrsService> _cqrsFuture;

  @override
  void initState() {
    super.initState();
    _cqrsFuture = CqrsService.create();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _accountController.dispose();
    _categoryController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050711),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050711),
        elevation: 0,
        title: const Text('Add Transaction'),
      ),
      body: FutureBuilder<CqrsService>(
        future: _cqrsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildForm(context, snapshot.data!);
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
          ],
        ),
        const SizedBox(height: 20),
        _buildField(
          controller: _amountController,
          label: 'Amount',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _currencyController,
          label: 'Currency',
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _accountController,
          label: 'Account name',
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _categoryController,
          label: 'Category name',
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _noteController,
          label: 'Note (optional)',
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Date',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _date.toIso8601String().split('T').first,
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.calendar_today, color: Colors.white70),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _date = picked;
              });
            }
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(cqrs),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7c3aed),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
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
        });
      },
      selectedColor: const Color(0xFF7c3aed),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
      ),
      backgroundColor: Colors.white12,
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
          borderSide: const BorderSide(color: Color(0xFF7c3aed)),
        ),
      ),
    );
  }

  Future<void> _save(CqrsService cqrs) async {
    final amount = double.tryParse(_amountController.text.trim());
    final accountName = _accountController.text.trim();
    final categoryName = _categoryController.text.trim();
    final currency = _currencyController.text.trim();

    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount.');
      return;
    }
    if (accountName.isEmpty || categoryName.isEmpty) {
      _showError('Account and category are required.');
      return;
    }
    if (currency.isEmpty) {
      _showError('Currency is required.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await cqrs.bus.execute(
        CreateUserCommand(
          userId: localUserId,
          email: 'local@device',
          displayName: 'Local User',
          now: DateTime.now(),
        ),
      );

      final accounts = await cqrs.bus.query(
        GetAccountsQuery(userId: localUserId),
      );
      final categories = await cqrs.bus.query(
        GetCategoriesQuery(userId: localUserId, type: _type),
      );

      final account = _findAccount(accounts, accountName) ??
          await _createAccount(cqrs, accountName, currency);
      final category = _findCategory(categories, categoryName) ??
          await _createCategory(cqrs, categoryName, _type);

      await cqrs.bus.execute(
        CreateTransactionCommand(
          userId: localUserId,
          accountId: account.accountId,
          categoryId: category.categoryId,
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
        Navigator.of(context).pop();
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

  AccountEntity? _findAccount(List<AccountEntity> accounts, String name) {
    for (final account in accounts) {
      if (account.name.toLowerCase() == name.toLowerCase()) {
        return account;
      }
    }
    return null;
  }

  CategoryEntity? _findCategory(List<CategoryEntity> categories, String name) {
    for (final category in categories) {
      if (category.name.toLowerCase() == name.toLowerCase()) {
        return category;
      }
    }
    return null;
  }

  Future<AccountEntity> _createAccount(
    CqrsService cqrs,
    String name,
    String currency,
  ) async {
    final accountId = generateId();
    await cqrs.bus.execute(
      CreateAccountCommand(
        userId: localUserId,
        name: name,
        type: 'cash',
        currency: currency,
        openingBalance: 0,
        accountId: accountId,
        now: DateTime.now(),
      ),
    );

    final accounts = await cqrs.bus.query(
      GetAccountsQuery(userId: localUserId),
    );
    return accounts.firstWhere(
      (account) => account.accountId == accountId,
    );
  }

  Future<CategoryEntity> _createCategory(
    CqrsService cqrs,
    String name,
    String type,
  ) async {
    final categoryId = generateId();
    await cqrs.bus.execute(
      CreateCategoryCommand(
        userId: localUserId,
        name: name,
        type: type,
        categoryId: categoryId,
      ),
    );

    final categories = await cqrs.bus.query(
      GetCategoriesQuery(userId: localUserId, type: type),
    );
    return categories.firstWhere(
      (category) => category.categoryId == categoryId,
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
