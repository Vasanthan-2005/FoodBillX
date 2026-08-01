import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/storage_service.dart';

enum PinFlowMode { checking, createPin, confirmPin, enterPin, unlocked }

class PinAuthState {
  final PinFlowMode mode;
  final String currentInput;
  final String? tempCreatedPin;
  final String? errorMessage;

  PinAuthState({
    required this.mode,
    this.currentInput = '',
    this.tempCreatedPin,
    this.errorMessage,
  });

  factory PinAuthState.initial() => PinAuthState(mode: PinFlowMode.checking);

  PinAuthState copyWith({
    PinFlowMode? mode,
    String? currentInput,
    String? tempCreatedPin,
    bool clearTempPin = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PinAuthState(
      mode: mode ?? this.mode,
      currentInput: currentInput ?? this.currentInput,
      tempCreatedPin: clearTempPin
          ? null
          : (tempCreatedPin ?? this.tempCreatedPin),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
      state = PinAuthState(mode: PinFlowMode.createPin);
    }
  }

  void appendDigit(String digit) {
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
        state = state.copyWith(
          currentInput: '',
          errorMessage: 'Incorrect PIN. Try again.',
        );
      }
    }
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    final ok = await _storage.changePin(oldPin, newPin);
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
