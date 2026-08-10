const { z } = require('zod');

// Regex to validate YYYY-MM-DD format
const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

const createBookingSchema = z.object({
  vehicle_id: z.string().uuid({ message: 'Invalid vehicle_id. Must be a valid UUID.' }),
  start_date: z.string().regex(dateRegex, { message: 'start_date must be in YYYY-MM-DD format.' }).refine((val) => {
    // start_date must not be in the past.
    // Compare date parts in UTC to ignore local timezone differences.
    const today = new Date();
    const todayUtc = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
    const start = new Date(val);
    const startUtc = Date.UTC(start.getFullYear(), start.getMonth(), start.getDate());
    return startUtc >= todayUtc;
  }, { message: 'start_date cannot be in the past.' }),
  end_date: z.string().regex(dateRegex, { message: 'end_date must be in YYYY-MM-DD format.' })
}).refine((data) => {
  const start = new Date(data.start_date);
  const end = new Date(data.end_date);
  const startUtc = Date.UTC(start.getFullYear(), start.getMonth(), start.getDate());
  const endUtc = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());
  // end_date must be after start_date
  return endUtc > startUtc;
}, {
  message: 'end_date must be after start_date.',
  path: ['end_date']
});

const availabilitySchema = z.object({
  vehicleId: z.string().uuid({ message: 'Invalid vehicleId. Must be a valid UUID.' }),
  startDate: z.string().regex(dateRegex, { message: 'startDate must be in YYYY-MM-DD format.' }),
  endDate: z.string().regex(dateRegex, { message: 'endDate must be in YYYY-MM-DD format.' })
}).refine((data) => {
  const start = new Date(data.startDate);
  const end = new Date(data.endDate);
  const startUtc = Date.UTC(start.getFullYear(), start.getMonth(), start.getDate());
  const endUtc = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());
  return endUtc > startUtc;
}, {
  message: 'endDate must be after startDate.',
  path: ['endDate']
});

const cancelBookingSchema = z.object({
  reason: z.string().min(1, { message: 'Cancellation reason is required.' }).max(1000, { message: 'Reason is too long.' })
});

module.exports = {
  createBookingSchema,
  availabilitySchema,
  cancelBookingSchema
};
