/// Tracks the synchronisation state of a locally-stored record.
enum SyncStatus {
  /// Record has been created / modified locally and is waiting to be pushed.
  pending,

  /// Record has been successfully pushed to the backend.
  synced,

  /// The last push attempt failed; will be retried.
  failed,
}

/// The type of operation stored in the sync outbox queue.
enum SyncOperationType { create, update, delete }

/// Which entity the sync operation targets.
enum SyncEntityType {
  category,
  menuItem,
  order,
  customer,
  expense,
  expenseCategory,
  settings,
}
