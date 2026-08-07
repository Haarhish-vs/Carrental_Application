const { supabase } = require('./src/config/supabase');

async function run() {
  const { data: vehicles, error } = await supabase
    .from('vehicles')
    .select('id, brand, model, is_available, status');
    
  if (error) {
    console.error('Error fetching vehicles:', error);
    return;
  }
  
  console.log('--- ALL VEHICLES ---');
  vehicles.forEach(v => {
    console.log(`ID: ${v.id} | Name: ${v.brand} ${v.model} | is_available: ${v.is_available} | status: ${v.status}`);
  });
}

run();
