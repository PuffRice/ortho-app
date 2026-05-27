import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../cqrs/commands.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';
import '../services/user_identity.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  Future<CqrsService>? _cqrsFuture;
  Future<List<AccountEntity>>? _accountsFuture;
  Future<String>? _userIdFuture;
  String? _userId;

  Future<CqrsService> get _cqrs {
    return _cqrsFuture ??= CqrsService.create();
  }

  Future<String> get _userIdLoad {
    return _userIdFuture ??=
        UserIdentityService.instance.getProfile().then((profile) {
      _userId = profile.userId;
      return profile.userId;
    });
  }

  @override
  void initState() {
    super.initState();
    _cqrsFuture = CqrsService.create();
    _userIdFuture = UserIdentityService.instance.getProfile().then((profile) {
      _userId = profile.userId;
      return profile.userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: const Text('Manage Accounts'),
        actions: [
          IconButton(
            onPressed: _openCreateAccount,
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
          ),
        ],
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
                      AppColors.primaryDeep.withOpacity(0.0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          FutureBuilder<CqrsService>(
            future: _cqrs,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return FutureBuilder<String>(
                future: _userIdLoad,
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return _buildAccountsList(
                    snapshot.data!,
                    userSnapshot.data!,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(CqrsService cqrs, String userId) {
    _accountsFuture ??= cqrs.bus.query(GetAccountsQuery(userId: userId));
    return FutureBuilder<List<AccountEntity>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final accounts = snapshot.data!;
        if (accounts.isEmpty) {
          return const Center(
            child: Text(
              'No accounts yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return _buildAccountCard(cqrs, account);
          },
        );
      },
    );
  }

  Widget _buildAccountCard(CqrsService cqrs, AccountEntity account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet,
                color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${account.type} - ${account.currency}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Balance: ${account.currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditAccountDialog(cqrs, account),
            icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: () => _confirmDeleteAccount(cqrs, account),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateAccount() async {
    final cqrs = await _cqrs;
    if (!mounted) {
      return;
    }
    await _showCreateAccountDialog(cqrs);
  }

  Future<void> _showCreateAccountDialog(CqrsService cqrs) async {
    final userId = _userId;
    if (userId == null) {
      _showError('User profile not ready yet.');
      return;
    }
    final nameController = TextEditingController();
    final currencyController = TextEditingController(text: 'USD');
    final openingBalanceController = TextEditingController(text: '0');
    var selectedType = 'cash';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgSecondary,
              title: const Text('New Account',
                  style: TextStyle(color: AppColors.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField(
                      controller: nameController,
                      label: 'Name',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                      dropdownColor: AppColors.bgSecondary,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _dialogDecoration('Type'),
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      controller: currencyController,
                      label: 'Currency',
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      controller: openingBalanceController,
                      label: 'Opening Balance',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Create',
                      style: TextStyle(color: AppColors.primaryViolet)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    final name = nameController.text.trim();
    final currency = currencyController.text.trim();
    final openingBalance =
        double.tryParse(openingBalanceController.text.trim());

    if (name.isEmpty || currency.isEmpty || openingBalance == null) {
      _showError('Please enter valid account details.');
      return;
    }

    try {
      await cqrs.bus.execute(CreateAccountCommand(
        userId: userId,
        name: name,
        type: selectedType,
        currency: currency,
        openingBalance: openingBalance,
      ));
      _reloadAccounts(cqrs);
    } catch (error) {
      _showError('Unable to create account.');
    }
  }

  Future<void> _showEditAccountDialog(
    CqrsService cqrs,
    AccountEntity account,
  ) async {
    final userId = _userId;
    if (userId == null) {
      _showError('User profile not ready yet.');
      return;
    }
    final nameController = TextEditingController(text: account.name);
    final currencyController = TextEditingController(text: account.currency);
    final openingBalanceController =
        TextEditingController(text: account.openingBalance.toStringAsFixed(2));
    var selectedType = account.type;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgSecondary,
              title: const Text('Edit Account',
                  style: TextStyle(color: AppColors.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField(
                      controller: nameController,
                      label: 'Name',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                      dropdownColor: AppColors.bgSecondary,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _dialogDecoration('Type'),
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      controller: currencyController,
                      label: 'Currency',
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      controller: openingBalanceController,
                      label: 'Opening Balance',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save',
                      style: TextStyle(color: AppColors.primaryViolet)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    final name = nameController.text.trim();
    final currency = currencyController.text.trim();
    final openingBalance =
        double.tryParse(openingBalanceController.text.trim());

    if (name.isEmpty || currency.isEmpty || openingBalance == null) {
      _showError('Please enter valid account details.');
      return;
    }

    try {
      await cqrs.bus.execute(UpdateAccountCommand(
        userId: userId,
        accountId: account.accountId,
        name: name,
        type: selectedType,
        currency: currency,
        openingBalance: openingBalance,
      ));
      _reloadAccounts(cqrs);
    } catch (error) {
      _showError('Unable to update account.');
    }
  }

  Future<void> _confirmDeleteAccount(
    CqrsService cqrs,
    AccountEntity account,
  ) async {
    final userId = _userId;
    if (userId == null) {
      _showError('User profile not ready yet.');
      return;
    }
    final blockedReason = await _accountDeleteBlockedReason(cqrs, account);
    if (blockedReason != null) {
      _showError(blockedReason);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('Delete Account',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            'Delete ${account.name}? This can be restored only from sync data.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    try {
      await cqrs.bus.execute(DeleteAccountCommand(
        userId: userId,
        accountId: account.accountId,
      ));
      _reloadAccounts(cqrs);
    } catch (error) {
      _showError('Unable to delete account.');
    }
  }

  void _reloadAccounts(CqrsService cqrs) {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    setState(() {
      _accountsFuture = cqrs.bus.query(GetAccountsQuery(userId: userId));
    });
  }

  Future<String?> _accountDeleteBlockedReason(
    CqrsService cqrs,
    AccountEntity account,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return 'User profile not ready yet.';
    }
    final transactions = await cqrs.bus.query(GetTransactionsQuery(
      userId: userId,
      accountId: account.accountId,
      limit: 1,
    ));
    if (transactions.isNotEmpty) {
      return 'Account is used by existing transactions.';
    }

    final transfers = await cqrs.bus.query(GetTransfersQuery(userId: userId));
    final hasTransfers = transfers.any(
      (transfer) =>
          transfer.fromAccountId == account.accountId ||
          transfer.toAccountId == account.accountId,
    );
    if (hasTransfers) {
      return 'Account is used by transfers.';
    }

    final recurring = await cqrs.bus.query(GetRecurringQuery(userId: userId));
    final hasRecurring =
        recurring.any((entry) => entry.accountId == account.accountId);
    if (hasRecurring) {
      return 'Account is used by recurring transactions.';
    }

    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _dialogDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryViolet),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _dialogDecoration(label),
    );
  }
}
