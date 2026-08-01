import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/settings_provider.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const MenuManagementScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Category Management ──────────────────────────────────────────
  void _showCategoryManagerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) {
            return _CategoryManagerSheet(scrollCtrl: scrollCtrl);
          },
        );
      },
    );
  }

  // ── Menu Item Form ───────────────────────────────────────────────
  void _showItemFormDialog([MenuItemModel? existingItem]) {
    final categories = ref.read(menuProvider).categories;

    if (existingItem == null && categories.isEmpty) {
      SnackbarUtils.showError(context, 'Please create a food category first.');
      _showCategoryManagerSheet();
      return;
    }

    final settings = ref.read(settingsProvider).settings;
    final defaultGst = settings?.taxPercentage ?? 5.0;

    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    final priceController = TextEditingController(
      text: existingItem != null ? existingItem.price.toString() : '',
    );
    final discountController = TextEditingController(
      text: existingItem?.discount.toString() ?? '0',
    );
    final gstController = TextEditingController(
      text: existingItem?.gstPercentage.toString() ?? defaultGst.toString(),
    );

    String selectedCatId =
        existingItem?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : '');
    bool isVeg = existingItem?.isVeg ?? true;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        existingItem == null
                            ? 'Add Food Item'
                            : 'Edit Food Item',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      if (categories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: selectedCatId.isNotEmpty
                              ? selectedCatId
                              : categories.first.id,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCatId = val);
                            }
                          },
                        ),
                      const SizedBox(height: 12),

                      // Item Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'Paneer Butter Masala',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter item name'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Price & Discount
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price *',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: discountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Discount (₹)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // GST (auto-filled from global setting)
                      TextFormField(
                        controller: gstController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'GST % (optional override)',
                          helperText:
                              'Default: $defaultGst% from global settings. Change only if different.',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Veg / Non-Veg toggle
                      Row(
                        children: [
                          const Text('Type: '),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('🟢 Veg'),
                            selected: isVeg,
                            selectedColor: Colors.green.shade100,
                            onSelected: (_) =>
                                setModalState(() => isVeg = true),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('🔴 Non-Veg'),
                            selected: !isVeg,
                            selectedColor: Colors.red.shade100,
                            onSelected: (_) =>
                                setModalState(() => isVeg = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);

                          final gstVal =
                              double.tryParse(gstController.text.trim()) ??
                              defaultGst;
                          final item = MenuItemModel(
                            id: existingItem?.id ?? '',
                            categoryId: selectedCatId,
                            name: nameController.text.trim(),
                            description: '',
                            price: double.parse(priceController.text.trim()),
                            discount:
                                double.tryParse(
                                  discountController.text.trim(),
                                ) ??
                                0.0,
                            gstPercentage: gstVal,
                            image: existingItem?.image ?? '',
                            isVeg: isVeg,
                            isAvailable: existingItem?.isAvailable ?? true,
                          );

                          bool ok;
                          if (existingItem == null) {
                            ok = await ref
                                .read(menuProvider.notifier)
                                .createMenuItem(item);
                          } else {
                            ok = await ref
                                .read(menuProvider.notifier)
                                .updateMenuItem(item);
                          }

                          if (mounted) {
                            if (ok) {
                              SnackbarUtils.showSuccess(
                                context,
                                existingItem == null
                                    ? 'Item "${item.name}" added'
                                    : 'Item "${item.name}" updated',
                              );
                            } else {
                              SnackbarUtils.showError(
                                context,
                                'Failed to save item. Try again.',
                              );
                            }
                          }
                        },
                        child: Text(
                          existingItem == null ? 'ADD ITEM' : 'SAVE CHANGES',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            tooltip: _isGridView
                ? 'Switch to List View'
                : 'Switch to Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: _showCategoryManagerSheet,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemFormDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 6,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  ref.read(menuProvider.notifier).setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(menuProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: const Text('All Items'),
                    selected: state.selectedCategoryId == null,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: state.selectedCategoryId == null
                          ? Colors.white
                          : null,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) =>
                        ref.read(menuProvider.notifier).selectCategory(null),
                  ),
                ),
                ...state.categories.map((c) {
                  final isSelected = state.selectedCategoryId == c.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) =>
                          ref.read(menuProvider.notifier).selectCategory(c.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                ? EmptyStateWidget(
                    iconEmoji: '🍔',
                    title: 'No menu items yet',
                    description:
                        'Tap Add Item to create your first food item in the menu.',
                    actionLabel: 'Add Item',
                    onActionPressed: () => _showItemFormDialog(),
                  )
                : _isGridView
                ? _buildGridView(state)
                : _buildListView(state),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(MenuState state) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.items.length,
      itemBuilder: (ctx, index) {
        final item = state.items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: item.isVeg
                              ? AppColors.vegGreen
                              : AppColors.nonVegRed,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: item.isVeg
                            ? AppColors.vegGreen
                            : AppColors.nonVegRed,
                      ),
                    ),
                    Switch(
                      value: item.isAvailable,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (_) {
                        ref
                            .read(menuProvider.notifier)
                            .toggleAvailability(item.id);
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(item.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    _ItemPopupMenu(item: item, onEdit: _showItemFormDialog),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(MenuState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: state.items.length,
      itemBuilder: (ctx, index) {
        final item = state.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: item.isVeg
                          ? AppColors.vegGreen
                          : AppColors.nonVegRed,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.circle,
                    size: 10,
                    color: item.isVeg
                        ? AppColors.vegGreen
                        : AppColors.nonVegRed,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CurrencyFormatter.format(item.price)}  •  GST ${item.gstPercentage}%',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(
                      value: item.isAvailable,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (_) => ref
                          .read(menuProvider.notifier)
                          .toggleAvailability(item.id),
                    ),
                    Text(
                      item.isAvailable ? 'In Stock' : 'Out',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.isAvailable
                            ? AppColors.secondary
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _ItemPopupMenu(item: item, onEdit: _showItemFormDialog),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 30).ms);
      },
    );
  }
}

// ── Item Popup Menu ────────────────────────────────────────────────
class _ItemPopupMenu extends ConsumerWidget {
  final MenuItemModel item;
  final void Function([MenuItemModel?]) onEdit;
  const _ItemPopupMenu({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (val) async {
        if (val == 'edit') {
          onEdit(item);
        } else if (val == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Item?'),
              content: Text('Delete "${item.name}" from the menu permanently?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            final ok = await ref
                .read(menuProvider.notifier)
                .deleteMenuItem(item.id);
            if (context.mounted) {
              ok
                  ? SnackbarUtils.showSuccess(context, '"${item.name}" deleted')
                  : SnackbarUtils.showError(context, 'Failed to delete item');
            }
          }
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Category Manager Bottom Sheet ──────────────────────────────────
class _CategoryManagerSheet extends ConsumerStatefulWidget {
  final ScrollController scrollCtrl;
  const _CategoryManagerSheet({required this.scrollCtrl});

  @override
  ConsumerState<_CategoryManagerSheet> createState() =>
      _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends ConsumerState<_CategoryManagerSheet> {
  void _showAddEditDialog([String? existingId, String? existingName]) {
    final ctrl = TextEditingController(text: existingName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existingId == null ? 'New Category' : 'Edit Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Beverages, Rolls',
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
              bool ok;
              if (existingId == null) {
                ok = await ref
                    .read(menuProvider.notifier)
                    .createCategory(name, 'fastfood');
              } else {
                ok = await ref
                    .read(menuProvider.notifier)
                    .updateCategory(existingId, name, 'fastfood');
              }
              if (mounted) {
                ok
                    ? SnackbarUtils.showSuccess(
                        context,
                        existingId == null
                            ? 'Category "$name" created'
                            : 'Category renamed to "$name"',
                      )
                    : SnackbarUtils.showError(
                        context,
                        'Failed to save category',
                      );
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
        content: Text(
          'Delete "$name"? Items in this category will be hidden from the menu.',
        ),
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
      final ok = await ref.read(menuProvider.notifier).deleteCategory(id);
      if (mounted) {
        ok
            ? SnackbarUtils.showSuccess(context, 'Category "$name" deleted')
            : SnackbarUtils.showError(context, 'Failed to delete category');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menuProvider).categories;

    return Column(
      children: [
        // Handle bar
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
                  'Manage Categories',
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
          child: categories.isEmpty
              ? const Center(
                  child: Text(
                    'No categories yet.\nTap Add to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  controller: widget.scrollCtrl,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final cat = categories[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withAlpha(30),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: AppColors.primary,
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
                                _showAddEditDialog(cat.id, cat.name),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(cat.id, cat.name),
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
