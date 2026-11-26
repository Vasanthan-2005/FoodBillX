import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_update_service.dart';
import '../../core/storage/local_database.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/report_export_helper.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/custom_date_range_dialog.dart';
import '../../core/widgets/onboarding_dialog.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/pin_auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/app_update_dialog.dart';

enum ExportCategory {
  orders,
  customers,
  reports,
  backup,
}

enum ExportDateRange {
  allTime,
  today,
  thisMonth,
  last1Month,
  last2Months,
  last3Months,
  last6Months,
  custom,
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _currencyController;
  late TextEditingController _prefixController;
  late TextEditingController _serviceChargeController;
  late TextEditingController _footerController;
  late TextEditingController _loyaltyVisitsController;
  late TextEditingController _rewardTextController;
  bool _didPopulateSettings = false;
  bool _isExporting = false;
  bool _isImporting = false;
  Timer? _syncPollTimer;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).settings;
    _nameController = TextEditingController(text: settings?.businessName ?? '');
    _phoneController = TextEditingController(text: settings?.phone ?? '');
    _addressController = TextEditingController(text: settings?.address ?? '');
    _currencyController = TextEditingController(text: settings?.currency ?? '₹');
    _prefixController = TextEditingController(text: settings?.invoicePrefix ?? 'B');
    _serviceChargeController = TextEditingController(text: settings?.serviceChargePercentage.toString() ?? '0.0');
    _footerController = TextEditingController(text: settings?.invoiceFooter ?? 'Thank you for dining with us!');
    _loyaltyVisitsController = TextEditingController(text: settings?.loyaltyTargetVisits.toString() ?? '6');
    _rewardTextController = TextEditingController(text: settings?.loyaltyRewardDescription ?? 'Free Drink');
    _didPopulateSettings = settings != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(syncProvider.notifier).refreshStatus();
      }
    });
    _syncPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        ref.read(syncProvider.notifier).refreshStatus();
      }
    });
  }

  void _populateSettings(SettingsState state) {
    final settings = state.settings;
    if (_didPopulateSettings || settings == null) return;
    _didPopulateSettings = true;
    _nameController.text = settings.businessName;
    _phoneController.text = settings.phone;
    _addressController.text = settings.address;
    _currencyController.text = settings.currency;
    _prefixController.text = settings.invoicePrefix;
    _serviceChargeController.text = settings.serviceChargePercentage.toString();
    _footerController.text = settings.invoiceFooter;
    _loyaltyVisitsController.text = settings.loyaltyTargetVisits.toString();
    _rewardTextController.text = settings.loyaltyRewardDescription;
  }

  @override
  void dispose() {
    _syncPollTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currencyController.dispose();
    _prefixController.dispose();
    _serviceChargeController.dispose();
    _footerController.dispose();
    _loyaltyVisitsController.dispose();
    _rewardTextController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final rewardVal = _rewardTextController.text.trim();
    final updateData = {
      'businessName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'currency': _currencyController.text.trim(),
      'invoicePrefix': _prefixController.text.trim(),
      'taxPercentage': 0.0,
      'serviceChargePercentage': double.tryParse(_serviceChargeController.text) ?? 0.0,
      'invoiceFooter': _footerController.text.trim(),
      'loyaltyTargetVisits': int.tryParse(_loyaltyVisitsController.text.trim()) ?? 6,
      'loyaltyRewardType': rewardVal,
      'loyaltyRewardDescription': rewardVal,
    };

    final ok = await ref.read(settingsProvider.notifier).updateSettings(updateData);
    if (ok && mounted) {
      SnackbarUtils.showSuccess(context, 'Settings saved successfully!');
    } else if (mounted) {
      SnackbarUtils.showError(context, 'Failed to save settings');
    }
  }

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Security PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Current 4-Digit PIN'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'New 4-Digit PIN'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Confirm New PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final oldPin = oldPinController.text.trim();
                final newPin = newPinController.text.trim();
                final confirmPin = confirmPinController.text.trim();

                final pinPattern = RegExp(r'^\d{4}$');
                if (!pinPattern.hasMatch(oldPin) || !pinPattern.hasMatch(newPin)) {
                  SnackbarUtils.showError(context, 'PIN must be 4 digits');
                  return;
                }
                if (newPin != confirmPin) {
                  SnackbarUtils.showError(context, 'New PINs do not match');
                  return;
                }

                Navigator.pop(ctx);
                final ok = await ref.read(pinAuthProvider.notifier).changePin(oldPin, newPin);
                if (ok && mounted) {
                  SnackbarUtils.showSuccess(context, 'PIN updated successfully');
                } else if (mounted) {
                  SnackbarUtils.showError(context, 'Incorrect current PIN');
                }
              },
              child: const Text('Save New PIN'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog() {
    AppUpdateDialog.show(context);
  }

  String _formatLastSync(DateTime dt) {
    final now = DateTime.now();
    final isToday = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final timeStr = DateFormat('h:mm a').format(dt);
    if (isToday) return 'Today, $timeStr';
    final yest = now.subtract(const Duration(days: 1));
    final isYest = yest.year == dt.year && yest.month == dt.month && yest.day == dt.day;
    if (isYest) return 'Yesterday, $timeStr';
    return DateFormat('dd MMM, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SettingsState>(settingsProvider, (_, next) {
      _populateSettings(next);
    });
    final state = ref.watch(settingsProvider);
    final syncState = ref.watch(syncProvider);
    final currentTheme = ref.watch(themeProvider);
    _populateSettings(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ═══════════════════════════════════════════
                    // 🎨 APPEARANCE
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.palette_outlined, 'Appearance'),
                    const SizedBox(height: 12),
                    _buildThemeSelector(context, currentTheme),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════
                    // ☁️ CLOUD SYNC
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.cloud_outlined, 'Cloud Synchronization'),
                    const SizedBox(height: 12),
                    _buildSyncCard(context, syncState),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════
                    // 🔒 SECURITY
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.shield_outlined, 'Security'),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.lock, color: Colors.white, size: 20),
                        ),
                        title: const Text('Change Security PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Update your 4-digit access PIN'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showChangePinDialog,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════
                    // 🎁 LOYALTY REWARDS
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.card_giftcard_outlined, 'Loyalty Rewards Program'),
                    const SizedBox(height: 12),
                    _buildLoyaltyCard(),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════
                    // 🏪 STORE DETAILS
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.storefront_outlined, 'Store Details'),
                    const SizedBox(height: 12),
                    _buildStoreDetailsCard(),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════
                    // 🧾 INVOICE & BILLING
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.receipt_long_outlined, 'Invoice & Billing'),
                    const SizedBox(height: 12),
                    _buildInvoiceCard(),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saveSettings,
                      child: const Text(
                        'Save All Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════
                    // 🔄 DATA TRANSFER (EXPORT & IMPORT)
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.swap_vert_rounded, 'Data Transfer & Backup'),
                    const SizedBox(height: 12),
                    _buildDataTransferCard(context, state.settings?.businessName ?? 'FoodBillX'),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════
                    // 📱 APP
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.phone_android_outlined, 'App'),
                    const SizedBox(height: 12),
                    _buildAppSection(context),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════
                    // 🗑️ DATA MANAGEMENT & STORAGE
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(context, Icons.delete_outline_rounded, 'Data Management'),
                    const SizedBox(height: 12),
                    _buildDataManagementSection(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Section Header Widget
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Theme Selector
  // ─────────────────────────────────────────────────────────────────
  Widget _buildThemeSelector(BuildContext context, AppThemeMode currentTheme) {
    final themes = [
      _ThemeOption(
        mode: AppThemeMode.dark,
        label: 'Dark',
        icon: Icons.dark_mode_rounded,
        colors: [AppColors.darkBackground, AppColors.darkSurface, AppColors.darkCard],
        accentColor: AppColors.primary,
      ),
      _ThemeOption(
        mode: AppThemeMode.amoledDark,
        label: 'Ultra Dark',
        icon: Icons.contrast_rounded,
        colors: [AppColors.amoledBackground, AppColors.amoledCard, AppColors.amoledBorder],
        accentColor: AppColors.primary,
      ),
      _ThemeOption(
        mode: AppThemeMode.light,
        label: 'Light',
        icon: Icons.light_mode_rounded,
        colors: [AppColors.lightBackground, AppColors.lightSurface, AppColors.lightCard],
        accentColor: AppColors.primary,
      ),
      _ThemeOption(
        mode: AppThemeMode.saffronDark,
        label: 'Saffron',
        icon: Icons.local_fire_department_rounded,
        colors: [AppColors.saffronBackground, AppColors.saffronSurface, AppColors.saffronCard],
        accentColor: AppColors.saffronPrimary,
      ),
      _ThemeOption(
        mode: AppThemeMode.emeraldDark,
        label: 'Emerald',
        icon: Icons.eco_rounded,
        colors: [AppColors.emeraldBackground, AppColors.emeraldSurface, AppColors.emeraldCard],
        accentColor: AppColors.emeraldPrimary,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Theme',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: themes.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final isSelected = currentTheme == t.mode;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: idx < themes.length - 1 ? 6 : 0),
                    child: GestureDetector(
                      onTap: () => ref.read(themeProvider.notifier).setTheme(t.mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? t.accentColor
                                : Theme.of(context).dividerColor.withAlpha(60),
                            width: isSelected ? 2.2 : 1,
                          ),
                          color: isSelected
                              ? t.accentColor.withAlpha(20)
                              : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mini theme preview
                            Container(
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                gradient: LinearGradient(
                                  colors: t.colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: t.accentColor.withAlpha(80),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 14,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: t.accentColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(
                              t.icon,
                              size: 16,
                              color: isSelected
                                  ? t.accentColor
                                  : Theme.of(context).colorScheme.onSurface.withAlpha(140),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                t.label,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? t.accentColor
                                      : Theme.of(context).colorScheme.onSurface.withAlpha(160),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: isSelected ? t.accentColor : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Cloud Sync Card
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSyncCard(BuildContext context, SyncState syncState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: syncState.isOffline
                      ? Colors.grey.withAlpha(40)
                      : (syncState.pendingCount > 0
                          ? Colors.amber.withAlpha(40)
                          : Colors.green.withAlpha(40)),
                  child: Icon(
                    syncState.isOffline
                        ? Icons.cloud_off_rounded
                        : (syncState.pendingCount > 0
                            ? Icons.cloud_upload_outlined
                            : Icons.cloud_done_rounded),
                    color: syncState.isOffline
                        ? Colors.grey
                        : (syncState.pendingCount > 0
                            ? Colors.amber.shade800
                            : Colors.green),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncState.isSyncing
                            ? 'Uploading... (${CurrencyFormatter.formatInteger(syncState.pendingCount)} remaining)'
                            : (syncState.isOffline
                                ? (syncState.pendingCount > 0
                                    ? 'Offline • ${CurrencyFormatter.formatInteger(syncState.pendingCount)} queued'
                                    : 'Offline')
                                : (syncState.pendingCount > 0
                                    ? '● ${CurrencyFormatter.formatInteger(syncState.pendingCount)} changes queued for upload'
                                    : '✓ Synced with Cloud')),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: syncState.isSyncing
                              ? Theme.of(context).colorScheme.primary
                              : (syncState.isOffline
                                  ? Colors.grey
                                  : (syncState.pendingCount > 0
                                      ? Colors.amber.shade900
                                      : Colors.green.shade700)),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        syncState.isSyncing
                            ? (syncState.syncMessage ?? 'Uploading pending data in batches...')
                            : (syncState.isOffline
                                ? 'Your data is safely stored on this device.'
                                : (syncState.lastSyncedAt != null
                                    ? 'Auto-uploads in background when online • Last: ${_formatLastSync(syncState.lastSyncedAt!)}'
                                    : 'Auto-uploads in background when online • Not synced yet')),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (syncState.isSyncing) ...[
              const SizedBox(height: 12),
              _RunningSyncProgressBar(
                progress: syncState.syncProgress,
                pushedCount: syncState.pushedSyncCount,
                totalCount: syncState.totalSyncCount,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: syncState.isSyncing
                    ? null
                    : () async {
                        final res = await ref.read(syncProvider.notifier).uploadToCloud();
                        if (context.mounted) {
                          if (res.success) {
                            SnackbarUtils.showSuccess(context, res.message);
                          } else {
                            SnackbarUtils.showInfo(context, res.message);
                          }
                        }
                      },
                icon: syncState.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                label: Text(
                  syncState.isSyncing ? 'Uploading...' : 'Upload to Cloud',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Loyalty Card
  // ─────────────────────────────────────────────────────────────────
  Widget _buildLoyaltyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _loyaltyVisitsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reward Visit Milestone',
                hintText: '6',
                prefixIcon: Icon(Icons.stars_rounded),
                helperText: 'Default: Every 6th purchase qualifies for a reward',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 1 ? 'Enter valid visits count (min 1)' : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _rewardTextController,
              decoration: const InputDecoration(
                labelText: 'Reward Benefit / Custom Description *',
                hintText: 'e.g. Free Biryani, Free Egg, 10% Off, ₹50 Discount',
                prefixIcon: Icon(Icons.card_giftcard_rounded),
                helperText: 'Type any custom reward benefit or pick a preset below',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter reward description' : null,
            ),
            const SizedBox(height: 10),
            const Text(
              'Quick Presets:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                '🥤 Free Drink',
                '🥚 Free Egg',
                '🍗 Free Chicken',
                '🏷️ 10% Discount',
                '💰 ₹50 Off',
                '🍛 Free Biryani',
              ].map((preset) {
                return ActionChip(
                  label: Text(preset, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _rewardTextController.text = preset.replaceAll(RegExp(r'^[^\s]+\s*'), '');
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Store Details Card
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStoreDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.store)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Invoice & Billing Card
  // ─────────────────────────────────────────────────────────────────
  Widget _buildInvoiceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prefixController,
                    decoration: const InputDecoration(labelText: 'Invoice Prefix', hintText: 'B'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(labelText: 'Currency Symbol', hintText: '₹'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serviceChargeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Service Charge (%)', prefixIcon: Icon(Icons.room_service_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _footerController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Invoice Footer', prefixIcon: Icon(Icons.notes_rounded)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Data Transfer Card (Single Export & Import Buttons)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDataTransferCard(BuildContext context, String businessName) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_vert_rounded, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Transfer & Backup',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Export reports, orders & customer data or import from CSV',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isExporting || _isImporting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isExporting ? 'Generating export file...' : 'Importing data into local database...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Single Export Data and Single Import Data Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 20),
                    label: const Text(
                      'Export Data',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: (_isExporting || _isImporting)
                        ? null
                        : () => _showExportDialog(context, businessName),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(150)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.file_upload_outlined, size: 20),
                    label: const Text(
                      'Import Data',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: (_isExporting || _isImporting)
                        ? null
                        : () => _showImportDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────
  // Export Data Popup (Dropdown selectors: Category, Date Slicer & Format)
  // ─────────────────────────────────────────────────────────────────
  void _showExportDialog(BuildContext context, String businessName) {
    ExportCategory selectedCategory = ExportCategory.orders;
    ExportDateRange selectedDateRange = ExportDateRange.allTime;
    ExportFormat selectedFormat = ExportFormat.excel;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime customFromDate = today.subtract(const Duration(days: 6));
    DateTime customToDate = today;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isBackup = selectedCategory == ExportCategory.backup;
            final isCustomerOnly = selectedCategory == ExportCategory.customers;
            final effectiveFormat = isBackup ? ExportFormat.excel : selectedFormat;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_download_outlined, color: Colors.teal, size: 24),
                      SizedBox(width: 10),
                      Text('Export Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Choose export category, date timeframe, and file format:',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // 1. Report Category Dropdown
                    _buildDropdownSection(
                      context: context,
                      label: 'Export Category',
                      icon: Icons.category_outlined,
                      child: DropdownButton<ExportCategory>(
                        value: selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: const [
                          DropdownMenuItem(
                            value: ExportCategory.reports,
                            child: Text('Business Report', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          DropdownMenuItem(
                            value: ExportCategory.customers,
                            child: Text('Customer Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          DropdownMenuItem(
                            value: ExportCategory.orders,
                            child: Text('Order Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          DropdownMenuItem(
                            value: ExportCategory.backup,
                            child: Text('Full Backup (Excel only)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Date Range / Timeframe Slicer Dropdown
                    _buildDropdownSection(
                      context: context,
                      label: isCustomerOnly ? 'Customer Scope' : 'Date Range (Timeframe)',
                      icon: Icons.date_range_outlined,
                      child: isCustomerOnly
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text('All Registered Customers', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            )
                          : DropdownButton<ExportDateRange>(
                              value: selectedDateRange,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: const [
                                DropdownMenuItem(value: ExportDateRange.allTime, child: Text('All Time (Full History)', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: ExportDateRange.today, child: Text('Today Only', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: ExportDateRange.thisMonth, child: Text('This Month', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: ExportDateRange.last1Month, child: Text('Last 1 Month (Past 30 Days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                DropdownMenuItem(value: ExportDateRange.last2Months, child: Text('Last 2 Months (Past 60 Days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                DropdownMenuItem(value: ExportDateRange.last3Months, child: Text('Last 3 Months (Past 90 Days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                DropdownMenuItem(value: ExportDateRange.last6Months, child: Text('Last 6 Months (Past 180 Days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                DropdownMenuItem(value: ExportDateRange.custom, child: Text('Custom Date Range (From - To)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedDateRange = val;
                                  });
                                }
                              },
                            ),
                    ),
                    if (!isCustomerOnly && selectedDateRange == ExportDateRange.custom) ...[
                      const SizedBox(height: 12),
                      InlineFromToDatePickers(
                        fromDate: customFromDate,
                        toDate: customToDate,
                        includeOrders: true,
                        includeExpenses: selectedCategory != ExportCategory.orders,
                        excludeRefundedOrders: selectedCategory != ExportCategory.orders,
                        onFromChanged: (d) {
                          setDialogState(() {
                            customFromDate = d;
                            if (customToDate.isBefore(customFromDate)) {
                              customToDate = customFromDate;
                            }
                          });
                        },
                        onToChanged: (d) {
                          setDialogState(() => customToDate = d);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 3. Format Dropdown (Excel vs PDF)
                    _buildDropdownSection(
                      context: context,
                      label: 'File Format',
                      icon: Icons.tune_rounded,
                      child: isBackup
                          ? Row(
                              children: [
                                Icon(Icons.table_chart_rounded, color: Colors.green.shade700, size: 18),
                                const SizedBox(width: 8),
                                const Text('Excel (.xlsx) - Full Archive', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text('Excel only', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                ),
                              ],
                            )
                          : DropdownButton<ExportFormat>(
                              value: selectedFormat,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: const [
                                DropdownMenuItem(
                                  value: ExportFormat.excel,
                                  child: Row(
                                    children: [
                                      Icon(Icons.table_chart_rounded, color: Colors.green, size: 18),
                                      SizedBox(width: 8),
                                      Text('Excel Spreadsheet (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ExportFormat.pdf,
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 18),
                                      SizedBox(width: 8),
                                      Text('Executive PDF (.pdf)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedFormat = val;
                                  });
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 18),

                    // Action Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveFormat == ExportFormat.excel ? Colors.green.shade700 : Colors.redAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(effectiveFormat == ExportFormat.excel ? Icons.table_chart_rounded : Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(
                        'Export ${_getCategoryName(selectedCategory)} (${effectiveFormat == ExportFormat.excel ? "Excel" : "PDF"})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _handleExportExecution(
                          businessName: businessName,
                          category: selectedCategory,
                          range: selectedDateRange,
                          format: effectiveFormat,
                          customFromDate: customFromDate,
                          customToDate: customToDate,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Import Data Popup (Unified Single Excel Importer)
  // ─────────────────────────────────────────────────────────────────
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.file_upload_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  const Text('Import App Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(90)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.table_chart_rounded, size: 38, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 10),
                      const Text(
                        'Import Excel Backup (.xlsx)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accepts complete app backups or single-sheet files. Sheet names are automatically recognized:\n• "Orders" (past bills & sales)\n• "Customers" (contacts & loyalty)\n• "Menu" (categories & items)\n• "Expenses" & "Settings"\n\nAny single sheet or combination will be cleanly ingested.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.file_open_rounded, size: 18),
                  label: const Text(
                    'Pick Excel File (.xlsx)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _importTotalAppData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownSection({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withAlpha(120)),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
      ],
    );
  }

  String _getCategoryName(ExportCategory cat) {
    switch (cat) {
      case ExportCategory.orders:
        return 'Order Data';
      case ExportCategory.customers:
        return 'Customer Data';
      case ExportCategory.reports:
        return 'Business Report';
      case ExportCategory.backup:
        return 'Full Backup';
    }
  }

  (DateTime?, DateTime?, String) _resolveRangeBounds(
    ExportDateRange range, {
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    switch (range) {
      case ExportDateRange.allTime:
        return (null, null, 'All Time');
      case ExportDateRange.today:
        return (DateTime(now.year, now.month, now.day), todayEnd, 'Today');
      case ExportDateRange.thisMonth:
        return (DateTime(now.year, now.month, 1), todayEnd, 'This Month');
      case ExportDateRange.last1Month:
        return (now.subtract(const Duration(days: 30)), todayEnd, 'Last 1 Month');
      case ExportDateRange.last2Months:
        return (now.subtract(const Duration(days: 60)), todayEnd, 'Last 2 Months');
      case ExportDateRange.last3Months:
        return (now.subtract(const Duration(days: 90)), todayEnd, 'Last 3 Months');
      case ExportDateRange.last6Months:
        return (now.subtract(const Duration(days: 180)), todayEnd, 'Last 6 Months');
      case ExportDateRange.custom:
        final f = customFrom ?? now.subtract(const Duration(days: 6));
        final t = customTo ?? now;
        final orderedStart = f.isAfter(t) ? t : f;
        final orderedEnd = f.isAfter(t) ? f : t;
        final s = DateTime(orderedStart.year, orderedStart.month, orderedStart.day, 0, 0, 0);
        final e = DateTime(orderedEnd.year, orderedEnd.month, orderedEnd.day, 23, 59, 59, 999);
        final label = '${DateFormat('dd MMM yyyy').format(s)} - ${DateFormat('dd MMM yyyy').format(e)}';
        return (s, e, label);
    }
  }

  Future<void> _handleExportExecution({
    required String businessName,
    required ExportCategory category,
    required ExportDateRange range,
    required ExportFormat format,
    DateTime? customFromDate,
    DateTime? customToDate,
  }) async {
    final (startDate, endDate, rangeLabel) = _resolveRangeBounds(
      range,
      customFrom: customFromDate,
      customTo: customToDate,
    );

    switch (category) {
      case ExportCategory.orders:
        await _exportOrders(businessName, format, startDate, endDate, rangeLabel);
        break;
      case ExportCategory.customers:
        await _exportCustomers(businessName, format, rangeLabel);
        break;
      case ExportCategory.reports:
        await _exportReports(businessName, format, startDate, endDate, rangeLabel);
        break;
      case ExportCategory.backup:
        await _exportTotalBackup(businessName, startDate, endDate, rangeLabel);
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Export & Import Handlers
  // ─────────────────────────────────────────────────────────────────
  Future<void> _exportReports(
    String businessName,
    ExportFormat format,
    DateTime? startDate,
    DateTime? endDate,
    String dateRangeLabel,
  ) async {
    setState(() => _isExporting = true);
    try {
      final baseMetrics = ref.read(dashboardProvider);
      final settings = ref.read(settingsProvider).settings;
      if (startDate == null && endDate == null) {
        await ReportExportHelper.exportReport(
          metrics: baseMetrics,
          businessName: businessName,
          format: format,
          settings: settings,
          dateRangeLabel: dateRangeLabel,
        );
      } else {
        final periodData = await LocalDatabase.instance.computePeriodReports(
          timeframe: 'Custom',
          referenceDate: DateTime.now(),
          customStartDate: startDate,
          customEndDate: endDate,
        );
        final rev = (periodData['revenue'] as num?)?.toDouble() ?? 0.0;
        final exp = (periodData['expenses'] as num?)?.toDouble() ?? 0.0;
        final ord = (periodData['orderCount'] as num?)?.toInt() ?? 0;
        final prof = (periodData['profit'] as num?)?.toDouble() ?? (rev - exp);
        final dishes = (periodData['dishBreakdown'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            baseMetrics.todayDishBreakdown;
        final rawPayments = periodData['paymentAnalytics'] as Map?;
        final payments = <String, double>{
          'cash': (rawPayments?['cash'] as num?)?.toDouble() ?? 0.0,
          'upi': (rawPayments?['upi'] as num?)?.toDouble() ?? 0.0,
          'card': (rawPayments?['card'] as num?)?.toDouble() ?? 0.0,
          'wallet': (rawPayments?['wallet'] as num?)?.toDouble() ?? 0.0,
        };
        final expenseBreakdown = (periodData['expenseBreakdown'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            baseMetrics.expenseBreakdown;
        final customerAnalytics = periodData['customerAnalytics'] is Map
            ? Map<String, dynamic>.from(periodData['customerAnalytics'] as Map)
            : baseMetrics.customerAnalytics;
        final chartPoints = (periodData['chartDataPoints'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [];
        final chartLabels = (periodData['chartLabels'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();

        final sliced = baseMetrics.copyWith(
          todayRevenue: rev,
          todayOrderCount: ord,
          todayExpenseTotal: exp,
          netProfitToday: prof,
          todayDishBreakdown: dishes,
          topSellingItems: dishes,
          paymentAnalytics: payments,
          expenseBreakdown: expenseBreakdown,
          customerAnalytics: customerAnalytics,
          averageBillValue:
              (periodData['averageBillValue'] as num?)?.toDouble() ??
                  baseMetrics.averageBillValue,
          peakSellingHour:
              (periodData['peakSellingHour'] as String?) ??
                  baseMetrics.peakSellingHour,
          hourlyRevenueToday: chartPoints,
        );

        await ReportExportHelper.exportReport(
          metrics: sliced,
          businessName: businessName,
          format: format,
          settings: settings,
          dateRangeLabel: dateRangeLabel,
          isPeriodSlice: true,
          chartLabels: chartLabels,
        );
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export report: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportOrders(
    String businessName,
    ExportFormat format,
    DateTime? startDate,
    DateTime? endDate,
    String dateRangeLabel,
  ) async {
    setState(() => _isExporting = true);
    try {
      final orders = await LocalDatabase.instance.getOrders(
        startDate: startDate,
        endDate: endDate,
        limit: 50000,
      );
      if (orders.isEmpty) {
        if (mounted) SnackbarUtils.showInfo(context, 'No orders found for the selected timeframe ($dateRangeLabel).');
        return;
      }
      final settings = ref.read(settingsProvider).settings;
      await ReportExportHelper.exportOrders(
        orders: orders,
        businessName: businessName,
        format: format,
        settings: settings,
        dateRangeLabel: dateRangeLabel,
      );
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export orders: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCustomers(String businessName, ExportFormat format, String dateRangeLabel) async {
    setState(() => _isExporting = true);
    try {
      final customers = await LocalDatabase.instance.getCustomers();
      if (customers.isEmpty) {
        if (mounted) SnackbarUtils.showInfo(context, 'No customers found to export.');
        return;
      }
      final settings = ref.read(settingsProvider).settings;
      await ReportExportHelper.exportCustomers(
        customers: customers,
        businessName: businessName,
        format: format,
        settings: settings,
        dateRangeLabel: dateRangeLabel,
      );
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export customers: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportTotalBackup(
    String businessName,
    DateTime? startDate,
    DateTime? endDate,
    String dateRangeLabel,
  ) async {
    setState(() => _isExporting = true);
    try {
      final settings = ref.read(settingsProvider).settings;
      await ReportExportHelper.exportCompleteAppBackup(
        db: LocalDatabase.instance,
        businessName: businessName,
        settings: settings,
        startDate: startDate,
        endDate: endDate,
        dateRangeLabel: dateRangeLabel,
      );
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export complete backup: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importTotalAppData() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final picked = result.files.first;
      String? path = picked.path;
      if ((path == null || path.isEmpty) && picked.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final ext = picked.extension ?? 'xlsx';
        final tempFile = File('${tempDir.path}/imported_backup.$ext');
        await tempFile.writeAsBytes(picked.bytes!);
        path = tempFile.path;
      }
      if (path == null || path.isEmpty) {
        if (mounted) SnackbarUtils.showError(context, 'Unable to access the chosen file');
        return;
      }
      final stats = await ReportExportHelper.importTotalAppData(path);

      final ordersCount = stats['orders'] as int? ?? 0;
      final customersCount = stats['customers'] as int? ?? 0;
      final menuCount = stats['menu'] as int? ?? stats['menuItems'] as int? ?? 0;
      final expenseCount = stats['expenses'] as int? ?? 0;
      final settingsImported = stats['settings'] as bool? ?? stats['settingsUpdated'] as bool? ?? false;

      // Reload all providers with fresh data safely
      try {
        await ref.read(ordersProvider.notifier).loadOrders(forceSpinner: true);
      } catch (e) {
        debugPrint('Error refreshing orders: $e');
      }
      try {
        await ref.read(dashboardProvider.notifier).refresh(forceSpinner: true);
      } catch (e) {
        debugPrint('Error refreshing dashboard: $e');
      }
      try {
        await ref.read(customerProvider.notifier).loadCustomers(forceSpinner: true);
      } catch (e) {
        debugPrint('Error refreshing customers: $e');
      }
      try {
        await ref.read(menuProvider.notifier).loadCategoriesAndItems(forceSpinner: true);
      } catch (e) {
        debugPrint('Error refreshing menu: $e');
      }
      try {
        await ref.read(expenseProvider.notifier).loadAll(forceSpinner: true);
      } catch (e) {
        debugPrint('Error refreshing expenses: $e');
      }
      try {
        await ref.read(settingsProvider.notifier).loadSettings();
      } catch (e) {
        debugPrint('Error refreshing settings: $e');
      }
      try {
        await ref.read(syncProvider.notifier).refreshStatus();
        ref.read(syncProvider.notifier).autoSyncIfOnline();
      } catch (_) {}

      final parts = <String>[];
      if (ordersCount > 0) parts.add('$ordersCount Orders');
      if (customersCount > 0) parts.add('$customersCount Customers');
      if (menuCount > 0) parts.add('$menuCount Menu items');
      if (expenseCount > 0) parts.add('$expenseCount Expenses');
      if (settingsImported) parts.add('Settings restored');

      if (mounted) {
        if (parts.isNotEmpty) {
          SnackbarUtils.showSuccess(context, 'Import Successful!\nIngested: ${parts.join(', ')}');
        } else {
          SnackbarUtils.showWarning(context, 'No valid records found in the selected file.');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to import app data: $e\n$stackTrace');
      if (mounted) SnackbarUtils.showError(context, 'Failed to import app data: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // App Section
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAppSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Check for Updates (matches Requirement 1)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
              child: Icon(Icons.system_update_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            title: const Text('Check for Updates', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('v$kCurrentAppVersion (Build $kCurrentVersionCode)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showUpdateDialog,
          ),
          const Divider(height: 1),
          // Replay Onboarding
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.withAlpha(30),
              child: const Icon(Icons.explore_rounded, color: Colors.amber, size: 20),
            ),
            title: const Text('Replay Onboarding Tour', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Interactive feature walkthrough'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref.read(onboardingTourTriggerProvider.notifier).state++;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Storage & Data Management Card
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDataManagementSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.redAccent.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local Data & Storage Reset',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Permanently erase local orders, customers, expenses & database',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                label: const Text(
                  'Clear All Local Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _showClearDataConfirmationDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text('Clear All Data?'),
            ],
          ),
          content: const Text(
            'This action will permanently delete all local bills, orders, expenses, customers, and cached data from this device.\n\nAre you sure you want to proceed? This cannot be undone.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _performClearAllData();
              },
              child: const Text(
                'Clear Everything',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performClearAllData() async {
    try {
      // 1. Wipe SQLite database and recreate clean schema
      await LocalDatabase.instance.clearAllLocalData();

      // 2. Reset in-memory billing cart
      ref.read(billingProvider.notifier).clearCart();

      // 3. Refresh ALL state providers so every screen UI reflects empty state immediately
      ref.read(ordersProvider.notifier).loadOrders(forceSpinner: true);
      ref.read(customerProvider.notifier).loadCustomers();
      ref.read(dashboardProvider.notifier).refresh();
      ref.read(expenseProvider.notifier).loadAll(forceSpinner: true);
      ref.read(menuProvider.notifier).loadCategoriesAndItems(forceSpinner: true);
      await ref.read(settingsProvider.notifier).loadSettings();

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'All local data has been completely erased.');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to clear data: $e');
      }
    }
  }
}

/// Helper class for theme option data.
class _ThemeOption {
  final AppThemeMode mode;
  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color accentColor;

  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
    required this.colors,
    required this.accentColor,
  });
}

/// Animated running-line progress bar shown while cloud sync upload is running.
class _RunningSyncProgressBar extends StatefulWidget {
  final double? progress;
  final int pushedCount;
  final int totalCount;

  const _RunningSyncProgressBar({
    required this.progress,
    required this.pushedCount,
    required this.totalCount,
  });

  @override
  State<_RunningSyncProgressBar> createState() => _RunningSyncProgressBarState();
}

class _RunningSyncProgressBarState extends State<_RunningSyncProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final trackColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withAlpha(24)
        : Colors.black.withAlpha(18);
    final pct = widget.progress != null ? (widget.progress! * 100).round() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.totalCount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.formatInteger(widget.pushedCount)} / ${CurrencyFormatter.formatInteger(widget.totalCount)} synced',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              if (pct != null)
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 7,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final runnerWidth = (totalWidth * 0.34).clamp(48.0, 140.0);
                final fillWidth = widget.progress != null
                    ? (totalWidth * widget.progress!).clamp(0.0, totalWidth)
                    : 0.0;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: trackColor),
                    if (fillWidth > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: fillWidth,
                          height: 7,
                          color: primary.withAlpha(130),
                        ),
                      ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final dx = -runnerWidth +
                            (_controller.value * (totalWidth + runnerWidth));
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: runnerWidth,
                              height: 7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: [
                                    primary.withAlpha(0),
                                    primary,
                                    Colors.white.withAlpha(220),
                                    primary,
                                    primary.withAlpha(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
