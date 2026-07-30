import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { JWT } from "google-auth-library";
import {
  matchesExpectedTime,
  NotificationCategory,
  notificationCopy,
  romeDate,
} from "./logic.ts";

type Candidate = {
  user_id: string;
  vehicle_id: string;
  category: NotificationCategory;
  reasons: unknown[];
  scheduled_for: string;
  title: string;
  body: string;
  deduplication_key: string;
};

type OutboxRow = Candidate & {
  id: string;
  data: Record<string, string>;
  is_test: boolean;
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const readCandidates = async (
  admin: SupabaseClient,
  asOf: string,
): Promise<Candidate[]> => {
  const { data, error } = await admin.rpc("notification_candidates", {
    p_as_of: asOf,
  });
  if (error) throw new Error(`candidate-query-failed:${error.code}`);
  return (data ?? []) as Candidate[];
};

const filterCandidates = (
  candidates: Candidate[],
  userId?: string,
  vehicleId?: string,
) =>
  candidates.filter((candidate) => {
    if (userId && candidate.user_id !== userId) return false;
    if (vehicleId && candidate.vehicle_id !== vehicleId) return false;
    return true;
  });

/**
 * Inserisce i candidati nell'outbox con un ciclo leggibile. Se una chiave
 * esiste gia', Postgres restituisce 23505 e passiamo al candidato successivo.
 */
const enqueue = async (
  admin: SupabaseClient,
  candidates: Candidate[],
  localDate: string,
  isTest: boolean,
) => {
  const inserted: OutboxRow[] = [];

  for (const candidate of candidates) {
    const suffix = isTest ? `:test:${crypto.randomUUID()}` : "";
    const { data, error } = await admin
      .from("notification_outbox")
      .insert({
        user_id: candidate.user_id,
        vehicle_id: candidate.vehicle_id,
        category: candidate.category,
        reasons: candidate.reasons,
        local_date: localDate,
        title: candidate.title,
        body: candidate.body,
        data: {
          type: candidate.category,
          vehicle_id: candidate.vehicle_id,
          route: "/home",
        },
        scheduled_for: isTest
          ? new Date().toISOString()
          : candidate.scheduled_for,
        is_test: isTest,
        deduplication_key: candidate.deduplication_key + suffix,
      })
      .select()
      .single();

    if (error?.code === "23505") continue;
    if (error) throw new Error(`outbox-insert-failed:${error.code}`);
    inserted.push(data as OutboxRow);
  }

  return inserted;
};

const accessTokenFor = async (account: ServiceAccount): Promise<string> => {
  const client = new JWT({
    email: account.client_email,
    key: account.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const credentials = await client.authorize();
  if (!credentials.access_token) {
    throw new Error("firebase-oauth-token-missing");
  }
  return credentials.access_token;
};

const firebaseErrorCode = (body: Record<string, unknown>): string => {
  const error = body.error as Record<string, unknown> | undefined;
  const details = error?.details;
  if (Array.isArray(details)) {
    for (const detail of details) {
      if (detail && typeof detail === "object" && "errorCode" in detail) {
        return String((detail as Record<string, unknown>).errorCode);
      }
    }
  }
  return String(error?.status ?? "FCM_ERROR");
};

const sendToFirebase = async (
  account: ServiceAccount,
  accessToken: string,
  token: string,
  row: OutboxRow,
) => {
  let lastError = "FCM_ERROR";

  // Tre tentativi sono sufficienti per errori di rete brevi. Usiamo un ciclo
  // semplice; non serve introdurre una libreria di retry per tre iterazioni.
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: "POST",
          signal: AbortSignal.timeout(10_000),
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: row.title, body: row.body },
              data: row.data,
              android: {
                priority: "high",
                notification: { channel_id: "automob_reminders" },
              },
              apns: { payload: { aps: { sound: "default" } } },
            },
          }),
        },
      );

      const responseBody = await response.json() as Record<string, unknown>;
      if (response.ok) {
        return { success: true, messageId: String(responseBody.name ?? "") };
      }
      lastError = firebaseErrorCode(responseBody);

      // Un token non valido non diventa valido riprovando.
      if (
        ["UNREGISTERED", "SENDER_ID_MISMATCH", "INVALID_ARGUMENT"].includes(
          lastError,
        )
      ) {
        break;
      }
    } catch (error) {
      lastError = error instanceof Error ? error.name : "NETWORK_ERROR";
    }
  }

  return { success: false, errorCode: lastError };
};

const dispatchRows = async (
  admin: SupabaseClient,
  rows: OutboxRow[],
  currentCandidates: Candidate[],
  skipRevalidation = false,
) => {
  const rawAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!rawAccount) throw new Error("firebase-service-account-missing");
  const account = JSON.parse(rawAccount) as ServiceAccount;
  const accessToken = await accessTokenFor(account);
  const activeKeys = new Set(
    currentCandidates.map((candidate) =>
      `${candidate.vehicle_id}:${candidate.category}`
    ),
  );
  const results: Record<string, unknown>[] = [];

  for (const row of rows) {
    const key = `${row.vehicle_id}:${row.category}`;
    if (!skipRevalidation && !activeKeys.has(key)) {
      await admin.from("notification_outbox")
        .update({ status: "cancelled" }).eq("id", row.id);
      results.push({ id: row.id, status: "cancelled" });
      continue;
    }

    const { data: devices, error: devicesError } = await admin
      .from("device_tokens")
      .select("id, token")
      .eq("user_id", row.user_id)
      .eq("is_active", true);
    if (devicesError) {
      throw new Error(`device-query-failed:${devicesError.code}`);
    }

    if (!devices || devices.length === 0) {
      await admin.from("notification_outbox")
        .update({ status: "no_device" }).eq("id", row.id);
      results.push({ id: row.id, status: "no_device" });
      continue;
    }

    let sentCount = 0;
    let lastError = "";
    for (const device of devices) {
      const delivery = await sendToFirebase(
        account,
        accessToken,
        String(device.token),
        row,
      );

      await admin.from("notification_deliveries").upsert({
        outbox_id: row.id,
        device_token_id: device.id,
        status: delivery.success ? "sent" : "failed",
        provider_message_id: delivery.success ? delivery.messageId : null,
        error_code: delivery.success ? null : delivery.errorCode,
        attempted_at: new Date().toISOString(),
      }, { onConflict: "outbox_id,device_token_id" });

      if (delivery.success) {
        sentCount++;
      } else {
        lastError = delivery.errorCode ?? "FCM_ERROR";
        if (
          ["UNREGISTERED", "SENDER_ID_MISMATCH", "INVALID_ARGUMENT"].includes(
            lastError,
          )
        ) {
          await admin.from("device_tokens")
            .update({ is_active: false, updated_at: new Date().toISOString() })
            .eq("id", device.id);
        }
      }
    }

    const status = sentCount > 0 ? "sent" : "failed";
    await admin.from("notification_outbox").update({
      status,
      sent_at: sentCount > 0 ? new Date().toISOString() : null,
      last_error: sentCount > 0 ? null : lastError,
    }).eq("id", row.id);
    results.push({ id: row.id, status, sentDevices: sentCount });
  }

  return results;
};

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
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ success: false, code: "configuration-error" }, 500);
  }
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch (_) {
    return json({ success: false, code: "invalid-json" }, 400);
  }

  const action = String(body.action ?? "");
  const cronSecret = request.headers.get("x-cron-secret") ?? "";
  const { data: validCronSecret } = await admin.rpc(
    "verify_notification_cron_secret",
    { p_secret: cronSecret },
  );

  // Le azioni di test possono essere usate da un utente autenticato, ma
  // vedono e modificano esclusivamente i suoi veicoli.
  let authenticatedUserId: string | undefined;
  const authorization = request.headers.get("Authorization");
  if (authorization) {
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const { data } = await userClient.auth.getUser();
    authenticatedUserId = data.user?.id;
  }

  const productionAction = action === "evaluate" || action === "dispatch";
  if (productionAction && validCronSecret !== true) {
    return json({ success: false, code: "invalid-cron-secret" }, 401);
  }
  if (!productionAction && validCronSecret !== true && !authenticatedUserId) {
    return json({ success: false, code: "unauthorized" }, 401);
  }

  const now = new Date();
  const expectedLocalTime = String(body.expected_local_time ?? "");
  if (productionAction && !matchesExpectedTime(now, expectedLocalTime)) {
    return json({ success: true, skipped: "different-local-time" });
  }

  const asOf = action === "preview" || action === "enqueue_test"
    ? String(body.as_of ?? romeDate(now))
    : romeDate(now);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(asOf)) {
    return json({ success: false, code: "invalid-date" }, 400);
  }

  const vehicleId = body.vehicle_id ? String(body.vehicle_id) : undefined;

  try {
    const allCandidates = await readCandidates(admin, asOf);
    const candidates = filterCandidates(
      allCandidates,
      validCronSecret === true ? undefined : authenticatedUserId,
      vehicleId,
    );

    if (action === "preview") {
      return json({
        success: true,
        asOf,
        count: candidates.length,
        candidates,
      });
    }

    if (action === "evaluate") {
      const rows = await enqueue(admin, candidates, asOf, false);
      return json({ success: true, queued: rows.length });
    }

    if (action === "enqueue_test") {
      const rows = await enqueue(admin, candidates, asOf, true);
      return json({ success: true, queued: rows.length, rows });
    }

    if (action === "send_test") {
      if (!vehicleId) {
        return json({ success: false, code: "vehicle-required" }, 400);
      }

      // Il client sceglie il veicolo, ma non ci fidiamo dell'id ricevuto.
      // La query con owner_id impedisce a un utente di usare send_test per un
      // veicolo appartenente a un altro account. Il test dal SQL Editor usa
      // invece il secret Cron e ricava il proprietario direttamente dal DB.
      let vehicleQuery = admin
        .from("vehicles")
        .select("id, owner_id")
        .eq("id", vehicleId);
      if (authenticatedUserId) {
        vehicleQuery = vehicleQuery.eq("owner_id", authenticatedUserId);
      }
      const { data: ownedVehicle, error: ownedVehicleError } =
        await vehicleQuery.maybeSingle();
      if (ownedVehicleError) {
        throw new Error(
          `vehicle-ownership-check-failed:${ownedVehicleError.code}`,
        );
      }
      if (!ownedVehicle) {
        return json({ success: false, code: "vehicle-not-found" }, 404);
      }

      const targetUserId = authenticatedUserId ?? String(ownedVehicle.owner_id);
      const category = String(body.category ?? "km") as NotificationCategory;
      if (!["km", "maintenance_kpi", "revision"].includes(category)) {
        return json({ success: false, code: "invalid-category" }, 400);
      }
      const copy = notificationCopy(category);
      const testCandidate: Candidate = {
        user_id: targetUserId,
        vehicle_id: vehicleId,
        category,
        reasons: [{ type: "manual-test" }],
        scheduled_for: now.toISOString(),
        title: `Test AutoMob - ${copy.title}`,
        body: copy.body,
        deduplication_key: `${vehicleId}:${category}:${asOf}`,
      };
      const rows = await enqueue(admin, [testCandidate], asOf, true);
      const results = await dispatchRows(admin, rows, [], true);
      return json({ success: true, results });
    }

    if (action === "dispatch") {
      const slot = String(body.slot ?? "");
      const slotCategories = slot === "09:00"
        ? ["km"]
        : slot === "13:00"
        ? ["maintenance_kpi"]
        : ["km", "revision"];
      const { data: pending, error } = await admin
        .from("notification_outbox")
        .select()
        .eq("status", "pending")
        .eq("is_test", false)
        .in("category", slotCategories)
        .lte("scheduled_for", now.toISOString())
        .order("scheduled_for")
        .limit(500);
      if (error) throw new Error(`outbox-query-failed:${error.code}`);
      const results = await dispatchRows(
        admin,
        (pending ?? []) as OutboxRow[],
        allCandidates,
      );
      return json({ success: true, processed: results.length, results });
    }

    return json({ success: false, code: "unknown-action" }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unexpected-error";
    console.error("notification-dispatch failed", message);
    return json({ success: false, code: message }, 500);
  }
});
