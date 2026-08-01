import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/menu_provider.dart';
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
  late TextEditingController _serviceChargeController;
  late TextEditingController _footerController;
  bool _didPopulateSettings = false;

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
    _serviceChargeController = TextEditingController(
      text: settings?.serviceChargePercentage.toString() ?? '0.0',
    );
    _footerController = TextEditingController(
      text: settings?.invoiceFooter ?? 'Thank you for dining with us!',
    );
    _didPopulateSettings = settings != null;
  }

  void _populateSettings(SettingsState state) {
    final settings = state.settings;
    if (_didPopulateSettings || settings == null) return;
    _didPopulateSettings = true;
    _nameController.text = settings.businessName;
    _phoneController.text = settings.phone;
    _addressController.text = settings.address;
    _gstinController.text = settings.gstin;
    _currencyController.text = settings.currency;
    _prefixController.text = settings.invoicePrefix;
    _taxController.text = settings.taxPercentage.toString();
    _serviceChargeController.text = settings.serviceChargePercentage.toString();
    _footerController.text = settings.invoiceFooter;
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
    _serviceChargeController.dispose();
    _footerController.dispose();
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
      'serviceChargePercentage':
          double.tryParse(_serviceChargeController.text) ?? 0.0,
      'invoiceFooter': _footerController.text.trim(),
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

                final pinPattern = RegExp(r'^\d{4}$');
                if (!pinPattern.hasMatch(oldPin) ||
                    !pinPattern.hasMatch(newPin)) {
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
    ).whenComplete(() {
      oldPinController.dispose();
      newPinController.dispose();
      confirmPinController.dispose();
    });
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiEndpoints.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Backend Server Connection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend server URL or IP address of your host machine running FoodBillX backend:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server Base URL / IP',
                hintText: 'http://192.168.0.176:5000/api/v1',
                prefixIcon: Icon(Icons.dns_rounded),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Quick Presets:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Wi-Fi LAN IP (192.168.0.176)'),
                  onPressed: () {
                    controller.text = ApiEndpoints.defaultLanIp;
                  },
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  onPressed: () {
                    controller.text = ApiEndpoints.emulatorIp;
                  },
                ),
                ActionChip(
                  label: const Text('Localhost (127.0.0.1)'),
                  onPressed: () {
                    controller.text = ApiEndpoints.localhostIp;
                  },
                ),
              ],
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
              final newUrl = controller.text.trim();
              Navigator.pop(ctx);
              await ApiEndpoints.saveCustomServerUrl(newUrl);
              if (mounted) {
                SnackbarUtils.showSuccess(
                  context,
                  'Server URL updated to $newUrl',
                );
                ref
                    .read(menuProvider.notifier)
                    .loadCategoriesAndItems(forceSpinner: true);
                ref
                    .read(customerProvider.notifier)
                    .loadCustomers(forceSpinner: true);
                ref
                    .read(dashboardProvider.notifier)
                    .refresh(forceSpinner: true);
                ref.read(settingsProvider.notifier).loadSettings();
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SettingsState>(settingsProvider, (_, next) {
      _populateSettings(next);
    });
    final state = ref.watch(settingsProvider);
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
                          const Divider(height: 1),
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.dns_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Server Connection & Host IP',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Target: ${ApiEndpoints.baseUrl}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showServerConfigDialog,
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
                              validator: (value) {
                                final rate = double.tryParse(value ?? '');
                                return rate == null || rate < 0 || rate > 100
                                    ? 'Enter a percentage from 0 to 100'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _serviceChargeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Service Charge (%)',
                                prefixIcon: Icon(Icons.room_service_outlined),
                              ),
                              validator: (value) {
                                final rate = double.tryParse(value ?? '');
                                return rate == null || rate < 0 || rate > 100
                                    ? 'Enter a percentage from 0 to 100'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _footerController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Invoice Footer',
                                prefixIcon: Icon(Icons.notes_rounded),
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
