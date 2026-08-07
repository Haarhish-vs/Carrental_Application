const axios = require('axios');

async function run() {
  try {
    const res = await axios.get('https://carrental-application-1.onrender.com/api/locations/recent');
    console.log('Recent Locations Success:', res.data);
  } catch (err) {
    if (err.response) {
      console.log('Recent Locations Status:', err.response.status);
      console.log('Recent Locations Data:', err.response.data);
    } else {
      console.error('Recent Locations Error:', err.message);
    }
  }
}

run();
