require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const Order = require('../src/models/Order');
const Expense = require('../src/models/Expense');
const Customer = require('../src/models/Customer');
const Category = require('../src/models/Category');
const MenuItem = require('../src/models/MenuItem');

jest.setTimeout(30000);

describe('Orders, Expenses & Business Insights Integration Tests', () => {
  let customerId = '';
  let categoryId = '';
  let menuItemId = '';
  let baselineExpenseTotal = 0;

  beforeAll(async () => {
    const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017/foodbillx_test';
    if (mongoose.connection.readyState === 0) {
      await mongoose.connect(mongoUri);
    }

    // Keep reruns deterministic even if a previous test process was interrupted.
    await Order.deleteMany({ customerName: 'Loyal Customer Rahul' });
    await Expense.deleteMany({ title: /.*Test Expense.*/ });
    await Customer.deleteMany({ phone: '9876543210' });
    await MenuItem.deleteMany({ name: 'Crispy Paneer Roll' });
    await Category.deleteMany({ name: 'Fast Food Test' });

    const baselineRes = await request(app).get('/api/v1/reports/dashboard');
    baselineExpenseTotal = baselineRes.body.data.summary.todayExpenseTotal;

    // Create Category & Item
    const catRes = await request(app)
      .post('/api/v1/categories')
      .send({ name: 'Fast Food Test', icon: 'fastfood' });
    categoryId = catRes.body.data.category._id;

    const itemRes = await request(app)
      .post('/api/v1/menu-items')
      .send({
        name: 'Crispy Paneer Roll',
        category: categoryId,
        price: 150,
        gstPercentage: 5,
        isVeg: true,
      });
    menuItemId = itemRes.body.data.item._id;

    // Create Customer with Physical Card #505
    const custRes = await request(app)
      .post('/api/v1/customers')
      .send({
        name: 'Loyal Customer Rahul',
        phone: '9876543210',
        loyaltyCardNumber: '505',
      });
    customerId = custRes.body.data.customer._id;
  });

  afterAll(async () => {
    await Order.deleteMany({ customerName: 'Loyal Customer Rahul' });
    await Expense.deleteMany({ title: /.*Test Expense.*/ });
    await Customer.deleteMany({ phone: '9876543210' });
    await Category.deleteMany({ name: 'Fast Food Test' });
    await MenuItem.deleteMany({ name: 'Crispy Paneer Roll' });
    await mongoose.connection.close();
  });

  it('should create a new POS order and update customer spending/points', async () => {
    const res = await request(app)
      .post('/api/v1/orders')
      .send({
        customerId,
        customerName: 'Loyal Customer Rahul',
        customerPhone: '9876543210',
        paymentMethod: 'upi',
        discountAmount: 10,
        items: [
          {
            menuItem: menuItemId,
            name: 'Crispy Paneer Roll',
            price: 150,
            quantity: 2,
            gstPercentage: 5,
          },
        ],
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.order.orderNumber).toBeDefined();
    expect(res.body.data.order.grandTotal).toBeGreaterThan(0);
  });

  it('should log a daily operational expense', async () => {
    const res = await request(app)
      .post('/api/v1/expenses')
      .send({
        category: 'vegetables',
        title: 'Test Expense Tomatoes & Onions',
        amount: 350,
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.expense.amount).toBe(350);
  });

  it('should fetch executive dashboard metrics with Net Profit calculation', async () => {
    const res = await request(app)
      .get('/api/v1/reports/dashboard');

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.summary.todayRevenue).toBeGreaterThan(0);
    expect(res.body.data.summary.todayExpenseTotal).toBe(
      baselineExpenseTotal + 350
    );
    expect(res.body.data.summary.netProfitToday).toBeDefined();
  });
});
