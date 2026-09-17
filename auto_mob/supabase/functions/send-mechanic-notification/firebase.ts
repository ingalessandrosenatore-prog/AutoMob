import { JWT } from "google-auth-library";
import type { Draft } from "./handler.ts";

export type PushResult = {
  status: "sent" | "failed";
  messageId?: string;
  error?: string;
};

export async function createPushSender() {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw) throw new Error("firebase-not-configured");
  const account = JSON.parse(raw);
  const jwt = new JWT({
    email: account.client_email,
    key: account.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const credentials = await jwt.authorize();
  if (!credentials.access_token) throw new Error("firebase-auth-failed");
  return async (token: string, draft: Draft): Promise<PushResult> => {
    try {
      // Do not retry an ambiguous timeout: FCM may already have accepted it.
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: "POST",
          signal: AbortSignal.timeout(10_000),
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${credentials.access_token}`,
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: draft.title, body: draft.body },
              data: {
                type: "mechanic_reminder",
                vehicle_id: draft.vehicle_id,
                intervention_type: draft.intervention_type,
              },
              android: {
                priority: "high",
                notification: { channel_id: "automob_reminders" },
              },
              apns: { payload: { aps: { sound: "default" } } },
            },
          }),
        },
      );
      const result = await response.json();
      if (response.ok) return { status: "sent", messageId: result.name };
      const code = result.error?.details?.find((
        detail: { errorCode?: string },
      ) => detail.errorCode)?.errorCode;
      return {
        status: "failed",
        error: code ?? result.error?.status ?? "FCM_ERROR",
      };
    } catch {
      return { status: "failed", error: "DELIVERY_UNCONFIRMED" };
    }
  };
}
