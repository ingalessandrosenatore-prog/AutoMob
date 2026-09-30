import {
  notificationHandler,
  type NotificationPorts,
  parseDraft,
} from "../send-mechanic-notification/handler.ts";

const draft = {
  vehicle_id: "11111111-1111-4111-8111-111111111111",
  request_id: "22222222-2222-4222-8222-222222222222",
  intervention_type: "tagliando",
  title: "Tagliando",
  body: "Contattaci per il tagliando.",
};
function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
const request = (body: unknown = draft, authorized = true) =>
  new Request("https://example.test", {
    method: "POST",
    headers: authorized ? { Authorization: "Bearer user-jwt" } : {},
    body: JSON.stringify(body),
  });
function fixture() {
  const calls: string[] = [];
  const ports: NotificationPorts = {
    authenticate: async () => {
      calls.push("auth");
      return "mechanic-user";
    },
    recipient: async (user, vehicle) => {
      assert(user === "mechanic-user" && vehicle === draft.vehicle_id);
      calls.push("recipient");
      return { mechanicId: "mechanic", ownerId: "owner-from-db" };
    },
    reserve: async (input, recipient) => {
      assert(recipient.ownerId === "owner-from-db");
      assert(input.title === "Tagliando");
      calls.push("reserve");
      return { id: "outbox", status: "pending", created: true };
    },
    deliver: async () => {
      calls.push("deliver");
      return "sent";
    },
  };
  return { ports, calls };
}

Deno.test("reject unauthenticated calls before querying or sending", async () => {
  const { ports, calls } = fixture();
  assert(
    (await notificationHandler(ports)(request(draft, false))).status === 401,
  );
  assert(calls.length === 0);
  ports.authenticate = async () => null;
  assert((await notificationHandler(ports)(request())).status === 401);
});
Deno.test("unlinked mechanic cannot reserve or send a notification", async () => {
  const { ports, calls } = fixture();
  ports.recipient = async () => null;
  assert((await notificationHandler(ports)(request())).status === 403);
  assert(!calls.includes("deliver") && !calls.includes("reserve"));
});
Deno.test("owner is resolved server-side and edited text reaches delivery", async () => {
  const { ports } = fixture();
  ports.deliver = async (_, input, recipient) => {
    assert(input.body === "Testo modificato");
    assert(recipient.ownerId === "owner-from-db");
    return "sent";
  };
  const response = await notificationHandler(ports)(
    request({ ...draft, body: "Testo modificato", user_id: "attacker-target" }),
  );
  assert(response.status === 200);
  assert((await response.json()).status === "sent");
});
Deno.test("duplicate request returns stored result without another delivery", async () => {
  const { ports, calls } = fixture();
  ports.reserve = async () => ({
    id: "outbox",
    status: "sent",
    created: false,
  });
  const response = await notificationHandler(ports)(request());
  assert((await response.json()).status === "sent");
  assert(!calls.includes("deliver"));
});
Deno.test("no device and failed delivery are not reported as success", async () => {
  for (const status of ["no_device", "failed", "pending"] as const) {
    const { ports } = fixture();
    ports.deliver = async () => status;
    const response = await notificationHandler(ports)(request());
    assert((await response.json()).status === status);
  }
});
Deno.test("validates four intervention types, UUIDs, blank and oversized copy", () => {
  for (
    const intervention_type of [
      "tagliando",
      "distribuzione",
      "pneumatici_cambio",
      "pneumatici_inversione",
    ]
  ) {
    assert(parseDraft({ ...draft, intervention_type }));
  }
  for (
    const invalid of [
      null,
      [],
      { ...draft, vehicle_id: "bad" },
      { ...draft, intervention_type: "revision" },
      { ...draft, title: " " },
      { ...draft, body: " " },
      { ...draft, title: "x".repeat(101) },
      { ...draft, body: "x".repeat(501) },
    ]
  ) assert(parseDraft(invalid) === null);
  assert(
    parseDraft({ ...draft, title: "  Tagliando  " })?.title === "Tagliando",
  );
});
