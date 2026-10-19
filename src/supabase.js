import { createClient } from '@supabase/supabase-js';

const url = 'https://gxcpnixtjqpjgonpidix.supabase.co';
const publishableKey = 'sb_publishable_I2U7ErxczkFmiEGUhfICQw_B4OG-Oog';

export const supabase = createClient(url, publishableKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
});
