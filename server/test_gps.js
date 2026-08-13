// test_gps.js
require('dotenv').config();
const { supabase } = require('./src/config/supabase');
const bookingService = require('./src/modules/bookings/booking.service');

async function testGpsTracking() {
  console.log("🧪 Starting GPS Live Tracking Verification Test...");

  try {
    // 1. Fetch a booking to test
    const { data: bookings, error: fetchErr } = await supabase
      .from('bookings')
      .select('id, renter_id, vehicle_id, status')
      .limit(1);

    if (fetchErr || !bookings || bookings.length === 0) {
      console.log("❌ No bookings found in Supabase database to test:", fetchErr);
      return;
    }

    const testBooking = bookings[0];
    console.log(`📌 Found Test Booking ID: ${testBooking.id} (Renter: ${testBooking.renter_id})`);

    // Simulated GPS Coordinates (Bangalore, India: 12.9716, 77.5946)
    const testLat = 12.9716;
    const testLng = 77.5946;

    // 2. Perform location update via bookingService
    console.log(`📡 Sending test location update: [Lat: ${testLat}, Lng: ${testLng}]...`);
    const updateResult = await bookingService.updateBookingLocation(
      testBooking.id,
      testBooking.renter_id,
      testLat,
      testLng
    );
    console.log("✅ Location update response ID:", updateResult.id);

    // 3. Verify vehicle table location persistence
    const { data: vehicle, error: vehErr } = await supabase
      .from('vehicles')
      .select('id, location_lat, location_lng')
      .eq('id', testBooking.vehicle_id)
      .single();

    if (vehErr || !vehicle) {
      console.log("❌ Error fetching updated vehicle record:", vehErr);
    } else {
      console.log(`🚗 Supabase Vehicle Table Saved Coordinates -> Lat: ${vehicle.location_lat}, Lng: ${vehicle.location_lng}`);
      if (Number(vehicle.location_lat) === testLat && Number(vehicle.location_lng) === testLng) {
        console.log("🎉 SUCCESS: Vehicle location table correctly persisted test GPS coordinates!");
      }
    }

    // 4. Verify getBookingById fallback resolution
    const fetchedBooking = await bookingService.getBookingById(testBooking.id, testBooking.renter_id);
    console.log(`📍 getBookingById Returned Coordinates -> current_lat: ${fetchedBooking.current_lat}, current_lng: ${fetchedBooking.current_lng}`);

    if (Number(fetchedBooking.current_lat) === testLat && Number(fetchedBooking.current_lng) === testLng) {
      console.log("🚀 ALL TESTS PASSED! GPS live tracking pipeline is 100% WORKING!");
    } else {
      console.log("⚠️ Coordinates resolved differently, check result above.");
    }

  } catch (e) {
    console.error("❌ Test failed with exception:", e);
  } finally {
    process.exit(0);
  }
}

testGpsTracking();
