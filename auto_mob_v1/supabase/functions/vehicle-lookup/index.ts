import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.95.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json" },
});

const normalizePlate = (value: unknown) => String(value ?? "")
  .replace(/[^a-z0-9]/gi, "")
  .toUpperCase();

const asInt = (value: unknown): number | null => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.round(parsed) : null;
};

const yearFrom = (data: Record<string, unknown>): number | null => {
  const date = data.registrationDate;
  if (typeof date === "string") {
    const match = date.match(/(\d{4})$/);
    if (match) return Number(match[1]);
  }
  const timestamp = asInt(data.registrationTimestamp);
  return timestamp == null ? null : new Date(timestamp).getUTCFullYear();
};

const blockWarnings = (data: Record<string, unknown>): string[] => {
  const labels: Record<string, string> = {
    details: "dettagli",
    insurance: "assicurazione",
    emissions: "emissioni",
    licenseEligibility: "idoneità neopatentati",
    inspection: "revisione",
    theft: "furto",
  };
  return Object.entries(labels).flatMap(([key, label]) => {
    const block = data[key];
    if (block == null) return [`Dati ${label} non disponibili`];
    if (typeof block === "object") {
      const value = block as Record<string, unknown>;
      if (value.success === false || value.error != null) {
        return [`Recupero ${label} non riuscito`];
      }
    }
    return [];
  });
};

const normalizedErrorCode = (status: number, providerCode?: string) => {
  if (status === 400) return "bad-request";
  if (status === 401) return "unauthorized";
  if (status === 403) return "forbidden";
  if (status === 429) return "rate-limited";
  if (status >= 500) return "unexpected-error";
  return providerCode || "unexpected-error";
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ success: false, code: "bad-request" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const providerKey = Deno.env.get("INFOTARGA_API_KEY");
  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return json({ success: false, code: "unauthorized" }, 401);
  }
  if (!supabaseUrl || !anonKey || !serviceRoleKey || !providerKey) {
    // Non mascheriamo un segreto server mancante come errore dell'utente.
    // La chiave InfoTarga resta esclusivamente nei secret della Edge Function.
    return json({
      success: false,
      code: "configuration-error",
      message: "Configurazione server incompleta",
    }, 500);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) return json({ success: false, code: "unauthorized" }, 401);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return json({ success: false, code: "bad-request" }, 400);
  }
  const plate = normalizePlate(body.plate);
  if (!/^[A-Z]{2}[0-9]{3}[A-Z]{2}$/.test(plate)) {
    return json({ success: false, code: "invalid-plate" }, 400);
  }

  let providerResponse: Response;
  try {
    providerResponse = await fetch("https://api.infotarga.com/v2/query", {
      method: "POST",
      signal: AbortSignal.timeout(12_000),
      headers: { "x-api-key": providerKey, "Content-Type": "application/json" },
      body: JSON.stringify({
        plate,
        type: "car",
        details: true,
        insurance: true,
        emissions: true,
        licenseEligibility: true,
        inspection: true,
        theft: true,
      }),
    });
  } catch (error) {
    const timeout = error instanceof DOMException && error.name === "TimeoutError";
    return json({ success: false, code: timeout ? "proxy-timeout" : "proxy-network-error" }, timeout ? 504 : 503);
  }

  let envelope: Record<string, unknown>;
  try {
    envelope = await providerResponse.json();
  } catch (_) {
    return json({ success: false, code: "unexpected-error" }, 502);
  }
  if (!providerResponse.ok || envelope.success !== true) {
    return json({
      success: false,
      code: normalizedErrorCode(providerResponse.status, envelope.code?.toString()),
      message: envelope.message,
    }, providerResponse.status || 502);
  }
  if (envelope.data == null || typeof envelope.data !== "object") {
    return json({ success: false, code: "no-data" }, 404);
  }

  const data = envelope.data as Record<string, unknown>;
  const engine = data.engine && typeof data.engine === "object"
    ? data.engine as Record<string, unknown>
    : {};
  const core = {
    plate: normalizePlate(data.plate ?? plate),
    brand: typeof data.brand === "string" ? data.brand : null,
    model: typeof data.model === "string" ? data.model : null,
    year: yearFrom(data),
    fuel: typeof engine.fuel === "string"
      ? engine.fuel
      : typeof data.fuel === "string" ? data.fuel : null,
    displacementCc: asInt(engine.cc ?? data.cc),
    powerCv: asInt(engine.hp ?? data.hp),
  };
  const complete = Object.values(core).every((value) => value != null && value !== "");
  const quality = complete ? "complete" : "partial";
  const warnings = blockWarnings(data);
  const traceId = providerResponse.headers.get("CW-Trace-Id");

  const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
  const { data: lookup, error: insertError } = await admin
    .from("vehicle_lookup_results")
    .insert({
      owner_id: authData.user.id,
      plate: core.plate,
      status: quality,
      provider_code: String(envelope.code ?? "ok"),
      core_data: core,
      raw_payload: envelope,
      trace_id: traceId,
    })
    .select("id")
    .single();
  if (insertError) return json({ success: false, code: "snapshot-save-failed" }, 500);

  return json({
    success: true,
    code: envelope.code ?? "ok",
    data: { lookupId: lookup.id, quality, ...core, warnings },
  });
});
