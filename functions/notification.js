// functions/notification.js

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
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
 * Helper to fetch FCM tokens for a user from 'users', 'merchants', or 'technicians' collections
 */
async function getUserFcmTokens(userId) {
  if (!userId) return [];
  try {
    // Check 'users' collection
    const userDoc = await db.collection("users").doc(userId).get();
    if (userDoc.exists) {
      const data = userDoc.data();
      const tokens = data.fcmTokens || (data.fcmToken ? [data.fcmToken] : []);
      if (tokens.length > 0) return tokens;
    }

    // Check 'merchants' collection
    const merchantDoc = await db.collection("merchants").doc(userId).get();
    if (merchantDoc.exists) {
      const data = merchantDoc.data();
      const tokens = data.fcmTokens || (data.fcmToken ? [data.fcmToken] : []);
      if (tokens.length > 0) return tokens;
    }

    // Check 'technicians' collection
    const techDoc = await db.collection("technicians").doc(userId).get();
    if (techDoc.exists) {
      const data = techDoc.data();
      const tokens = data.fcmTokens || (data.fcmToken ? [data.fcmToken] : []);
      if (tokens.length > 0) return tokens;
    }
  } catch (error) {
    logger.error(`Error fetching FCM tokens for user ${userId}:`, error);
  }
  return [];
}

/**
 * 1. TRIGGER: Chat Message Created (/messages/{messageId})
 * Sends real-time FCM Push Notification to the message recipient (Customer, Technician, or Merchant).
 */
exports.onMessageCreated = onDocumentCreated(
  "messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const messageData = snap.data();
    const { senderId, senderName, senderRole, receiverId, receiverName, message, taskId } = messageData;

    if (!receiverId || !senderId || receiverId === senderId) {
      return;
    }

    logger.info(`💬 Message trigger: ${senderName} (${senderRole}) sent message to ${receiverId}`);

    const title = `💬 Message from ${senderName || "User"}`;
    const body = message && message.length > 100 ? `${message.substring(0, 100)}...` : message || "Sent you a message";

    try {
      // 1. Create Notification document in Firestore
      const notificationRef = db.collection("notifications").doc();
      await notificationRef.set({
        notificationId: notificationRef.id,
        userId: receiverId,
        merchantId: receiverId,
        senderId: senderId,
        senderName: senderName || "User",
        senderRole: senderRole || "user",
        title: title,
        body: body,
        taskId: taskId || "",
        type: "chat_message",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Fetch Receiver's FCM Tokens
      const fcmTokens = await getUserFcmTokens(receiverId);

      if (fcmTokens.length > 0) {
        const response = await messaging.sendEachForMulticast({
          tokens: fcmTokens,
          notification: { title, body },
          data: {
            type: "chat_message",
            taskId: taskId || "",
            senderId: senderId,
            senderName: senderName || "",
            senderRole: senderRole || "",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        });
        logger.info(`FCM chat notification sent to ${receiverId}. Success: ${response.successCount}, Failures: ${response.failureCount}`);
      } else {
        logger.info(`No FCM tokens found for receiver ${receiverId}`);
      }
    } catch (error) {
      logger.error("Error in onMessageCreated notification trigger:", error);
    }
  }
);

/**
 * 2. TRIGGER: Task Created or Updated (/tasks/{taskId})
 * Notifies Customer / Technician when a task is created or status changes.
 */
exports.onTaskUpdated = onDocumentUpdated(
  "tasks/{taskId}",
  async (event) => {
    const beforeData = event.data.before ? event.data.before.data() : {};
    const afterData = event.data.after ? event.data.after.data() : {};

    const oldStatus = beforeData.status;
    const newStatus = afterData.status;

    if (oldStatus === newStatus) return;

    const { customerId, technicianId, title, category } = afterData;
    const taskTitle = title || category || "Service Task";

    logger.info(`🛠️ Task status changed: "${taskTitle}" (${oldStatus} -> ${newStatus})`);

    let recipientId = "";
    let notificationTitle = "";
    let notificationBody = "";

    switch (newStatus) {
      case "accepted":
        recipientId = customerId;
        notificationTitle = "🛠️ Task Accepted!";
        notificationBody = `Technician has accepted your request for "${taskTitle}".`;
        break;
      case "inProgress":
        recipientId = customerId;
        notificationTitle = "⏳ Task In Progress";
        notificationBody = `Work has started on your task "${taskTitle}".`;
        break;
      case "completed":
        recipientId = customerId;
        notificationTitle = "🎉 Task Completed!";
        notificationBody = `Your task "${taskTitle}" has been marked as completed.`;
        break;
      case "cancelled":
        recipientId = customerId === beforeData.lastUpdatedBy ? technicianId : customerId;
        notificationTitle = "❌ Task Cancelled";
        notificationBody = `The task "${taskTitle}" was cancelled.`;
        break;
      default:
        return;
    }

    if (!recipientId) return;

    try {
      // 1. Save Notification
      const notificationRef = db.collection("notifications").doc();
      await notificationRef.set({
        notificationId: notificationRef.id,
        userId: recipientId,
        title: notificationTitle,
        body: notificationBody,
        taskId: event.params.taskId,
        type: "task_status",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Send FCM Push Notification
      const fcmTokens = await getUserFcmTokens(recipientId);

      if (fcmTokens.length > 0) {
        await messaging.sendEachForMulticast({
          tokens: fcmTokens,
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            type: "task_status",
            taskId: event.params.taskId,
            status: newStatus,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        });
        logger.info(`Task status notification sent to ${recipientId}`);
      }
    } catch (error) {
      logger.error("Error in onTaskUpdated notification trigger:", error);
    }
  }
);

/**
 * 3. TRIGGER: Shop Visit Recorded (/shop_visits/{visitId})
 * Notifies Merchant when a visitor views their shop.
 */
exports.onShopVisitCreated = onDocumentCreated(
  "shop_visits/{visitId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const visit = snap.data();
    const { visitorId, visitorName, visitorRole, visitorPhoto, merchantId, shopName } = visit;

    if (!visitorId || !merchantId || visitorId === merchantId) {
      return;
    }

    logger.info(`🏪 Shop visit trigger: ${visitorName} (${visitorRole}) visited shop ${shopName} owned by ${merchantId}`);

    const title = "New Shop Visitor! 🏪";
    const body = `${visitorName || "Someone"} (${visitorRole || "User"}) visited your shop "${shopName || "Store"}"`;

    try {
      // 1. Create Notification document in Firestore
      const notificationRef = db.collection("notifications").doc();
      await notificationRef.set({
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
      });

      // 2. Fetch Merchant's FCM Tokens
      const fcmTokens = await getUserFcmTokens(merchantId);

      if (fcmTokens.length > 0) {
        await messaging.sendEachForMulticast({
          tokens: fcmTokens,
          notification: { title, body },
          data: {
            notificationId: notificationRef.id,
            merchantId: merchantId,
            visitorId: visitorId,
            type: "shop_visit",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        });
        logger.info(`Shop visit FCM sent to merchant ${merchantId}`);
      }
    } catch (error) {
      logger.error("Error in onShopVisitCreated trigger:", error);
    }
  }
);

/**
 * 4. SCHEDULED TASK: Automated 30-Day Notification Cleanup
 * Runs daily at midnight.
 */
exports.cleanupOldNotifications = onSchedule(
  "every 24 hours",
  async () => {
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

      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();

      logger.info(`Successfully deleted ${snapshot.docs.length} old notifications.`);
    } catch (error) {
      logger.error("Error running 30-day notification cleanup task:", error);
    }
  }
);

/**
 * 5. CALLABLE FUNCTION: Mark Notification as Read / Seen
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
