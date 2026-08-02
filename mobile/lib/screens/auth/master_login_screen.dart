import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/pin_auth_provider.dart';

class MasterLoginScreen extends ConsumerStatefulWidget {
  const MasterLoginScreen({super.key});

  @override
  ConsumerState<MasterLoginScreen> createState() => _MasterLoginScreenState();
}

class _MasterLoginScreenState extends ConsumerState<MasterLoginScreen> {
  final _masterIdController = TextEditingController();
  final _masterPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _masterIdController.dispose();
    _masterPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleMasterLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final masterId = _masterIdController.text.trim();
    final masterPassword = _masterPasswordController.text.trim();
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.masterLogin,
        data: {
          'masterId': masterId,
          'masterPassword': masterPassword,
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 && response.data['success'] == true) {
          SnackbarUtils.showSuccess(
            context,
            'Master Authentication Successful! Set your security PIN.',
          );
          ref.read(pinAuthProvider.notifier).setMode(PinFlowMode.createPin);
          context.go('/pin');
        } else {
          setState(() {
            _errorMessage =
                response.data['message'] ?? 'Invalid Master ID or Password.';
          });
        }
      }
    } on DioException catch (dioErr) {
      if (mounted) {
        String msg = 'Connection failed. Please check network connection.';
        if (dioErr.response?.data is Map &&
            dioErr.response?.data['message'] != null) {
          msg = dioErr.response?.data['message'].toString() ?? msg;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred during verification: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                    // Master Shield Icon
                    Center(
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryVariant,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(90),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ).animate().scale(duration: 350.ms),
                    const SizedBox(height: 20),

                    Text(
                      'Master Login',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level 1 Master Authentication required to configure or reset app access PIN.',
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
                            TextFormField(
                              controller: _masterIdController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'Master ID',
                                hintText: 'Enter Master ID',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter Master ID';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _masterPasswordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Master Password',
                                hintText: 'Enter Master Password',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter Master Password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            if (_errorMessage != null)
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
                                        _errorMessage!,
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
                              onPressed: _isLoading ? null : _handleMasterLogin,
                              icon: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.verified_user_rounded),
                              label: Text(
                                _isLoading
                                    ? 'Authenticating...'
                                    : 'Verify Master Access',
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
