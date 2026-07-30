import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

/**
 * Registra e disattiva i token FCM.
 *
 * Il client non invia mai user_id: lo ricaviamo dal JWT Supabase. In questo
 * modo un utente non puo' associare un dispositivo all'account di un altro.
 */
Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ success: false, code: "method-not-allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = request.headers.get("Authorization");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ success: false, code: "configuration-error" }, 500);
  }
  if (!authorization) {
    return json({ success: false, code: "unauthorized" }, 401);
  }

  // Questo client usa il JWT ricevuto e identifica l'utente corrente.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) {
    return json({ success: false, code: "unauthorized" }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch (_) {
    return json({ success: false, code: "invalid-json" }, 400);
  }

  const action = String(body.action ?? "");
  const token = String(body.token ?? "").trim();
  const platform = String(body.platform ?? "").toLowerCase();

  if (token.length < 20 || token.length > 4096) {
    return json({ success: false, code: "invalid-token" }, 400);
  }

  // Il client admin serve per riassegnare in sicurezza lo stesso token quando
  // un telefono passa da un account a un altro. La service role resta server.
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  if (action === "register") {
    if (platform !== "android" && platform !== "ios") {
      return json({ success: false, code: "invalid-platform" }, 400);
    }

    const now = new Date().toISOString();
    const { error } = await admin.from("device_tokens").upsert(
      {
        user_id: authData.user.id,
        token,
        platform,
        is_active: true,
        last_seen_at: now,
        updated_at: now,
      },
      { onConflict: "token" },
    );

    if (error) {
      console.error("device-token register failed", error.code);
      return json({ success: false, code: "save-failed" }, 500);
    }
    return json({ success: true, action: "registered" });
  }

  if (action === "unregister") {
    const { error } = await admin
      .from("device_tokens")
      .update({ is_active: false, updated_at: new Date().toISOString() })
      .eq("user_id", authData.user.id)
      .eq("token", token);

    if (error) {
      console.error("device-token unregister failed", error.code);
      return json({ success: false, code: "save-failed" }, 500);
    }
    return json({ success: true, action: "unregistered" });
  }

  return json({ success: false, code: "unknown-action" }, 400);
});
