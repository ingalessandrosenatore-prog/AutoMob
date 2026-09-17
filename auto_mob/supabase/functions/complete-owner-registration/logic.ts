export type Registration = { full_name: string; phone: string; postal_code: string };

export function parseRegistration(value: unknown): Registration | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const data = value as Record<string, unknown>;
  if (typeof data.full_name !== 'string' || typeof data.phone !== 'string' ||
      typeof data.postal_code !== 'string') return null;
  const result = { full_name: data.full_name.trim(), phone: data.phone.trim(),
    postal_code: data.postal_code.trim() };
  const digits = result.phone.replace(/[^0-9]/g, '');
  if (!result.full_name || result.full_name.length > 150 ||
      !/^\+?[0-9 ()-]{8,30}$/.test(result.phone) || digits.length < 8 || digits.length > 15 ||
      !/^[0-9]{5}$/.test(result.postal_code)) return null;
  return result;
}

type Dependencies = {
  authenticate: (authorization: string) => Promise<string | null>;
  resolve: (userId: string, registration: Registration | null) => Promise<Record<string, unknown>>;
};

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};

export function createHandler(deps: Dependencies) {
  return async (request: Request): Promise<Response> => {
    const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers });
    if (request.method === 'OPTIONS') return new Response('ok', { headers });
    if (request.method !== 'POST') return json({ code: 'method-not-allowed' }, 405);
    try {
      const authorization = request.headers.get('Authorization');
      if (!authorization?.startsWith('Bearer ')) return json({ code: 'unauthorized' }, 401);
      const userId = await deps.authenticate(authorization);
      if (!userId) return json({ code: 'unauthorized' }, 401);
      let body;
      try { body = await request.json(); } catch { return json({ code: 'invalid-json' }, 400); }
      if (!body || typeof body !== 'object' || !['inspect', 'complete'].includes(body.action)) {
        return json({ code: 'invalid-action' }, 400);
      }
      const registration = body.action === 'complete' ? parseRegistration(body) : null;
      if (body.action === 'complete' && !registration) return json({ code: 'invalid-profile' }, 400);
      // Identity comes only from the verified token, never from the request body.
      const result = await deps.resolve(userId, registration);
      if (result.status === 'forbidden') return json({ code: 'owner-required' }, 403);
      if (result.status === 'missing') return json({ code: 'profile-missing' }, 409);
      return json(result);
    } catch {
      return json({ code: 'profile-unavailable' }, 503);
    }
  };
}
