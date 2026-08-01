class ApiResponseParser {
  static Map<String, dynamic> extractMap(dynamic data, [List<String> keys = const []]) {
    dynamic payload = data;
    if (payload is Map && payload.containsKey('data')) {
      payload = payload['data'];
    }
    if (payload is Map) {
      for (final key in keys) {
        if (payload.containsKey(key) && payload[key] is Map) {
          return Map<String, dynamic>.from(payload[key]);
        }
      }
      return Map<String, dynamic>.from(payload);
    }
    return {};
  }

  static List extractList(dynamic data, [List<String> keys = const []]) {
    dynamic payload = data;
    if (payload is Map && payload.containsKey('data')) {
      payload = payload['data'];
    }
    if (payload is Map) {
      for (final key in keys) {
        if (payload.containsKey(key) && payload[key] is List) {
          return payload[key] as List;
        }
      }
      for (final fallbackKey in ['items', 'categories', 'customers', 'expenses', 'orders', 'data', 'list']) {
        if (payload.containsKey(fallbackKey) && payload[fallbackKey] is List) {
          return payload[fallbackKey] as List;
        }
      }
    } else if (payload is List) {
      return payload;
    }
    return [];
  }
}
