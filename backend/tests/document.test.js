jest.mock('@supabase/supabase-js', () => ({
  createClient: () => global.mockSupabase,
}));

global.mockSupabase = {
  from: jest.fn().mockReturnThis(),
  select: jest.fn().mockReturnThis(),
  eq: jest.fn().mockReturnThis(),
  order: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  maybeSingle: jest.fn().mockReturnThis(),
  insert: jest.fn().mockReturnThis(),
  update: jest.fn().mockReturnThis(),
  single: jest.fn().mockReturnThis(),
  auth: { getUser: jest.fn() },
  storage: {
    from: jest.fn().mockReturnValue({
      upload: jest.fn().mockResolvedValue({ data: { path: 'ok' }, error: null }),
      getPublicUrl: jest.fn().mockReturnValue({ data: { publicUrl: 'https://example.com/document.pdf' } }),
      download: jest.fn().mockResolvedValue({ data: new Blob(['hello world']) }),
    }),
  },
};

const request = require('supertest');
const app = require('../src/app');
const ocrService = require('../src/services/ocrService');

describe('Document Analysis / Verification API', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    global.mockSupabase.storage.from.mockReturnValue({
      upload: jest.fn().mockResolvedValue({ data: { path: 'ok' }, error: null }),
      getPublicUrl: jest.fn().mockReturnValue({ data: { publicUrl: 'https://example.com/document.pdf' } }),
      download: jest.fn().mockResolvedValue({ data: new Blob(['hello world']) }),
    });

    global.mockSupabase.from.mockReturnThis();
    global.mockSupabase.select.mockReturnThis();
    global.mockSupabase.eq.mockReturnThis();
    global.mockSupabase.order.mockReturnThis();
    global.mockSupabase.limit.mockReturnThis();
    global.mockSupabase.maybeSingle.mockReturnThis();
    global.mockSupabase.insert.mockReturnThis();
    global.mockSupabase.update.mockReturnThis();
    global.mockSupabase.single.mockResolvedValue({ data: { id: 'doc-1' }, error: null });
  });

  test('accepts text files for document upload', async () => {
    const response = await request(app)
      .post('/api/documents/upload')
      .set('x-user-id', 'user-123')
      .field('vehicleId', 'vehicle-123')
      .attach('rc', Buffer.from('Vehicle Number: KA01AB1234'), {
        filename: 'rc.txt',
        contentType: 'text/plain',
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.uploadedDocuments[0].documentType).toBe('rc');
  });

  test('extracts readable text from a plain text document', async () => {
    const text = await ocrService.extractText({
      originalname: 'rc.txt',
      buffer: Buffer.from('Vehicle Number: KA01AB1234\nOwner: Jane Doe\n'),
      mimetype: 'text/plain',
    });

    expect(text).toContain('Vehicle Number');
    expect(text).toContain('Jane Doe');
  });
});
