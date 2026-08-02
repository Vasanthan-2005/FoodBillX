import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/pin_validator.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/forgot_pin_provider.dart';

class ResetPinScreen extends ConsumerStatefulWidget {
  const ResetPinScreen({super.key});

  @override
  ConsumerState<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends ConsumerState<ResetPinScreen> {
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    final validationError = PinValidator.validate(newPin);
    if (validationError != null) {
      SnackbarUtils.showError(context, validationError);
      return;
    }

    if (newPin != confirmPin) {
      SnackbarUtils.showError(context, 'New PIN and Confirm PIN do not match');
      return;
    }

    final success = await ref.read(forgotPinProvider.notifier).resetPin(
          newPin: newPin,
          confirmPin: confirmPin,
        );

    if (mounted) {
      if (success) {
        SnackbarUtils.showSuccess(
          context,
          'PIN updated successfully! Please log in with your new PIN.',
        );
        ref.read(forgotPinProvider.notifier).resetFlow();
        context.go('/pin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPinProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Security PIN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/pin'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Key Icon Header
                    Center(
                      child: Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryVariant,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(80),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ).animate().scale(duration: 300.ms),
                    const SizedBox(height: 20),

                    Text(
                      'Create New PIN',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set a new 4-digit security PIN for your POS app. Choose a strong PIN that is hard to guess.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // New PIN Field
                            TextFormField(
                              controller: _newPinController,
                              keyboardType: TextInputType.number,
                              obscureText: _obscurePin,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'New 4-Digit PIN',
                                prefixIcon: const Icon(Icons.password_rounded),
                                counterText: '',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePin
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePin = !_obscurePin;
                                    });
                                  },
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) => PinValidator.validate(val ?? ''),
                            ),
                            const SizedBox(height: 16),

                            // Confirm PIN Field
                            TextFormField(
                              controller: _confirmPinController,
                              keyboardType: TextInputType.number,
                              obscureText: _obscurePin,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Confirm New PIN',
                                prefixIcon:
                                    Icon(Icons.check_circle_outline_rounded),
                                counterText: '',
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please confirm your new PIN';
                                }
                                if (val != _newPinController.text.trim()) {
                                  return 'PINs do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            if (state.errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.red.shade400,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        state.errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().shake(),

                            ElevatedButton.icon(
                              onPressed: state.isSubmittingReset
                                  ? null
                                  : _handleReset,
                              icon: state.isSubmittingReset
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(
                                state.isSubmittingReset
                                    ? 'Saving PIN...'
                                    : 'Save & Set New PIN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
