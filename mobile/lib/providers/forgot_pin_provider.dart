import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/pin_validator.dart';
import 'pin_auth_provider.dart';
import 'settings_provider.dart';

class ForgotPinState {
  final bool isVerifying;
  final bool isVerified;
  final bool isSubmittingReset;
  final String? verifiedPhone;
  final String? errorMessage;
  final String? successMessage;

  ForgotPinState({
    this.isVerifying = false,
    this.isVerified = false,
    this.isSubmittingReset = false,
    this.verifiedPhone,
    this.errorMessage,
    this.successMessage,
  });

  ForgotPinState copyWith({
    bool? isVerifying,
    bool? isVerified,
    bool? isSubmittingReset,
    String? verifiedPhone,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return ForgotPinState(
      isVerifying: isVerifying ?? this.isVerifying,
      isVerified: isVerified ?? this.isVerified,
      isSubmittingReset: isSubmittingReset ?? this.isSubmittingReset,
      verifiedPhone: verifiedPhone ?? this.verifiedPhone,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ForgotPinNotifier extends StateNotifier<ForgotPinState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ForgotPinNotifier(this._apiClient, this._ref) : super(ForgotPinState());

  void resetFlow() {
    state = ForgotPinState();
  }

  Future<bool> verifyOwnerPhone(String inputPhone) async {
    final cleanPhone = inputPhone.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 7) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid phone number (at least 7 digits).',
        clearSuccess: true,
      );
      return false;
    }

    state = state.copyWith(
      isVerifying: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyOwner,
        data: {'phone': inputPhone.trim()},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        state = state.copyWith(
          isVerifying: false,
          isVerified: true,
          verifiedPhone: inputPhone.trim(),
          clearError: true,
        );
        return true;
      } else {
        final msg = response.data['message'] ??
            'Verification failed. Please check registered phone number.';
        state = state.copyWith(isVerifying: false, errorMessage: msg);
        return false;
      }
    } on DioException catch (dioErr) {
      // Offline fallback: check local settings
      final localPhone =
          (_ref.read(settingsProvider).settings?.phone ?? '')
              .trim()
              .replaceAll(RegExp(r'\D'), '');

      if (localPhone.isNotEmpty && cleanPhone == localPhone) {
        state = state.copyWith(
          isVerifying: false,
          isVerified: true,
          verifiedPhone: inputPhone.trim(),
          clearError: true,
        );
        return true;
      }

      String msg = 'Unable to connect to server. Please try again.';
      if (dioErr.response != null && dioErr.response?.data is Map) {
        msg = dioErr.response?.data['message']?.toString() ?? msg;
      } else if (localPhone.isNotEmpty && cleanPhone != localPhone) {
        msg = 'Phone number does not match registered store owner settings.';
      }
      state = state.copyWith(isVerifying: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> resetPin({
    required String newPin,
    required String confirmPin,
  }) async {
    if (!state.isVerified) {
      state = state.copyWith(
        errorMessage: 'Identity verification required before resetting PIN.',
      );
      return false;
    }

    final validationError = PinValidator.validate(newPin);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    if (newPin != confirmPin) {
      state = state.copyWith(
        errorMessage: 'New PIN and Confirm PIN do not match.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmittingReset: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final success = await _ref
          .read(pinAuthProvider.notifier)
          .resetPinDirectly(newPin);

      if (success) {
        state = state.copyWith(
          isSubmittingReset: false,
          successMessage: 'PIN reset successfully! You can now log in.',
          clearError: true,
        );
        return true;
      } else {
        state = state.copyWith(
          isSubmittingReset: false,
          errorMessage: 'Failed to update PIN. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSubmittingReset: false,
        errorMessage: 'Error resetting PIN: ${e.toString()}',
      );
      return false;
    }
  }
}

final forgotPinProvider =
    StateNotifierProvider<ForgotPinNotifier, ForgotPinState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ForgotPinNotifier(apiClient, ref);
});
