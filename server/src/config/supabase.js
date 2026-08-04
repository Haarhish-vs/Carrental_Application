const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey || supabaseUrl.includes('your-supabase-project')) {
  console.warn('WARNING: Supabase URL or Key is missing or using placeholder. Ensure SUPABASE_URL and SUPABASE_KEY are set in your environment.');
}

const supabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseKey || 'placeholder-key'
);

module.exports = supabase;
