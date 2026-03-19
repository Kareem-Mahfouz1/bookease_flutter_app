const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getFunctions } = require("firebase-admin/functions");
const { logger } = require("firebase-functions");

initializeApp();
setGlobalOptions({ maxInstances: 10, region: "us-central1" });

exports.onBookingCreated = onDocumentCreated(
    "bookings/{bookingId}",
    async (event) => {
        const booking = event.data?.data();
        if (!booking) return;

        if (booking.status !== "confirmed") return;

        const appointmentStart = booking.appointmentStart.toDate();
        const reminderTime = new Date(appointmentStart.getTime() - 2 * 60 * 1000);
        const now = new Date();

        logger.info(`Appointment start (UTC): ${appointmentStart.toISOString()}`);
        logger.info(`Reminder time (UTC): ${reminderTime.toISOString()}`);
        logger.info(`Now (UTC): ${now.toISOString()}`);
        logger.info(`Delay seconds: ${Math.floor((reminderTime.getTime() - now.getTime()) / 1000)}`);

        if (reminderTime <= now) {
            logger.info(`Skipping — reminder time already passed`);
            return;
        }

        const delaySeconds = Math.floor((reminderTime.getTime() - now.getTime()) / 1000);

        if (delaySeconds <= 0) {
            logger.info(`Skipping — delaySeconds is ${delaySeconds}`);
            return;
        }

        const queue = getFunctions().taskQueue("sendAppointmentReminder");
        const targetUri = await getFunctionUrl("sendAppointmentReminder");

        await queue.enqueue(
            {
                bookingId: event.params.bookingId,
                userId: booking.userId,
                serviceName: booking.serviceName,
                appointmentStartISO: appointmentStart.toISOString(),
            },
            {
                scheduleDelaySeconds: delaySeconds,
                dispatchDeadlineSeconds: 60 * 5,
                uri: targetUri,
            }
        );

        logger.info(`Reminder scheduled for booking ${event.params.bookingId} in ${delaySeconds}s`);
    }
);

exports.sendAppointmentReminder = onTaskDispatched(
    {
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 30 },
        rateLimits: { maxConcurrentDispatches: 10 },
    },
    async (req) => {
        const { bookingId, userId, serviceName, appointmentStartISO } = req.data;

        const userDoc = await getFirestore().collection("users").doc(userId).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (!fcmToken) {
            logger.warn(`No FCM token for user ${userId} — skipping`);
            return;
        }

        const bookingDoc = await getFirestore().collection("bookings").doc(bookingId).get();
        if (bookingDoc.data()?.status !== "confirmed") {
            logger.info(`Booking ${bookingId} no longer confirmed — skipping`);
            return;
        }

        const appointmentDate = new Date(appointmentStartISO);
        const displayTime = appointmentDate.toLocaleTimeString("en-US", {
            hour: "numeric",
            minute: "2-digit",
            hour12: true,
            timeZone: "Africa/Cairo",
        });

        await getMessaging().send({
            token: fcmToken,
            notification: {
                title: "Appointment Reminder",
                body: `Your ${serviceName} appointment is in 2 minutes at ${displayTime}`,
            },
            data: {
                bookingId,
                appointmentStartISO,
                type: "appointment_reminder",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "appointment_reminders",
                },
            },
        });

        logger.info(`Reminder sent to user ${userId} for booking ${bookingId}`);
    }
);

async function getFunctionUrl(name, location = "us-central1") {
    const { GoogleAuth } = require("google-auth-library");
    const auth = new GoogleAuth({ scopes: "https://www.googleapis.com/auth/cloud-platform" });
    const projectId = await auth.getProjectId();
    const url = `https://cloudfunctions.googleapis.com/v2beta/projects/${projectId}/locations/${location}/functions/${name}`;
    const client = await auth.getClient();
    const res = await client.request({ url });
    const uri = res.data?.serviceConfig?.uri;
    if (!uri) throw new Error(`Unable to retrieve URI for function ${name}`);
    return uri;
}