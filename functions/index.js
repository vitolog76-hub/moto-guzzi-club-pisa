const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

admin.initializeApp();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function getAllFcmTokens() {
  const db = admin.firestore();
  const snapshot = await db.collectionGroup("fcmTokens").get();
  return snapshot.docs
    .map((doc) => doc.data().token)
    .filter((t) => typeof t === "string" && t.length > 0);
}

function formatDate(timestamp) {
  if (!timestamp || !timestamp.toDate) return "";
  const d = timestamp.toDate();
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
}

// ---------------------------------------------------------------------------
// 1. Notifica: nuovo evento creato
// ---------------------------------------------------------------------------

exports.onEventCreated = onDocumentCreated(
  {
    document: "events/{eventId}",
    region: "europe-west1",
  },
  async (event) => {
    const data = event.data.data();
    const eventId = event.params.eventId;
    const titolo = data.titolo || "Evento Club";
    const tipo = data.tipo || "evento";
    const dataStr = formatDate(data.dataInizio);

    const tokens = await getAllFcmTokens();
    if (tokens.length === 0) {
      logger.info("onEventCreated: no FCM tokens available.");
      return;
    }

    const body = dataStr
      ? `${titolo} - ${dataStr}`
      : titolo;

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: `Nuovo ${tipo}`,
        body,
      },
      webpush: {
        notification: {
          icon: "https://vitolog76-hub.github.io/moto-guzzi-club-pisa/icons/Icon-192.png",
        },
      },
      data: {
        eventId,
        eventTitle: titolo,
      },
    });

    logger.info("onEventCreated push sent", {
      eventId,
      titolo,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  }
);

// ---------------------------------------------------------------------------
// 2. Notifica: evento modificato
// ---------------------------------------------------------------------------

const TRACKED_FIELDS = [
  "titolo",
  "tipo",
  "dataInizio",
  "dataFine",
  "luogo",
  "puntoRitrovo",
  "descrizione",
];

function hasMeaningfulChange(before, after) {
  for (const field of TRACKED_FIELDS) {
    const a = before[field];
    const b = after[field];
    // Handle Firestore Timestamps
    if (a && typeof a.isEqual === "function") {
      if (!b || !a.isEqual(b)) return true;
    } else if (JSON.stringify(a) !== JSON.stringify(b)) {
      return true;
    }
  }
  return false;
}

exports.onEventUpdated = onDocumentUpdated(
  {
    document: "events/{eventId}",
    region: "europe-west1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const eventId = event.params.eventId;

    if (!hasMeaningfulChange(before, after)) {
      logger.info("onEventUpdated: no meaningful changes, skipping.", {eventId});
      return;
    }

    const titolo = after.titolo || "Evento Club";

    const tokens = await getAllFcmTokens();
    if (tokens.length === 0) {
      logger.info("onEventUpdated: no FCM tokens available.");
      return;
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Evento aggiornato",
        body: `${titolo} è stato modificato`,
      },
      webpush: {
        notification: {
          icon: "https://vitolog76-hub.github.io/moto-guzzi-club-pisa/icons/Icon-192.png",
        },
      },
      data: {
        eventId,
        eventTitle: titolo,
      },
    });

    logger.info("onEventUpdated push sent", {
      eventId,
      titolo,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  }
);

// ---------------------------------------------------------------------------
// 3. Promemoria 3 giorni prima (esistente)
// ---------------------------------------------------------------------------

exports.sendThreeDayEventReminder = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Europe/Rome",
    region: "europe-west1",
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();

    const targetStart = new Date(now);
    targetStart.setHours(0, 0, 0, 0);
    targetStart.setDate(targetStart.getDate() + 3);

    const targetEnd = new Date(targetStart);
    targetEnd.setDate(targetEnd.getDate() + 1);

    const eventsSnapshot = await db
      .collection("events")
      .where("dataInizio", ">=", admin.firestore.Timestamp.fromDate(targetStart))
      .where("dataInizio", "<", admin.firestore.Timestamp.fromDate(targetEnd))
      .get();

    if (eventsSnapshot.empty) {
      logger.info("No events found for 3-day reminder window.");
      return;
    }

    const tokens = await getAllFcmTokens();
    if (tokens.length === 0) {
      logger.info("No FCM tokens available.");
      return;
    }

    for (const eventDoc of eventsSnapshot.docs) {
      const eventData = eventDoc.data();
      const eventTitle = eventData.titolo || "Evento Club";

      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "Promemoria evento",
          body: `${eventTitle} inizia tra 3 giorni.`,
        },
        webpush: {
          notification: {
            icon: "https://vitolog76-hub.github.io/moto-guzzi-club-pisa/icons/Icon-192.png",
          },
        },
        data: {
          eventId: eventDoc.id,
          eventTitle,
        },
      });

      logger.info("Reminder push sent", {
        eventId: eventDoc.id,
        eventTitle,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    }
  }
);
