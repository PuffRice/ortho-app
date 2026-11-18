import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/local_models.dart';
import '../services/local_db.dart';
import '../services/user_identity.dart';

class TransferFeeSettingsScreen extends StatefulWidget {
  const TransferFeeSettingsScreen({super.key});

  @override
  State<TransferFeeSettingsScreen> createState() => _TransferFeeSettingsScreenState();
}

class _TransferFeeSettingsScreenState extends State<TransferFeeSettingsScreen> {
  List<CategoryEntity>? _categories;
  String? _selected;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = await LocalDb.instance.open();
      final profile = await UserIdentityService.instance.getProfile();
      final categories = await db.getCategories(userId: profile.userId, type: 'expense');
      final selected = await db.getTransferFeeCategory(profile.userId);
      if (mounted) setState(() {
        _categories = categories;
        _selected = categories.any((c) => c.categoryId == selected) ? selected : null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not load categories: $error');
    }
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      final db = await LocalDb.instance.open();
      final profile = await UserIdentityService.instance.getProfile();
      await db.setTransferFeeCategory(profile.userId, _selected!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPrimary,
    appBar: AppBar(title: const Text('Transfer fees'), backgroundColor: AppColors.bgSecondary),
    body: _categories == null && _error == null
      ? const Center(child: CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Fee category', style: TextStyle(color: AppColors.textPrimary, fontSize: 20)),
        const SizedBox(height: 12),
        const Text('Choose an existing expense category. Transfer fees are recorded as separate expenses from the sending account. Changing this setting applies when a transfer is saved.',
          style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.expenseNegative)),
        if (_categories != null && _categories!.isEmpty)
          const Text('Create an expense category in Manage Categories first.', style: TextStyle(color: AppColors.textSecondary)),
        for (final category in _categories ?? <CategoryEntity>[])
          ListTile(
            title: Text(category.name, style: const TextStyle(color: AppColors.textPrimary)),
            trailing: Icon(_selected == category.categoryId ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: AppColors.incomePositive),
            onTap: _saving ? null : () => setState(() => _selected = category.categoryId),
          ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _selected == null || _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
          child: Text(_saving ? 'Saving…' : 'Save category')),
      ]),
  );
}
