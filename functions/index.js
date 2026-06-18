const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getFunctions } = require("firebase-admin/functions");
const { logger } = require("firebase-functions");

initializeApp();
setGlobalOptions({ maxInstances: 10, region: "us-central1" });

const PAYMOB_API_KEY = defineSecret("PAYMOB_API_KEY");
const PAYMOB_INTEGRATION_ID = defineSecret("PAYMOB_INTEGRATION_ID");
const PAYMOB_WALLET_INTEGRATION_ID = defineSecret("PAYMOB_WALLET_INTEGRATION_ID");
const PAYMOB_KIOSK_INTEGRATION_ID = defineSecret("PAYMOB_KIOSK_INTEGRATION_ID");
const PAYMOB_HMAC_SECRET = defineSecret("PAYMOB_HMAC_SECRET");
const PAYMENT_HOLD_MINUTES = 15;

exports.onBookingCreated = onDocumentCreated(
    "bookings/{bookingId}",
    async (event) => {
        const booking = event.data?.data();
        if (!booking) return;

        if (booking.status !== "confirmed") return;

        const appointmentStart = booking.appointmentStart.toDate();
        const reminderTime = new Date(appointmentStart.getTime() - 60 * 60 * 1000);
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

exports.onBookingConfirmed = onDocumentUpdated(
    "bookings/{bookingId}",
    async (event) => {
        const before = event.data?.before?.data();
        const after = event.data?.after?.data();

        if (!before || !after) return;
        if (before.status === "confirmed" || after.status !== "confirmed") return;

        const appointmentStart = after.appointmentStart.toDate();
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
                userId: after.userId,
                serviceName: after.serviceName,
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

exports.expirePendingPaymobBooking = onTaskDispatched(
    {
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 30 },
        rateLimits: { maxConcurrentDispatches: 10 },
    },
    async (req) => {
        const { bookingId } = req.data;
        if (!bookingId) {
            logger.warn("expirePendingPaymobBooking called without bookingId");
            return;
        }

        const db = getFirestore();
        const bookingRef = db.collection("bookings").doc(bookingId);

        await db.runTransaction(async (transaction) => {
            const bookingSnapshot = await transaction.get(bookingRef);
            if (!bookingSnapshot.exists) return;

            const booking = bookingSnapshot.data();
            if (booking.status !== "pending" || booking.paymentStatus !== "pending") {
                return;
            }

            await releaseReservedSlotForBooking(transaction, db, booking);
            transaction.update(bookingRef, {
                status: "cancelled",
                paymentStatus: "expired",
                expiredAt: new Date(),
            });
        });

        logger.info(`Expired pending Paymob booking ${bookingId}`);
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

async function checkAndReserveSlot(appointmentStart, appointmentEnd) {
    const startDate = new Date(appointmentStart);
    const endDate = new Date(appointmentEnd);

    const { dateKey, startMinutes, endMinutes } = getSlotKeyAndMinutes(startDate, endDate);

    const db = getFirestore();
    const dailySlotsRef = db.collection("daily_slots").doc(dateKey);

    await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(dailySlotsRef);
        let bookedIntervals = [];
        if (doc.exists) {
            bookedIntervals = doc.data().bookedIntervals || [];
        }

        const hasOverlap = bookedIntervals.some(i => {
            return startMinutes < i.endMinutes && endMinutes > i.startMinutes;
        });

        if (hasOverlap) {
            throw new HttpsError("already-exists", "This time slot is no longer available.");
        }

        bookedIntervals.push({ startMinutes, endMinutes });
        transaction.set(dailySlotsRef, { bookedIntervals }, { merge: true });
    });
}

async function checkSlotAvailable(appointmentStart, appointmentEnd) {
    const { dateKey, startMinutes, endMinutes } = getSlotKeyAndMinutes(appointmentStart, appointmentEnd);

    const db = getFirestore();
    const dailySlotsRef = db.collection("daily_slots").doc(dateKey);
    const doc = await dailySlotsRef.get();
    const bookedIntervals = doc.exists ? doc.data().bookedIntervals || [] : [];

    const hasOverlap = bookedIntervals.some(i => {
        return startMinutes < i.endMinutes && endMinutes > i.startMinutes;
    });

    if (hasOverlap) {
        throw new HttpsError("already-exists", "This time slot is no longer available.");
    }
}

function getSlotKeyAndMinutes(appointmentStart, appointmentEnd) {
    const startDate = new Date(appointmentStart);
    const endDate = new Date(appointmentEnd);

    const dateFmt = new Intl.DateTimeFormat('en-CA', { timeZone: 'Africa/Cairo', year: 'numeric', month: '2-digit', day: '2-digit' });
    const timeFmt = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Cairo', hour: '2-digit', minute: '2-digit' });

    const dateKey = dateFmt.format(startDate);

    const startParts = timeFmt.format(startDate).split(':');
    const startMinutes = parseInt(startParts[0], 10) * 60 + parseInt(startParts[1], 10);

    const endParts = timeFmt.format(endDate).split(':');
    const endMinutes = parseInt(endParts[0], 10) * 60 + parseInt(endParts[1], 10);

    return { dateKey, startMinutes, endMinutes };
}

function firestoreDateToDate(value) {
    if (value?.toDate) return value.toDate();
    return new Date(value);
}

async function releaseSlot(appointmentStart, appointmentEnd) {
    const { dateKey, startMinutes, endMinutes } = getSlotKeyAndMinutes(appointmentStart, appointmentEnd);

    const db = getFirestore();
    const dailySlotsRef = db.collection("daily_slots").doc(dateKey);

    await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(dailySlotsRef);
        let bookedIntervals = [];
        if (doc.exists) {
            bookedIntervals = doc.data().bookedIntervals || [];
        }

        bookedIntervals = bookedIntervals.filter(i => {
            return i.startMinutes !== startMinutes || i.endMinutes !== endMinutes;
        });
        transaction.set(dailySlotsRef, { bookedIntervals }, { merge: true });
    });
}

async function releaseReservedSlotForBooking(transaction, db, booking) {
    if (booking.onlinePaymentMethod === "kiosk") return;

    const appointmentStart = firestoreDateToDate(booking.appointmentStart);
    const appointmentEnd = firestoreDateToDate(booking.appointmentEnd);
    const { dateKey, startMinutes, endMinutes } = getSlotKeyAndMinutes(appointmentStart, appointmentEnd);
    const slotsDocRef = db.collection("daily_slots").doc(dateKey);
    const slotsSnapshot = await transaction.get(slotsDocRef);

    if (!slotsSnapshot.exists) return;

    const intervals = slotsSnapshot.data().bookedIntervals || [];
    const bookedIntervals = intervals.filter(i => {
        return i.startMinutes !== startMinutes || i.endMinutes !== endMinutes;
    });

    transaction.set(slotsDocRef, { bookedIntervals }, { merge: true });
}

async function markBookingPaymentFailed(bookingRef, message = null) {
    if (!bookingRef) return;

    const updateData = {
        paymentStatus: "failed",
        status: "cancelled",
    };

    if (message) {
        updateData.paymentFailureMessage = message;
    }

    await bookingRef.update(updateData);
}

async function enqueuePendingPaymentExpiry(bookingId) {
    try {
        const queue = getFunctions().taskQueue("expirePendingPaymobBooking");
        const targetUri = await getFunctionUrl("expirePendingPaymobBooking");

        await queue.enqueue(
            { bookingId },
            {
                scheduleDelaySeconds: PAYMENT_HOLD_MINUTES * 60,
                dispatchDeadlineSeconds: 60,
                uri: targetUri,
            }
        );
    } catch (error) {
        logger.error(`Failed to enqueue pending payment expiry for booking ${bookingId}:`, error);
    }
}

async function reserveSlotForPaidBooking(transaction, db, booking) {
    const appointmentStart = firestoreDateToDate(booking.appointmentStart);
    const appointmentEnd = firestoreDateToDate(booking.appointmentEnd);
    const { dateKey, startMinutes, endMinutes } = getSlotKeyAndMinutes(appointmentStart, appointmentEnd);
    const slotsDocRef = db.collection("daily_slots").doc(dateKey);
    const slotsSnapshot = await transaction.get(slotsDocRef);
    const bookedIntervals = slotsSnapshot.exists ? slotsSnapshot.data().bookedIntervals || [] : [];

    const hasOverlap = bookedIntervals.some(i => {
        return startMinutes < i.endMinutes && endMinutes > i.startMinutes;
    });

    if (hasOverlap) {
        return false;
    }

    bookedIntervals.push({ startMinutes, endMinutes });
    transaction.set(slotsDocRef, { bookedIntervals }, { merge: true });
    return true;
}

function getPaymobIntegrationId(onlinePaymentMethod) {
    if (onlinePaymentMethod === "wallet") {
        return PAYMOB_WALLET_INTEGRATION_ID.value();
    }

    if (onlinePaymentMethod === "kiosk") {
        return PAYMOB_KIOSK_INTEGRATION_ID.value();
    }

    return PAYMOB_INTEGRATION_ID.value();
}

function normalizeOnlinePaymentMethod(onlinePaymentMethod) {
    const method = onlinePaymentMethod || "card";
    if (!["card", "wallet", "kiosk"].includes(method)) {
        throw new HttpsError("invalid-argument", "Unsupported online payment method.");
    }

    return method;
}

function normalizeWalletPhoneNumber(walletPhoneNumber) {
    const phone = walletPhoneNumber?.toString().trim() || "";
    if (!/^01\d{9}$/.test(phone)) {
        throw new HttpsError("invalid-argument", "Wallet phone number must use the 01XXXXXXXXX format.");
    }

    return phone;
}

async function parsePaymobErrorResponse(response) {
    const responseText = await response.text();
    try {
        return JSON.parse(responseText);
    } catch (_) {
        return responseText;
    }
}

function logPaymobError(step, response, body, context = {}) {
    logger.error(`Paymob ${step} failed`, {
        status: response.status,
        statusText: response.statusText,
        body,
        ...context,
    });
}

exports.createPaymobOrder = onCall(
    {
        secrets: [
            PAYMOB_API_KEY,
            PAYMOB_INTEGRATION_ID,
            PAYMOB_WALLET_INTEGRATION_ID,
            PAYMOB_KIOSK_INTEGRATION_ID,
        ],
    },
    async (request) => {
        const data = request.data;
        const {
            serviceId,
            serviceName,
            serviceDurationMinutes,
            price,
            appointmentStart,
            appointmentEnd,
            customerName,
            customerEmail,
            customerPhone,
            walletPhoneNumber,
            notes,
            paymentMethod,
            onlinePaymentMethod = "card"
        } = data;

        const userId = request.auth?.uid;
        if (!userId) {
            throw new HttpsError("unauthenticated", "User must be logged in.");
        }

        const normalizedOnlinePaymentMethod = normalizeOnlinePaymentMethod(onlinePaymentMethod);
        const normalizedWalletPhoneNumber = normalizedOnlinePaymentMethod === "wallet"
            ? normalizeWalletPhoneNumber(walletPhoneNumber || customerPhone)
            : null;
        let slotReserved = false;
        let bookingRef = null;
        try {
            if (normalizedOnlinePaymentMethod === "kiosk") {
                await checkSlotAvailable(appointmentStart, appointmentEnd);
            } else {
                await checkAndReserveSlot(appointmentStart, appointmentEnd);
                slotReserved = true;
            }

            // 1. Authenticate with Paymob

            const authRes = await fetch("https://accept.paymob.com/api/auth/tokens", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ api_key: PAYMOB_API_KEY.value() }),
            });
            if (!authRes.ok) {
                const errorBody = await parsePaymobErrorResponse(authRes);
                logPaymobError("auth", authRes, errorBody, {
                    onlinePaymentMethod: normalizedOnlinePaymentMethod,
                });
                throw new Error("Paymob auth failed");
            }
            const authData = await authRes.json();
            const token = authData.token;

            const amountCents = Math.round(price * 100);

            // 2. Create Order
            const orderRes = await fetch("https://accept.paymob.com/api/ecommerce/orders", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    auth_token: token,
                    delivery_needed: "false",
                    amount_cents: amountCents.toString(),
                    currency: "EGP",
                    items: [
                        {
                            name: serviceName,
                            amount_cents: amountCents.toString(),
                            description: "Appointment booking",
                            quantity: "1"
                        }
                    ],
                }),
            });
            if (!orderRes.ok) {
                const errorBody = await parsePaymobErrorResponse(orderRes);
                logPaymobError("order creation", orderRes, errorBody, {
                    onlinePaymentMethod: normalizedOnlinePaymentMethod,
                });
                throw new Error("Paymob order creation failed");
            }
            const orderData = await orderRes.json();
            const orderId = orderData.id.toString();

            // 3. Generate Payment Key
            const integrationId = getPaymobIntegrationId(normalizedOnlinePaymentMethod);
            const paymentKeyRes = await fetch("https://accept.paymob.com/api/acceptance/payment_keys", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    auth_token: token,
                    amount_cents: amountCents.toString(),
                    expiration: 3600,
                    order_id: orderId,
                    billing_data: {
                        apartment: "NA",
                        email: customerEmail,
                        floor: "NA",
                        first_name: customerName.split(" ")[0] || "NA",
                        street: "NA",
                        building: "NA",
                        phone_number: customerPhone || "NA",
                        shipping_method: "NA",
                        postal_code: "NA",
                        city: "NA",
                        country: "EG",
                        last_name: customerName.split(" ").slice(1).join(" ") || "NA",
                        state: "NA",
                    },
                    currency: "EGP",
                    integration_id: integrationId,
                    lock_order_when_paid: "false"
                }),
            });
            if (!paymentKeyRes.ok) {
                const errorBody = await parsePaymobErrorResponse(paymentKeyRes);
                logPaymobError("payment key generation", paymentKeyRes, errorBody, {
                    onlinePaymentMethod: normalizedOnlinePaymentMethod,
                    integrationId,
                    orderId,
                });
                throw new Error("Paymob payment key generation failed");
            }
            const paymentKeyData = await paymentKeyRes.json();
            const paymentToken = paymentKeyData.token;
            let kioskReferenceNumber = null;
            let walletRedirectUrl = null;
            const paymentExpiresAt = normalizedOnlinePaymentMethod === "kiosk"
                ? null
                : new Date(Date.now() + PAYMENT_HOLD_MINUTES * 60 * 1000);

            bookingRef = getFirestore().collection("bookings").doc();
            await bookingRef.set({
                serviceId,
                serviceName,
                serviceDurationMinutes,
                price,
                appointmentStart: new Date(appointmentStart),
                appointmentEnd: new Date(appointmentEnd),
                userId,
                customerName,
                customerEmail,
                customerPhone: customerPhone || null,
                notes: notes || null,
                status: "pending",
                paymentStatus: "pending",
                paymobOrderId: orderId,
                paymentMethod: paymentMethod || "online",
                onlinePaymentMethod: normalizedOnlinePaymentMethod,
                kioskReferenceNumber,
                walletPhoneNumber: normalizedWalletPhoneNumber,
                walletRedirectUrl,
                paymentExpiresAt,
                createdAt: new Date(),
            });

            if (paymentExpiresAt) {
                await enqueuePendingPaymentExpiry(bookingRef.id);
            }

            if (normalizedOnlinePaymentMethod === "kiosk") {
                const kioskPayRes = await fetch("https://accept.paymob.com/api/acceptance/payments/pay", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        source: {
                            identifier: "AGGREGATOR",
                            subtype: "AGGREGATOR",
                        },
                        payment_token: paymentToken,
                    }),
                });
                if (!kioskPayRes.ok) {
                    const errorBody = await parsePaymobErrorResponse(kioskPayRes);
                    logPaymobError("kiosk payment", kioskPayRes, errorBody, {
                        integrationId,
                        orderId,
                    });
                    await markBookingPaymentFailed(bookingRef, "Paymob kiosk payment failed");
                    throw new Error("Paymob kiosk payment failed");
                }
                const kioskPayData = await kioskPayRes.json();
                kioskReferenceNumber = kioskPayData.data?.bill_reference?.toString() || null;

                if (!kioskReferenceNumber) {
                    await markBookingPaymentFailed(bookingRef, "Paymob kiosk reference missing");
                    throw new HttpsError("failed-precondition", "Failed to create Fawry reference.");
                }

                await bookingRef.update({ kioskReferenceNumber });
            }

            if (normalizedOnlinePaymentMethod === "wallet") {
                const walletPayRes = await fetch("https://accept.paymob.com/api/acceptance/payments/pay", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        source: {
                            identifier: normalizedWalletPhoneNumber,
                            subtype: "WALLET",
                        },
                        payment_token: paymentToken,
                    }),
                });
                if (!walletPayRes.ok) {
                    const errorBody = await parsePaymobErrorResponse(walletPayRes);
                    logPaymobError("wallet payment", walletPayRes, errorBody, {
                        integrationId,
                        orderId,
                        walletPhoneNumber: normalizedWalletPhoneNumber,
                    });
                    await markBookingPaymentFailed(bookingRef, "Paymob wallet payment failed");
                    if (slotReserved) {
                        await releaseSlot(appointmentStart, appointmentEnd);
                        slotReserved = false;
                    }
                    throw new Error("Paymob wallet payment failed");
                }
                const walletPayData = await walletPayRes.json();
                walletRedirectUrl = walletPayData.redirect_url?.toString() || null;

                if (!walletRedirectUrl) {
                    const walletMessage = walletPayData.data?.message?.toString()
                        || "Wallet payment could not be started.";
                    logger.error("Paymob wallet redirect URL missing", {
                        integrationId,
                        orderId,
                        walletPhoneNumber: normalizedWalletPhoneNumber,
                        walletPayData,
                    });
                    await markBookingPaymentFailed(bookingRef, walletMessage);
                    if (slotReserved) {
                        await releaseSlot(appointmentStart, appointmentEnd);
                        slotReserved = false;
                    }
                    throw new HttpsError("failed-precondition", walletMessage);
                }

                await bookingRef.update({ walletRedirectUrl });
            }

            return {
                payment_token: paymentToken,
                bookingId: bookingRef.id,
                kioskReferenceNumber,
                walletRedirectUrl,
            };
        } catch (error) {
            logger.error("createPaymobOrder error:", error);
            if (slotReserved) {
                try {
                    await releaseSlot(appointmentStart, appointmentEnd);
                } catch (releaseError) {
                    logger.error("Failed to release slot after Paymob order error:", releaseError);
                }
            }
            if (error instanceof HttpsError) {
                throw error;
            }
            throw new HttpsError("internal", "Failed to create Paymob order");
        }
    });

exports.createCashBooking = onCall({}, async (request) => {
    const data = request.data;
    const {
        serviceId,
        serviceName,
        serviceDurationMinutes,
        price,
        appointmentStart,
        appointmentEnd,
        customerName,
        customerEmail,
        customerPhone,
        notes,
        paymentMethod
    } = data;

    const userId = request.auth?.uid;
    if (!userId) {
        throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    try {
        await checkAndReserveSlot(appointmentStart, appointmentEnd);

        const bookingRef = getFirestore().collection("bookings").doc();
        await bookingRef.set({
            serviceId,
            serviceName,
            serviceDurationMinutes,
            price,
            appointmentStart: new Date(appointmentStart),
            appointmentEnd: new Date(appointmentEnd),
            userId,
            customerName,
            customerEmail,
            customerPhone: customerPhone || null,
            notes: notes || null,
            status: "confirmed",
            paymentStatus: "pending",
            paymobOrderId: null,
            paymentMethod: paymentMethod || "cash",
            createdAt: new Date(),
        });

        return { bookingId: bookingRef.id };
    } catch (error) {
        logger.error("createCashBooking error:", error);
        if (error instanceof HttpsError) {
            throw error;
        }
        throw new HttpsError("internal", "Failed to create cash booking");
    }
});

exports.cancelPendingPaymobBooking = onCall({}, async (request) => {
    const { bookingId } = request.data;
    const userId = request.auth?.uid;

    if (!userId) {
        throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    if (!bookingId) {
        throw new HttpsError("invalid-argument", "bookingId is required.");
    }

    const db = getFirestore();
    const bookingRef = db.collection("bookings").doc(bookingId);
    let cancelled = false;

    await db.runTransaction(async (transaction) => {
        const bookingSnapshot = await transaction.get(bookingRef);
        if (!bookingSnapshot.exists) {
            throw new HttpsError("not-found", "Booking not found.");
        }

        const booking = bookingSnapshot.data();
        if (booking.userId !== userId) {
            throw new HttpsError("permission-denied", "You cannot cancel this booking.");
        }

        if (booking.status !== "pending" || booking.paymentStatus !== "pending") {
            return;
        }

        await releaseReservedSlotForBooking(transaction, db, booking);
        transaction.update(bookingRef, {
            status: "cancelled",
            paymentStatus: "cancelled",
            cancelledAt: new Date(),
            cancellationReason: "user_abandoned_payment",
        });
        cancelled = true;
    });

    return { cancelled };
});

exports.paymobWebhook = onRequest({ secrets: [PAYMOB_HMAC_SECRET] }, async (req, res) => {
    if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
    }

    const { body, query } = req;
    const hmac = query.hmac;

    const obj = body.obj;
    if (!obj) {
        return res.status(400).send("Invalid body");
    }

    const hmacString = [
        obj.amount_cents,
        obj.created_at,
        obj.currency,
        obj.error_occured,
        obj.has_parent_transaction,
        obj.id,
        obj.integration_id,
        obj.is_3d_secure,
        obj.is_auth,
        obj.is_capture,
        obj.is_refunded,
        obj.is_standalone_payment,
        obj.is_voided,
        obj.order?.id,
        obj.owner,
        obj.pending,
        obj.source_data?.pan,
        obj.source_data?.sub_type,
        obj.source_data?.type,
        obj.success
    ].join("");

    const calculatedHmac = crypto.createHmac("sha512", PAYMOB_HMAC_SECRET.value())
        .update(hmacString)
        .digest("hex");

    if (calculatedHmac !== hmac) {
        logger.warn("Invalid HMAC signature");
        return res.status(401).send("Unauthorized");
    }

    const orderId = obj.order?.id?.toString();
    const success = obj.success;

    const snapshot = await getFirestore().collection("bookings").where("paymobOrderId", "==", orderId).get();
    if (snapshot.empty) {
        logger.warn(`Booking with order ID ${orderId} not found`);
        return res.status(200).send("OK");
    }

    const doc = snapshot.docs[0];

    if (success === true || success === "true") {
        const db = getFirestore();

        await db.runTransaction(async (transaction) => {
            const bookingSnapshot = await transaction.get(doc.ref);
            if (!bookingSnapshot.exists) return;

            const booking = bookingSnapshot.data();
            if (booking.status === "cancelled" && booking.paymentStatus !== "failed") {
                transaction.update(doc.ref, {
                    paymentStatus: "paid_after_cancelled",
                    paidAfterCancelledAt: new Date(),
                });
                return;
            }

            if (booking.onlinePaymentMethod === "kiosk" && booking.status !== "confirmed") {
                const slotReserved = await reserveSlotForPaidBooking(transaction, db, booking);
                if (!slotReserved) {
                    transaction.update(doc.ref, {
                        paymentStatus: "paid_slot_unavailable",
                        status: "cancelled",
                    });
                    return;
                }
            }

            transaction.update(doc.ref, {
                paymentStatus: "paid",
                status: "confirmed",
            });
        });
    } else {
        const db = getFirestore();

        await db.runTransaction(async (transaction) => {
            const bookingSnapshot = await transaction.get(doc.ref);
            if (!bookingSnapshot.exists) return;

            const booking = bookingSnapshot.data();
            await releaseReservedSlotForBooking(transaction, db, booking);

            transaction.update(doc.ref, {
                paymentStatus: "failed",
                status: "cancelled",
            });
        });
    }

    res.status(200).send("OK");
});
