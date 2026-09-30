export type Draft = {
  vehicle_id: string;
  request_id: string;
  intervention_type: string;
  title: string;
  body: string;
};
export type Recipient = { mechanicId: string; ownerId: string };
export type SendStatus = "pending" | "sent" | "failed" | "no_device";
export type Reservation = { id: string; status: SendStatus; created: boolean };
export interface NotificationPorts {
  authenticate(authorization: string): Promise<string | null>;
  recipient(userId: string, vehicleId: string): Promise<Recipient | null>;
  reserve(draft: Draft, recipient: Recipient): Promise<Reservation>;
  deliver(id: string, draft: Draft, recipient: Recipient): Promise<SendStatus>;
}
const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers });
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function parseDraft(value: unknown): Draft | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  const input = value as Record<string, unknown>;
  if (
    !["vehicle_id", "request_id", "intervention_type", "title", "body"]
      .every((key) => typeof input[key] === "string")
  ) return null;
  const draft = Object.fromEntries(
    ["vehicle_id", "request_id", "intervention_type", "title", "body"]
      .map((key) => [key, (input[key] as string).trim()]),
  ) as Draft;
  return uuid.test(draft.vehicle_id) && uuid.test(draft.request_id) &&
      [
        "distribuzione",
        "tagliando",
        "pneumatici_cambio",
        "pneumatici_inversione",
      ].includes(draft.intervention_type) &&
      draft.title.length > 0 && draft.title.length <= 100 &&
      draft.body.length > 0 && draft.body.length <= 500
    ? draft
    : null;
}

export const notificationHandler =
  (ports: NotificationPorts) => async (request: Request) => {
    if (request.method === "OPTIONS") return new Response("ok", { headers });
    if (request.method !== "POST") {
      return json({ code: "method-not-allowed" }, 405);
    }
    try {
      const authorization = request.headers.get("Authorization");
      if (!authorization) return json({ code: "unauthorized" }, 401);
      const userId = await ports.authenticate(authorization);
      if (!userId) return json({ code: "unauthorized" }, 401);
      let body: unknown;
      try {
        body = await request.json();
      } catch {
        return json({ code: "invalid-json" }, 400);
      }
      const draft = parseDraft(body);
      if (!draft) return json({ code: "invalid-payload" }, 400);
      const recipient = await ports.recipient(userId, draft.vehicle_id);
      if (!recipient) return json({ code: "vehicle-not-authorized" }, 403);
      const reservation = await ports.reserve(draft, recipient);
      // Only the request that inserts the unique outbox key may send. A retry
      // after a lost HTTP response returns the recorded outcome, without a push.
      const status = reservation.created
        ? await ports.deliver(reservation.id, draft, recipient)
        : reservation.status;
      return json({ status, notification_id: reservation.id });
    } catch (error) {
      console.error(
        "mechanic-notification-failed",
        error instanceof Error ? error.message : "unknown",
      );
      return json({ code: "send-unavailable" }, 500);
    }
  };
