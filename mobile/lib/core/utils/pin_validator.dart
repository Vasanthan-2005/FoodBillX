class PinValidator {
  static const List<String> _forbiddenWeakPins = [
    '0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999',
    '1234', '2345', '3456', '4567', '5678', '6789', '0123',
    '4321', '5432', '6543', '7654', '8765', '9876', '3210',
    '1212', '1010', '2020', '3030', '4040', '5050', '6969', '1313', '1414',
    '1515', '0101', '1122', '2211', '1221', '2112', '9090', '0909'
  ];

  /// Validates a candidate PIN against security rules.
  /// Returns `null` if the PIN is valid and strong, or a human-friendly error string if invalid.
  static String? validate(String pin) {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) {
      return 'PIN cannot be empty';
    }
    if (cleanPin.length != 4) {
      return 'PIN must be exactly 4 digits';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(cleanPin)) {
      return 'PIN must contain only numbers';
    }

    // Check against explicit list of weak PINs
    if (_forbiddenWeakPins.contains(cleanPin)) {
      return 'PIN is too simple (avoid numbers like $cleanPin)';
    }

    // Check all repeating digits (e.g. 1111, 2222)
    final firstChar = cleanPin[0];
    if (cleanPin.split('').every((c) => c == firstChar)) {
      return 'PIN is too simple (avoid repeating numbers)';
    }

    // Check 2-digit repeating pattern (e.g. 1212)
    if (cleanPin.substring(0, 2) == cleanPin.substring(2, 4)) {
      return 'PIN is too simple (avoid repeating patterns)';
    }

    return null;
  }
}
