import { assertEquals } from "jsr:@std/assert@1";
import {
  matchesExpectedTime,
  notificationCopy,
  romeDate,
  romeTime,
} from "../notification-dispatch/logic.ts";

Deno.test("romeDate usa il calendario italiano", () => {
  assertEquals(romeDate(new Date("2026-07-15T22:30:00Z")), "2026-07-16");
});

Deno.test("romeTime gestisce l'ora legale", () => {
  assertEquals(romeTime(new Date("2026-07-15T07:00:00Z")), "09:00");
  assertEquals(
    matchesExpectedTime(
      new Date("2026-07-15T07:00:00Z"),
      "09:00",
    ),
    true,
  );
});

Deno.test("ogni categoria ha un testo", () => {
  assertEquals(notificationCopy("km").title.length > 0, true);
  assertEquals(notificationCopy("maintenance_kpi").body.length > 0, true);
  assertEquals(notificationCopy("revision").title.length > 0, true);
});
