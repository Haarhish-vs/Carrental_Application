require('dotenv').config();
const { supabase } = require('./src/config/supabase');

async function checkCarDb() {
  console.log("🔍 Querying Supabase directly for car 'sfdgg safdsvbf'...");

  // 1. Search vehicles table
  const { data: vehicles, error: vErr } = await supabase
    .from('vehicles')
    .select('*')
    .or('brand.ilike.%sfdgg%,model.ilike.%safdsvbf%');

  if (vErr) {
    console.error("❌ Error querying vehicles:", vErr);
  } else {
    console.log(`\n==================================================`);
    console.log(`🚗 VEHICLE TABLE MATCHES (${vehicles ? vehicles.length : 0}):`);
    console.log(`==================================================`);
    (vehicles || []).forEach(v => {
      console.log(`• ID: ${v.id}`);
      console.log(`  Name: ${v.brand} ${v.model}`);
      console.log(`  Owner ID: ${v.owner_id}`);
      console.log(`  Status: ${v.status} | Available: ${v.is_available}`);
      console.log(`  Location Lat: ${v.location_lat} | Lng: ${v.location_lng}`);
      console.log(`  Updated At: ${v.updated_at}`);
    });

    if (vehicles && vehicles.length > 0) {
      const vehicleIds = vehicles.map(v => v.id);
      const { data: bookings, error: bErr } = await supabase
        .from('bookings')
        .select('*, vehicle:vehicles(*)')
        .in('vehicle_id', vehicleIds);

      if (bErr) {
        console.error("❌ Error querying bookings:", bErr);
      } else {
        console.log(`\n==================================================`);
        console.log(`📅 BOOKINGS TABLE MATCHES (${bookings ? bookings.length : 0}):`);
        console.log(`==================================================`);
        (bookings || []).forEach(b => {
          console.log(`• Booking ID: ${b.id}`);
          console.log(`  Vehicle: ${b.vehicle?.brand} ${b.vehicle?.model}`);
          console.log(`  Booking Status: ${b.status} | Payment: ${b.payment_status}`);
          console.log(`  Dates: ${b.start_date} to ${b.end_date}`);
          console.log(`  Total Price: ₹${b.total_price}`);
          console.log(`  Current Lat: ${b.current_lat} | Current Lng: ${b.current_lng}`);
          console.log(`  Last Tracked At: ${b.last_tracked_at}`);
          console.log(`  Vehicle Lat: ${b.vehicle?.location_lat} | Vehicle Lng: ${b.vehicle?.location_lng}`);
        });
      }
    }
  }

  process.exit(0);
}

checkCarDb();
