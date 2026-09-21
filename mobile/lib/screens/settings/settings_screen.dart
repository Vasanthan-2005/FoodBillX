import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_update_service.dart';
import '../../core/storage/local_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/report_export_helper.dart';
import '../../core/utils/snackbar_utils.dart';
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
              children: themes.map((t) {
                final isSelected = currentTheme == t.mode;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: t.mode != AppThemeMode.emeraldDark ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => ref.read(themeProvider.notifier).setTheme(t.mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? t.accentColor
                                : Theme.of(context).dividerColor.withAlpha(60),
                            width: isSelected ? 2.5 : 1,
                          ),
                          color: isSelected
                              ? t.accentColor.withAlpha(20)
                              : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            // Mini theme preview
                            Container(
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
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
                                  width: 18,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: t.accentColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              t.icon,
                              size: 18,
                              color: isSelected
                                  ? t.accentColor
                                  : Theme.of(context).colorScheme.onSurface.withAlpha(140),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? t.accentColor
                                    : Theme.of(context).colorScheme.onSurface.withAlpha(160),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Icon(Icons.check_circle_rounded, size: 16, color: t.accentColor),
                            ],
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
                        syncState.isOffline
                            ? 'Offline'
                            : (syncState.pendingCount > 0
                                ? '● ${syncState.pendingCount} changes queued for upload'
                                : '✓ Synced with Cloud'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: syncState.isOffline
                              ? Colors.grey
                              : (syncState.pendingCount > 0
                                  ? Colors.amber.shade900
                                  : Colors.green.shade700),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        syncState.isOffline
                            ? 'Your data is safely stored on this device.'
                            : (syncState.lastSyncedAt != null
                                ? 'Auto-uploads in background when online • Last: ${_formatLastSync(syncState.lastSyncedAt!)}'
                                : 'Auto-uploads in background when online • Not synced yet'),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
  // Export Data Popup (3 Options: Business Reports, Orders, Customers)
  // ─────────────────────────────────────────────────────────────────
  void _showExportDialog(BuildContext context, String businessName) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                  'Select the data category you wish to export:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Option 1: Business Reports
                _buildPopupOptionCard(
                  icon: Icons.analytics_outlined,
                  iconColor: Colors.orangeAccent,
                  title: '1. Business Reports',
                  subtitle: 'Financial summary, revenue, profit & dish leaderboard',
                  actions: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Excel (.csv)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _exportSummaryExcel(businessName);
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('PDF Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _exportSummaryPdf(businessName);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Option 2: Order / Sales Data
                _buildPopupOptionCard(
                  icon: Icons.receipt_long_rounded,
                  iconColor: Colors.blueAccent,
                  title: '2. Order / Sales Data',
                  subtitle: 'Complete bill register with customer, payment & items',
                  actions: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Excel (.csv)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _exportOrdersExcel(businessName);
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('PDF Ledger', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _exportOrdersPdf(businessName);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Option 3: Customer Data
                _buildPopupOptionCard(
                  icon: Icons.people_alt_outlined,
                  iconColor: Colors.teal,
                  title: '3. Customer Data',
                  subtitle: 'Customer contacts, visit history & loyalty points',
                  actions: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Excel (.csv)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _exportCustomersExcel(businessName);
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('PDF Directory', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _exportCustomersPdf(businessName);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Import Data Popup (3 Options: Business Reports, Orders, Customers)
  // ─────────────────────────────────────────────────────────────────
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.file_upload_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  const Text('Import Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  'Select data category to import into your local database:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Option 1: Business Reports
                _buildPopupOptionCard(
                  icon: Icons.analytics_outlined,
                  iconColor: Colors.orangeAccent,
                  title: '1. Business Reports',
                  subtitle: 'Live-aggregated directly from your imported sales orders',
                  actions: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ref.read(dashboardProvider.notifier).refresh(forceSpinner: true);
                        SnackbarUtils.showInfo(context, 'Reports refreshed from current orders.');
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Reports Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Option 2: Order / Sales Data
                _buildPopupOptionCard(
                  icon: Icons.receipt_long_rounded,
                  iconColor: Colors.blueAccent,
                  title: '2. Order / Sales Data',
                  subtitle: 'Import past bills and order records from a CSV file',
                  actions: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.file_open_outlined, size: 16),
                      label: const Text('Pick Orders CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _importOrdersFromCsv();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Option 3: Customer Data
                _buildPopupOptionCard(
                  icon: Icons.people_alt_outlined,
                  iconColor: Colors.teal,
                  title: '3. Customer Data',
                  subtitle: 'Import customer contacts, addresses & loyalty points from CSV',
                  actions: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.file_open_outlined, size: 16),
                      label: const Text('Pick Customer CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _importCustomersFromCsv();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(children: actions),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Export & Import Handlers
  // ─────────────────────────────────────────────────────────────────
  Future<void> _exportSummaryExcel(String businessName) async {
    setState(() => _isExporting = true);
    try {
      final metrics = ref.read(dashboardProvider);
      await ReportExportHelper.exportReportToExcel(metrics, businessName);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export summary Excel: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportSummaryPdf(String businessName) async {
    setState(() => _isExporting = true);
    try {
      final metrics = ref.read(dashboardProvider);
      await ReportExportHelper.exportReportToPdf(metrics, businessName);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export summary PDF: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportOrdersExcel(String businessName) async {
    setState(() => _isExporting = true);
    try {
      final orders = await LocalDatabase.instance.getOrders(limit: 5000);
      if (orders.isEmpty) {
        if (mounted) SnackbarUtils.showInfo(context, 'No orders found to export.');
        return;
      }
      await ReportExportHelper.exportOrdersToExcel(orders, businessName);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export orders: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportOrdersPdf(String businessName) async {
    setState(() => _isExporting = true);
    try {
      final orders = await LocalDatabase.instance.getOrders(limit: 5000);
      if (orders.isEmpty) {
        if (mounted) SnackbarUtils.showInfo(context, 'No orders found to export.');
        return;
      }
      await ReportExportHelper.exportOrdersToPdf(orders, businessName);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export orders PDF: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCustomersExcel(String businessName) async {
    setState(() => _isExporting = true);
    try {
      final customers = await LocalDatabase.instance.getCustomers();
      if (customers.isEmpty) {
        if (mounted) SnackbarUtils.showInfo(context, 'No customers found to export.');
        return;
      }
      await ReportExportHelper.exportCustomersToExcel(customers, businessName);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export customers Excel: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCustomersPdf(String businessName) async {
    setState(() => _isExporting = true);
    try {
      final customers = await LocalDatabase.instance.getCustomers();
      if (customers.isEmpty) {
        if (mounted) SnackbarUtils.showInfo(context, 'No customers found to export.');
        return;
      }
      await ReportExportHelper.exportCustomersToPdf(customers, businessName);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to export customers PDF: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importOrdersFromCsv() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        return;
      }
      final path = result.files.first.path!;
      final file = File(path);
      final content = await file.readAsString();

      final count = await ReportExportHelper.importOrdersFromCsv(content);
      if (count > 0) {
        ref.read(ordersProvider.notifier).loadOrders(forceSpinner: true);
        ref.read(dashboardProvider.notifier).refresh(forceSpinner: true);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Successfully imported $count order(s) into local database!');
        }
      } else {
        if (mounted) {
          SnackbarUtils.showWarning(context, 'No valid order rows found in the selected CSV file.');
        }
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to import orders: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _importCustomersFromCsv() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        return;
      }
      final path = result.files.first.path!;
      final file = File(path);
      final content = await file.readAsString();

      final count = await ReportExportHelper.importCustomersFromCsv(content);
      if (count > 0) {
        await ref.read(customerProvider.notifier).loadCustomers();
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Successfully imported $count customer(s) into local database!');
        }
      } else {
        if (mounted) {
          SnackbarUtils.showWarning(context, 'No valid customer rows found in the selected CSV file.');
        }
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to import customers: $e');
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
              Navigator.pop(context);
              OnboardingDialog.forceShow(context);
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
