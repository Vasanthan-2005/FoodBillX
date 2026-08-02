const request = require('supertest');
const app = require('../src/app');

describe('Health Check Endpoint Tests', () => {
  it('should return HTTP 200 with health status JSON on GET /health', async () => {
    const res = await request(app).get('/health');

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.status).toBe('healthy');
    expect(res.body.service).toBe('FoodBillX Backend');
    expect(typeof res.body.timestamp).toBe('string');
    expect(typeof res.body.uptime).toBe('number');
    expect(typeof res.body.environment).toBe('string');
  });

  it('should return HTTP 200 with health status JSON on GET /api/v1/health', async () => {
    const res = await request(app).get('/api/v1/health');

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.status).toBe('healthy');
    expect(res.body.service).toBe('FoodBillX Backend');
  });
});
