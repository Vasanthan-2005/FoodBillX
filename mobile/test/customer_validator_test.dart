import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/customer_validator.dart';

void main() {
  group('CustomerValidator.validateName', () {
    test('rejects empty and whitespace-only names', () {
      expect(CustomerValidator.validateName(''), 'Customer name is required');
      expect(CustomerValidator.validateName('   '), 'Customer name is required');
      expect(CustomerValidator.validateName(null), 'Customer name is required');
    });

    test('rejects names shorter than 2 characters', () {
      expect(CustomerValidator.validateName('A'), 'Name must be at least 2 characters');
    });

    test('rejects names with numbers or symbols', () {
      expect(
        CustomerValidator.validateName('John123'),
        'Name must contain only letters and spaces',
      );
      expect(
        CustomerValidator.validateName('Sarah@Home'),
        'Name must contain only letters and spaces',
      );
    });

    test('accepts valid customer names', () {
      expect(CustomerValidator.validateName('Rahul Sharma'), isNull);
      expect(CustomerValidator.validateName('Dr. J. Watson'), isNull);
      expect(CustomerValidator.validateName("O'Connor"), isNull);
      expect(CustomerValidator.validateName('Mary-Jane'), isNull);
    });
  });

  group('CustomerValidator.validatePhone', () {
    test('rejects empty phone numbers', () {
      expect(CustomerValidator.validatePhone(''), 'Phone number is required');
      expect(CustomerValidator.validatePhone('   '), 'Phone number is required');
      expect(CustomerValidator.validatePhone(null), 'Phone number is required');
    });

    test('rejects non-numeric characters', () {
      expect(
        CustomerValidator.validatePhone('98765abcd0'),
        'Phone number must contain digits only',
      );
    });

    test('rejects phone numbers with length other than 10 digits', () {
      expect(
        CustomerValidator.validatePhone('987654321'),
        'Phone number must be exactly 10 digits',
      );
      expect(
        CustomerValidator.validatePhone('98765432100'),
        'Phone number must be exactly 10 digits',
      );
    });

    test('rejects phone numbers not starting with 6, 7, 8, or 9', () {
      expect(
        CustomerValidator.validatePhone('1234567890'),
        'Enter a valid 10-digit mobile number (starts with 6-9)',
      );
      expect(
        CustomerValidator.validatePhone('0123456789'),
        'Enter a valid 10-digit mobile number (starts with 6-9)',
      );
    });

    test('accepts valid 10-digit mobile numbers', () {
      expect(CustomerValidator.validatePhone('9876543210'), isNull);
      expect(CustomerValidator.validatePhone('8123456789'), isNull);
      expect(CustomerValidator.validatePhone('7000012345'), isNull);
      expect(CustomerValidator.validatePhone('6380012345'), isNull);
    });
  });

  group('CustomerValidator.validateLoyaltyCard', () {
    test('rejects empty loyalty card numbers', () {
      expect(
        CustomerValidator.validateLoyaltyCard(''),
        'Loyalty card number is required',
      );
      expect(
        CustomerValidator.validateLoyaltyCard('   '),
        'Loyalty card number is required',
      );
      expect(
        CustomerValidator.validateLoyaltyCard(null),
        'Loyalty card number is required',
      );
    });

    test('accepts any valid loyalty card number of any length', () {
      expect(CustomerValidator.validateLoyaltyCard('1'), isNull);
      expect(CustomerValidator.validateLoyaltyCard('12'), isNull);
      expect(CustomerValidator.validateLoyaltyCard('505'), isNull);
      expect(CustomerValidator.validateLoyaltyCard('HMB-1001'), isNull);
      expect(CustomerValidator.validateLoyaltyCard('CARD_9921'), isNull);
      expect(CustomerValidator.validateLoyaltyCard('VIP-GOLD-01'), isNull);
    });
  });
}
