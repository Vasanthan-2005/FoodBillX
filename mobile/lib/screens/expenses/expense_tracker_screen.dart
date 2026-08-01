import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_category_model.dart';

// ── Screen ────────────────────────────────────────────────────────────
class ExpenseTrackerScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const ExpenseTrackerScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<ExpenseTrackerScreen> createState() =>
      _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends ConsumerState<ExpenseTrackerScreen> {
  // ── Add Expense Dialog ────────────────────────────────────────────
  void _showAddExpenseDialog(List<ExpenseCategoryModel> categories) {
    final amountController = TextEditingController();
    String selectedCategory = categories.isNotEmpty
        ? categories.first.name
        : 'Miscellaneous';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Log Expense',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Expense Category',
                    ),
                    items: categories
                        .map<DropdownMenuItem<String>>(
                          (cat) => DropdownMenuItem<String>(
                            value: cat.name,
                            child: Text(cat.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                      hintText: '0.00',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amount <= 0) {
                      SnackbarUtils.showError(context, 'Enter a valid amount');
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);

                    final ok = await ref
                        .read(expenseProvider.notifier)
                        .createExpense({
                          'category': selectedCategory,
                          'amount': amount,
                        });

                    if (ok) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '₹${amount.toStringAsFixed(0)} under "$selectedCategory" logged',
                          ),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Failed to log expense'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Record Expense',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Manage Expense Categories ─────────────────────────────────────
  void _showManageCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) =>
            _ExpenseCategorySheet(scrollCtrl: scrollCtrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: _showManageCategoriesSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(expenseProvider.notifier).loadAll(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(expenseState.categories),
        backgroundColor: Colors.red.shade700,
        icon: const Icon(
          Icons.remove_circle_outline_rounded,
          color: Colors.white,
        ),
        label: const Text(
          'Log Expense',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 6,
      ),
      body: expenseState.isLoading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SkeletonLoader(width: double.infinity, height: 90),
                  SizedBox(height: 16),
                  MetricCardSkeleton(),
                ],
              ),
            )
          : expenseState.errorMessage != null
          ? ErrorStateWidget(
              title: 'Unable to load expenses',
              message: expenseState.errorMessage!,
              onRetry: () => ref.read(expenseProvider.notifier).loadAll(),
            )
          : _buildExpenseContent(expenseState),
    );
  }

  Widget _buildExpenseContent(ExpenseState state) {
    final expenses = state.expenses;
    final double totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        // Summary Banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade900, Colors.red.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade900.withAlpha(90),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Recorded Expenses',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Operational costs & ingredients',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(totalAmount),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: expenses.isEmpty
              ? EmptyStateWidget(
                  iconEmoji: '💸',
                  title: 'No expenses logged',
                  description:
                      'Record ingredients, fuel, electricity, or maintenance costs.',
                  actionLabel: 'Log Expense',
                  onActionPressed: () =>
                      _showAddExpenseDialog(state.categories),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: expenses.length,
                  itemBuilder: (ctx, index) {
                    final exp = expenses[index];
                    final category = exp.category;
                    final amount = exp.amount;
                    final dateStr = exp.date;
                    final idStr = exp.id;

                    return Dismissible(
                      key: Key(idStr),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Expense?'),
                            content: Text(
                              'Remove this ₹${amount.toStringAsFixed(0)} entry?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await ref
                            .read(expenseProvider.notifier)
                            .deleteExpense(idStr);
                        if (ok) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Expense deleted'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Failed to delete expense'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withAlpha(30),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.red.shade400,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${dateStr.day}/${dateStr.month}/${dateStr.year}  •  Swipe ← to delete',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '- ${CurrencyFormatter.format(amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 25).ms);
                  },
                ),
        ),
      ],
    );
  }
}

// ── Expense Category Manager Sheet ─────────────────────────────────
class _ExpenseCategorySheet extends ConsumerStatefulWidget {
  final ScrollController scrollCtrl;
  const _ExpenseCategorySheet({required this.scrollCtrl});

  @override
  ConsumerState<_ExpenseCategorySheet> createState() =>
      _ExpenseCategorySheetState();
}

class _ExpenseCategorySheetState extends ConsumerState<_ExpenseCategorySheet> {
  void _showAddEditDialog([String? existingId, String? existingName]) {
    final ctrl = TextEditingController(text: existingName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existingId == null ? 'New Expense Category' : 'Edit Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Rent, Gas, Salary',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await ref
                  .read(expenseProvider.notifier)
                  .createExpenseCategory(name, 'attach_money');
              if (mounted) {
                if (ok) {
                  SnackbarUtils.showSuccess(
                    context,
                    existingId == null
                        ? 'Category "$name" created'
                        : 'Category saved',
                  );
                } else {
                  SnackbarUtils.showError(context, 'Failed to save category');
                }
              }
            },
            child: Text(existingId == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Remove "$name" from expense categories?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final ok = await ref
          .read(expenseProvider.notifier)
          .deleteExpenseCategory(id);
      if (mounted) {
        if (ok) {
          SnackbarUtils.showSuccess(context, 'Category deleted');
        } else {
          SnackbarUtils.showError(context, 'Failed to delete category');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final cats = expenseState.categories;

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Expense Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: cats.isEmpty
              ? const Center(
                  child: Text(
                    'No categories yet.\nTap Add to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  controller: widget.scrollCtrl,
                  itemCount: cats.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final cat = cats[i];
                    final catId = cat.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withAlpha(30),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Edit',
                            onPressed: () =>
                                _showAddEditDialog(catId, cat.name),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(catId, cat.name),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
