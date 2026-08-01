require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const Category = require('../src/models/Category');
const SyncReceipt = require('../src/models/SyncReceipt');

jest.setTimeout(30000);

describe('Offline sync contract', () => {
  const operationId = 'test-device:category:1';

  beforeAll(async () => {
    const mongoUri =
      process.env.MONGO_URI ||
      process.env.MONGODB_URI ||
      'mongodb://localhost:27017/foodbillx_test';
    if (mongoose.connection.readyState === 0) await mongoose.connect(mongoUri);
    await Category.deleteMany({ name: 'Sync Idempotency Test' });
    await SyncReceipt.deleteMany({ operationId });
  });

  afterAll(async () => {
    await Category.deleteMany({ name: 'Sync Idempotency Test' });
    await SyncReceipt.deleteMany({ operationId });
    await mongoose.connection.close();
  });

  it('rejects malformed batches', async () => {
    const response = await request(app).post('/api/v1/sync/push').send({});
    expect(response.statusCode).toBe(400);
  });

  it('deduplicates a retried create operation', async () => {
    const operation = {
      operationId,
      entityType: 'category',
      operationType: 'create',
      localId: 1,
      payload: { name: 'Sync Idempotency Test', icon: 'sync' },
    };
    const first = await request(app)
      .post('/api/v1/sync/push')
      .send({ operations: [operation] });
    const second = await request(app)
      .post('/api/v1/sync/push')
      .send({ operations: [operation] });

    expect(first.statusCode).toBe(200);
    expect(second.statusCode).toBe(200);
    expect(second.body.data.results[0].serverId).toBe(
      first.body.data.results[0].serverId
    );
    expect(
      await Category.countDocuments({ name: 'Sync Idempotency Test' })
    ).toBe(1);
  });

  it('supports incremental pulls and validates timestamps', async () => {
    const pull = await request(app)
      .get('/api/v1/sync/pull')
      .query({ since: new Date(Date.now() - 60_000).toISOString() });
    expect(pull.statusCode).toBe(200);
    expect(Array.isArray(pull.body.data.categories)).toBe(true);
    expect(Array.isArray(pull.body.data.orders)).toBe(true);
    expect(Array.isArray(pull.body.data.tombstones)).toBe(true);

    const invalid = await request(app)
      .get('/api/v1/sync/pull')
      .query({ since: 'not-a-date' });
    expect(invalid.statusCode).toBe(400);
  });
});
