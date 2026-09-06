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
    const name = customerData.name?.trim();
    if (!name || name.length < 2) {
      throw new AppError('Customer name is required (minimum 2 characters)', 400);
    }

    const phone = customerData.phone?.trim();
    if (!phone) {
      throw new AppError('Phone number is required', 400);
    }
    if (!/^[6-9]\d{9}$/.test(phone)) {
      throw new AppError('Please provide a valid 10-digit mobile number (starts with 6-9)', 400);
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
      name,
      phone,
      loyaltyCardNumber,
      address: customerData.address?.trim() || '',
      notes: customerData.notes?.trim() || '',
    };

    return await Customer.create(cleanData);
  }

  async updateCustomer(customerId, updateData) {
    if (updateData.name !== undefined) {
      const name = updateData.name.trim();
      if (name.length < 2) {
        throw new AppError('Customer name must be at least 2 characters', 400);
      }
      updateData.name = name;
    }

    if (updateData.phone) {
      const phone = updateData.phone.trim();
      if (!/^[6-9]\d{9}$/.test(phone)) {
        throw new AppError('Please provide a valid 10-digit mobile number (starts with 6-9)', 400);
      }
      const conflict = await Customer.findOne({
        phone,
        _id: { $ne: customerId },
      });
      if (conflict) throw new AppError('A customer with this mobile number already exists.', 400);
      updateData.phone = phone;
    }

    if (updateData.loyaltyCardNumber) {
      const loyaltyCardNumber = updateData.loyaltyCardNumber.trim();
      const cardConflict = await Customer.findOne({
        loyaltyCardNumber,
        _id: { $ne: customerId },
      });
      if (cardConflict) throw new AppError('Another customer with this Loyalty Card Number already exists', 400);
      updateData.loyaltyCardNumber = loyaltyCardNumber;
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
    const card = cardNumber?.trim();
    if (!card) {
      throw new AppError('Loyalty card number is required', 400);
    }

    const existingCard = await Customer.findOne({
      loyaltyCardNumber: card,
      _id: { $ne: customerId },
    });
    if (existingCard) {
      throw new AppError(`Loyalty Card #${card} is already assigned to another customer`, 400);
    }

    const customer = await Customer.findByIdAndUpdate(
      customerId,
      { loyaltyCardNumber: card },
      { new: true }
    );
    if (!customer) throw new AppError('Customer not found', 404);
    return customer;
  }
}

module.exports = new CustomerService();
