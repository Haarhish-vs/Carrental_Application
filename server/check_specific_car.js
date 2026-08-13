const https = require('https');

function checkSpecificCar() {
  console.log("🔍 Checking vehicle details for brand: 'sfdgg', model: 'safdsvbf'...");

  https.get('https://carrental-application-z49a.onrender.com/api/vehicles', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      try {
        const json = JSON.parse(data);
        if (json.data && json.data.length > 0) {
          const matchedVehicles = json.data.filter(v => 
            (v.brand && v.brand.toLowerCase().includes('sfdgg')) || 
            (v.model && v.model.toLowerCase().includes('safdsvbf'))
          );

          console.log(`\n==================================================`);
          console.log(`🚗 Found ${matchedVehicles.length} matching vehicle(s)`);
          console.log(`==================================================\n`);

          matchedVehicles.forEach(v => {
            console.log(`• Vehicle ID: ${v.id}`);
            console.log(`  Name: ${v.brand} ${v.model}`);
            console.log(`  Owner ID: ${v.owner_id}`);
            console.log(`  City: ${v.city}`);
            console.log(`  Price/day: ₹${v.price_per_day}`);
            console.log(`  Status: ${v.status} | Available: ${v.is_available}`);
            console.log(`  GPS Latitude: ${v.location_lat}`);
            console.log(`  GPS Longitude: ${v.location_lng}`);
            console.log(`  Last Updated: ${v.updated_at}`);
            console.log(`--------------------------------------------------`);
          });
        } else {
          console.log("❌ No vehicles returned from server.");
        }
      } catch (e) {
        console.error("❌ Error parsing response:", e);
      }
    });
  }).on('error', (err) => {
    console.error("❌ Request Error:", err.message);
  });
}

checkSpecificCar();
