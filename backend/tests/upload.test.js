const request = require('supertest');
const app = require('../src/app');
const path = require('path');
const fs = require('fs');

describe('Upload Endpoints API', () => {
  let uploadedFilename = '';

  test('POST /api/v1/upload - should upload image successfully', async () => {
    // Create a temporary dummy image buffer
    const buffer = Buffer.from('fake-image-bytes-for-unit-test');

    const res = await request(app)
      .post('/api/v1/upload')
      .attach('image', buffer, 'test_dish.jpg');

    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBe(true);
    expect(res.body.url).toBeDefined();
    expect(res.body.filename).toBeDefined();
    uploadedFilename = res.body.filename;
  });

  test('DELETE /api/v1/upload/:filename - should delete uploaded image', async () => {
    expect(uploadedFilename).not.toBe('');

    const res = await request(app)
      .delete(`/api/v1/upload/${uploadedFilename}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
  });
});
