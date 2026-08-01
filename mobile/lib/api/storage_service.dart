import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyPinHash = 'fbx_owner_pin_hash';
  static const String _salt = 'foodbillx_salt_secure_2026';

  String _hashPin(String pin) {
    final bytes = utf8.encode('$pin$_salt');
    return sha256.convert(bytes).toString();
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(_keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<bool> savePin(String pin) async {
    if (pin.length != 4) return false;
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    return await prefs.setString(_keyPinHash, hash);
  }

  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_keyPinHash);
    if (storedHash == null) return false;
    return storedHash == _hashPin(enteredPin);
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    final isCorrect = await verifyPin(currentPin);
    if (!isCorrect) return false;
    return await savePin(newPin);
  }
}
