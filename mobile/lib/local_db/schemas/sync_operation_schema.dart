import 'package:isar/isar.dart';
import 'sync_enums.dart';

part 'sync_operation_schema.g.dart';

/// A single entry in the sync outbox queue.
///
/// When the app creates, updates, or deletes a local record, a [SyncOperationSchema]
/// is written to this collection. The [SyncService] processes these operations
/// whenever connectivity is available and removes them on success.
@Collection()
class SyncOperationSchema {
  Id id = Isar.autoIncrement;

  /// Which entity this operation targets.
  @Enumerated(EnumType.name)
  late SyncEntityType entityType;

  /// The type of operation (create / update / delete).
  @Enumerated(EnumType.name)
  late SyncOperationType operationType;

  /// Isar ID of the affected local record.
  @Index()
  late int localId;

  /// MongoDB ID, if already known (populated after create succeeds).
  String? serverId;

  /// JSON-encoded payload to send to the backend.
  late String payload;

  @Index()
  late DateTime createdAt;

  /// Number of failed push attempts.
  late int retryCount;

  /// Error message from the last failed attempt.
  String? lastError;
}
