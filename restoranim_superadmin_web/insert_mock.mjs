import fs from 'fs';
import { createClient } from '@supabase/supabase-js';

const env = fs.readFileSync('.env.local', 'utf8').split('\n').reduce((acc, line) => {
  const [k, ...v] = line.split('=');
  if(k && v) acc[k.trim()] = v.join('=').trim();
  return acc;
}, {});

const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

async function run() {
  console.log("Fetching users and restaurants to use as foreign keys...");
  let { data: users, error: uErr } = await supabase.from('users').select('id');
  if (uErr) console.error("User Error:", uErr);
  const { data: restaurants } = await supabase.from('restaurants').select('id');

  if (!restaurants?.length) {
    console.error("Missing restaurants. Restaurants:", restaurants?.length);
    return;
  }

  if (!users?.length) {
    console.log("No users found. Inserting a dummy user...");
    const { data: newUser, error: insErr } = await supabase.from('users').insert({
      id: "11111111-1111-1111-1111-111111111111", // Random UUID format
      full_name: "Mock User",
      email: "mock@user.com",
    }).select('id');
    if (insErr) {
      console.error("Failed to insert dummy user:", insErr);
      return;
    }
    users = newUser;
  }

  const mockReservations = Array.from({ length: 10 }).map((_, i) => {
    const rId = restaurants[i % restaurants.length].id;
    const uId = users[i % users.length].id;
    const d = new Date();
    d.setDate(d.getDate() - (i % 7)); // Spread over last 7 days

    return {
      restaurant_id: rId,
      user_id: uId,
      date: d.toISOString().split('T')[0],
      time: "19:00",
      end_time: "21:00",
      guests: Math.floor(Math.random() * 4) + 1,
      status: "confirmed",
      guest_name: `Misafir ${i+1}`,
      allergies: i % 3 === 0 ? "Fıstık alerjisi" : null,
      dietary_preferences: i % 4 === 0 ? "Vegan" : null,
      chronic_diseases: i % 5 === 0 ? "Diyabet" : null,
      created_at: d.toISOString(),
    };
  });

  console.log("Inserting reservations...");
  const { data, error } = await supabase.from('reservations').insert(mockReservations).select('*');
  console.log("Inserted:", data?.length, "Error:", error);
}
run();
