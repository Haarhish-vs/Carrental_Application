const https = require('https');

function testSpecificCar() {
  const carId = '9befb04d-edd0-4e55-ba31-793747a83f7f';
  console.log(`🔍 Inspecting Car ID: ${carId} on Live Production API...`);

  https.get('https://carrental-application-z49a.onrender.com/api/vehicles', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      try {
        const json = JSON.parse(data);
        if (json.data && json.data.length > 0) {
          const car = json.data.find(v => v.id === carId);

          if (car) {
            console.log(`\n==================================================`);
            console.log(`🚗 CAR FOUND IN LIVE PRODUCTION DATABASE:`);
            console.log(`   • ID: ${car.id}`);
            console.log(`   • Name: ${car.brand} ${car.model} (${car.variant || 'Standard'})`);
            console.log(`   • Owner ID: ${car.owner_id}`);
            console.log(`   • City: ${car.city}`);
            console.log(`   • Price/Day: ₹${car.price_per_day}`);
            console.log(`   • Status: ${car.status} | Available: ${car.is_available}`);
            console.log(`   • Live GPS Latitude: ${car.location_lat}`);
            console.log(`   • Live GPS Longitude: ${car.location_lng}`);
            console.log(`   • Last Updated: ${car.updated_at}`);
            console.log(`==================================================\n`);
          } else {
            console.log(`ℹ️ Car ID ${carId} not found in public listings (may be currently under active rental or booked).`);
          }
        }
      } catch (e) {
        console.error("❌ Error parsing response:", e);
      }
    });
  }).on('error', (err) => {
    console.error("❌ Request Error:", err.message);
  });
}

testSpecificCar();
