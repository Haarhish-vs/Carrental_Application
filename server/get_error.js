const axios = require('axios');

async function run() {
  try {
    const res = await axios.get('https://carrental-application-1.onrender.com/api/vehicles');
    console.log('Vehicles Success:', res.data);
  } catch (err) {
    if (err.response) {
      console.log('Vehicles Error Status:', err.response.status);
      console.log('Vehicles Error Data:', err.response.data);
    } else {
      console.error('Vehicles Error Message:', err.message);
    }
  }
}

run();
