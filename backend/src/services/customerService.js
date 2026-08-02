const Customer = require('../models/Customer');
const AppError = require('../utils/appError');

class CustomerService {
  async getCustomers(query = {}) {
    const { search, cardNumber, phone } = query;
    const filter = {};

    if (phone) {
      filter.phone = phone.trim();
    } else if (cardNumber) {
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
    const phone = customerData.phone?.trim();
    if (!phone) {
      throw new AppError('Phone number is required', 400);
    }

    const existingPhone = await Customer.findOne({ phone });
    if (existingPhone) {
      throw new AppError('Customer already exists with this mobile number.', 400);
    }

    let loyaltyCardNumber = customerData.loyaltyCardNumber?.trim();
    if (loyaltyCardNumber) {
      const existingCard = await Customer.findOne({ loyaltyCardNumber });
      if (existingCard) {
        throw new AppError('Customer with this Loyalty Card Number already exists', 400);
      }
    } else {
      loyaltyCardNumber = `HMB-${Math.floor(100000 + Math.random() * 900000)}`;
    }

    const cleanData = {
      name: customerData.name?.trim(),
      phone,
      loyaltyCardNumber,
      address: customerData.address?.trim() || '',
      notes: customerData.notes?.trim() || '',
    };

    return await Customer.create(cleanData);
  }

  async updateCustomer(customerId, updateData) {
    if (updateData.phone) {
      const conflict = await Customer.findOne({
        phone: updateData.phone.trim(),
        _id: { $ne: customerId },
      });
      if (conflict) throw new AppError('A customer with this mobile number already exists.', 400);
    }

    if (updateData.loyaltyCardNumber) {
      const cardConflict = await Customer.findOne({
        loyaltyCardNumber: updateData.loyaltyCardNumber.trim(),
        _id: { $ne: customerId },
      });
      if (cardConflict) throw new AppError('Another customer with this Loyalty Card Number already exists', 400);
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
