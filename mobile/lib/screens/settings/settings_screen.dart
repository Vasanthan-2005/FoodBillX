import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sync/connectivity_service.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_status_notifier.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/pin_auth_provider.dart';
import '../../providers/settings_provider.dart';

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
  late TextEditingController _gstinController;
  late TextEditingController _currencyController;
  late TextEditingController _prefixController;
  late TextEditingController _taxController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).settings;
    _nameController = TextEditingController(text: settings?.businessName ?? '');
    _phoneController = TextEditingController(text: settings?.phone ?? '');
    _addressController = TextEditingController(text: settings?.address ?? '');
    _gstinController = TextEditingController(text: settings?.gstin ?? '');
    _currencyController = TextEditingController(
      text: settings?.currency ?? '₹',
    );
    _prefixController = TextEditingController(
      text: settings?.invoicePrefix ?? 'INV-',
    );
    _taxController = TextEditingController(
      text: settings?.taxPercentage.toString() ?? '5.0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _currencyController.dispose();
    _prefixController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final updateData = {
      'businessName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'gstin': _gstinController.text.trim(),
      'currency': _currencyController.text.trim(),
      'invoicePrefix': _prefixController.text.trim(),
      'taxPercentage': double.tryParse(_taxController.text) ?? 5.0,
    };

    final ok = await ref
        .read(settingsProvider.notifier)
        .updateSettings(updateData);
    if (ok && mounted) {
      SnackbarUtils.showSuccess(
        context,
        'Business settings saved successfully',
      );
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
                decoration: const InputDecoration(
                  labelText: 'Current 4-Digit PIN',
                ),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPin = oldPinController.text.trim();
                final newPin = newPinController.text.trim();
                final confirmPin = confirmPinController.text.trim();

                if (oldPin.length != 4 || newPin.length != 4) {
                  SnackbarUtils.showError(context, 'PIN must be 4 digits');
                  return;
                }
                if (newPin != confirmPin) {
                  SnackbarUtils.showError(context, 'New PINs do not match');
                  return;
                }

                Navigator.pop(ctx);
                final ok = await ref
                    .read(pinAuthProvider.notifier)
                    .changePin(oldPin, newPin);
                if (ok && mounted) {
                  SnackbarUtils.showSuccess(
                    context,
                    'PIN updated successfully',
                  );
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.asData?.value ?? false;

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
                    // Offline-First & Sync Status Section
                    Text(
                      'Offline-First & Cloud Sync',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isOnline
                                      ? 'Online (Connected)'
                                      : 'Offline Mode (Local Storage)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      syncStatus.isSyncing
                                          ? 'Syncing in progress...'
                                          : syncStatus.pendingCount > 0
                                          ? '${syncStatus.pendingCount} pending changes'
                                          : 'All changes synced with cloud',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (syncStatus.lastSyncedAt != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Last synced: ${syncStatus.lastSyncedAt!.hour}:${syncStatus.lastSyncedAt!.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: syncStatus.isSyncing
                                      ? null
                                      : () async {
                                          await ref
                                              .read(syncServiceProvider)
                                              .syncNow();
                                        },
                                  icon: syncStatus.isSyncing
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.sync_rounded,
                                          size: 18,
                                        ),
                                  label: Text(
                                    syncStatus.isSyncing
                                        ? 'Syncing...'
                                        : 'Sync Now',
                                  ),
                                ),
                              ],
                            ),
                            if (syncStatus.lastError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Sync warning: ${syncStatus.lastError}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Security Section
                    Text(
                      'Security & App Lock',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Change Security PIN',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Update your local 4-digit POS PIN',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showChangePinDialog,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            secondary: const Icon(Icons.fingerprint),
                            title: const Text('Biometric / Face Unlock'),
                            subtitle: const Text(
                              'Use Fingerprint or Face ID (Coming in V2)',
                            ),
                            value: false,
                            onChanged: null,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.screen_lock_portrait,
                              color: Colors.orange,
                            ),
                            title: const Text(
                              'Lock App Now',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Require PIN to resume application',
                            ),
                            onTap: () {
                              ref.read(pinAuthProvider.notifier).lockApp();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Store Details Section
                    Text(
                      'Store Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Business / Shop Name',
                                prefixIcon: Icon(Icons.store),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _gstinController,
                              decoration: const InputDecoration(
                                labelText: 'GSTIN Number (Optional)',
                                prefixIcon: Icon(Icons.receipt),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Billing & Invoice Settings
                    Text(
                      'Invoice & Tax Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _prefixController,
                                    decoration: const InputDecoration(
                                      labelText: 'Invoice Prefix',
                                      hintText: 'INV-',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _currencyController,
                                    decoration: const InputDecoration(
                                      labelText: 'Currency Symbol',
                                      hintText: '₹',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _taxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Default Tax Rate (%)',
                                prefixIcon: Icon(Icons.percent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: _saveSettings,
                      child: const Text(
                        'Save Business Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
