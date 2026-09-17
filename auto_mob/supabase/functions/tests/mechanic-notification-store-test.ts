import { createClient } from 'npm:@supabase/supabase-js@2.95.0';
import { findRecipient, reserveNotification } from '../send-mechanic-notification/store.ts';

function assert(value: unknown): asserts value { if (!value) throw new Error('assertion failed'); }
function client(responses: { body: unknown; status?: number }[]) {
  const calls: { url: URL; body: Record<string, unknown> | null }[] = [];
  const admin = createClient('https://example.test', 'fake-test-key', {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { fetch: async (input, init) => {
      calls.push({ url: new URL(String(input)), body: init?.body ? JSON.parse(String(init.body)) : null });
      const response = responses.shift();
      if (!response) throw new Error('unexpected query');
      return new Response(JSON.stringify(response.body), { status: response.status ?? 200,
        headers: { 'Content-Type': 'application/json' } });
    } },
  });
  return { admin, calls };
}

Deno.test('recipient lookup constrains active mechanic, relationship and vehicle', async () => {
  const { admin, calls } = client([{ body: { id: 'mechanic-id' } },
    { body: { id: 'link-id' } }, { body: { owner_id: 'actual-owner' } }]);
  const recipient = await findRecipient(admin, 'current-user', 'selected-vehicle');
  assert(recipient?.ownerId === 'actual-owner');
  assert(calls[0].url.searchParams.get('user_id') === 'eq.current-user');
  assert(calls[0].url.searchParams.get('is_active') === 'eq.true');
  assert(calls[1].url.searchParams.get('mechanic_id') === 'eq.mechanic-id');
  assert(calls[1].url.searchParams.get('vehicle_id') === 'eq.selected-vehicle');
  assert(calls[2].url.searchParams.get('id') === 'eq.selected-vehicle');
});
Deno.test('missing mechanic or connection stops before reading the owner', async () => {
  for (const responses of [[{ body: null }], [{ body: { id: 'mechanic-id' } }, { body: null }]]) {
    const expected = responses.length;
    const { admin, calls } = client(responses);
    assert(await findRecipient(admin, 'user', 'vehicle') === null);
    assert(calls.length === expected);
  }
});
Deno.test('reservation writes database owner and sender, never a client recipient', async () => {
  const { admin, calls } = client([{ body: { id: 'outbox-id', status: 'pending' } }]);
  const result = await reserveNotification(admin, { vehicle_id: 'vehicle', request_id: 'request',
    intervention_type: 'tagliando', title: 'Titolo', body: 'Messaggio' },
    { ownerId: 'actual-owner', mechanicId: 'actual-mechanic' });
  assert(result.created);
  assert(calls[0].body?.user_id === 'actual-owner');
  assert(calls[0].body?.sender_mechanic_id === 'actual-mechanic');
  assert(calls[0].body?.deduplication_key === 'mechanic:actual-mechanic:request');
});
Deno.test('unique conflict reads outcome with matching owner, vehicle and payload', async () => {
  const { admin, calls } = client([{ status: 409, body: { code: '23505', message: 'duplicate' } },
    { body: { id: 'outbox-id', status: 'sent' } }]);
  const result = await reserveNotification(admin, { vehicle_id: 'vehicle', request_id: 'request',
    intervention_type: 'tagliando', title: 'Titolo', body: 'Messaggio' },
    { ownerId: 'owner', mechanicId: 'mechanic' });
  assert(!result.created && result.status === 'sent');
  assert(calls[1].url.searchParams.get('vehicle_id') === 'eq.vehicle');
  assert(calls[1].url.searchParams.get('user_id') === 'eq.owner');
  assert(calls[1].url.searchParams.get('body') === 'eq.Messaggio');
});
