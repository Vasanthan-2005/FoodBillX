class CustomerValidator {
  /// Validates a customer's name.
  /// Returns `null` if valid, or a descriptive error message if invalid.
  static String? validateName(String? name) {
    final clean = name?.trim() ?? '';
    if (clean.isEmpty) {
      return 'Customer name is required';
    }
    if (clean.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s\.\'\-]+$").hasMatch(clean)) {
      return 'Name must contain only letters and spaces';
    }
    return null;
  }

  /// Validates an Indian mobile phone number (10 digits starting with 6, 7, 8, or 9).
  /// Returns `null` if valid, or a descriptive error message if invalid.
  static String? validatePhone(String? phone) {
    final clean = phone?.trim() ?? '';
    if (clean.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(clean)) {
      return 'Phone number must contain digits only';
    }
    if (clean.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return 'Enter a valid 10-digit mobile number (starts with 6-9)';
    }
    return null;
  }

  /// Validates a loyalty card number.
  /// Returns `null` if valid, or a descriptive error message if invalid.
  static String? validateLoyaltyCard(String? cardNumber) {
    final clean = cardNumber?.trim() ?? '';
    if (clean.isEmpty) {
      return 'Loyalty card number is required';
    }
    if (clean.length > 25) {
      return 'Card number cannot exceed 25 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(clean)) {
      return 'Card number can only contain letters, numbers, and hyphens';
    }
    return null;
  }
}
