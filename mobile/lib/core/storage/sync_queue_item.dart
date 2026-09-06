class SyncQueueItem {
  final String operationId;
  final String entityType; // 'expense', 'expenseCategory', 'category', 'menuItem', 'customer', 'order', 'settings'
  final String operationType; // 'create', 'update', 'delete'
  final String localId;
  final String? serverId;
  final Map<String, dynamic> payload;

  const SyncQueueItem({
    required this.operationId,
    required this.entityType,
    required this.operationType,
    required this.localId,
    this.serverId,
    required this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'entityType': entityType,
      'operationType': operationType,
      'localId': localId,
      if (serverId != null && serverId!.isNotEmpty) 'serverId': serverId,
      'payload': payload,
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      operationId: json['operationId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      operationType: json['operationType'] as String? ?? '',
      localId: json['localId'] as String? ?? '',
      serverId: json['serverId'] as String?,
      payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : {},
    );
  }
}
