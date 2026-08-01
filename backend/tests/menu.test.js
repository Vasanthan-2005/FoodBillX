require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const Category = require('../src/models/Category');
const MenuItem = require('../src/models/MenuItem');

jest.setTimeout(30000);

describe('Menu & Category Integration Tests', () => {
  let createdCategoryId = '';
  let createdItemId = '';

  beforeAll(async () => {
    const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017/foodbillx_test';
    if (mongoose.connection.readyState === 0) {
      await mongoose.connect(mongoUri);
    }

    // Keep reruns deterministic even if a previous test process was interrupted.
    await MenuItem.deleteMany({ name: 'Samosa Chat' });
    await Category.deleteMany({ name: 'Snacks Test' });
  });

  afterAll(async () => {
    if (createdItemId) await MenuItem.findByIdAndDelete(createdItemId);
    if (createdCategoryId) await Category.findByIdAndDelete(createdCategoryId);
    await mongoose.connection.close();
  });

  it('should create a new food category', async () => {
    const res = await request(app)
      .post('/api/v1/categories')
      .send({
        name: 'Snacks Test',
        icon: 'snack_icon',
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.category.name).toBe('Snacks Test');
    createdCategoryId = res.body.data.category._id;
  });

  it('should fetch categories list', async () => {
    const res = await request(app).get('/api/v1/categories');
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data.categories)).toBe(true);
  });

  it('should create a new menu item', async () => {
    const res = await request(app)
      .post('/api/v1/menu-items')
      .send({
        category: createdCategoryId,
        name: 'Samosa Chat',
        description: 'Crispy samosa with curd & chutney',
        price: 80,
        gstPercentage: 5,
        isVeg: true,
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.item.name).toBe('Samosa Chat');
    createdItemId = res.body.data.item._id;
  });

  it('should toggle item availability', async () => {
    const res = await request(app)
      .patch(`/api/v1/menu-items/${createdItemId}/toggle-availability`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.item.isAvailable).toBe(false);
  });
});
