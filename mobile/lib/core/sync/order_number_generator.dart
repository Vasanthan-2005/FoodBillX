import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../local_db/schemas/order_schema.dart';

/// Generates offline order numbers in the format:
/// `{prefix}{YYYYMMDD}-{NNNN}`
///
/// Example: `INV-20260727-0001`
///
/// The daily sequence counter is derived from the count of local orders
/// created today, so it survives app restarts without extra storage.
class OrderNumberGenerator {
  final Isar _isar;

  OrderNumberGenerator(this._isar);

  /// Generates the next order number for today.
  Future<String> generate(String prefix) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);

    // Count orders already created today to determine the next sequence.
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayCount = await _isar.orderSchemas
        .filter()
        .createdAtBetween(startOfDay, endOfDay, includeUpper: false)
        .count();

    final seq = (todayCount + 1).toString().padLeft(4, '0');
    return '$prefix$dateStr-$seq';
  }
}
