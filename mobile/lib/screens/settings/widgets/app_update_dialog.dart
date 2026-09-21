import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class AppUpdateDialog extends ConsumerStatefulWidget {
  const AppUpdateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AppUpdateDialog(),
    );
  }

  @override
  ConsumerState<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends ConsumerState<AppUpdateDialog> {
  final TextEditingController _customUrlController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    // Auto-check for updates on opening dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUpdateProvider.notifier).checkForUpdate();
    });
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Invalid download URL');
      }
      return;
    }
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!launched) {
        SnackbarUtils.showError(context, 'Could not open browser to download update');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Failed to launch download link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(appUpdateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'App Update',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'v$kCurrentAppVersion+$kCurrentVersionCode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Checking State
            if (updateState.isChecking) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Checking for updates...',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ]
            // Downloading State
            else if (updateState.isDownloading) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Downloading APK...',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          '${(updateState.downloadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: updateState.downloadProgress > 0 ? updateState.downloadProgress : null,
                        minHeight: 8,
                        backgroundColor: AppColors.primary.withAlpha(30),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The package installer will launch after download completes.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ]
            // Update Available State
            else if (updateState.versionInfo?.updateAvailable == true) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.new_releases_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'New Update: v${updateState.versionInfo!.latestVersion} (Build ${updateState.versionInfo!.versionCode})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (updateState.versionInfo?.releaseNotes != null &&
                        updateState.versionInfo!.releaseNotes!.isNotEmpty) ...[
                       const SizedBox(height: 8),
                       Text(
                        updateState.versionInfo!.releaseNotes!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: theme.colorScheme.onSurface.withAlpha(200),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Update Now Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final ok = await ref.read(appUpdateProvider.notifier).downloadAndInstall();
                  if (!context.mounted) return;
                  final err = ref.read(appUpdateProvider).errorMessage;
                  if (!ok && err != null) {
                    SnackbarUtils.showError(context, err);
                  }
                },
                icon: const Icon(Icons.system_update_rounded, size: 20),
                label: const Text(
                  'Update Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              // Secondary fallback button: Open in Browser
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final url = updateState.versionInfo?.downloadUrl ?? kDefaultApkDownloadUrl;
                  _launchExternalUrl(url);
                },
                icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                label: const Text('Download via Browser'),
              ),
            ]
            // Up to Date State
            else if (updateState.versionInfo != null && !updateState.versionInfo!.updateAvailable) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.teal.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You\'re using the latest version',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'FoodBillX v$kCurrentAppVersion (Build $kCurrentVersionCode) is up to date.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Check again or direct download option
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => ref.read(appUpdateProvider.notifier).checkForUpdate(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Check Again'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _launchExternalUrl(kDefaultApkDownloadUrl),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Get APK'),
                    ),
                  ),
                ],
              ),
            ]
            // Error / Not configured state
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        updateState.errorMessage ??
                            'Click the button below to check or download the latest release APK directly.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _launchExternalUrl(kDefaultApkDownloadUrl),
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'Download Latest APK (GitHub)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ref.read(appUpdateProvider.notifier).checkForUpdate(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Server Check'),
              ),
            ],

            const SizedBox(height: 12),
            // Expandable Custom URL Input
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _showCustomInput = !_showCustomInput),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      _showCustomInput ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Enter custom APK link manually',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            if (_showCustomInput) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customUrlController,
                decoration: InputDecoration(
                  labelText: 'Custom APK Link',
                  hintText: 'https://drive.google.com/... or https://...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.link, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final url = _customUrlController.text.trim();
                  if (url.isEmpty) {
                    SnackbarUtils.showError(context, 'Please paste a download link');
                    return;
                  }
                  _launchExternalUrl(url);
                },
                icon: const Icon(Icons.launch_rounded, size: 16),
                label: const Text('Open Custom Link'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
