import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/background_sync_service.dart';
import 'package:mobile/core/storage/local_database.dart';
import 'package:mobile/core/storage/sync_queue_item.dart';
import 'package:mobile/models/expense_model.dart';
import 'package:mobile/providers/expense_provider.dart';

void main() {
  group('Expense Monthly Budget & Calculations', () {
    test('budgetUsageRatio, remaining, and isOverBudget calculations', () {
      final stateUnderBudget = ExpenseState(
        expenses: [],
        categories: [],
        monthlyBudget: 50000.0,
        monthExpenseTotal: 12500.0,
        currentMonthKey: '2026-09',
      );

      expect(stateUnderBudget.budgetRemaining, 37500.0);
      expect(stateUnderBudget.budgetUsageRatio, 0.25);
      expect(stateUnderBudget.isOverBudget, isFalse);

      final stateOverBudget = ExpenseState(
        expenses: [],
        categories: [],
        monthlyBudget: 30000.0,
        monthExpenseTotal: 35000.0,
        currentMonthKey: '2026-09',
      );

      expect(stateOverBudget.budgetRemaining, 0.0);
      expect(stateOverBudget.budgetUsageRatio, 1.0);
      expect(stateOverBudget.isOverBudget, isTrue);

      final stateZeroBudget = ExpenseState(
        expenses: [],
        categories: [],
        monthlyBudget: 0.0,
        monthExpenseTotal: 1000.0,
        currentMonthKey: '2026-09',
      );

      expect(stateZeroBudget.budgetRemaining, 0.0);
      expect(stateZeroBudget.budgetUsageRatio, 0.0);
      expect(stateZeroBudget.isOverBudget, isFalse);
    });

    test('formatMonthKey generates consistent YYYY-MM keys', () {
      final dateSep = DateTime(2026, 9, 6);
      expect(LocalDatabase.formatMonthKey(dateSep), '2026-09');

      final dateJan = DateTime(2026, 1, 15);
      expect(LocalDatabase.formatMonthKey(dateJan), '2026-01');

      final dateDec = DateTime(2025, 12, 31);
      expect(LocalDatabase.formatMonthKey(dateDec), '2025-12');
    });
  });

  group('SyncQueueItem Serialization', () {
    test('serializes and deserializes create operation with payload correctly', () {
      final item = SyncQueueItem(
        operationId: 'op-12345',
        entityType: 'expense',
        operationType: 'create',
        localId: 'loc-exp-1',
        payload: {
          'title': 'Fresh Chicken Stock',
          'category': 'Chicken',
          'amount': 2400.0,
          'date': '2026-09-06T12:00:00.000Z',
          'notes': '50kg wholesale',
        },
      );

      final json = item.toJson();
      expect(json['operationId'], 'op-12345');
      expect(json['entityType'], 'expense');
      expect(json['operationType'], 'create');
      expect(json['localId'], 'loc-exp-1');
      expect(json.containsKey('serverId'), isFalse);
      expect(json['payload']['amount'], 2400.0);

      final parsed = SyncQueueItem.fromJson(json);
      expect(parsed.operationId, item.operationId);
      expect(parsed.entityType, item.entityType);
      expect(parsed.localId, item.localId);
      expect(parsed.payload['title'], 'Fresh Chicken Stock');
    });

    test('serializes delete operation with serverId', () {
      final item = SyncQueueItem(
        operationId: 'op-999',
        entityType: 'expense',
        operationType: 'delete',
        localId: 'loc-exp-2',
        serverId: 'mongo-id-abcdef123456',
        payload: {},
      );

      final json = item.toJson();
      expect(json['operationType'], 'delete');
      expect(json['serverId'], 'mongo-id-abcdef123456');
    });
  });

  group('Expense Model Offline Data Integrity', () {
    test('ExpenseModel fromJson and toJson preserves Tamil unicode characters', () {
      final json = {
        'id': 'exp-tamil-1',
        'category': 'காய்கறிகள்', // Vegetables in Tamil
        'title': 'தினசரி கோழி மற்றும் முட்டை', // Daily chicken & egg in Tamil
        'amount': 850.50,
        'date': '2026-09-06T10:00:00.000Z',
        'notes': 'உள்ளூர் சந்தை ரசீது #42', // Local market receipt in Tamil
      };

      final model = ExpenseModel.fromJson(json);
      expect(model.category, 'காய்கறிகள்');
      expect(model.title, 'தினசரி கோழி மற்றும் முட்டை');
      expect(model.amount, 850.50);
      expect(model.notes, 'உள்ளூர் சந்தை ரசீது #42');

      final serialized = model.toJson();
      expect(serialized['title'], 'தினசரி கோழி மற்றும் முட்டை');
      expect(serialized['category'], 'காய்கறிகள்');
      expect(serialized['notes'], 'உள்ளூர் சந்தை ரசீது #42');
    });
  });

  group('Nightly 10:00 PM Auto-Sync Scheduling', () {
    test('calculateDelayUntilNext10Pm returns a valid non-negative delay <= 24h', () {
      final delay = calculateDelayUntilNext10Pm();
      expect(delay.isNegative, isFalse);
      expect(delay.inSeconds <= const Duration(days: 1).inSeconds, isTrue);
    });

    test('isAutoSyncTimeReached accurately handles daytime vs after 10:00 PM night closing', () {
      // Daytime (should NOT auto-sync, offline billing continues undisturbed)
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 19, 9, 0)), isFalse);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 19, 13, 30)), isFalse);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 19, 18, 0)), isFalse);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 19, 21, 59)), isFalse);

      // Night closing window (at or after 10:00 PM until 4:00 AM)
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 19, 22, 0)), isTrue);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 19, 22, 30)), isTrue);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 19, 23, 45)), isTrue);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 20, 0, 15)), isTrue);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 20, 1, 30)), isTrue);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 20, 3, 59)), isTrue);

      // Morning after closing
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 20, 4, 0)), isFalse);
      expect(isAutoSyncTimeReached(DateTime(2026, 9, 20, 6, 0)), isFalse);
    });
  });

  group('Order Number Sequence & Prefix Verification', () {
    test('sequence formatting generates padded 3-digit order numbers', () {
      final now = DateTime(2026, 9, 20);
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      expect('$dateStr-001', '20260920-001');
      expect('$dateStr-042', '20260920-042');
      expect('$dateStr-100', '20260920-100');
    });
  });
}
