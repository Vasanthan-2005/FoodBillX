import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../local_db/isar_database.dart';
import '../local_db/schemas/business_settings_schema.dart';
import '../local_db/schemas/sync_enums.dart';
import '../local_db/schemas/sync_operation_schema.dart';
import '../models/business_settings_model.dart';

/// Repository for business settings (singleton document).
class SettingsRepository {
  final Isar _isar;

  SettingsRepository(this._isar);

  // ── Read ──────────────────────────────────────────────────────

  Future<BusinessSettingsModel?> get() async {
    final schema = await _isar.businessSettingsSchemas.get(1);
    if (schema == null) return null;
    return _toModel(schema);
  }

  Stream<BusinessSettingsModel?> watch() {
    return _isar.businessSettingsSchemas
        .watchObject(1, fireImmediately: true)
        .map((s) => s != null ? _toModel(s) : null);
  }

  // ── Write ─────────────────────────────────────────────────────

  Future<BusinessSettingsModel> upsert(Map<String, dynamic> data) async {
    final now = DateTime.now();
    var schema = await _isar.businessSettingsSchemas.get(1);

    if (schema == null) {
      schema = BusinessSettingsSchema()
        ..businessName = data['businessName'] ?? 'My Food Outlet'
        ..logo = data['logo'] ?? ''
        ..phone = data['phone'] ?? ''
        ..address = data['address'] ?? ''
        ..gstin = data['gstin'] ?? ''
        ..currency = data['currency'] ?? '₹'
        ..invoicePrefix = data['invoicePrefix'] ?? 'INV-'
        ..taxPercentage = (data['taxPercentage'] as num?)?.toDouble() ?? 5.0
        ..serviceChargePercentage =
            (data['serviceChargePercentage'] as num?)?.toDouble() ?? 0.0
        ..invoiceFooter =
            data['invoiceFooter'] ?? 'Thank you for dining with us!'
        ..syncStatus = SyncStatus.pending
        ..updatedAt = now;
    } else {
      if (data.containsKey('businessName')) {
        schema.businessName = data['businessName'];
      }
      if (data.containsKey('logo')) schema.logo = data['logo'];
      if (data.containsKey('phone')) schema.phone = data['phone'];
      if (data.containsKey('address')) schema.address = data['address'];
      if (data.containsKey('gstin')) schema.gstin = data['gstin'];
      if (data.containsKey('currency')) schema.currency = data['currency'];
      if (data.containsKey('invoicePrefix')) {
        schema.invoicePrefix = data['invoicePrefix'];
      }
      if (data.containsKey('taxPercentage')) {
        schema.taxPercentage = (data['taxPercentage'] as num).toDouble();
      }
      if (data.containsKey('serviceChargePercentage')) {
        schema.serviceChargePercentage =
            (data['serviceChargePercentage'] as num).toDouble();
      }
      if (data.containsKey('invoiceFooter')) {
        schema.invoiceFooter = data['invoiceFooter'];
      }
      schema
        ..syncStatus = SyncStatus.pending
        ..updatedAt = now;
    }

    await _isar.writeTxn(() async {
      await _isar.businessSettingsSchemas.put(schema!);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.settings
        ..operationType = schema.serverId != null
            ? SyncOperationType.update
            : SyncOperationType.create
        ..localId = schema.id
        ..serverId = schema.serverId
        ..payload = jsonEncode(data)
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return _toModel(schema);
  }

  // ── Helpers ───────────────────────────────────────────────────

  BusinessSettingsModel _toModel(BusinessSettingsSchema s) {
    return BusinessSettingsModel(
      id: s.serverId ?? s.id.toString(),
      businessName: s.businessName,
      logo: s.logo,
      phone: s.phone,
      address: s.address,
      gstin: s.gstin,
      currency: s.currency,
      invoicePrefix: s.invoicePrefix,
      taxPercentage: s.taxPercentage,
      serviceChargePercentage: s.serviceChargePercentage,
    );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(isarProvider));
});
