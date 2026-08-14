const https = require('https');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

function testSupportEndpoint() {
  console.log("🧪 Testing Support Details & Policies Endpoint...");

  // 1. Test live deployed URL
  https.get('https://carrental-application-z49a.onrender.com/api/support/details', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      try {
        const json = JSON.parse(data);
        console.log(`\n==================================================`);
        console.log(`📡 Deployed API Status Code: ${res.statusCode}`);
        console.log(`✅ Success: ${json.success}`);
        console.log(`📞 Customer Support Phone: ${json.data?.customerSupport?.phone}`);
        console.log(`📧 Customer Support Email: ${json.data?.customerSupport?.email}`);
        console.log(`📜 Total Policies Returned: ${json.data?.policiesList?.length || Object.keys(json.data?.policiesMap || {}).length}`);
        console.log(`==================================================\n`);
        console.log('Full Response Data:');
        console.log(JSON.stringify(json, null, 2));
      } catch (e) {
        console.error("❌ Error parsing live response:", e.message);
      }
    });
  }).on('error', (err) => {
    console.error("❌ Live Request Error:", err.message);
  });
}

testSupportEndpoint();
