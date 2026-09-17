import type { SupabaseClient } from "npm:@supabase/supabase-js@2.95.0";
import type { Draft, Recipient, Reservation } from "./handler.ts";

export async function findRecipient(
  admin: SupabaseClient,
  userId: string,
  vehicleId: string,
): Promise<Recipient | null> {
  const mechanic = await admin.from("mechanics").select("id")
    .eq("user_id", userId).eq("is_active", true).maybeSingle();
  if (mechanic.error) throw new Error("mechanic-query-failed");
  if (!mechanic.data) return null;
  const link = await admin.from("vehicle_mechanics").select("id")
    .eq("mechanic_id", mechanic.data.id).eq("vehicle_id", vehicleId)
    .maybeSingle();
  if (link.error) throw new Error("link-query-failed");
  if (!link.data) return null;
  const vehicle = await admin.from("vehicles").select("owner_id").eq(
    "id",
    vehicleId,
  ).maybeSingle();
  if (vehicle.error) throw new Error("vehicle-query-failed");
  if (!vehicle.data?.owner_id) return null;
  return { mechanicId: mechanic.data.id, ownerId: vehicle.data.owner_id };
}

export async function reserveNotification(
  admin: SupabaseClient,
  draft: Draft,
  recipient: Recipient,
): Promise<Reservation> {
  const key = `mechanic:${recipient.mechanicId}:${draft.request_id}`;
  const now = new Date();
  const inserted = await admin.from("notification_outbox").insert({
    user_id: recipient.ownerId,
    vehicle_id: draft.vehicle_id,
    sender_mechanic_id: recipient.mechanicId,
    category: "mechanic_reminder",
    title: draft.title,
    body: draft.body,
    data: {
      type: "mechanic_reminder",
      vehicle_id: draft.vehicle_id,
      intervention_type: draft.intervention_type,
    },
    local_date: new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/Rome" })
      .format(now),
    scheduled_for: now.toISOString(),
    deduplication_key: key,
  }).select("id, status").single();
  if (!inserted.error) {
    return { ...inserted.data, created: true } as Reservation;
  }
  if (inserted.error.code !== "23505") throw new Error("outbox-insert-failed");
  const existing = await admin.from("notification_outbox").select("id, status")
    .eq("deduplication_key", key).eq("vehicle_id", draft.vehicle_id)
    .eq("user_id", recipient.ownerId).eq("title", draft.title).eq(
      "body",
      draft.body,
    )
    .eq("data->>intervention_type", draft.intervention_type).single();
  if (existing.error) throw new Error("request-conflict");
  return { ...existing.data, created: false } as Reservation;
}
