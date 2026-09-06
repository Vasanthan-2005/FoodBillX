import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/menu_item_repository.dart';
import '../core/utils/local_image_storage_service.dart';

class MenuState {
  final List<CategoryModel> categories;
  final List<MenuItemModel> items;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool? vegFilter;
  final bool isLoading;
  final String? errorMessage;

  MenuState({
    required this.categories,
    required this.items,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.vegFilter,
    this.isLoading = false,
    this.errorMessage,
  });

  factory MenuState.initial() => MenuState(categories: [], items: []);

  MenuState copyWith({
    List<CategoryModel>? categories,
    List<MenuItemModel>? items,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    bool? vegFilter,
    bool clearVegFilter = false,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MenuState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      vegFilter: clearVegFilter ? null : (vegFilter ?? this.vegFilter),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final CategoryRepository _categoryRepo;
  final MenuItemRepository _menuItemRepo;
  List<MenuItemModel> _allItems = const [];

  MenuNotifier(this._categoryRepo, this._menuItemRepo)
    : super(MenuState.initial()) {
    loadCategoriesAndItems();
  }

  void _applyFilters() {
    final query = state.searchQuery.trim().toLowerCase();
    final filtered = _allItems
        .where((item) {
          final matchesCategory =
              state.selectedCategoryId == null ||
              item.categoryId == state.selectedCategoryId;
          final matchesSearch =
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query);
          final matchesVeg =
              state.vegFilter == null || item.isVeg == state.vegFilter;
          return matchesCategory && matchesSearch && matchesVeg;
        })
        .toList(growable: false);
    state = state.copyWith(
      items: filtered,
      isLoading: false,
      errorMessage: null,
    );
  }

  void updateFromBootstrap(
    List<CategoryModel> categories,
    List<MenuItemModel> items,
  ) {
    _allItems = items;
    state = state.copyWith(
      categories: categories,
      isLoading: false,
      errorMessage: null,
    );
    _applyFilters();
  }

  Future<void> loadCategoriesAndItems({bool forceSpinner = false}) async {
    final showLoading = forceSpinner || _allItems.isEmpty;
    state = state.copyWith(isLoading: showLoading, errorMessage: null);

    try {
      final categories = await _categoryRepo.getAll();
      _allItems = await _menuItemRepo.getAll();
      state = state.copyWith(
        categories: categories,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _allItems.isEmpty
            ? e.toString().replaceAll('Exception: ', '')
            : null,
      );
    }
  }

  void selectCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    _applyFilters();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  Future<void> loadMenuItems() async {
    try {
      _allItems = await _menuItemRepo.getAll();
      _applyFilters();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ── Category CRUD ──────────────────────────────────────────────
  Future<bool> createCategory(String name, String icon) async {
    try {
      await _categoryRepo.create(name, icon);
      await loadCategoriesAndItems(forceSpinner: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCategory(String id, String name, String icon) async {
    try {
      await _categoryRepo.update(id, name, icon);
      await loadCategoriesAndItems(forceSpinner: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _categoryRepo.delete(id);
      if (state.selectedCategoryId == id) {
        state = state.copyWith(clearCategory: true);
      }
      await loadCategoriesAndItems(forceSpinner: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Menu Item CRUD ─────────────────────────────────────────────
  Future<bool> createMenuItem(MenuItemModel item) async {
    try {
      await _menuItemRepo.create(item);
      await loadMenuItems();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMenuItem(MenuItemModel item) async {
    try {
      await _menuItemRepo.update(item);
      await loadMenuItems();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleAvailability(String itemId) async {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final oldItem = _allItems[index];
    final updatedItem = oldItem.copyWith(isAvailable: !oldItem.isAvailable);

    // 1. Instant local state update (0ms UI latency!)
    _allItems[index] = updatedItem;
    _applyFilters();

    // 2. Perform backend API sync in background
    try {
      await _menuItemRepo.toggleAvailability(itemId);
    } catch (_) {
      // Revert if network failed
      _allItems[index] = oldItem;
      _applyFilters();
    }
  }

  Future<bool> deleteMenuItem(String itemId) async {
    try {
      final index = _allItems.indexWhere((i) => i.id == itemId);
      if (index != -1 && _allItems[index].image.isNotEmpty) {
        await LocalImageStorageService.deleteDishImage(_allItems[index].image);
      }
      await _menuItemRepo.delete(itemId);
      await loadMenuItems();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final menuItemRepo = ref.watch(menuItemRepositoryProvider);
  return MenuNotifier(categoryRepo, menuItemRepo);
});
