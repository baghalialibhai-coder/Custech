// functions/merchantNotification.js

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

// Ensure admin app is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * 1. Trigger when a shop visit is recorded in 'shop_visits' collection.
 * Creates notification in Firestore and sends background FCM push notification to merchant.
 * Ignores self-visits (visitorId === merchantId).
 */
exports.onShopVisitCreated = onDocumentCreated(
  "shop_visits/{visitId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("No data associated with the shop visit event");
      return;
    }

    const visit = snap.data();
    const { visitorId, visitorName, visitorRole, visitorPhoto, merchantId, shopName } = visit;

    // RULE: Ignore self-visit (merchant visiting their own shop)
    if (!visitorId || !merchantId || visitorId === merchantId) {
      logger.info(`Self-visit or invalid IDs detected (visitor: ${visitorId}, merchant: ${merchantId}). Skipping notification.`);
      return;
    }

    logger.info(`Shop visit detected: ${visitorName} (${visitorRole}) visited shop ${shopName} owned by merchant ${merchantId}`);

    const title = "New Shop Visitor! 🏪";
    const body = `${visitorName || "Someone"} (${visitorRole || "User"}) visited your shop "${shopName || "Store"}"`;

    try {
      // 1. Create Notification document in Firestore
      const notificationRef = db.collection("notifications").doc();
      const notificationData = {
        notificationId: notificationRef.id,
        merchantId: merchantId,
        userId: merchantId,
        title: title,
        body: body,
        visitorId: visitorId,
        visitorName: visitorName || "User",
        visitorRole: visitorRole || "Customer",
        visitorPhoto: visitorPhoto || "",
        shopName: shopName || "",
        type: "shop_visit",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await notificationRef.set(notificationData);
      logger.info(`Created notification document ${notificationRef.id} for merchant ${merchantId}`);

      // 2. Fetch Merchant's FCM Tokens for Background Push Notification
      const merchantUserDoc = await db.collection("users").doc(merchantId).get();
      if (merchantUserDoc.exists) {
        const userData = merchantUserDoc.data();
        const fcmTokens = userData.fcmTokens || (userData.fcmToken ? [userData.fcmToken] : []);

        if (fcmTokens.length > 0) {
          const payload = {
            notification: {
              title: title,
              body: body,
            },
            data: {
              notificationId: notificationRef.id,
              merchantId: merchantId,
              visitorId: visitorId,
              type: "shop_visit",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          };

          // Send FCM message to all merchant's tokens
          const response = await messaging.sendEachForMulticast({
            tokens: fcmTokens,
            notification: payload.notification,
            data: payload.data,
          });

          logger.info(`FCM notification sent. Success count: ${response.successCount}, Failure count: ${response.failureCount}`);
        }
      }
    } catch (error) {
      logger.error("Error processing shop visit notification:", error);
    }
  }
);

/**
 * 2. Scheduled Task: Automatically cleanup notifications older than 30 days (1 month).
 * Runs daily at midnight.
 */
exports.cleanupOldNotifications = onSchedule(
  "every 24 hours",
  async (event) => {
    logger.info("Starting automated 30-day notification cleanup task...");

    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const snapshot = await db
        .collection("notifications")
        .where("createdAt", "<=", thirtyDaysAgo)
        .get();

      if (snapshot.empty) {
        logger.info("No notifications older than 30 days found for cleanup.");
        return;
      }

      logger.info(`Found ${snapshot.docs.length} notifications older than 30 days. Deleting...`);

      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      logger.info(`Successfully deleted ${snapshot.docs.length} old notifications.`);
    } catch (error) {
      logger.error("Error running 30-day notification cleanup task:", error);
    }
  }
);

/**
 * 3. Callable Function: Mark Notification as Read / Seen
 */
exports.markNotificationSeen = onCall(async (request) => {
  const notificationId = request.data.notificationId;
  if (!notificationId) {
    throw new Error("notificationId is required");
  }

  try {
    await db.collection("notifications").doc(notificationId).update({
      isRead: true,
      seenAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true };
  } catch (error) {
    logger.error(`Error marking notification ${notificationId} as seen:`, error);
    throw new Error(error.message);
  }
});
