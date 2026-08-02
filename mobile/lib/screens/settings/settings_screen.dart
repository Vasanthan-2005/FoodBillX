import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/onboarding_dialog.dart';
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
  late TextEditingController _currencyController;
  late TextEditingController _prefixController;
  late TextEditingController _serviceChargeController;
  late TextEditingController _footerController;
  late TextEditingController _loyaltyVisitsController;
  late TextEditingController _rewardTextController;
  bool _didPopulateSettings = false;

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
      SnackbarUtils.showSuccess(context, 'Business and Loyalty settings saved!');
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

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiEndpoints.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Backend Server Connection', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter backend server URL or IP:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server Base URL / IP',
                prefixIcon: Icon(Icons.dns_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              Navigator.pop(ctx);
              await ApiEndpoints.saveCustomServerUrl(newUrl);
              if (mounted) {
                SnackbarUtils.showSuccess(context, 'Server URL updated');
                ref.read(menuProvider.notifier).loadCategoriesAndItems(forceSpinner: true);
                ref.read(customerProvider.notifier).loadCustomers(forceSpinner: true);
                ref.read(dashboardProvider.notifier).refresh(forceSpinner: true);
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
                    // Security & Server
                    Text(
                      'Security & Connection',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.lock, color: Colors.white, size: 20),
                            ),
                            title: const Text('Change Security PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showChangePinDialog,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.dns_rounded, color: Colors.white, size: 20),
                            ),
                            title: const Text('Server Connection & Host IP', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Target: ${ApiEndpoints.baseUrl}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showServerConfigDialog,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.amber,
                              child: Icon(Icons.explore_rounded, color: Colors.white, size: 20),
                            ),
                            title: const Text('Replay App Onboarding Tour', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Interactive feature walkthrough for staff'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => OnboardingDialog.forceShow(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Customer Loyalty Rewards Settings
                    Text(
                      'Loyalty Rewards Program',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Card(
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
                    ),
                    const SizedBox(height: 24),

                    // Store Details
                    Text(
                      'Store Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Card(
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
                    ),
                    const SizedBox(height: 24),

                    // Invoice & Billing Settings
                    Text(
                      'Invoice & Billing Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: _saveSettings,
                      child: const Text(
                        'Save All Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
