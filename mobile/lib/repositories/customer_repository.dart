import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<CustomerModel>> getAll({
    String? search,
    String? cardNumber,
    String? phone,
  }) async {
    return await _localDb.getCustomers(
      search: search,
      phone: phone,
      cardNumber: cardNumber,
    );
  }

  Future<CustomerModel> create(Map<String, dynamic> data) async {
    return await _localDb.insertCustomer(data);
  }

  Future<CustomerModel> update(String id, Map<String, dynamic> data) async {
    final updated = await _localDb.updateCustomer(id, data);
    if (updated == null) {
      throw Exception('Customer not found');
    }
    return updated;
  }

  Future<void> delete(String id) async {
    await _localDb.deleteCustomer(id);
  }

  Future<CustomerModel> assignLoyaltyCard(String id, String cardNumber) async {
    final updated = await _localDb.updateCustomer(id, {'loyaltyCardNumber': cardNumber});
    if (updated == null) {
      throw Exception('Customer not found');
    }
    return updated;
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});
