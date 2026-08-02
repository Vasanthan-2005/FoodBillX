import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';

const List<String> defaultExpenseCategories = [
  'Rent',
  'Salary',
  'Grocery',
  'Chicken',
  'Mutton',
  'Vegetables',
  'Gas',
  'Packaging',
  'Transport',
  'Maintenance',
  'Miscellaneous',
];

class ExpenseTrackerScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const ExpenseTrackerScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends ConsumerState<ExpenseTrackerScreen> {
  void _showAddEditExpenseDialog([ExpenseModel? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(2) : '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String selectedCategory = existing?.category ?? defaultExpenseCategories.first;
    DateTime selectedDate = existing?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                existing == null ? 'Add Expense' : 'Edit Expense',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name *',
                        hintText: 'e.g. Daily Chicken Supply',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category *'),
                      items: defaultExpenseCategories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹) *',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Optional Notes',
                        hintText: 'Add bill receipt # or seller info',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (title.isEmpty) {
                      SnackbarUtils.showError(context, 'Expense name is required');
                      return;
                    }
                    if (amount <= 0) {
                      SnackbarUtils.showError(context, 'Enter a valid amount');
                      return;
                    }

                    Navigator.pop(ctx);
                    final payload = {
                      'title': title,
                      'category': selectedCategory,
                      'amount': amount,
                      'date': selectedDate.toIso8601String(),
                      'notes': notesController.text.trim(),
                    };

                    bool success;
                    if (existing == null) {
                      success = await ref.read(expenseProvider.notifier).createExpense(payload);
                    } else {
                      success = await ref.read(expenseProvider.notifier).updateExpense(existing.id, payload);
                    }

                    if (mounted) {
                      if (success) {
                        SnackbarUtils.showSuccess(
                          context,
                          existing == null ? 'Expense logged successfully' : 'Expense updated',
                        );
                      } else {
                        SnackbarUtils.showError(context, 'Failed to save expense');
                      }
                    }
                  },
                  child: Text(
                    existing == null ? 'Record Expense' : 'Save Changes',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(expenseProvider.notifier).loadAll(forceSpinner: true),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditExpenseDialog(),
        backgroundColor: Colors.red.shade700,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        // Summary Card
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
                    'Total Expenses Logged',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Operational costs & stock purchases',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(totalAmount),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ),

        Expanded(
          child: expenses.isEmpty
              ? EmptyStateWidget(
                  iconEmoji: '💸',
                  title: 'No expenses recorded yet',
                  description: 'Record ingredients, rent, salaries, gas, or packaging expenses.',
                  actionLabel: 'Add Expense',
                  onActionPressed: () => _showAddEditExpenseDialog(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: expenses.length,
                  itemBuilder: (ctx, index) {
                    final exp = expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        onTap: () => _showAddEditExpenseDialog(exp),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withAlpha(30),
                          child: Icon(Icons.receipt_long_rounded, color: Colors.red.shade400, size: 20),
                        ),
                        title: Text(
                          exp.title.isNotEmpty ? exp.title : exp.category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Category: ${exp.category}  •  ${DateFormat('dd MMM yyyy').format(exp.date)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '- ${CurrencyFormatter.format(exp.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Colors.red.shade400,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Expense?'),
                                    content: Text('Delete "${exp.title}" (₹${exp.amount.toStringAsFixed(0)})?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final ok = await ref.read(expenseProvider.notifier).deleteExpense(exp.id);
                                  if (context.mounted && ok) {
                                    SnackbarUtils.showSuccess(context, 'Expense deleted');
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 20).ms);
                  },
                ),
        ),
      ],
    );
  }
}
