// ⚠️ FILL THESE IN — see SETUP.md Step 2.
// Both values come from your Supabase project's Settings → API page.
// The "anon public" key is SAFE to put in this public file — it's designed
// to be public. Never put the "service_role" key anywhere in this project.

const SUPABASE_URL = "https://vqlojjooblxguwtoefkb.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_LfjrcHB61IZwJFa21F7FkA_Qkh4QaiV";

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
