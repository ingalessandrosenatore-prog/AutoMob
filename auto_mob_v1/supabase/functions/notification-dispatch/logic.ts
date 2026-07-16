export type NotificationCategory = "km" | "maintenance_kpi" | "revision";

/** Restituisce YYYY-MM-DD nel calendario italiano. */
export const romeDate = (date: Date): string =>
  new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Rome",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);

/** Restituisce HH:mm in Europe/Rome, includendo automaticamente l'ora legale. */
export const romeTime = (date: Date): string =>
  new Intl.DateTimeFormat("it-IT", {
    timeZone: "Europe/Rome",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(date);

export const matchesExpectedTime = (date: Date, expected?: string): boolean =>
  expected == null || expected === "" || romeTime(date) === expected;

/** Testo volutamente generale: il dettaglio resta nella dashboard AutoMob. */
export const notificationCopy = (category: NotificationCategory) => {
  switch (category) {
    case "km":
      return {
        title: "Ogni chilometro racconta una storia",
        body: "Aggiorna AutoMob e prenditi cura della tua auto.",
      };
    case "maintenance_kpi":
      return {
        title: "La tua auto merita attenzione",
        body: "Apri AutoMob e controlla come prendertene cura.",
      };
    case "revision":
      return {
        title: "E' il momento di controllare la revisione",
        body: "Apri AutoMob e assicurati di circolare sempre in regola.",
      };
  }
};
