import { createClient } from "@supabase/supabase-js";
import { notificationHandler } from "./handler.ts";
import { findRecipient, reserveNotification } from "./store.ts";
import { deliverNotification } from "./delivery.ts";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

Deno.serve(notificationHandler({
  authenticate: async (authorization) => {
    const token = authorization.match(/^Bearer\s+(.+)$/i)?.[1];
    if (!token) return null;
    const { data, error } = await admin.auth.getUser(token);
    return error ? null : data.user?.id ?? null;
  },
  recipient: (userId, vehicleId) => findRecipient(admin, userId, vehicleId),
  reserve: (draft, recipient) => reserveNotification(admin, draft, recipient),
  deliver: (id, draft, recipient) =>
    deliverNotification(admin, id, draft, recipient),
}));
