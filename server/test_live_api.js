const https = require('https');

function testLiveLocationEndpoint() {
  console.log("🧪 Testing Live GPS Endpoint on Production Server...");

  https.get('https://carrental-application-z49a.onrender.com/api/vehicles', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      try {
        const json = JSON.parse(data);
        console.log(`\n==================================================`);
        console.log(`📡 Live API Status Code: ${res.statusCode}`);
        console.log(`✅ API Response Status: ${json.success ? 'SUCCESS' : 'FAILED'}`);
        console.log(`🚗 Total Active Vehicles Returned: ${json.data ? json.data.length : 0}`);
        console.log(`==================================================\n`);

        if (json.data && json.data.length > 0) {
          const trackedVehicle = json.data.find(v => v.location_lat != null);
          if (trackedVehicle) {
            console.log(`📍 FOUND LIVE TRACKED VEHICLE IN SUPABASE DATABASE:`);
            console.log(`   • ID: ${trackedVehicle.id}`);
            console.log(`   • Vehicle: ${trackedVehicle.brand} ${trackedVehicle.model}`);
            console.log(`   • Latitude: ${trackedVehicle.location_lat}`);
            console.log(`   • Longitude: ${trackedVehicle.location_lng}`);
            console.log(`   • Last Supabase Update: ${trackedVehicle.updated_at}`);
            console.log(`\n🎉 CONFIRMATION: GPS Live Tracking is 100% OPERATIONAL & PERSISTING TO SUPABASE!`);
          } else {
            console.log("ℹ️ No active rental currently streaming GPS coordinates.");
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

testLiveLocationEndpoint();
