import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../cqrs/commands.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';
import '../services/user_identity.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  static const List<Color> _presetColors = [
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFFF6B5F),
    Color(0xFFFF8A3D),
    Color(0xFF7C3AED),
    Color(0xFFB794F4),
    Color(0xFFF472B6),
    Color(0xFFFFB86B),
  ];

  static const Map<String, IconData> _iconOptions = {
    'shopping_bag': Icons.shopping_bag,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'home': Icons.home,
    'fitness_center': Icons.fitness_center,
    'movie': Icons.movie,
    'school': Icons.school,
  };

  Future<CqrsService>? _cqrsFuture;
  Future<List<CategoryEntity>>? _categoriesFuture;
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
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            onPressed: _openCreateCategory,
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

                  return _buildCategoriesList(
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

  Widget _buildCategoriesList(CqrsService cqrs, String userId) {
    _categoriesFuture ??= cqrs.bus.query(GetCategoriesQuery(userId: userId));
    return FutureBuilder<List<CategoryEntity>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!;
        if (categories.isEmpty) {
          return const Center(
            child: Text(
              'No categories yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(cqrs, category);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(CqrsService cqrs, CategoryEntity category) {
    final iconData = _iconForName(category.icon);
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
              color: _categoryColor(category).withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: _categoryColor(category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Type: ${category.type}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sort order: ${category.sortOrder}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditCategoryDialog(cqrs, category),
            icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: () => _confirmDeleteCategory(cqrs, category),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateCategory() async {
    final cqrs = await _cqrs;
    if (!mounted) {
      return;
    }
    await _showCreateCategoryDialog(cqrs);
  }

  Future<void> _showCreateCategoryDialog(CqrsService cqrs) async {
    final userId = _userId;
    if (userId == null) {
      _showError('User profile not ready yet.');
      return;
    }
    final nameController = TextEditingController();
    final sortOrderController = TextEditingController(text: '0');
    var selectedType = 'expense';
    var selectedColor = _presetColors.first;
    var selectedIconName = _iconOptions.keys.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgSecondary,
              title: const Text('New Category',
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
                        DropdownMenuItem(
                            value: 'expense', child: Text('Expense')),
                        DropdownMenuItem(
                            value: 'income', child: Text('Income')),
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
                    _buildSectionLabel('Color'),
                    const SizedBox(height: 8),
                    _buildColorPicker(
                      selectedColor: selectedColor,
                      onSelected: (value) {
                        setDialogState(() {
                          selectedColor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSectionLabel('Icon'),
                    const SizedBox(height: 8),
                    _buildIconPicker(
                      selectedIconName: selectedIconName,
                      onSelected: (value) {
                        setDialogState(() {
                          selectedIconName = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      controller: sortOrderController,
                      label: 'Sort Order',
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
    final sortOrder = int.tryParse(sortOrderController.text.trim());

    if (name.isEmpty || sortOrder == null) {
      _showError('Please enter valid category details.');
      return;
    }

    try {
      await cqrs.bus.execute(CreateCategoryCommand(
        userId: userId,
        name: name,
        type: selectedType,
        icon: selectedIconName,
        color: selectedColor.value,
        sortOrder: sortOrder,
      ));
      _reloadCategories(cqrs);
    } catch (error) {
      _showError('Unable to create category.');
    }
  }

  Future<void> _showEditCategoryDialog(
    CqrsService cqrs,
    CategoryEntity category,
  ) async {
    final userId = _userId;
    if (userId == null) {
      _showError('User profile not ready yet.');
      return;
    }
    final nameController = TextEditingController(text: category.name);
    final sortOrderController =
        TextEditingController(text: category.sortOrder.toString());
    var selectedType = category.type;
    var selectedColor = _resolveCategoryColor(category);
    var selectedIconName = _resolveCategoryIconName(category.icon);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgSecondary,
              title: const Text('Edit Category',
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
                        DropdownMenuItem(
                            value: 'expense', child: Text('Expense')),
                        DropdownMenuItem(
                            value: 'income', child: Text('Income')),
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
                    _buildSectionLabel('Color'),
                    const SizedBox(height: 8),
                    _buildColorPicker(
                      selectedColor: selectedColor,
                      onSelected: (value) {
                        setDialogState(() {
                          selectedColor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSectionLabel('Icon'),
                    const SizedBox(height: 8),
                    _buildIconPicker(
                      selectedIconName: selectedIconName,
                      onSelected: (value) {
                        setDialogState(() {
                          selectedIconName = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      controller: sortOrderController,
                      label: 'Sort Order',
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
    final sortOrder = int.tryParse(sortOrderController.text.trim());

    if (name.isEmpty || sortOrder == null) {
      _showError('Please enter valid category details.');
      return;
    }

    try {
      await cqrs.bus.execute(UpdateCategoryCommand(
        userId: userId,
        categoryId: category.categoryId,
        name: name,
        type: selectedType,
        icon: selectedIconName,
        color: selectedColor.value,
        sortOrder: sortOrder,
      ));
      _reloadCategories(cqrs);
    } catch (error) {
      _showError('Unable to update category.');
    }
  }

  Future<void> _confirmDeleteCategory(
    CqrsService cqrs,
    CategoryEntity category,
  ) async {
    final userId = _userId;
    if (userId == null) {
      _showError('User profile not ready yet.');
      return;
    }
    final blockedReason = await _categoryDeleteBlockedReason(cqrs, category);
    if (blockedReason != null) {
      _showError(blockedReason);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('Delete Category',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            'Delete ${category.name}? This can be restored only from sync data.',
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
      await cqrs.bus.execute(DeleteCategoryCommand(
        userId: userId,
        categoryId: category.categoryId,
      ));
      _reloadCategories(cqrs);
    } catch (error) {
      _showError('Unable to delete category.');
    }
  }

  void _reloadCategories(CqrsService cqrs) {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    setState(() {
      _categoriesFuture = cqrs.bus.query(
        GetCategoriesQuery(userId: userId),
      );
    });
  }

  Future<String?> _categoryDeleteBlockedReason(
    CqrsService cqrs,
    CategoryEntity category,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return 'User profile not ready yet.';
    }
    final transactions = await cqrs.bus.query(GetTransactionsQuery(
      userId: userId,
      categoryId: category.categoryId,
      limit: 1,
    ));
    if (transactions.isNotEmpty) {
      return 'Category is used by existing transactions.';
    }

    final budgets = await cqrs.bus.query(GetBudgetsQuery(userId: userId));
    final hasBudgets = budgets.any(
      (budget) => budget.categoryId == category.categoryId,
    );
    if (hasBudgets) {
      return 'Category is used by budgets.';
    }

    final recurring = await cqrs.bus.query(GetRecurringQuery(userId: userId));
    final hasRecurring =
        recurring.any((entry) => entry.categoryId == category.categoryId);
    if (hasRecurring) {
      return 'Category is used by recurring transactions.';
    }

    return null;
  }

  Color _categoryColor(CategoryEntity category) {
    return _resolveCategoryColor(category);
  }

  Color _resolveCategoryColor(CategoryEntity category) {
    if (category.color == null) {
      return _presetColors.first;
    }
    return Color(category.color!);
  }

  String _resolveCategoryIconName(String? iconName) {
    if (iconName == null || !_iconOptions.containsKey(iconName)) {
      return _iconOptions.keys.first;
    }
    return iconName;
  }

  IconData _iconForName(String? iconName) {
    if (iconName == null) {
      return Icons.category;
    }
    return _iconOptions[iconName] ?? Icons.category;
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

  Widget _buildSectionLabel(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildColorPicker({
    required Color selectedColor,
    required ValueChanged<Color> onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _presetColors.map((color) {
        final isSelected = color.value == selectedColor.value;
        return InkWell(
          onTap: () => onSelected(color),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconPicker({
    required String selectedIconName,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _iconOptions.entries.map((entry) {
        final isSelected = entry.key == selectedIconName;
        return InkWell(
          onTap: () => onSelected(entry.key),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryViolet
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              entry.value,
              color: isSelected ? AppColors.primaryViolet : AppColors.textMuted,
            ),
          ),
        );
      }).toList(),
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
