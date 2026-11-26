import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../models/business_settings_model.dart';
import '../../models/category_model.dart';
import '../../models/customer_model.dart';
import '../../models/expense_category_model.dart';
import '../../models/expense_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/order_model.dart';
import 'sync_queue_item.dart';

/// Tracks which years, months, and calendar days actually hold recorded data
/// so date/month/year pickers can dim and disable empty periods.
class AvailableDataDates {
  final Set<String> months; // 'yyyy-MM'
  final Set<String> days;   // 'yyyy-MM-dd'
  final Set<int> years;     // e.g. 2026
  final DateTime? earliestDate;
  final DateTime? latestDate;

  const AvailableDataDates({
    this.months = const {},
    this.days = const {},
    this.years = const {},
    this.earliestDate,
    this.latestDate,
  });

  static const empty = AvailableDataDates();

  bool get isEmpty => months.isEmpty;
  bool get isNotEmpty => months.isNotEmpty;

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool hasMonth(int year, int month) =>
      months.contains('$year-${month.toString().padLeft(2, '0')}');

  bool hasMonthForDate(DateTime day) =>
      months.contains(monthKey(day));

  bool hasDay(DateTime day) =>
      days.contains(dayKey(day));

  /// Ascending list of month-start dates (`DateTime(y, m, 1)`) where data exists.
  List<DateTime> get sortedMonths {
    final parsed = <DateTime>[];
    for (final ym in months) {
      final parts = ym.split('-');
      if (parts.length == 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          parsed.add(DateTime(y, m, 1));
        }
      }
    }
    parsed.sort();
    return parsed;
  }

  /// Resolves assertion-safe `firstDate`, `lastDate`, `initialDate`, and
  /// `selectableDayPredicate` for Flutter's `showDatePicker`.
  /// Months with no recorded data are dimmed and unclickable.
  ({
    DateTime firstDate,
    DateTime lastDate,
    DateTime initialDate,
    bool Function(DateTime) selectableDayPredicate,
  }) buildPickerConstraints({
    required DateTime candidateInitialDate,
    DateTime? minFirstDate,
    DateTime? maxLastDate,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upperBound = maxLastDate == null
        ? today
        : (maxLastDate.isAfter(today)
            ? today
            : DateTime(maxLastDate.year, maxLastDate.month, maxLastDate.day));

    if (months.isEmpty) {
      var first = minFirstDate != null
          ? DateTime(minFirstDate.year, minFirstDate.month, minFirstDate.day)
          : today;
      var last = upperBound;
      if (first.isAfter(last)) first = last;
      var init = DateTime(
        candidateInitialDate.year,
        candidateInitialDate.month,
        candidateInitialDate.day,
      );
      if (init.isBefore(first)) init = first;
      if (init.isAfter(last)) init = last;
      return (
        firstDate: first,
        lastDate: last,
        initialDate: init,
        selectableDayPredicate: (d) =>
            d.year == init.year && d.month == init.month && d.day == init.day,
      );
    }

    final sortedM = sortedMonths;
    final earliestMonthStart = DateTime(sortedM.first.year, sortedM.first.month, 1);
    final latestMonthEnd = DateTime(sortedM.last.year, sortedM.last.month + 1, 0);

    var first = earliestMonthStart;
    if (minFirstDate != null) {
      final minDay = DateTime(
        minFirstDate.year,
        minFirstDate.month,
        minFirstDate.day,
      );
      if (minDay.isAfter(first)) first = minDay;
    }

    var last = latestMonthEnd.isAfter(upperBound) ? upperBound : latestMonthEnd;
    if (first.isAfter(last)) {
      first = last;
    }

    bool predicate(DateTime day) {
      final d = DateTime(day.year, day.month, day.day);
      if (d.isBefore(first) || d.isAfter(last)) return false;
      return months.contains(monthKey(d));
    }

    var init = DateTime(
      candidateInitialDate.year,
      candidateInitialDate.month,
      candidateInitialDate.day,
    );
    if (init.isBefore(first)) init = first;
    if (init.isAfter(last)) init = last;

    if (!predicate(init)) {
      DateTime? best;
      int bestDiff = 1 << 30;
      for (final mStart in sortedM) {
        final mLastDay = DateTime(mStart.year, mStart.month + 1, 0);
        final segStart = mStart.isBefore(first) ? first : mStart;
        final segEnd = mLastDay.isAfter(last) ? last : mLastDay;
        if (segStart.isAfter(segEnd)) continue;

        final candidate = init.isBefore(segStart)
            ? segStart
            : (init.isAfter(segEnd) ? segEnd : init);
        final diff = (candidate.difference(init).inDays).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          best = candidate;
        }
      }
      if (best != null) {
        init = best;
      } else {
        return (
          firstDate: first,
          lastDate: last,
          initialDate: init,
          selectableDayPredicate: (d) =>
              d.year == init.year && d.month == init.month && d.day == init.day,
        );
      }
    }

    return (
      firstDate: first,
      lastDate: last,
      initialDate: init,
      selectableDayPredicate: predicate,
    );
  }
}

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
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'foodbillx_local.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureIndexes(db);
      },
      onOpen: (db) async {
        await _ensureIndexes(db);
      },
    );
  }

  Future<void> _ensureIndexes(DatabaseExecutor db) async {
    const statements = [
      'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);',
      'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);',
      'CREATE INDEX IF NOT EXISTS idx_expenses_sync ON expenses(sync_status);',
      'CREATE INDEX IF NOT EXISTS idx_expenses_deleted ON expenses(deleted_at);',
      'CREATE INDEX IF NOT EXISTS idx_expenses_deleted_date ON expenses(deleted_at, date);',
      'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);',
      'CREATE INDEX IF NOT EXISTS idx_customers_card ON customers(loyalty_card_number);',
      'CREATE INDEX IF NOT EXISTS idx_customers_deleted_visits ON customers(deleted_at, total_visits DESC, name ASC);',
      'CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at);',
      'CREATE INDEX IF NOT EXISTS idx_orders_status_deleted_created ON orders(deleted_at, order_status, created_at);',
      'CREATE INDEX IF NOT EXISTS idx_orders_payment ON orders(payment_method, created_at);',
      'CREATE INDEX IF NOT EXISTS idx_menu_items_cat_deleted ON menu_items(category_id, deleted_at, sort_order);',
    ];
    for (final stmt in statements) {
      await db.execute(stmt);
    }
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
      'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
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
    if (data.containsKey('amount')) updateFields['amount'] = (data['amount'] as num?)?.toDouble() ?? 0.0;
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
    final todayDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final db = await database;
    final res = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE (date LIKE ? OR (date >= ? AND date <= ?)) AND deleted_at IS NULL',
      ['$todayDateStr%', startOfDay, endOfDay],
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
    if (data.containsKey('taxPercentage')) {
      row['tax_percentage'] = (data['taxPercentage'] as num?)?.toDouble() ?? 0.0;
    }
    if (data.containsKey('serviceChargePercentage')) {
      row['service_charge_percentage'] = (data['serviceChargePercentage'] as num?)?.toDouble() ?? 0.0;
    }
    if (data.containsKey('invoiceFooter')) row['invoice_footer'] = data['invoiceFooter'];
    if (data.containsKey('loyaltyTargetVisits')) {
      row['loyalty_target_visits'] = (data['loyaltyTargetVisits'] as num?)?.toInt() ?? 6;
    }
    if (data.containsKey('loyaltyRewardType')) row['loyalty_reward_type'] = data['loyaltyRewardType'];
    if (data.containsKey('loyaltyRewardDescription')) {
      row['loyalty_reward_description'] = data['loyaltyRewardDescription'];
    }
    if (data.containsKey('monthlyExpenseBudget')) {
      row['monthly_expense_budget'] = (data['monthlyExpenseBudget'] as num?)?.toDouble() ?? 0.0;
    }

    final count = await db.update('business_settings', row, where: 'id = ?', whereArgs: ['singleton']);
    if (count == 0) {
      await db.insert('business_settings', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    final updated = await getSettings();
    if (updated != null) return updated;

    return BusinessSettingsModel(
      id: 'singleton',
      businessName: data['businessName'] as String? ?? 'HMB Bills',
      logo: data['logo'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      gstin: data['gstin'] as String? ?? '',
      currency: data['currency'] as String? ?? '₹',
      invoicePrefix: data['invoicePrefix'] as String? ?? 'B',
      taxPercentage: (data['taxPercentage'] as num?)?.toDouble() ?? 0.0,
      serviceChargePercentage: (data['serviceChargePercentage'] as num?)?.toDouble() ?? 0.0,
      invoiceFooter: data['invoiceFooter'] as String? ?? 'Thank you for dining with us!',
      loyaltyTargetVisits: (data['loyaltyTargetVisits'] as num?)?.toInt() ?? 6,
      loyaltyRewardType: data['loyaltyRewardType'] as String? ?? 'Free Drink',
      loyaltyRewardDescription: data['loyaltyRewardDescription'] as String? ?? 'Free Drink',
    );
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
    if (data.containsKey('totalVisits')) updates['total_visits'] = (data['totalVisits'] as num?)?.toInt() ?? 0;
    if (data.containsKey('totalSpent')) updates['total_spent'] = (data['totalSpent'] as num?)?.toDouble() ?? 0.0;
    if (data.containsKey('loyaltyPoints')) updates['loyalty_points'] = (data['loyaltyPoints'] as num?)?.toInt() ?? 0;

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
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final cleanPrefix = prefix.trim().isNotEmpty ? prefix.trim() : 'B';
    final pattern = '$cleanPrefix-$dateStr-%';

    final db = await database;
    final rows = await db.rawQuery(
      'SELECT order_number FROM orders WHERE order_number LIKE ?',
      [pattern],
    );

    int maxSeq = 0;
    for (final row in rows) {
      final numStr = row['order_number'] as String?;
      if (numStr != null) {
        final parts = numStr.split('-');
        if (parts.isNotEmpty) {
          final lastPart = int.tryParse(parts.last);
          if (lastPart != null && lastPart > maxSeq) {
            maxSeq = lastPart;
          }
        }
      }
    }

    int nextSeq = maxSeq + 1;
    String candidate = '$cleanPrefix-$dateStr-${nextSeq.toString().padLeft(3, '0')}';

    while (true) {
      final existing = await db.query(
        'orders',
        columns: ['id'],
        where: 'order_number = ?',
        whereArgs: [candidate],
        limit: 1,
      );
      if (existing.isEmpty) break;
      nextSeq++;
      candidate = '$cleanPrefix-$dateStr-${nextSeq.toString().padLeft(3, '0')}';
    }

    return candidate;
  }

  Future<OrderModel> insertOrder({
    String? orderNumber,
    String? prefix,
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
    DateTime? createdAt,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = (createdAt ?? DateTime.now()).toIso8601String();

    final finalOrderNumber = orderNumber != null && orderNumber.isNotEmpty
        ? orderNumber
        : await generateNextOrderNumber(prefix ?? 'B');

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

    await db.insert('orders', row, conflictAlgorithm: ConflictAlgorithm.replace);

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

  /// Deletes an order from the database and decrements matching customer totals
  /// in the same transaction so all sales, profits, dishes, and customer metrics update accurately.
  Future<bool> deleteOrderAndRecalculate(String id) async {
    final db = await database;
    return await db.transaction((txn) async {
      final rows = await txn.query(
        'orders',
        columns: ['id', 'server_id', 'sync_status', 'order_status', 'customer_phone', 'grand_total'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return false;

      final orderRow = rows.first;
      final serverId = orderRow['server_id'] as String?;
      final syncStatus = orderRow['sync_status'] as String?;
      final status = (orderRow['order_status'] as String? ?? 'completed').toLowerCase();
      final phone = (orderRow['customer_phone'] as String? ?? '').trim();
      final total = (orderRow['grand_total'] as num?)?.toDouble() ?? 0.0;

      if (status != 'refunded' && phone.isNotEmpty) {
        final custRows = await txn.query(
          'customers',
          columns: ['id', 'total_visits', 'total_spent', 'sync_status'],
          where: 'phone = ? AND deleted_at IS NULL',
          whereArgs: [phone],
          limit: 1,
        );
        if (custRows.isNotEmpty) {
          final cust = custRows.first;
          final currentVisits = (cust['total_visits'] as num?)?.toInt() ?? 0;
          final currentSpent = (cust['total_spent'] as num?)?.toDouble() ?? 0.0;
          final newVisits = currentVisits > 0 ? currentVisits - 1 : 0;
          final newSpent = (currentSpent - total) > 0 ? (currentSpent - total) : 0.0;
          final currentSync = cust['sync_status'] as String? ?? 'synced';
          final newSync = currentSync == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';

          await txn.update(
            'customers',
            {
              'total_visits': newVisits,
              'total_spent': newSpent,
              'updated_at': DateTime.now().toIso8601String(),
              'sync_status': newSync,
            },
            where: 'id = ?',
            whereArgs: [cust['id']],
          );
        }
      }

      if (serverId == null || serverId.isEmpty || syncStatus == 'pendingCreate') {
        final deletedCount = await txn.delete('orders', where: 'id = ?', whereArgs: [id]);
        return deletedCount > 0;
      }

      final now = DateTime.now().toIso8601String();
      final updatedCount = await txn.update(
        'orders',
        {
          'deleted_at': now,
          'sync_status': 'pendingDelete',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return updatedCount > 0;
    });
  }

  /// Updates an existing order's customer metadata, payment method, items, totals,
  /// and adjusts any matched customer's total_spent delta inside a single transaction.
  Future<OrderModel?> updateOrderDetails({
    required String id,
    required String customerName,
    required String customerPhone,
    required String paymentMethod,
    required List<OrderItemModel> items,
    required double subtotal,
    required double discountAmount,
    required double serviceChargeAmount,
    required double grandTotal,
    String notes = '',
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final existingRows = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existingRows.isEmpty) return null;

      final prev = existingRows.first;
      final prevTotal = (prev['grand_total'] as num?)?.toDouble() ?? 0.0;
      final prevPhone = (prev['customer_phone'] as String? ?? '').trim();
      final prevStatus = (prev['order_status'] as String? ?? 'completed').toLowerCase();
      final currentSync = prev['sync_status'] as String? ?? 'synced';
      final newSync = currentSync == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';
      final now = DateTime.now().toIso8601String();
      final trimmedPhone = customerPhone.trim();

      if (prevStatus != 'refunded' && prevPhone.isNotEmpty) {
        final totalDelta = grandTotal - prevTotal;
        if (totalDelta.abs() > 0.001) {
          final custRows = await txn.query(
            'customers',
            columns: ['id', 'total_spent', 'sync_status'],
            where: 'phone = ? AND deleted_at IS NULL',
            whereArgs: [prevPhone],
            limit: 1,
          );
          if (custRows.isNotEmpty) {
            final cust = custRows.first;
            final oldSpent = (cust['total_spent'] as num?)?.toDouble() ?? 0.0;
            final updatedSpent = (oldSpent + totalDelta) > 0 ? (oldSpent + totalDelta) : 0.0;
            final cSync = cust['sync_status'] as String? ?? 'synced';
            await txn.update(
              'customers',
              {
                'total_spent': updatedSpent,
                'updated_at': now,
                'sync_status': cSync == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate',
              },
              where: 'id = ?',
              whereArgs: [cust['id']],
            );
          }
        }
      }

      final itemsJson = jsonEncode(items.map((i) => i.toJson()).toList());
      await txn.update(
        'orders',
        {
          'customer_name': customerName.trim().isNotEmpty ? customerName.trim() : 'Walk-in Customer',
          'customer_phone': trimmedPhone,
          'payment_method': paymentMethod.toLowerCase(),
          'items_json': itemsJson,
          'subtotal': subtotal,
          'discount_amount': discountAmount,
          'service_charge_amount': serviceChargeAmount,
          'grand_total': grandTotal,
          'notes': notes,
          'updated_at': now,
          'sync_status': newSync,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      final updatedRows = await txn.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
      if (updatedRows.isEmpty) return null;
      return _mapToOrder(updatedRows.first);
    });
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
    final todayDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final expToday = await db.rawQuery('''
      SELECT SUM(amount) as exp FROM expenses 
      WHERE (date LIKE ? OR (date >= ? AND date <= ?)) AND deleted_at IS NULL
    ''', ['$todayDateStr%', todayStart, todayEnd]);
    final todayExpenseTotal = (expToday.first['exp'] as num?)?.toDouble() ?? 0.0;

    final weekDt = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekDateStr = '${weekDt.year}-${weekDt.month.toString().padLeft(2, '0')}-${weekDt.day.toString().padLeft(2, '0')}';
    final monthDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

    final expWeek = await db.rawQuery('''
      SELECT SUM(amount) as exp FROM expenses 
      WHERE ((date >= ? AND date <= ?) OR (date >= ? AND date <= ?)) AND deleted_at IS NULL
    ''', [weekStart, todayEnd, weekDateStr, '$todayDateStr~']);
    final weekExpenseTotal = (expWeek.first['exp'] as num?)?.toDouble() ?? 0.0;

    final expMonth = await db.rawQuery('''
      SELECT SUM(amount) as exp FROM expenses 
      WHERE ((date >= ? AND date <= ?) OR (date >= ? AND date <= ?)) AND deleted_at IS NULL
    ''', [monthStart, todayEnd, monthDateStr, '$todayDateStr~']);
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

    // Current calendar week daily revenue: Monday to Sunday (7 slots)
    // Ensures Monday's sale always appears under Monday (index 0)
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final currentWeekDailyRevenue = <double>[];
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (day.isAfter(now)) {
        currentWeekDailyRevenue.add(0.0);
      } else {
        final dStart = DateTime(day.year, day.month, day.day).toIso8601String();
        final dEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999).toIso8601String();
        final dayRes = await db.rawQuery('''
          SELECT SUM(grand_total) as rev
          FROM orders
          WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
        ''', [dStart, dEnd]);
        currentWeekDailyRevenue.add((dayRes.first['rev'] as num?)?.toDouble() ?? 0.0);
      }
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

    // 10. Top Selling Items (parse items_json of most recent 300 orders)
    final recentOrders = await db.query(
      'orders',
      columns: ['items_json'],
      where: "order_status != 'refunded' AND deleted_at IS NULL",
      orderBy: 'created_at DESC',
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
          final entry = itemSalesMap.putIfAbsent(name, () => {'_id': name, 'totalQuantity': 0, 'totalSales': 0.0});
          entry['totalQuantity'] = (entry['totalQuantity'] as int? ?? 0) + qty;
          entry['totalSales'] = (entry['totalSales'] as num? ?? 0.0).toDouble() + sub;
        }
      } catch (_) {}
    }
    final topItems = itemSalesMap.values.toList()
      ..sort((a, b) => (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int));

    // Previous week boundaries for real comparison
    final prevWeekStart = DateTime.parse(weekStart).subtract(const Duration(days: 7)).toIso8601String();
    final prevWeekEnd = weekStart;
    final prevWeekRes = await db.rawQuery('''
      SELECT SUM(grand_total) as rev
      FROM orders
      WHERE created_at >= ? AND created_at < ? AND order_status != 'refunded' AND deleted_at IS NULL
    ''', [prevWeekStart, prevWeekEnd]);
    final previousWeekRevenue = (prevWeekRes.first['rev'] as num?)?.toDouble() ?? 0.0;

    // Previous month boundaries for real comparison
    final prevMonthYear = now.month == 1 ? now.year - 1 : now.year;
    final prevMonthMonth = now.month == 1 ? 12 : now.month - 1;
    final prevMonthStart = DateTime(prevMonthYear, prevMonthMonth, 1).toIso8601String();
    final prevMonthEnd = monthStart;
    final prevMonthRes = await db.rawQuery('''
      SELECT SUM(grand_total) as rev
      FROM orders
      WHERE created_at >= ? AND created_at < ? AND order_status != 'refunded' AND deleted_at IS NULL
    ''', [prevMonthStart, prevMonthEnd]);
    final previousMonthRevenue = (prevMonthRes.first['rev'] as num?)?.toDouble() ?? 0.0;

    // Real hourly buckets for Today (6 blocks of 4 hours: 12-4 AM, 4-8 AM, 8-12 PM, 12-4 PM, 4-8 PM, 8-12 AM)
    final hourlyRevenueToday = List<double>.filled(6, 0.0);
    final todayOrders = await db.query(
      'orders',
      columns: ['created_at', 'grand_total', 'payment_method', 'items_json'],
      where: "created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL",
      whereArgs: [todayStart, todayEnd],
    );

    final todayItemSales = <String, int>{};
    final todayPaymentCounts = <String, double>{'cash': 0.0, 'upi': 0.0, 'card': 0.0};

    for (final o in todayOrders) {
      final total = (o['grand_total'] as num?)?.toDouble() ?? 0.0;
      final createdAtStr = o['created_at'] as String?;
      if (createdAtStr != null) {
        try {
          final dt = DateTime.parse(createdAtStr);
          final hour = dt.hour;
          final bucket = (hour / 4).floor().clamp(0, 5);
          hourlyRevenueToday[bucket] += total;
        } catch (_) {}
      }

      final pay = (o['payment_method'] as String? ?? 'cash').toLowerCase();
      todayPaymentCounts[pay] = (todayPaymentCounts[pay] ?? 0.0) + total;

      final itemsRaw = o['items_json'] as String?;
      if (itemsRaw != null) {
        try {
          final list = jsonDecode(itemsRaw) as List;
          for (final it in list) {
            final name = it['name']?.toString() ?? 'Dish';
            final qty = (it['quantity'] as num?)?.toInt() ?? 1;
            todayItemSales[name] = (todayItemSales[name] ?? 0) + qty;
          }
        } catch (_) {}
      }
    }

    // Helper to extract dish breakdown from orders
    List<Map<String, dynamic>> extractDishBreakdown(List<Map<String, dynamic>> ordersRows) {
      final dishMap = <String, Map<String, dynamic>>{};
      for (final o in ordersRows) {
        final raw = o['items_json'] as String?;
        if (raw == null) continue;
        try {
          final list = jsonDecode(raw) as List;
          for (final it in list) {
            final name = it['name']?.toString() ?? 'Dish';
            final qty = (it['quantity'] as num?)?.toInt() ?? 1;
            final sub = (it['subtotal'] as num?)?.toDouble() ?? 0.0;
            final entry = dishMap.putIfAbsent(name, () => {'_id': name, 'name': name, 'totalQuantity': 0, 'totalSales': 0.0});
            entry['totalQuantity'] = (entry['totalQuantity'] as int? ?? 0) + qty;
            entry['totalSales'] = (entry['totalSales'] as num? ?? 0.0).toDouble() + sub;
          }
        } catch (_) {}
      }
      return dishMap.values.toList()
        ..sort((a, b) => (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int));
    }

    final todayDishBreakdown = extractDishBreakdown(todayOrders);

    final weekOrdersRows = await db.query(
      'orders',
      columns: ['items_json'],
      where: "created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL",
      whereArgs: [weekStart, todayEnd],
    );
    final weekDishBreakdown = extractDishBreakdown(weekOrdersRows);

    final monthOrdersRows = await db.query(
      'orders',
      columns: ['items_json'],
      where: "created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL",
      whereArgs: [monthStart, todayEnd],
    );
    final monthDishBreakdown = extractDishBreakdown(monthOrdersRows);
    final overallDishBreakdown = extractDishBreakdown(recentOrders);

    String todayTopDishName = '';
    int todayTopDishCount = 0;
    if (todayDishBreakdown.isNotEmpty) {
      todayTopDishName = todayDishBreakdown.first['name'] as String? ?? '';
      todayTopDishCount = todayDishBreakdown.first['totalQuantity'] as int? ?? 0;
    }

    // Weekly intervals for the current month (5 slots)
    final monthlyWeeklyRevenue = List<double>.filled(5, 0.0);
    for (int w = 0; w < 5; w++) {
      final wStart = DateTime(now.year, now.month, 1 + (w * 7)).toIso8601String();
      final endDay = (1 + ((w + 1) * 7) - 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      final actualEndDay = endDay > lastDayOfMonth ? lastDayOfMonth : endDay;
      if (1 + (w * 7) <= lastDayOfMonth) {
        final wEnd = DateTime(now.year, now.month, actualEndDay, 23, 59, 59, 999).toIso8601String();
        final wRes = await db.rawQuery('''
          SELECT SUM(grand_total) as rev
          FROM orders
          WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
        ''', [wStart, wEnd]);
        monthlyWeeklyRevenue[w] = (wRes.first['rev'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // Real Peak Selling Hour (SQL-level GROUP BY for large-dataset speed)
    String peakSellingHour = 'No orders yet';
    if (overallOrderCount > 0) {
      final peakRows = await db.rawQuery('''
        SELECT CAST(substr(created_at, 12, 2) AS INTEGER) AS hr, COUNT(*) AS cnt
        FROM orders
        WHERE order_status != 'refunded' AND deleted_at IS NULL AND length(created_at) >= 13
        GROUP BY hr
        ORDER BY cnt DESC
        LIMIT 1
      ''');
      if (peakRows.isNotEmpty) {
        final peakH = ((peakRows.first['hr'] as num?)?.toInt() ?? 0).clamp(0, 23);
        final period = peakH >= 12 ? 'PM' : 'AM';
        final displayH = peakH == 0 ? 12 : (peakH > 12 ? peakH - 12 : peakH);
        final nextH = (peakH + 1) % 24;
        final nextPeriod = nextH >= 12 ? 'PM' : 'AM';
        final nextDisplayH = nextH == 0 ? 12 : (nextH > 12 ? nextH - 12 : nextH);
        peakSellingHour = '$displayH:00 $period - $nextDisplayH:00 $nextPeriod';
      }
    }

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
      'previousWeekRevenue': previousWeekRevenue,
      'monthRevenue': monthRevenue,
      'monthOrderCount': monthOrderCount,
      'monthExpenseTotal': monthExpenseTotal,
      'monthlyProfit': monthRevenue - monthExpenseTotal,
      'previousMonthRevenue': previousMonthRevenue,
      'overallRevenue': overallRevenue,
      'overallOrderCount': overallOrderCount,
      'overallExpenseTotal': overallExpenseTotal,
      'overallProfit': overallRevenue - overallExpenseTotal,
      'averageBillValue': overallOrderCount > 0 ? (overallRevenue / overallOrderCount) : 0.0,
      'peakSellingHour': peakSellingHour,
      'recentDailyRevenue': recentDailyRevenue,
      'currentWeekDailyRevenue': currentWeekDailyRevenue,
      'hourlyRevenueToday': hourlyRevenueToday,
      'monthlyWeeklyRevenue': monthlyWeeklyRevenue,
      'topSellingItems': topItems.take(5).toList(),
      'leastSellingItems': topItems.reversed.take(5).toList(),
      'todayDishBreakdown': todayDishBreakdown,
      'weekDishBreakdown': weekDishBreakdown,
      'monthDishBreakdown': monthDishBreakdown,
      'overallDishBreakdown': overallDishBreakdown,
      'todayTopDishName': todayTopDishName,
      'todayTopDishCount': todayTopDishCount,
      'todayPaymentBreakdown': todayPaymentCounts,
      'customerAnalytics': {
        'totalCustomers': custTotal.toInt(),
        'loyaltyMembers': custLoyal.toInt(),
        'returningCustomers': custReturn.toInt(),
        'rewardsRedeemed': 0,
      },
      'paymentAnalytics': paymentAnalytics,
    };
  }

  Future<Map<String, dynamic>> computePeriodReports({
    required String timeframe, // 'Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom', 'All Time'
    required DateTime referenceDate,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final db = await database;
    final now = DateTime.now();

    late DateTime startDate;
    late DateTime endDate;
    late DateTime priorStart;
    late DateTime priorEnd;
    List<String> chartLabels = [];
    List<double> chartDataPoints = [];

    switch (timeframe) {
      case 'Daily':
        startDate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, 0, 0, 0);
        endDate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, 23, 59, 59, 999);
        final priorDate = referenceDate.subtract(const Duration(days: 1));
        priorStart = DateTime(priorDate.year, priorDate.month, priorDate.day, 0, 0, 0);
        priorEnd = DateTime(priorDate.year, priorDate.month, priorDate.day, 23, 59, 59, 999);
        chartLabels = ['12-4A', '4-8A', '8-12P', '12-4P', '4-8P', '8-12A'];
        chartDataPoints = List<double>.filled(6, 0.0);
        break;

      case 'Weekly':
        final monday = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: referenceDate.weekday - 1));
        startDate = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        priorStart = startDate.subtract(const Duration(days: 7));
        priorEnd = endDate.subtract(const Duration(days: 7));
        chartLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        chartDataPoints = List<double>.filled(7, 0.0);
        break;

      case 'Monthly':
        startDate = DateTime(referenceDate.year, referenceDate.month, 1, 0, 0, 0);
        final lastDay = DateTime(referenceDate.year, referenceDate.month + 1, 0).day;
        endDate = DateTime(referenceDate.year, referenceDate.month, lastDay, 23, 59, 59, 999);

        final prevYear = referenceDate.month == 1 ? referenceDate.year - 1 : referenceDate.year;
        final prevMonth = referenceDate.month == 1 ? 12 : referenceDate.month - 1;
        final prevLastDay = DateTime(prevYear, prevMonth + 1, 0).day;
        priorStart = DateTime(prevYear, prevMonth, 1, 0, 0, 0);
        priorEnd = DateTime(prevYear, prevMonth, prevLastDay, 23, 59, 59, 999);

        chartLabels = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5'];
        chartDataPoints = List<double>.filled(5, 0.0);
        break;

      case 'Yearly':
        startDate = DateTime(referenceDate.year, 1, 1, 0, 0, 0);
        endDate = DateTime(referenceDate.year, 12, 31, 23, 59, 59, 999);
        priorStart = DateTime(referenceDate.year - 1, 1, 1, 0, 0, 0);
        priorEnd = DateTime(referenceDate.year - 1, 12, 31, 23, 59, 59, 999);
        chartLabels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
        chartDataPoints = List<double>.filled(12, 0.0);
        break;

      case 'Custom':
        final rawStart = customStartDate ?? referenceDate;
        final rawEnd = customEndDate ?? referenceDate;
        final orderedStart = rawStart.isAfter(rawEnd) ? rawEnd : rawStart;
        final orderedEnd = rawStart.isAfter(rawEnd) ? rawStart : rawEnd;
        startDate = DateTime(orderedStart.year, orderedStart.month, orderedStart.day, 0, 0, 0);
        endDate = DateTime(orderedEnd.year, orderedEnd.month, orderedEnd.day, 23, 59, 59, 999);
        final spanDays = endDate.difference(startDate).inDays + 1;
        priorEnd = startDate.subtract(const Duration(milliseconds: 1));
        priorStart = DateTime(startDate.year, startDate.month, startDate.day).subtract(Duration(days: spanDays));

        if (spanDays <= 1) {
          chartLabels = ['12-4A', '4-8A', '8-12P', '12-4P', '4-8P', '8-12A'];
          chartDataPoints = List<double>.filled(6, 0.0);
        } else if (spanDays <= 14) {
          chartLabels = List.generate(spanDays, (i) {
            final d = startDate.add(Duration(days: i));
            return DateFormat('d/M').format(d);
          });
          chartDataPoints = List<double>.filled(spanDays, 0.0);
        } else if (spanDays <= 90) {
          const buckets = 6;
          final step = (spanDays / buckets).ceil();
          chartLabels = List.generate(buckets, (i) {
            final d = startDate.add(Duration(days: (i * step).clamp(0, spanDays - 1)));
            return DateFormat('d MMM').format(d);
          });
          chartDataPoints = List<double>.filled(buckets, 0.0);
        } else {
          chartLabels = [];
          chartDataPoints = [];
        }
        break;

      case 'All Time':
      default:
        startDate = DateTime(2000, 1, 1);
        endDate = DateTime(2099, 12, 31, 23, 59, 59, 999);
        priorStart = startDate;
        priorEnd = endDate;
        break;
    }

    final startIso = startDate.toIso8601String();
    final endIso = endDate.toIso8601String();
    final priorStartIso = priorStart.toIso8601String();
    final priorEndIso = priorEnd.toIso8601String();

    // 1. Current Period Revenue & Order Count
    final ordersRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt, SUM(grand_total) as rev
      FROM orders
      WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
    ''', [startIso, endIso]);
    final revenue = (ordersRes.first['rev'] as num?)?.toDouble() ?? 0.0;
    final orderCount = (ordersRes.first['cnt'] as num?)?.toInt() ?? 0;

    // 2. Prior Period Revenue (for % change comparison)
    double priorRevenue = 0.0;
    if (timeframe != 'All Time') {
      final priorRes = await db.rawQuery('''
        SELECT SUM(grand_total) as rev
        FROM orders
        WHERE created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL
      ''', [priorStartIso, priorEndIso]);
      priorRevenue = (priorRes.first['rev'] as num?)?.toDouble() ?? 0.0;
    }

    // 3. Expenses in Period & Category Breakdown (safe for Weekly/Custom/Monthly/Yearly/Daily/All Time)
    final startDayStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endDayStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}~';

    final expRows = await db.rawQuery('''
      SELECT category, SUM(amount) as total, COUNT(*) as cnt
      FROM expenses
      WHERE (
        (date >= ? AND date <= ?) OR
        (date >= ? AND date <= ?)
      ) AND deleted_at IS NULL
      GROUP BY category
      ORDER BY total DESC
    ''', [startIso, endIso, startDayStr, endDayStr]);

    double expenses = 0.0;
    final expenseBreakdown = <Map<String, dynamic>>[];
    for (final row in expRows) {
      final amt = (row['total'] as num?)?.toDouble() ?? 0.0;
      expenses += amt;
      expenseBreakdown.add({
        'category': row['category'] as String? ?? 'Miscellaneous',
        'amount': amt,
        'count': (row['cnt'] as num?)?.toInt() ?? 0,
      });
    }

    // 4. Order rows details in Period (Dishes, Payments, Peak Hour, Chart Buckets)
    final periodOrders = await db.query(
      'orders',
      columns: ['created_at', 'grand_total', 'payment_method', 'items_json', 'customer_phone', 'customer_name'],
      where: "created_at >= ? AND created_at <= ? AND order_status != 'refunded' AND deleted_at IS NULL",
      whereArgs: [startIso, endIso],
    );

    final paymentAnalytics = <String, double>{
      'cash': 0.0,
      'upi': 0.0,
      'card': 0.0,
      'wallet': 0.0,
    };
    final dishMap = <String, Map<String, dynamic>>{};
    final hourHistogram = <int, int>{};
    final allTimeMonthlyMap = <String, double>{};
    final activeGuestKeys = <String>{};

    for (final o in periodOrders) {
      final total = (o['grand_total'] as num?)?.toDouble() ?? 0.0;
      final method = (o['payment_method'] as String? ?? 'cash').toLowerCase();
      paymentAnalytics[method] = (paymentAnalytics[method] ?? 0.0) + total;

      final phone = (o['customer_phone'] as String? ?? '').trim();
      final custName = (o['customer_name'] as String? ?? '').trim();
      if (phone.isNotEmpty) {
        activeGuestKeys.add(phone);
      } else if (custName.isNotEmpty && custName.toLowerCase() != 'guest' && custName.toLowerCase() != 'walk-in customer') {
        activeGuestKeys.add(custName.toLowerCase());
      }

      final createdAtStr = o['created_at'] as String?;
      if (createdAtStr != null) {
        try {
          final dt = DateTime.parse(createdAtStr).toLocal();
          hourHistogram[dt.hour] = (hourHistogram[dt.hour] ?? 0) + 1;

          switch (timeframe) {
            case 'Daily':
              final bucket = (dt.hour / 4).floor().clamp(0, 5);
              chartDataPoints[bucket] += total;
              break;
            case 'Weekly':
              final idx = (dt.weekday - 1).clamp(0, 6);
              chartDataPoints[idx] += total;
              break;
            case 'Monthly':
              final idx = ((dt.day - 1) ~/ 7).clamp(0, 4);
              chartDataPoints[idx] += total;
              break;
            case 'Yearly':
              final idx = (dt.month - 1).clamp(0, 11);
              chartDataPoints[idx] += total;
              break;
            case 'Custom':
              final spanDays = endDate.difference(startDate).inDays + 1;
              if (spanDays <= 1) {
                final bucket = (dt.hour / 4).floor().clamp(0, 5);
                chartDataPoints[bucket] += total;
              } else if (spanDays <= 14) {
                final dDiff = DateTime(dt.year, dt.month, dt.day)
                    .difference(DateTime(startDate.year, startDate.month, startDate.day))
                    .inDays
                    .clamp(0, spanDays - 1);
                chartDataPoints[dDiff] += total;
              } else if (spanDays <= 90) {
                const buckets = 6;
                final step = (spanDays / buckets).ceil();
                final dDiff = DateTime(dt.year, dt.month, dt.day)
                    .difference(DateTime(startDate.year, startDate.month, startDate.day))
                    .inDays;
                final idx = (dDiff ~/ step).clamp(0, buckets - 1);
                chartDataPoints[idx] += total;
              } else {
                final ym = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
                allTimeMonthlyMap[ym] = (allTimeMonthlyMap[ym] ?? 0.0) + total;
              }
              break;
            case 'All Time':
            default:
              final ym = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
              allTimeMonthlyMap[ym] = (allTimeMonthlyMap[ym] ?? 0.0) + total;
              break;
          }
        } catch (_) {}
      }

      final itemsRaw = o['items_json'] as String?;
      if (itemsRaw != null) {
        try {
          final list = jsonDecode(itemsRaw) as List;
          for (final it in list) {
            final name = it['name']?.toString() ?? 'Dish';
            final qty = (it['quantity'] as num?)?.toInt() ?? 1;
            final sub = (it['subtotal'] as num?)?.toDouble() ?? 0.0;
            final entry = dishMap.putIfAbsent(name, () => {'_id': name, 'name': name, 'totalQuantity': 0, 'totalSales': 0.0});
            entry['totalQuantity'] = (entry['totalQuantity'] as int? ?? 0) + qty;
            entry['totalSales'] = (entry['totalSales'] as num? ?? 0.0).toDouble() + sub;
          }
        } catch (_) {}
      }
    }

    if (timeframe == 'All Time' || (timeframe == 'Custom' && endDate.difference(startDate).inDays + 1 > 90)) {
      if (allTimeMonthlyMap.isNotEmpty) {
        final sortedKeys = allTimeMonthlyMap.keys.toList()..sort();
        final displayKeys = sortedKeys.length > 12 ? sortedKeys.sublist(sortedKeys.length - 12) : sortedKeys;
        if (displayKeys.length == 1) {
          // Show 5 preceding months leading up to the active month so chart draws smoothly
          final parts = displayKeys.first.split('-');
          final y = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          for (int k = 5; k >= 0; k--) {
            final t = DateTime(y, m - k, 1);
            final key = '${t.year}-${t.month.toString().padLeft(2, '0')}';
            chartLabels.add(DateFormat('MMM yy').format(t));
            chartDataPoints.add(allTimeMonthlyMap[key] ?? 0.0);
          }
        } else {
          for (final ym in displayKeys) {
            final parts = ym.split('-');
            final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
            chartLabels.add(displayKeys.length > 6 ? DateFormat('MMM').format(dt) : DateFormat('MMM yy').format(dt));
            chartDataPoints.add(allTimeMonthlyMap[ym] ?? 0.0);
          }
        }
      } else {
        for (int m = 5; m >= 0; m--) {
          final target = DateTime(now.year, now.month - m, 1);
          chartLabels.add(DateFormat('MMM').format(target));
          chartDataPoints.add(0.0);
        }
      }
    }

    final dishBreakdown = dishMap.values.toList()
      ..sort((a, b) => (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int));

    // Peak hour
    String peakSellingHour = 'No orders for this period';
    if (hourHistogram.isNotEmpty) {
      final sortedHours = hourHistogram.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final peakH = sortedHours.first.key;
      final period = peakH >= 12 ? 'PM' : 'AM';
      final displayH = peakH == 0 ? 12 : (peakH > 12 ? peakH - 12 : peakH);
      final nextH = (peakH + 1) % 24;
      final nextPeriod = nextH >= 12 ? 'PM' : 'AM';
      final nextDisplayH = nextH == 0 ? 12 : (nextH > 12 ? nextH - 12 : nextH);
      peakSellingHour = '$displayH:00 $period - $nextDisplayH:00 $nextPeriod';
    }

    // Customer analytics
    final custTotal = (await db.rawQuery('SELECT COUNT(*) as c FROM customers WHERE deleted_at IS NULL')).first['c'] as num? ?? 0;
    final custLoyal = (await db.rawQuery("SELECT COUNT(*) as c FROM customers WHERE loyalty_card_number != '' AND deleted_at IS NULL")).first['c'] as num? ?? 0;
    final custReturn = (await db.rawQuery('SELECT COUNT(*) as c FROM customers WHERE total_visits > 1 AND deleted_at IS NULL')).first['c'] as num? ?? 0;

    return {
      'revenue': revenue,
      'orderCount': orderCount,
      'expenses': expenses,
      'profit': revenue - expenses,
      'priorRevenue': priorRevenue,
      'averageBillValue': orderCount > 0 ? (revenue / orderCount) : 0.0,
      'peakSellingHour': peakSellingHour,
      'chartLabels': chartLabels,
      'chartDataPoints': chartDataPoints,
      'dishBreakdown': dishBreakdown,
      'paymentAnalytics': paymentAnalytics,
      'expenseBreakdown': expenseBreakdown,
      'customerAnalytics': {
        'totalCustomers': custTotal.toInt(),
        'loyaltyMembers': custLoyal.toInt(),
        'returningCustomers': custReturn.toInt(),
        'periodActiveGuests': activeGuestKeys.length,
        'rewardsRedeemed': 0,
      },
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  // ==========================================
  // SYNC HELPERS & CHANGE TRACKING
  // ==========================================

  String _normalizePaymentMethodForSync(String? raw) {
    final cleaned = (raw ?? 'cash').toLowerCase().trim();
    if (cleaned == 'cash' || cleaned == 'upi' || cleaned == 'card' || cleaned == 'wallet') {
      return cleaned;
    }
    if (cleaned.contains('upi') ||
        cleaned.contains('gpay') ||
        cleaned.contains('phonepe') ||
        cleaned.contains('paytm') ||
        cleaned.contains('qr') ||
        cleaned.contains('online') ||
        cleaned.contains('bank')) {
      return 'upi';
    }
    if (cleaned.contains('card') || cleaned.contains('credit') || cleaned.contains('debit')) {
      return 'card';
    }
    if (cleaned.contains('wallet')) {
      return 'wallet';
    }
    return 'cash';
  }

  String _normalizeOrderStatusForSync(String? raw) {
    final cleaned = (raw ?? 'completed').toLowerCase().trim();
    if (cleaned == 'completed' || cleaned == 'edited' || cleaned == 'refunded') {
      return cleaned;
    }
    return 'completed';
  }

  String _normalizePaymentStatusForSync(String? raw) {
    final cleaned = (raw ?? 'paid').toLowerCase().trim();
    if (cleaned == 'paid' || cleaned == 'pending') {
      return cleaned;
    }
    return 'paid';
  }

  String _resolveOperationType(String syncStatus, String? serverId) {
    if (syncStatus == 'pendingDelete') return 'delete';
    if (syncStatus == 'pendingCreate') return 'create';
    return (serverId == null || serverId.isEmpty) ? 'create' : 'update';
  }

  Future<int> getPendingChangesCount() async {
    final db = await database;
    int count = 0;
    const tables = [
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
      final businessName = (r['business_name'] as String?)?.trim() ?? '';
      ops.add(SyncQueueItem(
        operationId: 'settings:singleton:update:${r['updated_at'] ?? ''}',
        entityType: 'settings',
        operationType: 'update',
        localId: 'singleton',
        serverId: r['server_id'] as String?,
        payload: {
          'businessName': businessName.isNotEmpty ? businessName : 'HMB Bills',
          'logo': r['logo'] ?? '',
          'phone': r['phone'] ?? '',
          'address': r['address'] ?? '',
          'gstin': r['gstin'] ?? '',
          'currency': r['currency'] ?? '₹',
          'invoicePrefix': r['invoice_prefix'] ?? 'B',
          'taxPercentage': r['tax_percentage'] ?? 0.0,
          'serviceChargePercentage': r['service_charge_percentage'] ?? 0.0,
          'invoiceFooter': r['invoice_footer'] ?? 'Thank you for dining with us!',
          'loyaltyTargetVisits': r['loyalty_target_visits'] ?? 6,
          'loyaltyRewardType': r['loyalty_reward_type'] ?? 'Free Drink',
          'loyaltyRewardDescription': r['loyalty_reward_description'] ?? 'Free Drink',
        },
      ));
    }

    // 2. Customers (preload lookup map so orders avoid N+1 server_id queries)
    final custServerIdMap = <String, String>{};
    final allCustIds = await db.query('customers', columns: ['id', 'server_id']);
    for (final c in allCustIds) {
      final cid = c['id'] as String?;
      final sid = c['server_id'] as String?;
      if (cid != null && sid != null && sid.isNotEmpty) {
        custServerIdMap[cid] = sid;
      }
    }

    final custRows = await db.query('customers', where: "sync_status != 'synced'");
    for (final r in custRows) {
      final localId = r['id'] as String;
      final serverId = r['server_id'] as String?;
      final status = r['sync_status'] as String;
      final opType = _resolveOperationType(status, serverId);
      if (opType == 'delete' && (serverId == null || serverId.isEmpty)) {
        await db.delete('customers', where: 'id = ?', whereArgs: [localId]);
        continue;
      }

      ops.add(SyncQueueItem(
        operationId: 'customer:$localId:$opType:${r['updated_at'] ?? ''}',
        entityType: 'customer',
        operationType: opType,
        localId: localId,
        serverId: serverId,
        payload: {
          'name': r['name'] ?? '',
          'phone': (r['phone'] as String? ?? '').trim(),
          'address': r['address'] ?? '',
          'birthday': r['birthday'],
          'notes': r['notes'] ?? '',
          'totalVisits': r['total_visits'] ?? 0,
          'totalSpent': r['total_spent'] ?? 0.0,
          'loyaltyPoints': r['loyalty_points'] ?? 0,
          'loyaltyCardNumber': r['loyalty_card_number'] ?? '',
        },
      ));
    }

    // 3. Orders (preload menu_items server_id lookup map to avoid N*items queries)
    final menuServerIdMap = <String, String>{};
    final allMenuIds = await db.query('menu_items', columns: ['id', 'server_id']);
    for (final m in allMenuIds) {
      final mid = m['id'] as String?;
      final sid = m['server_id'] as String?;
      if (mid != null && sid != null && sid.isNotEmpty) {
        menuServerIdMap[mid] = sid;
      }
    }

    final orderRows = await db.query('orders', where: "sync_status != 'synced'");
    for (final r in orderRows) {
      final localId = r['id'] as String;
      final serverId = r['server_id'] as String?;
      final status = r['sync_status'] as String;
      final opType = _resolveOperationType(status, serverId);
      if (opType == 'delete' && (serverId == null || serverId.isEmpty)) {
        await db.delete('orders', where: 'id = ?', whereArgs: [localId]);
        continue;
      }

      // Resolve customer server_id if present
      String? customerRef;
      final rawCustId = r['customer_id'] as String?;
      if (rawCustId != null && rawCustId.isNotEmpty) {
        customerRef = custServerIdMap[rawCustId] ?? rawCustId;
      }

      final items = <dynamic>[];
      try {
        final rawItems = jsonDecode(r['items_json'] as String? ?? '[]');
        if (rawItems is List) {
          for (final rawIt in rawItems) {
            if (rawIt is Map) {
              final itCopy = Map<String, dynamic>.from(rawIt);
              final rawMenuId = itCopy['menuItem']?.toString();
              if (rawMenuId != null && rawMenuId.isNotEmpty) {
                itCopy['menuItem'] = menuServerIdMap[rawMenuId] ?? rawMenuId;
              }
              final itemName = (itCopy['name'] as String? ?? '').trim();
              final itemPrice = (itCopy['price'] as num?)?.toDouble() ?? 0.0;
              final rawQty = (itCopy['quantity'] as num?)?.toInt() ?? 1;
              final qty = rawQty >= 1 ? rawQty : 1;
              itCopy['name'] = itemName.isNotEmpty ? itemName : 'Item';
              itCopy['price'] = itemPrice;
              itCopy['quantity'] = qty;
              itCopy['gstPercentage'] = (itCopy['gstPercentage'] as num?)?.toDouble() ?? 0.0;
              itCopy['subtotal'] = (itCopy['subtotal'] as num?)?.toDouble() ?? (itemPrice * qty);
              itCopy['notes'] = (itCopy['notes'] as String?) ?? '';
              items.add(itCopy);
            }
          }
        }
      } catch (_) {}

      final orderPayload = <String, dynamic>{
        'orderNumber': r['order_number'],
        'customer': customerRef,
        'customerId': customerRef,
        'customerName': (r['customer_name'] as String?)?.trim().isNotEmpty == true
            ? r['customer_name']
            : 'Walk-in Customer',
        'customerPhone': r['customer_phone'] ?? '',
        'loyaltyCardNumber': r['loyalty_card_number'] ?? '',
        'visitCount': r['visit_count'] ?? 1,
        'rewardStatus': r['reward_status'] ?? '',
        'orderStatus': _normalizeOrderStatusForSync(r['order_status'] as String?),
        'items': items,
        'subtotal': r['subtotal'] ?? 0.0,
        'discountAmount': r['discount_amount'] ?? 0.0,
        'gstAmount': r['gst_amount'] ?? 0.0,
        'serviceChargeAmount': r['service_charge_amount'] ?? 0.0,
        'grandTotal': r['grand_total'] ?? 0.0,
        'paymentMethod': _normalizePaymentMethodForSync(r['payment_method'] as String?),
        'paymentStatus': _normalizePaymentStatusForSync(r['payment_status'] as String?),
        'notes': r['notes'] ?? '',
      };

      final createdAt = r['created_at'] as String?;
      final updatedAt = r['updated_at'] as String?;
      if (createdAt != null && createdAt.isNotEmpty) {
        orderPayload['createdAt'] = createdAt;
      }
      if (updatedAt != null && updatedAt.isNotEmpty) {
        orderPayload['updatedAt'] = updatedAt;
      }

      ops.add(SyncQueueItem(
        operationId: 'order:$localId:$opType:${updatedAt ?? ''}',
        entityType: 'order',
        operationType: opType,
        localId: localId,
        serverId: serverId,
        payload: orderPayload,
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

  // ==========================================
  // CLEAR LOCAL DATA & STORAGE RESET
  // ==========================================

  Future<void> clearAllLocalData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('expenses');
      await txn.delete('expense_categories');
      await txn.delete('categories');
      await txn.delete('menu_items');
      await txn.delete('customers');
      await txn.delete('orders');
      await txn.delete('monthly_budgets');
      await txn.delete('sync_metadata');
    });

    // Re-seed default expense categories
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
      await db.insert('expense_categories', {
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
  }

  // ==========================================
  // HIGH-THROUGHPUT BATCH IMPORTS (SCALE SAFE)
  // ==========================================

  Future<int> importOrdersBatch(List<Map<String, dynamic>> orderPayloads) async {
    if (orderPayloads.isEmpty) return 0;
    final db = await database;

    return await db.transaction((txn) async {
      // Preload existing sequence numbers per B-YYYYMMDD prefix to avoid N+1 queries
      final existingNumRows = await txn.rawQuery(
        "SELECT order_number FROM orders WHERE order_number LIKE 'B-%'",
      );
      final seqByDate = <String, int>{};
      for (final r in existingNumRows) {
        final numStr = r['order_number'] as String? ?? '';
        final parts = numStr.split('-');
        if (parts.length >= 3) {
          final dateKey = '${parts[0]}-${parts[1]}';
          final seq = int.tryParse(parts.last) ?? 0;
          if (seq > (seqByDate[dateKey] ?? 0)) {
            seqByDate[dateKey] = seq;
          }
        }
      }

      // Preload existing customers by trimmed phone to avoid N+1 reads/writes
      final custRows = await txn.query(
        'customers',
        columns: ['id', 'phone', 'total_visits', 'total_spent', 'loyalty_card_number', 'sync_status'],
        where: 'deleted_at IS NULL',
      );
      final custByPhone = <String, Map<String, dynamic>>{};
      for (final c in custRows) {
        final p = (c['phone'] as String? ?? '').trim();
        if (p.isNotEmpty) {
          custByPhone[p] = Map<String, dynamic>.from(c);
        }
      }

      final custDeltas = <String, Map<String, dynamic>>{};
      final batch = txn.batch();
      int count = 0;

      for (final payload in orderPayloads) {
        final id = _uuid.v4();
        final createdAt = (payload['createdAt'] as DateTime?) ?? DateTime.now();
        final nowIso = createdAt.toIso8601String();

        String orderNumber = (payload['orderNumber'] as String? ?? '').trim();
        if (orderNumber.isEmpty) {
          final d = DateTime.now();
          final dateStr =
              '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
          final key = 'B-$dateStr';
          final nextSeq = (seqByDate[key] ?? 0) + 1;
          seqByDate[key] = nextSeq;
          orderNumber = '$key-${nextSeq.toString().padLeft(4, '0')}';
        }

        final items = payload['items'] as List<OrderItemModel>? ?? const [];
        final itemsJson = jsonEncode(items.map((i) => i.toJson()).toList());
        final custPhone = (payload['customerPhone'] as String? ?? '').trim();
        final grandTotal = (payload['grandTotal'] as num?)?.toDouble() ?? 0.0;
        final loyaltyCard = (payload['loyaltyCardNumber'] as String? ?? '').trim();

        batch.insert(
          'orders',
          {
            'id': id,
            'server_id': null,
            'order_number': orderNumber,
            'customer_id': payload['customerId'],
            'customer_name': (payload['customerName'] as String? ?? 'Guest').trim(),
            'customer_phone': custPhone,
            'loyalty_card_number': loyaltyCard,
            'visit_count': 1,
            'reward_status': '',
            'order_status': 'completed',
            'items_json': itemsJson,
            'subtotal': (payload['subtotal'] as num?)?.toDouble() ?? grandTotal,
            'discount_amount': (payload['discountAmount'] as num?)?.toDouble() ?? 0.0,
            'gst_amount': (payload['gstAmount'] as num?)?.toDouble() ?? 0.0,
            'service_charge_amount':
                (payload['serviceChargeAmount'] as num?)?.toDouble() ?? 0.0,
            'grand_total': grandTotal,
            'payment_method':
                (payload['paymentMethod'] as String? ?? 'cash').toLowerCase(),
            'payment_status': 'paid',
            'notes': payload['notes'] ?? 'Imported from Backup',
            'created_at': nowIso,
            'updated_at': nowIso,
            'sync_status': 'pendingCreate',
            'deleted_at': null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (custPhone.isNotEmpty && custByPhone.containsKey(custPhone)) {
          final existing = custByPhone[custPhone]!;
          final cid = existing['id'] as String;
          final curDelta = custDeltas.putIfAbsent(cid, () => {
                'visits': 0,
                'spent': 0.0,
                'baseVisits': (existing['total_visits'] as num?)?.toInt() ?? 0,
                'baseSpent': (existing['total_spent'] as num?)?.toDouble() ?? 0.0,
                'syncStatus': existing['sync_status'] as String? ?? 'synced',
                'card': loyaltyCard,
              });
          curDelta['visits'] = (curDelta['visits'] as int) + 1;
          curDelta['spent'] = (curDelta['spent'] as double) + grandTotal;
          if (loyaltyCard.isNotEmpty) {
            curDelta['card'] = loyaltyCard;
          }
        }
        count++;
      }

      final updateNow = DateTime.now().toIso8601String();
      for (final entry in custDeltas.entries) {
        final d = entry.value;
        final syncStatus = d['syncStatus'] == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate';
        final updateMap = <String, dynamic>{
          'total_visits': (d['baseVisits'] as int) + (d['visits'] as int),
          'total_spent': (d['baseSpent'] as double) + (d['spent'] as double),
          'updated_at': updateNow,
          'sync_status': syncStatus,
        };
        if ((d['card'] as String).isNotEmpty) {
          updateMap['loyalty_card_number'] = d['card'];
        }
        batch.update('customers', updateMap, where: 'id = ?', whereArgs: [entry.key]);
      }

      await batch.commit(noResult: true);
      return count;
    });
  }

  Future<int> importCustomersBatch(List<Map<String, dynamic>> customerPayloads) async {
    if (customerPayloads.isEmpty) return 0;
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final batch = txn.batch();
      int count = 0;
      for (final data in customerPayloads) {
        batch.insert(
          'customers',
          {
            'id': _uuid.v4(),
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
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        count++;
      }
      await batch.commit(noResult: true);
      return count;
    });
  }

  Future<int> importMenuItemsBatch(List<MenuItemModel> items) async {
    if (items.isEmpty) return 0;
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final batch = txn.batch();
      int count = 0;
      for (final item in items) {
        batch.insert(
          'menu_items',
          {
            'id': _uuid.v4(),
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
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        count++;
      }
      await batch.commit(noResult: true);
      return count;
    });
  }

  Future<int> importExpensesBatch(List<Map<String, dynamic>> expensePayloads) async {
    if (expensePayloads.isEmpty) return 0;
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final batch = txn.batch();
      int count = 0;
      for (final data in expensePayloads) {
        batch.insert(
          'expenses',
          {
            'id': _uuid.v4(),
            'server_id': null,
            'category': data['category'] ?? 'Miscellaneous',
            'title': data['title'] ?? '',
            'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
            'date': data['date'] ?? now,
            'notes': data['notes'] ?? '',
            'created_at': now,
            'updated_at': now,
            'sync_status': 'pendingCreate',
            'deleted_at': null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        count++;
      }
      await batch.commit(noResult: true);
      return count;
    });
  }

  /// Queries SQLite for distinct years, months, and dates that contain at least
  /// one non-deleted order and/or expense record.
  Future<AvailableDataDates> getAvailableDataDates({
    bool includeOrders = true,
    bool includeExpenses = true,
    bool excludeRefundedOrders = true,
  }) async {
    final db = await database;
    final months = <String>{};
    final days = <String>{};
    final years = <int>{};
    DateTime? earliest;
    DateTime? latest;

    void recordTimestamp(String? raw) {
      if (raw == null || raw.isEmpty) return;
      try {
        final dt = DateTime.parse(raw).toLocal();
        final dayOnly = DateTime(dt.year, dt.month, dt.day);
        years.add(dt.year);
        months.add(AvailableDataDates.monthKey(dayOnly));
        days.add(AvailableDataDates.dayKey(dayOnly));
        if (earliest == null || dayOnly.isBefore(earliest!)) {
          earliest = dayOnly;
        }
        if (latest == null || dayOnly.isAfter(latest!)) {
          latest = dayOnly;
        }
      } catch (_) {}
    }

    if (includeOrders) {
      final orderWhere = excludeRefundedOrders
          ? "deleted_at IS NULL AND order_status != 'refunded'"
          : 'deleted_at IS NULL';
      final rows = await db.rawQuery(
        'SELECT created_at FROM orders WHERE $orderWhere GROUP BY substr(created_at, 1, 13)',
      );
      for (final row in rows) {
        recordTimestamp(row['created_at'] as String?);
      }
    }

    if (includeExpenses) {
      final rows = await db.rawQuery(
        'SELECT date FROM expenses WHERE deleted_at IS NULL GROUP BY substr(date, 1, 13)',
      );
      for (final row in rows) {
        recordTimestamp(row['date'] as String?);
      }
    }

    return AvailableDataDates(
      months: months,
      days: days,
      years: years,
      earliestDate: earliest,
      latestDate: latest,
    );
  }
}
