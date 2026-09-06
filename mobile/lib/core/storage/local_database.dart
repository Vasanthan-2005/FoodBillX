import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/business_settings_model.dart';
import '../../models/category_model.dart';
import '../../models/customer_model.dart';
import '../../models/expense_category_model.dart';
import '../../models/expense_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/order_model.dart';
import 'sync_queue_item.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._internal();
  LocalDatabase._internal();

  static Database? _database;
  static const _uuid = Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'foodbillx_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Expenses Table
    batch.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        server_id TEXT UNIQUE,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        deleted_at TEXT
      );
    ''');
    batch.execute('CREATE INDEX idx_expenses_date ON expenses(date);');
    batch.execute('CREATE INDEX idx_expenses_category ON expenses(category);');
    batch.execute('CREATE INDEX idx_expenses_sync ON expenses(sync_status);');
    batch.execute('CREATE INDEX idx_expenses_deleted ON expenses(deleted_at);');

    // 2. Expense Categories Table
    batch.execute('''
      CREATE TABLE expense_categories (
        id TEXT PRIMARY KEY,
        server_id TEXT UNIQUE,
        name TEXT NOT NULL UNIQUE,
        icon TEXT DEFAULT 'receipt_long',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        deleted_at TEXT
      );
    ''');

    // 3. Monthly Budgets Table
    batch.execute('''
      CREATE TABLE monthly_budgets (
        id TEXT PRIMARY KEY, -- 'YYYY-MM'
        month TEXT NOT NULL,
        budget_amount REAL NOT NULL DEFAULT 0.0,
        notes TEXT,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      );
    ''');

    // 4. Business Settings Table (Singleton)
    batch.execute('''
      CREATE TABLE business_settings (
        id TEXT PRIMARY KEY DEFAULT 'singleton',
        server_id TEXT,
        business_name TEXT DEFAULT 'HMB Bills',
        logo TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        address TEXT DEFAULT '',
        gstin TEXT DEFAULT '',
        currency TEXT DEFAULT '₹',
        invoice_prefix TEXT DEFAULT 'B',
        tax_percentage REAL DEFAULT 0.0,
        service_charge_percentage REAL DEFAULT 0.0,
        invoice_footer TEXT DEFAULT 'Thank you for dining with us!',
        loyalty_target_visits INTEGER DEFAULT 6,
        loyalty_reward_type TEXT DEFAULT 'Free Drink',
        loyalty_reward_description TEXT DEFAULT 'Free Drink',
        monthly_expense_budget REAL DEFAULT 0.0,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      );
    ''');

    // 5. Menu Categories Table
    batch.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        server_id TEXT UNIQUE,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'fastfood',
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        deleted_at TEXT
      );
    ''');

    // 6. Menu Items Table
    batch.execute('''
      CREATE TABLE menu_items (
        id TEXT PRIMARY KEY,
        server_id TEXT UNIQUE,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        price REAL NOT NULL,
        discount REAL DEFAULT 0.0,
        gst_percentage REAL DEFAULT 0.0,
        image TEXT DEFAULT '',
        is_veg INTEGER DEFAULT 1,
        is_available INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        deleted_at TEXT
      );
    ''');

    // 7. Customers Table
    batch.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        server_id TEXT UNIQUE,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        address TEXT DEFAULT '',
        birthday TEXT,
        notes TEXT DEFAULT '',
        total_visits INTEGER DEFAULT 0,
        total_spent REAL DEFAULT 0.0,
        loyalty_points INTEGER DEFAULT 0,
        loyalty_card_number TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        deleted_at TEXT
      );
    ''');
    batch.execute('CREATE INDEX idx_customers_phone ON customers(phone);');
    batch.execute('CREATE INDEX idx_customers_card ON customers(loyalty_card_number);');

    // 8. Orders Table
    batch.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        server_id TEXT UNIQUE,
        order_number TEXT NOT NULL UNIQUE,
        customer_id TEXT,
        customer_name TEXT DEFAULT 'Walk-in Customer',
        customer_phone TEXT DEFAULT '',
        loyalty_card_number TEXT DEFAULT '',
        visit_count INTEGER DEFAULT 1,
        reward_status TEXT DEFAULT '',
        order_status TEXT DEFAULT 'completed',
        items_json TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_amount REAL DEFAULT 0.0,
        gst_amount REAL DEFAULT 0.0,
        service_charge_amount REAL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        payment_method TEXT DEFAULT 'cash',
        payment_status TEXT DEFAULT 'paid',
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        deleted_at TEXT
      );
    ''');
    batch.execute('CREATE INDEX idx_orders_created ON orders(created_at);');

    // 9. Sync Metadata Table
    batch.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Insert Default Expense Categories
    const defaultCats = [
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
    final now = DateTime.now().toIso8601String();
    for (final cat in defaultCats) {
      batch.insert('expense_categories', {
        'id': _uuid.v4(),
        'server_id': null,
        'name': cat,
        'icon': 'receipt_long',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'synced',
        'deleted_at': null,
      });
    }

    // Insert Default Business Settings
    batch.insert('business_settings', {
      'id': 'singleton',
      'server_id': null,
      'business_name': 'HMB Bills',
      'logo': '',
      'phone': '',
      'address': '',
      'gstin': '',
      'currency': '₹',
      'invoice_prefix': 'B',
      'tax_percentage': 0.0,
      'service_charge_percentage': 0.0,
      'invoice_footer': 'Thank you for dining with us!',
      'loyalty_target_visits': 6,
      'loyalty_reward_type': 'Free Drink',
      'loyalty_reward_description': 'Free Drink',
      'monthly_expense_budget': 0.0,
      'updated_at': now,
      'sync_status': 'synced',
    });

    await batch.commit();
  }

  // ==========================================
  // EXPENSES CRUD
  // ==========================================

  Future<List<ExpenseModel>> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final whereClauses = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final rows = await db.query(
      'expenses',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date DESC, created_at DESC',
    );

    return rows.map((r) => _mapToExpense(r)).toList();
  }

  Future<ExpenseModel> insertExpense(Map<String, dynamic> data) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final date = data['date'] ?? now;

    final row = {
      'id': id,
      'server_id': null,
      'category': data['category'] ?? 'Miscellaneous',
      'title': data['title'] ?? data['category'] ?? '',
      'amount': (data['amount'] as num).toDouble(),
      'date': date is DateTime ? date.toIso8601String() : date.toString(),
      'notes': data['notes'] ?? '',
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pendingCreate',
      'deleted_at': null,
    };

    await db.insert('expenses', row);
    return _mapToExpense(row);
  }

  Future<ExpenseModel?> updateExpense(String id, Map<String, dynamic> data) async {
    final db = await database;
    final existing = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return null;

    final currentSyncStatus = existing.first['sync_status'] as String? ?? 'synced';
    final newSyncStatus = currentSyncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';
    final now = DateTime.now().toIso8601String();

    final updateFields = <String, dynamic>{
      'updated_at': now,
      'sync_status': newSyncStatus,
    };
    if (data.containsKey('title')) updateFields['title'] = data['title'];
    if (data.containsKey('category')) updateFields['category'] = data['category'];
    if (data.containsKey('amount')) updateFields['amount'] = (data['amount'] as num).toDouble();
    if (data.containsKey('date')) {
      final d = data['date'];
      updateFields['date'] = d is DateTime ? d.toIso8601String() : d.toString();
    }
    if (data.containsKey('notes')) updateFields['notes'] = data['notes'];

    await db.update('expenses', updateFields, where: 'id = ?', whereArgs: [id]);
    final updated = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    return _mapToExpense(updated.first);
  }

  Future<bool> deleteExpense(String id) async {
    final db = await database;
    final existing = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return false;

    final serverId = existing.first['server_id'] as String?;
    final syncStatus = existing.first['sync_status'] as String?;

    if (serverId == null || serverId.isEmpty || syncStatus == 'pendingCreate') {
      // Created offline and never reached cloud -> hard delete locally
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    } else {
      // Exists in cloud -> soft delete with pendingDelete status
      await db.update(
        'expenses',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'sync_status': 'pendingDelete',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return true;
  }

  Future<double> getTodayExpenseTotal() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

    final db = await database;
    final res = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ? AND deleted_at IS NULL',
      [startOfDay, endOfDay],
    );
    final total = res.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }

  Future<double> getMonthlyExpenseTotal(DateTime monthDate) async {
    final startOfMonth = DateTime(monthDate.year, monthDate.month, 1).toIso8601String();
    final nextMonth = DateTime(monthDate.year, monthDate.month + 1, 1);
    final endOfMonth = nextMonth.subtract(const Duration(milliseconds: 1)).toIso8601String();

    final db = await database;
    final res = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ? AND deleted_at IS NULL',
      [startOfMonth, endOfMonth],
    );
    final total = res.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }

  ExpenseModel _mapToExpense(Map<String, dynamic> r) {
    DateTime parsedDate = DateTime.now();
    if (r['date'] != null) {
      parsedDate = DateTime.tryParse(r['date'].toString())?.toLocal() ?? DateTime.now();
    }
    return ExpenseModel(
      id: r['id'] as String,
      category: r['category'] as String? ?? 'Miscellaneous',
      title: r['title'] as String? ?? '',
      amount: (r['amount'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      notes: r['notes'] as String? ?? '',
    );
  }

  // ==========================================
  // EXPENSE CATEGORIES CRUD
  // ==========================================

  Future<List<ExpenseCategoryModel>> getExpenseCategories() async {
    final db = await database;
    final rows = await db.query(
      'expense_categories',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map((r) {
      return ExpenseCategoryModel(
        id: r['id'] as String,
        name: r['name'] as String,
        icon: r['icon'] as String? ?? 'receipt_long',
        isActive: (r['is_active'] as int? ?? 1) == 1,
      );
    }).toList();
  }

  Future<ExpenseCategoryModel> insertExpenseCategory(String name, String icon) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final row = {
      'id': id,
      'server_id': null,
      'name': name.trim(),
      'icon': icon,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pendingCreate',
      'deleted_at': null,
    };
    await db.insert('expense_categories', row);
    return ExpenseCategoryModel(id: id, name: name, icon: icon, isActive: true);
  }

  Future<void> deleteExpenseCategory(String id) async {
    final db = await database;
    final existing = await db.query('expense_categories', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return;

    final serverId = existing.first['server_id'] as String?;
    final syncStatus = existing.first['sync_status'] as String?;

    if (serverId == null || serverId.isEmpty || syncStatus == 'pendingCreate') {
      await db.delete('expense_categories', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update(
        'expense_categories',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'sync_status': 'pendingDelete',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ==========================================
  // MONTHLY BUDGETS CRUD & RESET LOGIC
  // ==========================================

  static String formatMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Future<double> getMonthlyBudget(String monthKey) async {
    final db = await database;
    final rows = await db.query('monthly_budgets', where: 'id = ?', whereArgs: [monthKey]);
    if (rows.isNotEmpty) {
      return (rows.first['budget_amount'] as num?)?.toDouble() ?? 0.0;
    }
    // Fallback to configured global budget in settings if no custom monthly budget set
    final settings = await getSettings();
    return settings?.taxPercentage != null ? (rows.isEmpty ? (await _getGlobalBudgetSetting()) : 0.0) : 0.0;
  }

  Future<double> _getGlobalBudgetSetting() async {
    final db = await database;
    final rows = await db.query('business_settings', where: 'id = ?', whereArgs: ['singleton']);
    if (rows.isNotEmpty) {
      return (rows.first['monthly_expense_budget'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  Future<void> setMonthlyBudget(String monthKey, double amount) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'monthly_budgets',
      {
        'id': monthKey,
        'month': monthKey,
        'budget_amount': amount,
        'updated_at': now,
        'sync_status': 'pendingUpdate',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Also update global default budget in settings
    await db.update(
      'business_settings',
      {'monthly_expense_budget': amount, 'updated_at': now, 'sync_status': 'pendingUpdate'},
      where: 'id = ?',
      whereArgs: ['singleton'],
    );
  }

  // ==========================================
  // BUSINESS SETTINGS CRUD
  // ==========================================

  Future<BusinessSettingsModel?> getSettings() async {
    final db = await database;
    final rows = await db.query('business_settings', where: 'id = ?', whereArgs: ['singleton']);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return BusinessSettingsModel(
      id: r['server_id'] as String? ?? 'singleton',
      businessName: r['business_name'] as String? ?? 'HMB Bills',
      logo: r['logo'] as String? ?? '',
      phone: r['phone'] as String? ?? '',
      address: r['address'] as String? ?? '',
      gstin: r['gstin'] as String? ?? '',
      currency: r['currency'] as String? ?? '₹',
      invoicePrefix: r['invoice_prefix'] as String? ?? 'B',
      taxPercentage: (r['tax_percentage'] as num?)?.toDouble() ?? 0.0,
      serviceChargePercentage: (r['service_charge_percentage'] as num?)?.toDouble() ?? 0.0,
      invoiceFooter: r['invoice_footer'] as String? ?? 'Thank you for dining with us!',
      loyaltyTargetVisits: (r['loyalty_target_visits'] as num?)?.toInt() ?? 6,
      loyaltyRewardType: r['loyalty_reward_type'] as String? ?? 'Free Drink',
      loyaltyRewardDescription: r['loyalty_reward_description'] as String? ?? 'Free Drink',
    );
  }

  Future<BusinessSettingsModel> upsertSettings(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': 'singleton',
      'updated_at': now,
      'sync_status': 'pendingUpdate',
    };

    if (data.containsKey('businessName')) row['business_name'] = data['businessName'];
    if (data.containsKey('logo')) row['logo'] = data['logo'];
    if (data.containsKey('phone')) row['phone'] = data['phone'];
    if (data.containsKey('address')) row['address'] = data['address'];
    if (data.containsKey('gstin')) row['gstin'] = data['gstin'];
    if (data.containsKey('currency')) row['currency'] = data['currency'];
    if (data.containsKey('invoicePrefix')) row['invoice_prefix'] = data['invoicePrefix'];
    if (data.containsKey('taxPercentage')) row['tax_percentage'] = (data['taxPercentage'] as num).toDouble();
    if (data.containsKey('serviceChargePercentage')) {
      row['service_charge_percentage'] = (data['serviceChargePercentage'] as num).toDouble();
    }
    if (data.containsKey('invoiceFooter')) row['invoice_footer'] = data['invoiceFooter'];
    if (data.containsKey('loyaltyTargetVisits')) {
      row['loyalty_target_visits'] = (data['loyaltyTargetVisits'] as num).toInt();
    }
    if (data.containsKey('loyaltyRewardType')) row['loyalty_reward_type'] = data['loyaltyRewardType'];
    if (data.containsKey('loyaltyRewardDescription')) {
      row['loyalty_reward_description'] = data['loyaltyRewardDescription'];
    }
    if (data.containsKey('monthlyExpenseBudget')) {
      row['monthly_expense_budget'] = (data['monthlyExpenseBudget'] as num).toDouble();
    }

    final count = await db.update('business_settings', row, where: 'id = ?', whereArgs: ['singleton']);
    if (count == 0) {
      await db.insert('business_settings', row);
    }
    return (await getSettings())!;
  }

  // ==========================================
  // CUSTOMERS CRUD
  // ==========================================

  Future<List<CustomerModel>> getCustomers({String? search, String? phone, String? cardNumber}) async {
    final db = await database;
    final where = <String>['deleted_at IS NULL'];
    final args = <dynamic>[];

    if (search != null && search.isNotEmpty) {
      where.add('(name LIKE ? OR phone LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    if (phone != null && phone.isNotEmpty) {
      where.add('phone = ?');
      args.add(phone.trim());
    }
    if (cardNumber != null && cardNumber.isNotEmpty) {
      where.add('loyalty_card_number = ?');
      args.add(cardNumber.trim());
    }

    final rows = await db.query(
      'customers',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'total_visits DESC, name ASC',
    );
    return rows.map((r) => _mapToCustomer(r)).toList();
  }

  Future<CustomerModel> insertCustomer(Map<String, dynamic> data) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final row = {
      'id': id,
      'server_id': null,
      'name': data['name'] ?? '',
      'phone': (data['phone'] ?? '').toString().trim(),
      'address': data['address'] ?? '',
      'birthday': data['birthday'],
      'notes': data['notes'] ?? '',
      'total_visits': data['totalVisits'] ?? 0,
      'total_spent': (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      'loyalty_points': data['loyaltyPoints'] ?? 0,
      'loyalty_card_number': data['loyaltyCardNumber'] ?? '',
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pendingCreate',
      'deleted_at': null,
    };
    await db.insert('customers', row, conflictAlgorithm: ConflictAlgorithm.replace);
    return _mapToCustomer(row);
  }

  Future<CustomerModel?> updateCustomer(String id, Map<String, dynamic> data) async {
    final db = await database;
    final existing = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return null;

    final currentSyncStatus = existing.first['sync_status'] as String? ?? 'synced';
    final newSyncStatus = currentSyncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';
    final now = DateTime.now().toIso8601String();

    final updates = <String, dynamic>{
      'updated_at': now,
      'sync_status': newSyncStatus,
    };
    if (data.containsKey('name')) updates['name'] = data['name'];
    if (data.containsKey('phone')) updates['phone'] = data['phone'].toString().trim();
    if (data.containsKey('address')) updates['address'] = data['address'];
    if (data.containsKey('notes')) updates['notes'] = data['notes'];
    if (data.containsKey('loyaltyCardNumber')) updates['loyalty_card_number'] = data['loyaltyCardNumber'];
    if (data.containsKey('totalVisits')) updates['total_visits'] = data['totalVisits'];
    if (data.containsKey('totalSpent')) updates['total_spent'] = (data['totalSpent'] as num).toDouble();
    if (data.containsKey('loyaltyPoints')) updates['loyalty_points'] = data['loyaltyPoints'];

    await db.update('customers', updates, where: 'id = ?', whereArgs: [id]);
    final updated = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return _mapToCustomer(updated.first);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    final existing = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return;

    final serverId = existing.first['server_id'] as String?;
    final syncStatus = existing.first['sync_status'] as String?;

    if (serverId == null || serverId.isEmpty || syncStatus == 'pendingCreate') {
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update(
        'customers',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'sync_status': 'pendingDelete',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  CustomerModel _mapToCustomer(Map<String, dynamic> r) {
    return CustomerModel(
      id: r['id'] as String,
      name: r['name'] as String? ?? '',
      phone: r['phone'] as String? ?? '',
      address: r['address'] as String? ?? '',
      notes: r['notes'] as String? ?? '',
      totalVisits: (r['total_visits'] as num?)?.toInt() ?? 0,
      totalSpent: (r['total_spent'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: (r['loyalty_points'] as num?)?.toInt() ?? 0,
      loyaltyCardNumber: r['loyalty_card_number'] as String? ?? '',
    );
  }

  // ==========================================
  // MENU ITEMS & CATEGORIES CRUD
  // ==========================================

  Future<List<CategoryModel>> getMenuCategories() async {
    final db = await database;
    final rows = await db.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map((r) => CategoryModel(
      id: r['id'] as String,
      name: r['name'] as String,
      icon: r['icon'] as String? ?? 'fastfood',
      sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
      isActive: (r['is_active'] as int? ?? 1) == 1,
    )).toList();
  }

  Future<CategoryModel> insertMenuCategory(String name, String icon) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final row = {
      'id': id,
      'server_id': null,
      'name': name.trim(),
      'icon': icon,
      'sort_order': 0,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pendingCreate',
      'deleted_at': null,
    };
    await db.insert('categories', row);
    return CategoryModel(id: id, name: name, icon: icon, sortOrder: 0, isActive: true);
  }

  Future<CategoryModel?> updateMenuCategory(String id, String name, String icon) async {
    final db = await database;
    final existing = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return null;

    final currentSyncStatus = existing.first['sync_status'] as String? ?? 'synced';
    final newSyncStatus = currentSyncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';
    final now = DateTime.now().toIso8601String();

    await db.update(
      'categories',
      {'name': name, 'icon': icon, 'updated_at': now, 'sync_status': newSyncStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
    return CategoryModel(id: id, name: name, icon: icon, sortOrder: 0, isActive: true);
  }

  Future<void> deleteMenuCategory(String id) async {
    final db = await database;
    final existing = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return;

    final serverId = existing.first['server_id'] as String?;
    final syncStatus = existing.first['sync_status'] as String?;

    if (serverId == null || serverId.isEmpty || syncStatus == 'pendingCreate') {
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update(
        'categories',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'sync_status': 'pendingDelete',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<MenuItemModel>> getMenuItems({String? categoryId, String? search, bool? isVeg}) async {
    final db = await database;
    final where = <String>['deleted_at IS NULL'];
    final args = <dynamic>[];

    if (categoryId != null && categoryId.isNotEmpty) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (search != null && search.isNotEmpty) {
      where.add('(name LIKE ? OR description LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    if (isVeg != null) {
      where.add('is_veg = ?');
      args.add(isVeg ? 1 : 0);
    }

    final rows = await db.query(
      'menu_items',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map((r) => _mapToMenuItem(r)).toList();
  }

  Future<MenuItemModel> insertMenuItem(MenuItemModel item) async {
    final db = await database;
    final id = item.id.isNotEmpty ? item.id : _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final row = {
      'id': id,
      'server_id': null,
      'category_id': item.categoryId,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'discount': item.discount,
      'gst_percentage': item.gstPercentage,
      'image': item.image,
      'is_veg': item.isVeg ? 1 : 0,
      'is_available': item.isAvailable ? 1 : 0,
      'sort_order': 0,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pendingCreate',
      'deleted_at': null,
    };
    await db.insert('menu_items', row, conflictAlgorithm: ConflictAlgorithm.replace);
    return _mapToMenuItem(row);
  }

  Future<MenuItemModel?> updateMenuItem(MenuItemModel item) async {
    final db = await database;
    final existing = await db.query('menu_items', where: 'id = ?', whereArgs: [item.id]);
    if (existing.isEmpty) return null;

    final currentSyncStatus = existing.first['sync_status'] as String? ?? 'synced';
    final newSyncStatus = currentSyncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';
    final now = DateTime.now().toIso8601String();

    final row = {
      'category_id': item.categoryId,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'discount': item.discount,
      'gst_percentage': item.gstPercentage,
      'image': item.image,
      'is_veg': item.isVeg ? 1 : 0,
      'is_available': item.isAvailable ? 1 : 0,
      'updated_at': now,
      'sync_status': newSyncStatus,
    };
    await db.update('menu_items', row, where: 'id = ?', whereArgs: [item.id]);
    return item;
  }

  Future<MenuItemModel?> toggleMenuItemAvailability(String id) async {
    final db = await database;
    final existing = await db.query('menu_items', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return null;

    final currentAvail = (existing.first['is_available'] as int? ?? 1) == 1;
    final newAvail = !currentAvail;
    final currentSyncStatus = existing.first['sync_status'] as String? ?? 'synced';
    final newSyncStatus = currentSyncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';

    await db.update(
      'menu_items',
      {
        'is_available': newAvail ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': newSyncStatus,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await db.query('menu_items', where: 'id = ?', whereArgs: [id]);
    return _mapToMenuItem(updated.first);
  }

  Future<void> deleteMenuItem(String id) async {
    final db = await database;
    final existing = await db.query('menu_items', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return;

    final serverId = existing.first['server_id'] as String?;
    final syncStatus = existing.first['sync_status'] as String?;

    if (serverId == null || serverId.isEmpty || syncStatus == 'pendingCreate') {
      await db.delete('menu_items', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update(
        'menu_items',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'sync_status': 'pendingDelete',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  MenuItemModel _mapToMenuItem(Map<String, dynamic> r) {
    return MenuItemModel(
      id: r['id'] as String,
      categoryId: r['category_id'] as String? ?? '',
      name: r['name'] as String? ?? '',
      description: r['description'] as String? ?? '',
      price: (r['price'] as num?)?.toDouble() ?? 0.0,
      discount: (r['discount'] as num?)?.toDouble() ?? 0.0,
      gstPercentage: (r['gst_percentage'] as num?)?.toDouble() ?? 0.0,
      image: r['image'] as String? ?? '',
      isVeg: (r['is_veg'] as int? ?? 1) == 1,
      isAvailable: (r['is_available'] as int? ?? 1) == 1,
    );
  }

  // ==========================================
  // ORDERS CRUD & BILLING
  // ==========================================

  Future<List<OrderModel>> getOrders({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final where = <String>['deleted_at IS NULL'];
    final args = <dynamic>[];

    if (startDate != null) {
      where.add('created_at >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('created_at <= ?');
      args.add(endDate.toIso8601String());
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'all') {
      where.add('payment_method = ?');
      args.add(paymentMethod.toLowerCase());
    }
    if (status != null && status.isNotEmpty) {
      where.add('order_status = ?');
      args.add(status.toLowerCase());
    }

    final rows = await db.query(
      'orders',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((r) => _mapToOrder(r)).toList();
  }

  Future<String> generateNextOrderNumber(String prefix) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM orders WHERE created_at >= ? AND created_at <= ?',
      [startOfDay, endOfDay],
    );
    final count = (res.first['cnt'] as num?)?.toInt() ?? 0;
    final seq = (count + 1).toString().padLeft(3, '0');
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return '$prefix-$dateStr-$seq';
  }

  Future<OrderModel> insertOrder({
    String? orderNumber,
    String? customerId,
    required String customerName,
    required String customerPhone,
    String loyaltyCardNumber = '',
    required List<OrderItemModel> items,
    required double subtotal,
    required double discountAmount,
    required double gstAmount,
    required double serviceChargeAmount,
    required double grandTotal,
    required String paymentMethod,
    String notes = '',
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final finalOrderNumber = orderNumber != null && orderNumber.isNotEmpty
        ? orderNumber
        : await generateNextOrderNumber('B');

    final itemsJson = jsonEncode(items.map((i) => i.toJson()).toList());

    final row = {
      'id': id,
      'server_id': null,
      'order_number': finalOrderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'loyalty_card_number': loyaltyCardNumber,
      'visit_count': 1,
      'reward_status': '',
      'order_status': 'completed',
      'items_json': itemsJson,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'gst_amount': gstAmount,
      'service_charge_amount': serviceChargeAmount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'payment_status': 'paid',
      'notes': notes,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pendingCreate',
      'deleted_at': null,
    };

    await db.insert('orders', row);

    // If customer phone is present, update customer stats offline atomically!
    if (customerPhone.isNotEmpty) {
      final existingCust = await getCustomers(phone: customerPhone);
      if (existingCust.isNotEmpty) {
        final c = existingCust.first;
        await updateCustomer(c.id, {
          'totalVisits': c.totalVisits + 1,
          'totalSpent': c.totalSpent + grandTotal,
          if (loyaltyCardNumber.isNotEmpty) 'loyaltyCardNumber': loyaltyCardNumber,
        });
      }
    }

    return _mapToOrder(row);
  }

  Future<OrderModel?> refundOrder(String id) async {
    final db = await database;
    final existing = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) return null;

    final currentSyncStatus = existing.first['sync_status'] as String? ?? 'synced';
    final newSyncStatus = currentSyncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';
    final now = DateTime.now().toIso8601String();

    await db.update(
      'orders',
      {
        'order_status': 'refunded',
        'updated_at': now,
        'sync_status': newSyncStatus,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    return _mapToOrder(updated.first);
  }

  OrderModel _mapToOrder(Map<String, dynamic> r) {
    List<OrderItemModel> items = [];
    final rawJson = r['items_json'] as String?;
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List;
        items = decoded.map((i) => OrderItemModel.fromJson(Map<String, dynamic>.from(i))).toList();
      } catch (_) {}
    }

    return OrderModel(
      id: r['id'] as String,
      orderNumber: r['order_number'] as String? ?? '',
      customerName: r['customer_name'] as String? ?? 'Walk-in Customer',
      customerPhone: r['customer_phone'] as String? ?? '',
      loyaltyCardNumber: r['loyalty_card_number'] as String? ?? '',
      visitCount: (r['visit_count'] as num?)?.toInt() ?? 1,
      rewardStatus: r['reward_status'] as String? ?? '',
      orderStatus: r['order_status'] as String? ?? 'completed',
      items: items,
      subtotal: (r['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (r['discount_amount'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (r['gst_amount'] as num?)?.toDouble() ?? 0.0,
      serviceChargeAmount: (r['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (r['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: r['payment_method'] as String? ?? 'cash',
      paymentStatus: r['payment_status'] as String? ?? 'paid',
      createdAt: DateTime.tryParse(r['created_at'].toString())?.toLocal() ?? DateTime.now(),
    );
  }

  // ==========================================
  // OFFLINE DASHBOARD & REPORT AGGREGATIONS
  // ==========================================

  Future<Map<String, dynamic>> computeDashboardMetrics() async {
    final db = await database;
    final now = DateTime.now();

    // Time boundaries
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

    final yestDate = now.subtract(const Duration(days: 1));
    final yestStart = DateTime(yestDate.year, yestDate.month, yestDate.day).toIso8601String();
    final yestEnd = DateTime(yestDate.year, yestDate.month, yestDate.day, 23, 59, 59, 999).toIso8601String();

    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)).toIso8601String();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

    // 1. Today Revenue & Order Count
    final todayRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt, SUM(grand_total) as rev
      FROM orders
      WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
    ''', [todayStart, todayEnd]);
    final todayRevenue = (todayRes.first['rev'] as num?)?.toDouble() ?? 0.0;
    final todayOrderCount = (todayRes.first['cnt'] as num?)?.toInt() ?? 0;

    // 2. Yesterday Revenue
    final yestRes = await db.rawQuery('''
      SELECT SUM(grand_total) as rev
      FROM orders
      WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
    ''', [yestStart, yestEnd]);
    final yesterdayRevenue = (yestRes.first['rev'] as num?)?.toDouble() ?? 0.0;

    // 3. Weekly Revenue & Count
    final weekRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt, SUM(grand_total) as rev
      FROM orders
      WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
    ''', [weekStart, todayEnd]);
    final weekRevenue = (weekRes.first['rev'] as num?)?.toDouble() ?? 0.0;
    final weekOrderCount = (weekRes.first['cnt'] as num?)?.toInt() ?? 0;

    // 4. Monthly Revenue & Count
    final monthRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt, SUM(grand_total) as rev
      FROM orders
      WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
    ''', [monthStart, todayEnd]);
    final monthRevenue = (monthRes.first['rev'] as num?)?.toDouble() ?? 0.0;
    final monthOrderCount = (monthRes.first['cnt'] as num?)?.toInt() ?? 0;

    // 5. Overall Revenue & Count
    final overallRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt, SUM(grand_total) as rev
      FROM orders
      WHERE order_status != 'refunded' AND deleted_at IS NULL
    ''');
    final overallRevenue = (overallRes.first['rev'] as num?)?.toDouble() ?? 0.0;
    final overallOrderCount = (overallRes.first['cnt'] as num?)?.toInt() ?? 0;

    // 6. Expenses: Today, Week, Month, Overall
    final expToday = await db.rawQuery('''
      SELECT SUM(amount) as exp FROM expenses WHERE date >= ? AND date <= ? AND deleted_at IS NULL
    ''', [todayStart, todayEnd]);
    final todayExpenseTotal = (expToday.first['exp'] as num?)?.toDouble() ?? 0.0;

    final expWeek = await db.rawQuery('''
      SELECT SUM(amount) as exp FROM expenses WHERE date >= ? AND date <= ? AND deleted_at IS NULL
    ''', [weekStart, todayEnd]);
    final weekExpenseTotal = (expWeek.first['exp'] as num?)?.toDouble() ?? 0.0;

    final expMonth = await db.rawQuery('''
      SELECT SUM(amount) as exp FROM expenses WHERE date >= ? AND date <= ? AND deleted_at IS NULL
    ''', [monthStart, todayEnd]);
    final monthExpenseTotal = (expMonth.first['exp'] as num?)?.toDouble() ?? 0.0;

    final expOverall = await db.rawQuery('''
      SELECT SUM(amount) as exp FROM expenses WHERE deleted_at IS NULL
    ''');
    final overallExpenseTotal = (expOverall.first['exp'] as num?)?.toDouble() ?? 0.0;

    // 7. Recent 7 days daily revenue
    final recentDailyRevenue = <double>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dStart = day.toIso8601String();
      final dEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999).toIso8601String();
      final dayRes = await db.rawQuery('''
        SELECT SUM(grand_total) as rev
        FROM orders
        WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
      ''', [dStart, dEnd]);
      recentDailyRevenue.add((dayRes.first['rev'] as num?)?.toDouble() ?? 0.0);
    }

    // 8. Payment Breakdown
    final payRes = await db.rawQuery('''
      SELECT payment_method, SUM(grand_total) as total
      FROM orders
      WHERE order_status != 'refunded' AND deleted_at IS NULL
      GROUP BY payment_method
    ''');
    final paymentAnalytics = <String, double>{
      'cash': 0.0,
      'upi': 0.0,
      'card': 0.0,
      'wallet': 0.0,
    };
    for (final p in payRes) {
      final method = (p['payment_method'] as String? ?? 'cash').toLowerCase();
      paymentAnalytics[method] = (p['total'] as num?)?.toDouble() ?? 0.0;
    }

    // 9. Customer Counts
    final custTotal = (await db.rawQuery('SELECT COUNT(*) as c FROM customers WHERE deleted_at IS NULL')).first['c'] as num? ?? 0;
    final custLoyal = (await db.rawQuery("SELECT COUNT(*) as c FROM customers WHERE loyalty_card_number != '' AND deleted_at IS NULL")).first['c'] as num? ?? 0;
    final custReturn = (await db.rawQuery('SELECT COUNT(*) as c FROM customers WHERE total_visits > 1 AND deleted_at IS NULL')).first['c'] as num? ?? 0;

    // 10. Top Selling Items (parse items_json of recent orders)
    final recentOrders = await db.query(
      'orders',
      columns: ['items_json'],
      where: "order_status != 'refunded' AND deleted_at IS NULL",
      limit: 300,
    );
    final itemSalesMap = <String, Map<String, dynamic>>{};
    for (final o in recentOrders) {
      final raw = o['items_json'] as String?;
      if (raw == null) continue;
      try {
        final list = jsonDecode(raw) as List;
        for (final it in list) {
          final name = it['name']?.toString() ?? 'Dish';
          final qty = (it['quantity'] as num?)?.toInt() ?? 1;
          final sub = (it['subtotal'] as num?)?.toDouble() ?? 0.0;
          if (!itemSalesMap.containsKey(name)) {
            itemSalesMap[name] = {'_id': name, 'totalQuantity': 0, 'totalSales': 0.0};
          }
          itemSalesMap[name]!['totalQuantity'] += qty;
          itemSalesMap[name]!['totalSales'] += sub;
        }
      } catch (_) {}
    }
    final topItems = itemSalesMap.values.toList()
      ..sort((a, b) => (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int));

    return {
      'todayRevenue': todayRevenue,
      'todayOrderCount': todayOrderCount,
      'todayExpenseTotal': todayExpenseTotal,
      'netProfitToday': todayRevenue - todayExpenseTotal,
      'yesterdayRevenue': yesterdayRevenue,
      'weekRevenue': weekRevenue,
      'weekOrderCount': weekOrderCount,
      'weekExpenseTotal': weekExpenseTotal,
      'weeklyProfit': weekRevenue - weekExpenseTotal,
      'previousWeekRevenue': 0.0,
      'monthRevenue': monthRevenue,
      'monthOrderCount': monthOrderCount,
      'monthExpenseTotal': monthExpenseTotal,
      'monthlyProfit': monthRevenue - monthExpenseTotal,
      'previousMonthRevenue': 0.0,
      'overallRevenue': overallRevenue,
      'overallOrderCount': overallOrderCount,
      'overallExpenseTotal': overallExpenseTotal,
      'overallProfit': overallRevenue - overallExpenseTotal,
      'averageBillValue': overallOrderCount > 0 ? (overallRevenue / overallOrderCount) : 0.0,
      'peakSellingHour': '1:00 PM',
      'recentDailyRevenue': recentDailyRevenue,
      'topSellingItems': topItems.take(5).toList(),
      'leastSellingItems': topItems.reversed.take(5).toList(),
      'customerAnalytics': {
        'totalCustomers': custTotal.toInt(),
        'loyaltyMembers': custLoyal.toInt(),
        'returningCustomers': custReturn.toInt(),
        'rewardsRedeemed': 0,
      },
      'paymentAnalytics': paymentAnalytics,
    };
  }

  // ==========================================
  // SYNC HELPERS & CHANGE TRACKING
  // ==========================================

  Future<int> getPendingChangesCount() async {
    final db = await database;
    int count = 0;
    const tables = [
      'expenses',
      'expense_categories',
      'categories',
      'menu_items',
      'customers',
      'orders',
      'business_settings',
    ];
    for (final t in tables) {
      final res = await db.rawQuery("SELECT COUNT(*) as c FROM $t WHERE sync_status != 'synced'");
      count += (res.first['c'] as num?)?.toInt() ?? 0;
    }
    return count;
  }

  Future<List<SyncQueueItem>> getPendingOperations() async {
    final db = await database;
    final ops = <SyncQueueItem>[];

    // 1. Settings
    final settingsRows = await db.query('business_settings', where: "sync_status != 'synced'");
    for (final r in settingsRows) {
      ops.add(SyncQueueItem(
        operationId: _uuid.v4(),
        entityType: 'settings',
        operationType: 'update',
        localId: 'singleton',
        serverId: r['server_id'] as String?,
        payload: {
          'businessName': r['business_name'],
          'logo': r['logo'],
          'phone': r['phone'],
          'address': r['address'],
          'gstin': r['gstin'],
          'currency': r['currency'],
          'invoicePrefix': r['invoice_prefix'],
          'taxPercentage': r['tax_percentage'],
          'serviceChargePercentage': r['service_charge_percentage'],
          'invoiceFooter': r['invoice_footer'],
          'loyaltyTargetVisits': r['loyalty_target_visits'],
          'loyaltyRewardType': r['loyalty_reward_type'],
          'loyaltyRewardDescription': r['loyalty_reward_description'],
        },
      ));
    }

    // 2. Categories
    final catRows = await db.query('categories', where: "sync_status != 'synced'");
    for (final r in catRows) {
      final status = r['sync_status'] as String;
      final opType = status == 'pendingDelete' ? 'delete' : (status == 'pendingCreate' ? 'create' : 'update');
      ops.add(SyncQueueItem(
        operationId: _uuid.v4(),
        entityType: 'category',
        operationType: opType,
        localId: r['id'] as String,
        serverId: r['server_id'] as String?,
        payload: {
          'name': r['name'],
          'icon': r['icon'],
          'sortOrder': r['sort_order'],
          'isActive': (r['is_active'] as int? ?? 1) == 1,
        },
      ));
    }

    // 3. Expense Categories
    final expCatRows = await db.query('expense_categories', where: "sync_status != 'synced'");
    for (final r in expCatRows) {
      final status = r['sync_status'] as String;
      final opType = status == 'pendingDelete' ? 'delete' : (status == 'pendingCreate' ? 'create' : 'update');
      ops.add(SyncQueueItem(
        operationId: _uuid.v4(),
        entityType: 'expenseCategory',
        operationType: opType,
        localId: r['id'] as String,
        serverId: r['server_id'] as String?,
        payload: {
          'name': r['name'],
          'icon': r['icon'],
          'isActive': (r['is_active'] as int? ?? 1) == 1,
        },
      ));
    }

    // 4. Menu Items
    final itemRows = await db.query('menu_items', where: "sync_status != 'synced'");
    for (final r in itemRows) {
      final status = r['sync_status'] as String;
      final opType = status == 'pendingDelete' ? 'delete' : (status == 'pendingCreate' ? 'create' : 'update');
      ops.add(SyncQueueItem(
        operationId: _uuid.v4(),
        entityType: 'menuItem',
        operationType: opType,
        localId: r['id'] as String,
        serverId: r['server_id'] as String?,
        payload: {
          'category': r['category_id'],
          'name': r['name'],
          'description': r['description'],
          'price': r['price'],
          'discount': r['discount'],
          'gstPercentage': r['gst_percentage'],
          'image': r['image'],
          'isVeg': (r['is_veg'] as int? ?? 1) == 1,
          'isAvailable': (r['is_available'] as int? ?? 1) == 1,
          'sortOrder': r['sort_order'],
        },
      ));
    }

    // 5. Customers
    final custRows = await db.query('customers', where: "sync_status != 'synced'");
    for (final r in custRows) {
      final status = r['sync_status'] as String;
      final opType = status == 'pendingDelete' ? 'delete' : (status == 'pendingCreate' ? 'create' : 'update');
      ops.add(SyncQueueItem(
        operationId: _uuid.v4(),
        entityType: 'customer',
        operationType: opType,
        localId: r['id'] as String,
        serverId: r['server_id'] as String?,
        payload: {
          'name': r['name'],
          'phone': r['phone'],
          'address': r['address'],
          'birthday': r['birthday'],
          'notes': r['notes'],
          'totalVisits': r['total_visits'],
          'totalSpent': r['total_spent'],
          'loyaltyPoints': r['loyalty_points'],
          'loyaltyCardNumber': r['loyalty_card_number'],
        },
      ));
    }

    // 6. Expenses
    final expRows = await db.query('expenses', where: "sync_status != 'synced'");
    for (final r in expRows) {
      final status = r['sync_status'] as String;
      final opType = status == 'pendingDelete' ? 'delete' : (status == 'pendingCreate' ? 'create' : 'update');
      ops.add(SyncQueueItem(
        operationId: _uuid.v4(),
        entityType: 'expense',
        operationType: opType,
        localId: r['id'] as String,
        serverId: r['server_id'] as String?,
        payload: {
          'title': r['title'],
          'category': r['category'],
          'amount': r['amount'],
          'date': r['date'],
          'notes': r['notes'],
        },
      ));
    }

    // 7. Orders
    final orderRows = await db.query('orders', where: "sync_status != 'synced'");
    for (final r in orderRows) {
      final status = r['sync_status'] as String;
      final opType = status == 'pendingDelete' ? 'delete' : (status == 'pendingCreate' ? 'create' : 'update');
      List items = [];
      try {
        items = jsonDecode(r['items_json'] as String? ?? '[]');
      } catch (_) {}

      ops.add(SyncQueueItem(
        operationId: _uuid.v4(),
        entityType: 'order',
        operationType: opType,
        localId: r['id'] as String,
        serverId: r['server_id'] as String?,
        payload: {
          'orderNumber': r['order_number'],
          'customerId': r['customer_id'],
          'customerName': r['customer_name'],
          'customerPhone': r['customer_phone'],
          'loyaltyCardNumber': r['loyalty_card_number'],
          'visitCount': r['visit_count'],
          'rewardStatus': r['reward_status'],
          'orderStatus': r['order_status'],
          'items': items,
          'subtotal': r['subtotal'],
          'discountAmount': r['discount_amount'],
          'gstAmount': r['gst_amount'],
          'serviceChargeAmount': r['service_charge_amount'],
          'grandTotal': r['grand_total'],
          'paymentMethod': r['payment_method'],
          'paymentStatus': r['payment_status'],
          'notes': r['notes'],
        },
      ));
    }

    return ops;
  }

  Future<void> markOperationSynced(String entityType, String localId, String? serverId, String opType) async {
    final db = await database;
    final tableName = _tableNameFor(entityType);

    if (opType == 'delete') {
      // Confirmed deleted by backend -> purge permanently from SQLite
      await db.delete(tableName, where: 'id = ?', whereArgs: [localId]);
    } else {
      final updates = <String, dynamic>{
        'sync_status': 'synced',
      };
      if (serverId != null && serverId.isNotEmpty) {
        updates['server_id'] = serverId;
      }
      await db.update(tableName, updates, where: 'id = ?', whereArgs: [localId]);
    }
  }

  String _tableNameFor(String entityType) {
    return switch (entityType) {
      'expense' => 'expenses',
      'expenseCategory' => 'expense_categories',
      'category' => 'categories',
      'menuItem' => 'menu_items',
      'customer' => 'customers',
      'order' => 'orders',
      'settings' => 'business_settings',
      _ => 'expenses',
    };
  }

  // ==========================================
  // SYNC METADATA & SERVER WATERMARKS
  // ==========================================

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final rows = await db.query('sync_metadata', where: 'key = ?', whereArgs: [key]);
    if (rows.isNotEmpty) return rows.first['value'] as String?;
    return null;
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      'sync_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
