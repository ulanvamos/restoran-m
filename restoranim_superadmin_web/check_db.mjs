import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
  console.log("Checking reservations...");
  const { data: resData, error: resError } = await supabase.from('reservations').select('*').limit(5);
  console.log("Reservations:", resData, resError);

  console.log("Checking restaurants schema...");
  const { data: restData, error: restError } = await supabase.from('restaurants').select('*').limit(1);
  if (restData && restData.length > 0) {
    console.log("Restaurant columns:", Object.keys(restData[0]));
  } else {
    console.log("Restaurants error or empty:", restError);
  }
}

check();
