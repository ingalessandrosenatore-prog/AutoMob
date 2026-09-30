import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from '@supabase/supabase-js';
import { createHandler } from './logic.ts';

const url = Deno.env.get('SUPABASE_URL')!;
const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createHandler({
  authenticate: async (authorization) => {
    const client = createClient(url, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await client.auth.getUser();
    return error ? null : data.user?.id ?? null;
  },
  resolve: async (userId, registration) => {
    // The service-only RPC locks the profile and completes it once, atomically.
    const { data, error } = await admin.rpc('resolve_owner_registration', {
      p_user_id: userId,
      p_full_name: registration?.full_name ?? null,
      p_phone: registration?.phone ?? null,
      p_postal_code: registration?.postal_code ?? null,
      p_complete: registration !== null,
    });
    if (error) throw new Error('Profile operation failed');
    return data;
  },
}));
