import 'package:financetracker/config/app_colors.dart';
import 'package:flutter/material.dart';

import '../cqrs/commands.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';
import '../services/user_identity.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  AccountEntity? _selectedAccount;
  CategoryEntity? _selectedCategory;

  String _type = 'expense';
  DateTime _date = DateTime.now();
  bool _saving = false;
  late Future<CqrsService> _cqrsFuture;
  late Future<UserIdentityProfile> _profileFuture;
  UserIdentityProfile? _profile;

  @override
  void initState() {
    super.initState();
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
        title: const Text('Add Transaction'),
      ),
      body: FutureBuilder<CqrsService>(
        future: _cqrsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<UserIdentityProfile>(
            future: _profileFuture,
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
          ],
        ),
        const SizedBox(height: 20),
        _buildAmountField(),
        const SizedBox(height: 20),
        _buildAccountPicker(cqrs),
        const SizedBox(height: 16),
        _buildCategoryPicker(cqrs),
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
                  : const Text('Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                  )
            ),
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
          _selectedCategory = null;
        });
      },
      selectedColor: AppColors.primaryViolet,
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
        TextField(
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
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryViolet, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountPicker(CqrsService cqrs) {
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
        AccountEntity? selectedAccount;
        if (_selectedAccount != null) {
          for (final account in accounts) {
            if (account.accountId == _selectedAccount!.accountId) {
              selectedAccount = account;
              break;
            }
          }
        }

        return DropdownButtonFormField<AccountEntity>(
          value: selectedAccount,
          items: accounts
              .map(
                (account) => DropdownMenuItem<AccountEntity>(
                  value: account,
                  child: Text(account.name),
                ),
              )
              .toList(),
          onChanged: accounts.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedAccount = value;
                  });
                },
          decoration: _buildSelectDecoration('Account'),
          iconEnabledColor: Colors.white70,
          dropdownColor: const Color(0xFF0F0F19),
          style: const TextStyle(color: Colors.white),
        );
      },
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
        CategoryEntity? selectedCategory;
        if (_selectedCategory != null) {
          for (final category in categories) {
            if (category.categoryId == _selectedCategory!.categoryId) {
              selectedCategory = category;
              break;
            }
          }
        }

        return DropdownButtonFormField<CategoryEntity>(
          value: selectedCategory,
          items: categories
              .map(
                (category) => DropdownMenuItem<CategoryEntity>(
                  value: category,
                  child: Text(category.name),
                ),
              )
              .toList(),
          onChanged: categories.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedCategory = value;
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
    final account = _selectedAccount;
    final category = _selectedCategory;
    const currency = 'BDT';

    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount.');
      return;
    }
    if (account == null || category == null) {
      _showError('Account and category are required.');
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
        CreateTransactionCommand(
          userId: profile.userId,
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

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
