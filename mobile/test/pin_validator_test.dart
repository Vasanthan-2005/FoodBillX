import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/pin_validator.dart';

void main() {
  group('PinValidator Tests', () {
    test('rejects empty PIN', () {
      expect(PinValidator.validate(''), equals('PIN cannot be empty'));
    });

    test('rejects PIN with incorrect length', () {
      expect(PinValidator.validate('123'), equals('PIN must be exactly 4 digits'));
      expect(PinValidator.validate('12345'), equals('PIN must be exactly 4 digits'));
    });

    test('rejects PIN with non-digit characters', () {
      expect(PinValidator.validate('12a4'), equals('PIN must contain only numbers'));
    });

    test('rejects weak repeating PINs like 1111, 0000, 9999', () {
      expect(PinValidator.validate('1111'), isNotNull);
      expect(PinValidator.validate('0000'), isNotNull);
      expect(PinValidator.validate('9999'), isNotNull);
    });

    test('rejects weak sequential PINs like 1234, 4321, 5678', () {
      expect(PinValidator.validate('1234'), isNotNull);
      expect(PinValidator.validate('4321'), isNotNull);
      expect(PinValidator.validate('5678'), isNotNull);
    });

    test('rejects weak repeating pattern PINs like 1212, 1010', () {
      expect(PinValidator.validate('1212'), isNotNull);
      expect(PinValidator.validate('1010'), isNotNull);
      expect(PinValidator.validate('6969'), isNotNull);
    });

    test('accepts strong random PINs like 8472, 9135, 3692', () {
      expect(PinValidator.validate('8472'), isNull);
      expect(PinValidator.validate('9135'), isNull);
      expect(PinValidator.validate('3692'), isNull);
    });
  });
}
