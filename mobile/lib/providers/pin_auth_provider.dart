import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/storage_service.dart';

enum PinFlowMode { checking, masterLogin, createPin, confirmPin, enterPin, unlocked }

class PinAuthState {
  final PinFlowMode mode;
  final String currentInput;
  final String? tempCreatedPin;
  final String? errorMessage;
  final int failedAttempts;
  final DateTime? lockedUntil;

  PinAuthState({
    required this.mode,
    this.currentInput = '',
    this.tempCreatedPin,
    this.errorMessage,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  factory PinAuthState.initial() => PinAuthState(mode: PinFlowMode.checking);

  PinAuthState copyWith({
    PinFlowMode? mode,
    String? currentInput,
    String? tempCreatedPin,
    bool clearTempPin = false,
    String? errorMessage,
    bool clearError = false,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) {
    return PinAuthState(
      mode: mode ?? this.mode,
      currentInput: currentInput ?? this.currentInput,
      tempCreatedPin: clearTempPin
          ? null
          : (tempCreatedPin ?? this.tempCreatedPin),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

class PinAuthNotifier extends StateNotifier<PinAuthState> {
  final StorageService _storage;

  PinAuthNotifier(this._storage) : super(PinAuthState.initial()) {
    checkPinStatus();
  }

  Future<void> checkPinStatus() async {
    final exists = await _storage.hasPin();
    if (exists) {
      state = PinAuthState(mode: PinFlowMode.enterPin);
    } else {
      state = PinAuthState(mode: PinFlowMode.masterLogin);
    }
  }

  void setMode(PinFlowMode mode) {
    state = PinAuthState(mode: mode);
  }

  void appendDigit(String digit) {
    final lock = state.lockedUntil;
    if (lock != null && DateTime.now().isBefore(lock)) {
      final seconds = lock.difference(DateTime.now()).inSeconds + 1;
      state = state.copyWith(
        errorMessage: 'Too many attempts. Try again in $seconds seconds.',
      );
      return;
    }
    if (lock != null) {
      state = state.copyWith(
        clearLock: true,
        failedAttempts: 0,
        clearError: true,
      );
    }
    if (state.currentInput.length >= 4) return;
    final newInput = state.currentInput + digit;
    state = state.copyWith(currentInput: newInput, clearError: true);

    if (newInput.length == 4) {
      _handleFourDigitsEntered(newInput);
    }
  }

  void deleteDigit() {
    if (state.currentInput.isEmpty) return;
    final newInput = state.currentInput.substring(
      0,
      state.currentInput.length - 1,
    );
    state = state.copyWith(currentInput: newInput, clearError: true);
  }

  void clearInput() {
    state = state.copyWith(currentInput: '', clearError: true);
  }

  Future<void> _handleFourDigitsEntered(String pin) async {
    if (state.mode == PinFlowMode.createPin) {
      // Move to confirm PIN step
      state = PinAuthState(
        mode: PinFlowMode.confirmPin,
        tempCreatedPin: pin,
        currentInput: '',
      );
    } else if (state.mode == PinFlowMode.confirmPin) {
      if (pin == state.tempCreatedPin) {
        await _storage.savePin(pin);
        state = PinAuthState(mode: PinFlowMode.unlocked);
      } else {
        state = PinAuthState(
          mode: PinFlowMode.createPin,
          currentInput: '',
          errorMessage: 'PINs do not match. Please try again.',
        );
      }
    } else if (state.mode == PinFlowMode.enterPin) {
      final isCorrect = await _storage.verifyPin(pin);
      if (isCorrect) {
        state = PinAuthState(mode: PinFlowMode.unlocked);
      } else {
        final attempts = state.failedAttempts + 1;
        final shouldLock = attempts >= 5;
        state = state.copyWith(
          currentInput: '',
          failedAttempts: attempts,
          lockedUntil: shouldLock
              ? DateTime.now().add(const Duration(seconds: 30))
              : null,
          errorMessage: shouldLock
              ? 'Too many incorrect attempts. Locked for 30 seconds.'
              : 'Incorrect PIN. Try again.',
        );
      }
    }
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    final ok = await _storage.changePin(oldPin, newPin);
    return ok;
  }

  Future<bool> resetPinDirectly(String newPin) async {
    final ok = await _storage.resetPin(newPin);
    if (ok) {
      state = PinAuthState(
        mode: PinFlowMode.enterPin,
        currentInput: '',
        failedAttempts: 0,
      );
    }
    return ok;
  }

  void lockApp() async {
    final exists = await _storage.hasPin();
    state = PinAuthState(
      mode: exists ? PinFlowMode.enterPin : PinFlowMode.createPin,
    );
  }
}

final pinAuthProvider = StateNotifierProvider<PinAuthNotifier, PinAuthState>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return PinAuthNotifier(storage);
});
