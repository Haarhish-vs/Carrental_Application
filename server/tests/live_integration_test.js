// live_integration_test.js
const request = require('supertest');
const app = require('../src/app');

async function runLiveTests() {
  console.log('=== RUNNING LIVE INTEGRATION TESTS AGAINST SUPABASE ===\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`✅ PASS: ${message}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${message}`);
      failed++;
    }
  }

  // 1. GET /api/cars/filter-options
  console.log('--- Test 1: GET /api/cars/filter-options ---');
  const resFilters = await request(app).get('/api/cars/filter-options');
  assert(resFilters.status === 200, 'Status code is 200');
  assert(resFilters.body.success === true, 'Success is true');
  assert(Array.isArray(resFilters.body.filters.fuelTypes), 'Fuel types array returned');
  assert(Array.isArray(resFilters.body.filters.transmissions), 'Transmissions array returned');
  assert(Array.isArray(resFilters.body.filters.seatOptions), 'Seat options array returned');
  assert(resFilters.body.filters.priceRange.min > 0, `Price range min is valid: ${resFilters.body.filters.priceRange.min}`);
  assert(resFilters.body.filters.priceRange.max >= resFilters.body.filters.priceRange.min, `Price range max is valid: ${resFilters.body.filters.priceRange.max}`);
  console.log('Real DB Filters:', JSON.stringify(resFilters.body.filters, null, 2));

  // 2. GET /api/vehicles/filter-options (Alias)
  console.log('\n--- Test 2: GET /api/vehicles/filter-options ---');
  const resFiltersAlias = await request(app).get('/api/vehicles/filter-options');
  assert(resFiltersAlias.status === 200, 'Alias endpoint status is 200');

  // 3. POST /api/cars/search (Valid search in Coimbatore with future dates)
  console.log('\n--- Test 3: POST /api/cars/search (Coimbatore) ---');
  const resSearch = await request(app)
    .post('/api/cars/search')
    .send({
      location: {
        name: 'Coimbatore',
        city: 'Coimbatore',
        latitude: 11.0168,
        longitude: 76.9558
      },
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00',
      sort: 'recommended',
      page: 1,
      limit: 10
    });

  assert(resSearch.status === 200, 'Status code is 200');
  assert(resSearch.body.success === true, 'Success is true');
  assert(Array.isArray(resSearch.body.cars), 'Cars array returned');
  assert(resSearch.body.count === resSearch.body.cars.length, `Count matches length: ${resSearch.body.count}`);
  console.log(`Found ${resSearch.body.count} cars in Coimbatore for Aug 20-25.`);
  if (resSearch.body.cars.length > 0) {
    const sample = resSearch.body.cars[0];
    assert(sample.id !== undefined, 'Car has id');
    assert(sample.name !== undefined, `Car has name: ${sample.name}`);
    assert(sample.pricePerDay !== undefined, `Car has pricePerDay: ${sample.pricePerDay}`);
    assert(sample.fuelType !== undefined, `Car has fuelType: ${sample.fuelType}`);
  }

  // 4. POST /api/cars/search (No available cars in Nonexistent city)
  console.log('\n--- Test 4: POST /api/cars/search (No available cars) ---');
  const resNone = await request(app)
    .post('/api/cars/search')
    .send({
      location: 'NonExistentCity12345',
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00'
    });
  assert(resNone.status === 200, 'Status is 200 for empty search');
  assert(resNone.body.count === 0, 'Count is 0');
  assert(resNone.body.cars.length === 0, 'Cars is empty array');
  assert(typeof resNone.body.message === 'string', `Message returned: "${resNone.body.message}"`);

  // 5. POST /api/cars/search (Fuel Type Filter)
  console.log('\n--- Test 5: Fuel Type Filter ---');
  const resFuel = await request(app)
    .post('/api/cars/search')
    .send({
      location: 'Coimbatore',
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00',
      filters: {
        fuelType: 'Hybrid'
      }
    });
  assert(resFuel.status === 200, 'Status is 200');
  for (const car of resFuel.body.cars) {
    assert(car.fuelType.toLowerCase() === 'hybrid', `Car fuel type is Hybrid: ${car.name}`);
  }

  // 6. POST /api/cars/search (Transmission Filter)
  console.log('\n--- Test 6: Transmission Filter ---');
  const resTrans = await request(app)
    .post('/api/cars/search')
    .send({
      location: 'Coimbatore',
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00',
      filters: {
        transmission: 'Automatic'
      }
    });
  assert(resTrans.status === 200, 'Status is 200');
  for (const car of resTrans.body.cars) {
    assert(car.transmission.toLowerCase() === 'automatic', `Car transmission is Automatic: ${car.name}`);
  }

  // 7. POST /api/cars/search (Seats Filter)
  console.log('\n--- Test 7: Seats Filter (7 seats) ---');
  const resSeats = await request(app)
    .post('/api/cars/search')
    .send({
      location: 'Coimbatore',
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00',
      filters: {
        seats: 7
      }
    });
  assert(resSeats.status === 200, 'Status is 200');
  for (const car of resSeats.body.cars) {
    assert(car.seats >= 7, `Car seats >= 7: ${car.name} (${car.seats} seats)`);
  }

  // 8. POST /api/cars/search (Price Range Filter)
  console.log('\n--- Test 8: Price Range Filter (3000 to 5500) ---');
  const resPrice = await request(app)
    .post('/api/cars/search')
    .send({
      location: 'Coimbatore',
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00',
      filters: {
        minPrice: 3000,
        maxPrice: 5500
      }
    });
  assert(resPrice.status === 200, 'Status is 200');
  for (const car of resPrice.body.cars) {
    assert(car.pricePerDay >= 3000 && car.pricePerDay <= 5500, `Car price in range: ${car.name} (Rs. ${car.pricePerDay})`);
  }

  // 9. POST /api/cars/search (Sorting: price_low_to_high)
  console.log('\n--- Test 9: Sorting price_low_to_high ---');
  const resSortAsc = await request(app)
    .post('/api/cars/search')
    .send({
      location: 'townhall',
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00',
      sort: 'price_low_to_high'
    });
  assert(resSortAsc.status === 200, 'Status is 200');
  if (resSortAsc.body.cars.length >= 2) {
    assert(resSortAsc.body.cars[0].pricePerDay <= resSortAsc.body.cars[1].pricePerDay, 'Ascending sort confirmed');
  }

  // 10. POST /api/cars/search (Validation: Missing Location)
  console.log('\n--- Test 10: Validation (Missing Location) ---');
  const resValLoc = await request(app)
    .post('/api/cars/search')
    .send({
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00'
    });
  assert(resValLoc.status === 400, 'Returns 400 Bad Request for missing location');
  assert(resValLoc.body.success === false, 'success is false');

  // 11. POST /api/cars/search (Validation: Invalid Date Range)
  console.log('\n--- Test 11: Validation (Return before Pickup) ---');
  const resValDate = await request(app)
    .post('/api/cars/search')
    .send({
      location: 'Coimbatore',
      pickupDate: '2026-08-25',
      pickupTime: '10:00',
      returnDate: '2026-08-20',
      returnTime: '10:00'
    });
  assert(resValDate.status === 400, 'Returns 400 Bad Request for return date before pickup');

  // 12. POST /api/cars/search (Validation: Invalid Sort Option)
  console.log('\n--- Test 12: Validation (Invalid Sort) ---');
  const resValSort = await request(app)
    .post('/api/cars/search')
    .send({
      location: 'Coimbatore',
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00',
      sort: 'invalid_sort_param'
    });
  assert(resValSort.status === 400, 'Returns 400 Bad Request for invalid sort');

  // 13. POST /api/vehicles/search (Route Alias)
  console.log('\n--- Test 13: POST /api/vehicles/search Route Alias ---');
  const resVehiclesSearch = await request(app)
    .post('/api/vehicles/search')
    .send({
      location: 'Coimbatore',
      pickupDate: '2026-08-20',
      pickupTime: '10:00',
      returnDate: '2026-08-25',
      returnTime: '10:00'
    });
  assert(resVehiclesSearch.status === 200, 'POST /api/vehicles/search works');

  console.log(`\n========================================`);
  console.log(`LIVE TESTS COMPLETE: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  process.exit(failed > 0 ? 1 : 0);
}

runLiveTests().catch(err => {
  console.error('Test runner fatal error:', err);
  process.exit(1);
});
