import { createHandler, parseRegistration } from '../complete-owner-registration/logic.ts';

function assert(value: unknown, message = 'Assertion failed'): asserts value {
  if (!value) throw new Error(message);
}

Deno.test('contact validation rejects missing or malformed fields', () => {
  assert(parseRegistration(null) === null);
  assert(parseRegistration({ full_name: 'Mario', phone: 'abc3331234567', postal_code: '00100' }) === null);
  assert(parseRegistration({ full_name: '', phone: '3331234567', postal_code: '00100' }) === null);
  assert(parseRegistration({ full_name: 'Mario', phone: '3331234567', postal_code: '100' }) === null);
  assert(parseRegistration({ full_name: ' Mario ', phone: '+39 3331234567', postal_code: '00100' })?.full_name === 'Mario');
});

Deno.test('unauthenticated callers cannot reach profile storage', async () => {
  const handler = createHandler({ authenticate: async () => null,
    resolve: () => { throw new Error('Must not execute'); } });
  assert((await handler(new Request('https://test', { method: 'POST', headers: { Authorization: 'Bearer bad' }, body: '{}' }))).status === 401);
});

Deno.test('uses verified subject and ignores a forged user id', async () => {
  let called = false;
  const handler = createHandler({ authenticate: async () => 'verified-owner',
    resolve: async (id, registration) => {
      assert(id === 'verified-owner'); assert(registration?.postal_code === '00100');
      called = true; return { status: 'ready' };
    } });
  const response = await handler(new Request('https://test', { method: 'POST',
    headers: { Authorization: 'Bearer valid' }, body: JSON.stringify({ action: 'complete',
      user_id: 'victim', full_name: 'Mario', phone: '3331234567', postal_code: '00100' }) }));
  assert(response.status === 200 && called);
});

Deno.test('mechanic profiles are forbidden', async () => {
  const handler = createHandler({ authenticate: async () => 'mechanic', resolve: async () => ({ status: 'forbidden' }) });
  const response = await handler(new Request('https://test', { method: 'POST',
    headers: { Authorization: 'Bearer valid' }, body: '{"action":"inspect"}' }));
  assert(response.status === 403);
});

Deno.test('inspection does not submit registration data', async () => {
  const handler = createHandler({ authenticate: async () => 'owner', resolve: async (_, data) => {
    assert(data === null); return { status: 'incomplete', profile: {} };
  } });
  const response = await handler(new Request('https://test', { method: 'POST',
    headers: { Authorization: 'Bearer valid' }, body: '{"action":"inspect"}' }));
  assert((await response.json()).status === 'incomplete');
});
