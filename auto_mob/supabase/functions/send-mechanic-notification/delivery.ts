import type { SupabaseClient } from "@supabase/supabase-js";
import type { Draft, Recipient, SendStatus } from "./handler.ts";
import { createPushSender } from "./firebase.ts";

export async function deliverNotification(
  admin: SupabaseClient,
  id: string,
  draft: Draft,
  recipient: Recipient,
): Promise<SendStatus> {
  const devices = await admin.from("device_tokens").select("id, token")
    .eq("user_id", recipient.ownerId).eq("is_active", true);
  if (devices.error) {
    const saved = await admin.from("notification_outbox")
      .update({ status: "failed", last_error: "devices-query-failed" }).eq(
        "id",
        id,
      );
    if (saved.error) throw new Error("outbox-update-failed");
    return "failed";
  }
  let status: SendStatus = "no_device";
  let lastError: string | null = null;
  if (devices.data.length) {
    let send;
    try {
      send = await createPushSender();
    } catch {
      const saved = await admin.from("notification_outbox")
        .update({ status: "failed", last_error: "firebase-setup-failed" }).eq(
          "id",
          id,
        );
      if (saved.error) throw new Error("outbox-update-failed");
      return "failed";
    }
    // Parallel device delivery keeps a multi-device account within the HTTP
    // request lifetime. The outbox reservation prevents concurrent re-sends.
    const results = await Promise.all(devices.data.map(async (device) => {
      const result = await send(device.token, draft);
      const saved = await admin.from("notification_deliveries").upsert({
        outbox_id: id,
        device_token_id: device.id,
        status: result.status,
        provider_message_id: result.messageId ?? null,
        error_code: result.error ?? null,
        attempted_at: new Date().toISOString(),
      }, { onConflict: "outbox_id,device_token_id" });
      if (saved.error) throw new Error("delivery-save-failed");
      if (["UNREGISTERED", "SENDER_ID_MISMATCH"].includes(result.error ?? "")) {
        const update = await admin.from("device_tokens")
          .update({ is_active: false, updated_at: new Date().toISOString() })
          .eq("id", device.id);
        if (update.error) throw new Error("token-update-failed");
      }
      return result;
    }));
    status = results.some((result) => result.status === "sent")
      ? "sent"
      : results.some((result) => result.error === "DELIVERY_UNCONFIRMED")
      ? "pending"
      : "failed";
    lastError = status === "sent" ? null : results[0].error ?? "FCM_ERROR";
  }
  const saved = await admin.from("notification_outbox").update({
    status,
    sent_at: status === "sent" ? new Date().toISOString() : null,
    last_error: lastError,
  }).eq("id", id);
  if (saved.error) throw new Error("outbox-update-failed");
  return status;
}
