jest.mock('@supabase/supabase-js', () => ({
  createClient: () => global.mockSupabase
}));

global.mockSupabase = {
  from: jest.fn().mockReturnThis(),
  select: jest.fn().mockReturnThis(),
  eq: jest.fn().mockReturnThis(),
  in: jest.fn().mockReturnThis(),
  lte: jest.fn().mockReturnThis(),
  gte: jest.fn().mockReturnThis(),
  lt: jest.fn().mockReturnThis(),
  single: jest.fn().mockReturnThis(),
  insert: jest.fn().mockReturnThis(),
  update: jest.fn().mockReturnThis(),
  order: jest.fn().mockReturnThis(),
  auth: {
    getUser: jest.fn()
  }
};

const mockSupabase = global.mockSupabase;

const request = require('supertest');
const app = require('../src/app');
const { calculatePricing } = require('../src/modules/bookings/pricing.service');
const { isValidTransition } = require('../src/modules/bookings/booking.state-machine');
const { calculateCancellationFee } = require('../src/modules/bookings/cancellation.service');
const { expirePendingBookings } = require('../src/modules/bookings/jobs/expire-pending-bookings.cron');

describe('1. Pricing Service Logic', () => {
  test('1-day booking should calculate correct pricing (no discount)', () => {
    const result = calculatePricing(100, 200, '2026-08-01', '2026-08-02');
    expect(result.numberOfDays).toBe(1);
    expect(result.subtotal).toBe(100);
    expect(result.discount).toBe(0);
    expect(result.total).toBe(100);
    expect(result.deposit).toBe(200);
  });

  test('7-day booking should calculate correct pricing (5% discount)', () => {
    const result = calculatePricing(100, 200, '2026-08-01', '2026-08-08');
    expect(result.numberOfDays).toBe(7);
    expect(result.subtotal).toBe(700);
    expect(result.discount).toBe(35);
    expect(result.total).toBe(665);
    expect(result.deposit).toBe(200);
  });

  test('30-day booking should calculate correct pricing (10% discount)', () => {
    const result = calculatePricing(100, 200, '2026-08-01', '2026-08-31');
    expect(result.numberOfDays).toBe(30);
    expect(result.subtotal).toBe(3000);
    expect(result.discount).toBe(300);
    expect(result.total).toBe(2700);
    expect(result.deposit).toBe(200);
  });
});

describe('2. State Machine Transitions', () => {
  test('Valid transitions should be allowed', () => {
    expect(isValidTransition('pending', 'confirmed')).toBe(true);
    expect(isValidTransition('pending', 'cancelled')).toBe(true);
    expect(isValidTransition('confirmed', 'active')).toBe(true);
    expect(isValidTransition('confirmed', 'cancelled')).toBe(true);
    expect(isValidTransition('active', 'completed')).toBe(true);
  });

  test('Invalid transitions should be rejected', () => {
    expect(isValidTransition('pending', 'completed')).toBe(false);
    expect(isValidTransition('pending', 'active')).toBe(false);
    expect(isValidTransition('confirmed', 'completed')).toBe(false);
    expect(isValidTransition('active', 'confirmed')).toBe(false);
    expect(isValidTransition('active', 'cancelled')).toBe(false);
    expect(isValidTransition('completed', 'active')).toBe(false);
    expect(isValidTransition('cancelled', 'confirmed')).toBe(false);
  });
});

describe('3. Cancellation Fee Policies', () => {
  const booking = {
    start_date: '2026-08-05',
    total_price: 1000,
    deposit_amount: 500
  };

  test('More than 48 hours before start_date (72h) -> full refund, zero fee', () => {
    const cancelTime = new Date('2026-08-02T00:00:00.000Z');
    const result = calculateCancellationFee(booking, 'renter', cancelTime);
    expect(result.cancellationFee).toBe(0);
    expect(result.refundAmount).toBe(1500);
  });

  test('24 to 48 hours before start_date (30h) -> 50% fee on rental only, deposit fully refunded', () => {
    const cancelTime = new Date('2026-08-03T18:00:00.000Z');
    const result = calculateCancellationFee(booking, 'renter', cancelTime);
    expect(result.cancellationFee).toBe(500);
    expect(result.refundAmount).toBe(1000);
  });

  test('Less than 24 hours before start_date (10h) -> 100% fee on rental, deposit fully refunded', () => {
    const cancelTime = new Date('2026-08-04T14:00:00.000Z');
    const result = calculateCancellationFee(booking, 'renter', cancelTime);
    expect(result.cancellationFee).toBe(1000);
    expect(result.refundAmount).toBe(500);
  });

  test('Owner-initiated cancellation -> full refund regardless of timing', () => {
    const cancelTime = new Date('2026-08-04T22:00:00.000Z');
    const result = calculateCancellationFee(booking, 'owner', cancelTime);
    expect(result.cancellationFee).toBe(0);
    expect(result.refundAmount).toBe(1500);
  });
});

describe('4. Booking API Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    
    // Reset mockSupabase base methods
    mockSupabase.from.mockReturnThis();
    mockSupabase.select.mockReturnThis();
    mockSupabase.eq.mockReturnThis();
    mockSupabase.in.mockReturnThis();
    mockSupabase.lte.mockReturnThis();
    mockSupabase.gte.mockReturnThis();
    mockSupabase.lt.mockReturnThis();
    mockSupabase.insert.mockReturnThis();
    mockSupabase.update.mockReturnThis();
    mockSupabase.order.mockReturnThis();
    
    // Reset resolved values to avoid pollution
    mockSupabase.single.mockReset();
    mockSupabase.lt.mockReset();
  });

  test('POST /api/bookings - Should successfully create a booking', async () => {
    const mockVehicle = {
      id: 'fa405ad0-a92a-4df0-93cb-644b41cbde99',
      owner_id: 'owner-user-id',
      price_per_day: 100,
      deposit_amount: 200,
      status: 'active'
    };

    const mockCreatedBooking = {
      id: 'booking-id-123',
      vehicle_id: mockVehicle.id,
      renter_id: 'renter-user-id',
      start_date: '2026-08-10',
      end_date: '2026-08-12',
      status: 'pending',
      payment_status: 'unpaid',
      total_price: 200,
      deposit_amount: 200
    };

    mockSupabase.single
      .mockResolvedValueOnce({ data: mockVehicle, error: null }) // vehicle check
      .mockResolvedValueOnce({ data: mockCreatedBooking, error: null }); // insert result

    const response = await request(app)
      .post('/api/bookings')
      .set('x-user-id', 'renter-user-id')
      .send({
        vehicle_id: mockVehicle.id,
        start_date: '2026-08-10',
        end_date: '2026-08-12'
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data.total_price).toBe(200);
  });

  test('POST /api/bookings - Rejecting an overlapping booking (Exclusion Violation 23P01)', async () => {
    const mockVehicle = {
      id: 'fa405ad0-a92a-4df0-93cb-644b41cbde99',
      owner_id: 'owner-user-id',
      price_per_day: 100,
      deposit_amount: 200,
      status: 'active'
    };

    mockSupabase.single
      .mockResolvedValueOnce({ data: mockVehicle, error: null }) // vehicle check
      .mockResolvedValueOnce({
        data: null,
        error: { code: '23P01', message: 'Exclusion constraint violation' }
      }); // insert fails

    const response = await request(app)
      .post('/api/bookings')
      .set('x-user-id', 'renter-user-id')
      .send({
        vehicle_id: mockVehicle.id,
        start_date: '2026-08-10',
        end_date: '2026-08-12'
      });

    expect(response.status).toBe(409);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toBe('This vehicle is already booked for these dates');
  });

  test('PATCH /api/bookings/:id/confirm - Confirm booking by owner should succeed', async () => {
    const mockBooking = {
      id: 'booking-id-123',
      vehicle_id: 'vehicle-id',
      renter_id: 'renter-user-id',
      status: 'pending',
      vehicles: {
        owner_id: 'owner-user-id'
      }
    };

    mockSupabase.single
      .mockResolvedValueOnce({ data: mockBooking, error: null }) // fetch booking
      .mockResolvedValueOnce({ data: { ...mockBooking, status: 'confirmed' }, error: null }); // update booking

    const response = await request(app)
      .patch('/api/bookings/booking-id-123/confirm')
      .set('x-user-id', 'owner-user-id')
      .send();

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.status).toBe('confirmed');
  });

  test('PATCH /api/bookings/:id/confirm - Confirm booking by renter should fail (403)', async () => {
    const mockBooking = {
      id: 'booking-id-123',
      vehicle_id: 'vehicle-id',
      renter_id: 'renter-user-id',
      status: 'pending',
      vehicles: {
        owner_id: 'owner-user-id'
      }
    };

    mockSupabase.single.mockResolvedValueOnce({ data: mockBooking, error: null });

    const response = await request(app)
      .patch('/api/bookings/booking-id-123/confirm')
      .set('x-user-id', 'renter-user-id')
      .send();

    expect(response.status).toBe(403);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toContain('Only the vehicle owner can confirm this booking');
  });

  test('PATCH /api/bookings/:id/cancel - Reject cancellation attempts on active or completed bookings', async () => {
    const mockBooking = {
      id: 'booking-id-123',
      renter_id: 'renter-user-id',
      status: 'active',
      start_date: '2026-08-05',
      total_price: 1000,
      deposit_amount: 500,
      vehicles: {
        owner_id: 'owner-user-id'
      }
    };

    mockSupabase.single.mockResolvedValueOnce({ data: mockBooking, error: null });

    const response = await request(app)
      .patch('/api/bookings/booking-id-123/cancel')
      .set('x-user-id', 'renter-user-id')
      .send({ reason: 'trip cancelled' });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toBe('This booking cannot be cancelled at its current stage');
  });

  test('PATCH /api/bookings/:id/cancel - Reject cancellation by unauthorized user', async () => {
    const mockBooking = {
      id: 'booking-id-123',
      renter_id: 'renter-user-id',
      status: 'pending',
      start_date: '2026-08-05',
      total_price: 1000,
      deposit_amount: 500,
      vehicles: {
        owner_id: 'owner-user-id'
      }
    };

    mockSupabase.single.mockResolvedValueOnce({ data: mockBooking, error: null });

    const response = await request(app)
      .patch('/api/bookings/booking-id-123/cancel')
      .set('x-user-id', 'random-user-id')
      .send({ reason: 'unauthorized cancel' });

    expect(response.status).toBe(403);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toContain('You are not authorized to cancel this booking');
  });

  test('PATCH /api/bookings/:id/cancel - Renter cancels booking successfully and returns refund details', async () => {
    const mockBooking = {
      id: 'booking-id-123',
      renter_id: 'renter-user-id',
      status: 'pending',
      start_date: '2026-08-10',
      total_price: 1000,
      deposit_amount: 500,
      vehicles: {
        owner_id: 'owner-user-id'
      }
    };

    const mockCancelledBooking = {
      ...mockBooking,
      status: 'cancelled',
      cancelled_by: 'renter',
      cancellation_fee: 0,
      refund_amount: 1500
    };

    mockSupabase.single
      .mockResolvedValueOnce({ data: mockBooking, error: null }) // fetch booking
      .mockResolvedValueOnce({ data: mockCancelledBooking, error: null }); // update booking

    const response = await request(app)
      .patch('/api/bookings/booking-id-123/cancel')
      .set('x-user-id', 'renter-user-id')
      .send({ reason: 'Change of plans' });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.refund_amount).toBe(1500);
    expect(response.body.data.booking.status).toBe('cancelled');
  });
});

describe('5. Auto-Expiry Cron Job', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSupabase.from.mockReturnThis();
    mockSupabase.select.mockReturnThis();
    mockSupabase.eq.mockReturnThis();
    mockSupabase.lt.mockReset();
    mockSupabase.update.mockReturnThis();
  });

  test('expirePendingBookings should find stale unpaid bookings and cancel them via system', async () => {
    const mockStaleBookings = [
      { id: 'stale-1', total_price: 300, deposit_amount: 100 },
      { id: 'stale-2', total_price: 500, deposit_amount: 200 }
    ];

    // Mock the initial select search to return the stale bookings
    mockSupabase.lt.mockResolvedValueOnce({ data: mockStaleBookings, error: null });

    // Mock console.log to avoid cluttering test outputs
    const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

    await expirePendingBookings();

    expect(mockSupabase.from).toHaveBeenCalledWith('bookings');
    expect(mockSupabase.update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'cancelled',
        cancelled_by: 'system',
        cancellation_reason: 'Payment not completed in time',
        cancellation_fee: 0
      })
    );
    
    consoleLogSpy.mockRestore();
  });
});
