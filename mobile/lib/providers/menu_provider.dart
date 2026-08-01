import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/menu_item_repository.dart';
import '../core/sync/sync_status_notifier.dart';

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
  final SyncStatusNotifier _syncStatus;

  MenuNotifier(this._categoryRepo, this._menuItemRepo, this._syncStatus)
    : super(MenuState.initial()) {
    loadCategoriesAndItems();
  }

  Future<void> loadCategoriesAndItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categories = await _categoryRepo.getAll();
      final items = await _fetchMenuItems();
      state = state.copyWith(
        categories: categories,
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<List<MenuItemModel>> _fetchMenuItems() async {
    return _menuItemRepo.getAll(
      categoryServerId: state.selectedCategoryId,
      search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      isVeg: state.vegFilter,
    );
  }

  void selectCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    loadMenuItems();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadMenuItems();
  }

  Future<void> loadMenuItems() async {
    try {
      final items = await _fetchMenuItems();
      state = state.copyWith(items: items);
    } catch (_) {}
  }

  // ── Category CRUD ──────────────────────────────────────────────
  Future<bool> createCategory(String name, String icon) async {
    try {
      final newCat = await _categoryRepo.create(name, icon);
      state = state.copyWith(categories: [...state.categories, newCat]);
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCategory(String id, String name, String icon) async {
    try {
      final updated = await _categoryRepo.update(id, name, icon);
      final list = state.categories
          .map((c) => c.id == id ? updated : c)
          .toList();
      state = state.copyWith(categories: list);
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _categoryRepo.delete(id);
      final list = state.categories.where((c) => c.id != id).toList();
      // If currently selected category was deleted, clear selection
      final clearCat = state.selectedCategoryId == id;
      if (clearCat) {
        state = state.copyWith(categories: list, clearCategory: true);
      } else {
        state = state.copyWith(categories: list);
      }
      await loadMenuItems();
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Menu Item CRUD ─────────────────────────────────────────────
  Future<bool> createMenuItem(MenuItemModel item) async {
    try {
      final newItem = await _menuItemRepo.create(item);
      state = state.copyWith(items: [...state.items, newItem]);
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMenuItem(MenuItemModel item) async {
    try {
      final updated = await _menuItemRepo.update(item);
      final list = state.items
          .map((i) => i.id == updated.id ? updated : i)
          .toList();
      state = state.copyWith(items: list);
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleAvailability(String itemId) async {
    try {
      final updated = await _menuItemRepo.toggleAvailability(itemId);
      if (updated != null) {
        final list = state.items
            .map((i) => i.id == updated.id ? updated : i)
            .toList();
        state = state.copyWith(items: list);
        _syncStatus.refreshPending();
      }
    } catch (_) {}
  }

  Future<bool> deleteMenuItem(String itemId) async {
    try {
      await _menuItemRepo.delete(itemId);
      final list = state.items.where((i) => i.id != itemId).toList();
      state = state.copyWith(items: list);
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final menuItemRepo = ref.watch(menuItemRepositoryProvider);
  final syncStatus = ref.watch(syncStatusProvider.notifier);
  return MenuNotifier(categoryRepo, menuItemRepo, syncStatus);
});
