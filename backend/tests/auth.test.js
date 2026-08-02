const request = require('supertest');
const app = require('../src/app');
const BusinessSettings = require('../src/models/BusinessSettings');

jest.mock('../src/models/BusinessSettings');

describe('Owner Verification API Unit Tests', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should verify owner identity with matching phone number', async () => {
    BusinessSettings.findOne.mockResolvedValue({
      businessName: 'Test Food Outlet',
      phone: '9876543210',
    });

    const res = await request(app)
      .post('/api/v1/auth/verify-owner')
      .send({ phone: '9876543210' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.verified).toBe(true);
    expect(res.body.data.businessName).toBe('Test Food Outlet');
  });

  it('should reject verification with non-matching phone number', async () => {
    BusinessSettings.findOne.mockResolvedValue({
      businessName: 'Test Food Outlet',
      phone: '9876543210',
    });

    const res = await request(app)
      .post('/api/v1/auth/verify-owner')
      .send({ phone: '1111111111' });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Phone number does not match');
  });

  it('should reject request missing phone number', async () => {
    const res = await request(app)
      .post('/api/v1/auth/verify-owner')
      .send({});

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });
});
