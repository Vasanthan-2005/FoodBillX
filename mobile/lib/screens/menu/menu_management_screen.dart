import 'dart:async';
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
import '../../core/utils/image_picker_service.dart';
import '../../core/widgets/dish_image_widget.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const MenuManagementScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  bool _isGridView = false;

  void _onSearchQueryChanged(String val) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      ref.read(menuProvider.notifier).setSearchQuery(val);
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'No Food Categories Found',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Please create at least one food category (e.g. Beverages, Rolls, Main Course) before adding food items.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showCategoryManagerSheet();
              },
              child: const Text('Create Category'),
            ),
          ],
        ),
      );
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
    String selectedImage = existingItem?.image ?? '';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

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

                      // Dish Image Selector Card
                      InkWell(
                        onTap: isSaving
                            ? null
                            : () async {
                                final picked = await ImagePickerService.showImageSourceDialog(modalCtx);
                                if (picked != null) {
                                  setModalState(() => selectedImage = picked);
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkCard
                                : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedImage.isEmpty
                                  ? Colors.grey.withAlpha(100)
                                  : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              DishImageWidget(
                                imageUrl: selectedImage,
                                fallbackEmoji: isVeg ? '🥗' : '🍗',
                                size: 48,
                                borderRadius: 10,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedImage.isEmpty ? 'Upload Dish Image (Optional)' : 'Dish Image Attached',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: selectedImage.isEmpty ? Colors.grey : null,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selectedImage.isEmpty ? 'Tap to take camera photo or pick gallery' : 'Tap to change dish image',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                            ],
                          ),
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
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() => selectedCatId = val);
                                  }
                                },
                        ),
                      const SizedBox(height: 12),

                      // Item Name
                      TextFormField(
                        controller: nameController,
                        enabled: !isSaving,
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
                              enabled: !isSaving,
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
                              enabled: !isSaving,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Discount (₹)',
                              ),
                            ),
                          ),
                        ],
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
                            onSelected: isSaving
                                ? null
                                : (_) => setModalState(() => isVeg = true),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('🔴 Non-Veg'),
                            selected: !isVeg,
                            selectedColor: Colors.red.shade100,
                            onSelected: isSaving
                                ? null
                                : (_) => setModalState(() => isVeg = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSaving = true);

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
                                  image: selectedImage.trim(),
                                  isVeg: isVeg,
                                  isAvailable: existingItem?.isAvailable ?? true,
                                );

                                bool ok = false;
                                try {
                                  if (existingItem == null) {
                                    ok = await ref
                                        .read(menuProvider.notifier)
                                        .createMenuItem(item);
                                  } else {
                                    ok = await ref
                                        .read(menuProvider.notifier)
                                        .updateMenuItem(item);
                                  }
                                } catch (_) {
                                  ok = false;
                                }

                                if (modalCtx.mounted) {
                                  Navigator.pop(modalCtx);
                                }

                                if (mounted) {
                                  if (ok) {
                                    await ref
                                        .read(menuProvider.notifier)
                                        .loadCategoriesAndItems(forceSpinner: false);
                                    if (mounted) {
                                      SnackbarUtils.showSuccess(
                                        context,
                                        existingItem == null
                                            ? 'Dish "${item.name}" created successfully!'
                                            : 'Dish "${item.name}" updated successfully!',
                                      );
                                    }
                                  } else {
                                    SnackbarUtils.showError(
                                      context,
                                      'Failed to save dish. Please check database connection.',
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                existingItem == null ? 'ADD DISH' : 'SAVE CHANGES',
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
    ).whenComplete(() {
        nameController.dispose();
        priceController.dispose();
        discountController.dispose();
        gstController.dispose();
      });
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
              onChanged: _onSearchQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchQueryChanged('');
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
                const SizedBox(width: 10),
                DishImageWidget(
                  imageUrl: item.image,
                  fallbackEmoji: item.isVeg ? '🥗' : '🍗',
                  size: 40,
                  borderRadius: 10,
                ),
                const SizedBox(width: 12),
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
                        CurrencyFormatter.format(item.price),
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
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
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
