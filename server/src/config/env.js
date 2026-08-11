// env.js
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, '../../.env') });

const requiredEnv = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY'
  // JWT_SECRET is intentionally optional for the current development setup.
  // GOOGLE_MAPS_API_KEY is optional: Maps endpoints handle its absence.
];

// Check for required variables
for (const envVar of requiredEnv) {
  if (!process.env[envVar]) {
    if (process.env.NODE_ENV === 'test') {
      // Set dummy defaults for mock unit tests
      process.env.SUPABASE_URL = 'https://mockproject.supabase.co';
      process.env.SUPABASE_SERVICE_ROLE_KEY = 'mock-service-role-key-1234567890';
      process.env.GOOGLE_MAPS_API_KEY = 'mock-google-maps-api-key-1234567890';
      process.env.JWT_SECRET = 'mock-jwt-secret-key-1234567890-test-environment-key';
    } else {
      console.error(`Error: Missing required environment variable: ${envVar}`);
      process.exit(1);
    }
  }
}

module.exports = {
  PORT: process.env.PORT || 3000,
  SUPABASE_URL: process.env.SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY, // Default to service role if not provided
  JWT_SECRET: process.env.JWT_SECRET,
  SMS_PROVIDER_API_KEY: process.env.SMS_PROVIDER_API_KEY || 'mock-sms-key',
  CLOUDINARY_CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME || 'doymxkmea',
  CLOUDINARY_API_KEY: process.env.CLOUDINARY_API_KEY || '223194751911512',
  CLOUDINARY_API_SECRET: process.env.CLOUDINARY_API_SECRET || 'O-eufCz3z1iEWdakuVrrdEViY94',
  GOOGLE_MAPS_API_KEY: process.env.GOOGLE_MAPS_API_KEY,

  NODE_ENV: process.env.NODE_ENV || 'development'
};
