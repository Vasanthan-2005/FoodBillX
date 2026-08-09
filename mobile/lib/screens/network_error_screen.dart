import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/api_endpoints.dart';
import '../core/constants/app_colors.dart';
import '../providers/bootstrap_provider.dart';

class NetworkErrorScreen extends ConsumerWidget {
  const NetworkErrorScreen({super.key});

  void _showServerUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiEndpoints.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text(
                'Configure Server Address',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your backend server API URL (Cloud or Local Wi-Fi IP):',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    hintText: 'https://foodbillx.onrender.com/api/v1',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      backgroundColor: AppColors.primary.withAlpha(40),
                      label: const Text('Live Cloud Server', style: TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: () {
                        controller.text = ApiEndpoints.liveProductionUrl;
                      },
                    ),
                    ActionChip(
                      backgroundColor: Colors.white10,
                      label: const Text('Default LAN IP', style: TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: () {
                        controller.text = ApiEndpoints.defaultLanIp;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = controller.text.trim();
                await ApiEndpoints.saveCustomServerUrl(input);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) context.go('/splash');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save & Reconnect'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapState = ref.watch(bootstrapProvider);
    final errorMsg = bootstrapState.errorMessage ??
        "We couldn't connect to the server. Please check your internet connection and try again.";

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withAlpha(80),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.shade500.withAlpha(120),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade900.withAlpha(100),
                        blurRadius: 32,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.redAccent,
                    size: 56,
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fade(duration: 400.ms),

                const SizedBox(height: 32),

                const Text(
                  'Network Error',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fade(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade400,
                  ),
                ).animate().fade(delay: 350.ms, duration: 500.ms),

                const SizedBox(height: 12),

                // Current Server IP Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        ApiEndpoints.baseUrl,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: bootstrapState.isLoading
                        ? null
                        : () async {
                            context.go('/splash');
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: bootstrapState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Retry Connection',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fade(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // Configure Server URL Button
                OutlinedButton.icon(
                  onPressed: () => _showServerUrlDialog(context),
                  icon: const Icon(Icons.settings_input_component_rounded, size: 18),
                  label: const Text('Change Server Address'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ).animate().fade(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
