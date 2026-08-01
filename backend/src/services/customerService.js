const Customer = require('../models/Customer');
const AppError = require('../utils/appError');
const recordSyncDeletion = require('../utils/recordSyncDeletion');

class CustomerService {
  async getCustomers(query = {}) {
    const { search, cardNumber } = query;
    const filter = {};

    if (cardNumber) {
      filter.loyaltyCardNumber = cardNumber.trim();
    } else if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { loyaltyCardNumber: { $regex: search, $options: 'i' } },
      ];
    }

    return await Customer.find(filter).sort({ totalSpent: -1, name: 1 });
  }

  async createCustomer(customerData) {
    const existing = await Customer.findOne({ phone: customerData.phone.trim() });
    if (existing) {
      throw new AppError('Customer with this phone number already exists', 400);
    }
    return await Customer.create(customerData);
  }

  async updateCustomer(customerId, updateData) {
    // Prevent phone collision with another customer
    if (updateData.phone) {
      const conflict = await Customer.findOne({
        phone: updateData.phone.trim(),
        _id: { $ne: customerId },
      });
      if (conflict) throw new AppError('Another customer with this phone number already exists', 400);
    }
    const customer = await Customer.findByIdAndUpdate(
      customerId,
      updateData,
      { new: true, runValidators: true }
    );
    if (!customer) throw new AppError('Customer not found', 404);
    return customer;
  }

  async deleteCustomer(customerId) {
    const customer = await Customer.findByIdAndDelete(customerId);
    if (!customer) throw new AppError('Customer not found', 404);
    await recordSyncDeletion('customer', customer._id);
    return { message: 'Customer deleted successfully' };
  }

  async assignLoyaltyCard(customerId, cardNumber) {
    const existingCard = await Customer.findOne({
      loyaltyCardNumber: cardNumber.trim(),
      _id: { $ne: customerId },
    });
    if (existingCard) {
      throw new AppError(`Loyalty Card #${cardNumber} is already assigned to another customer`, 400);
    }

    const customer = await Customer.findByIdAndUpdate(
      customerId,
      { loyaltyCardNumber: cardNumber.trim() },
      { new: true }
    );
    if (!customer) throw new AppError('Customer not found', 404);
    return customer;
  }
}

module.exports = new CustomerService();
