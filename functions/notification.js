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
 * Custom Notification Payload Options with Custom Sound
 */
function buildFcmPayload({ title, body, data = {} }) {
  return {
    notification: { title, body },
    android: {
      notification: {
        sound: "custech_notification",
        channelId: "custech_channel",
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "custech_notification.aiff",
          contentAvailable: true,
        },
      },
    },
    data: {
      ...data,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  };
}

/**
 * Helper to fetch FCM tokens for a user from 'users', 'merchants', or 'technicians' collections
 */
async function getUserFcmTokens(userId) {
  if (!userId) return [];
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (userDoc.exists) {
      const data = userDoc.data();
      const tokens = data.fcmTokens || (data.fcmToken ? [data.fcmToken] : []);
      if (tokens.length > 0) return tokens;
    }

    const merchantDoc = await db.collection("merchants").doc(userId).get();
    if (merchantDoc.exists) {
      const data = merchantDoc.data();
      const tokens = data.fcmTokens || (data.fcmToken ? [data.fcmToken] : []);
      if (tokens.length > 0) return tokens;
    }

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
      // 1. Create Notification in Firestore
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

      // 2. Send FCM Multicast
      const fcmTokens = await getUserFcmTokens(receiverId);

      if (fcmTokens.length > 0) {
        const payload = buildFcmPayload({
          title,
          body,
          data: {
            type: "chat_message",
            taskId: taskId || "",
            senderId: senderId,
            senderName: senderName || "",
            senderRole: senderRole || "",
          },
        });

        const response = await messaging.sendEachForMulticast({
          tokens: fcmTokens,
          ...payload,
        });
        logger.info(`FCM chat notification sent to ${receiverId}. Success: ${response.successCount}`);
      }
    } catch (error) {
      logger.error("Error in onMessageCreated trigger:", error);
    }
  }
);

/**
 * 2. TRIGGER: Task Created (/tasks/{taskId})
 * Notifies matching technicians when a customer posts a new task.
 */
exports.onTaskCreated = onDocumentCreated(
  "tasks/{taskId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const taskData = snap.data();
    const { category, customerName, title, pincode } = taskData;

    const taskTitle = title || category || "New Service Task";
    logger.info(`🛠️ Task Created: "${taskTitle}" in category "${category}"`);

    try {
      // Find matching technicians
      let query = db.collection("technicians");
      if (category) {
        query = query.where("categories", "array-contains", category);
      }
      const techSnap = await query.get();

      if (techSnap.empty) {
        logger.info(`No matching technicians found for category ${category}`);
        return;
      }

      const techIds = techSnap.docs.map((doc) => doc.id);
      logger.info(`Found ${techIds.length} technicians for new task ${event.params.taskId}`);

      const notifTitle = `🆕 New Task Request: ${category || "Service"}`;
      const notifBody = `${customerName || "A Customer"} requested a task for "${taskTitle}".`;

      for (const techId of techIds) {
        // Save Notification in Firestore
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
          notificationId: notificationRef.id,
          userId: techId,
          title: notifTitle,
          body: notifBody,
          taskId: event.params.taskId,
          type: "new_task",
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send FCM Notification with Custom Sound
        const fcmTokens = await getUserFcmTokens(techId);
        if (fcmTokens.length > 0) {
          const payload = buildFcmPayload({
            title: notifTitle,
            body: notifBody,
            data: {
              type: "new_task",
              taskId: event.params.taskId,
            },
          });
          await messaging.sendEachForMulticast({ tokens: fcmTokens, ...payload });
        }
      }
    } catch (error) {
      logger.error("Error in onTaskCreated trigger:", error);
    }
  }
);

/**
 * 3. TRIGGER: Task Updated (/tasks/{taskId})
 * Notifies Customer / Technician when task status changes.
 */
exports.onTaskUpdated = onDocumentUpdated(
  "tasks/{taskId}",
  async (event) => {
    const beforeData = event.data.before ? event.data.before.data() : {};
    const afterData = event.data.after ? event.data.after.data() : {};

    const oldStatus = beforeData.status;
    const newStatus = afterData.status;

    if (oldStatus === newStatus) return;

    const { customerId, technicianId, title, category, technicianName } = afterData;
    const taskTitle = title || category || "Service Task";

    logger.info(`🛠️ Task status changed: "${taskTitle}" (${oldStatus} -> ${newStatus})`);

    let recipientId = "";
    let notificationTitle = "";
    let notificationBody = "";

    switch (newStatus) {
      case "accepted":
        recipientId = customerId;
        notificationTitle = "🛠️ Task Accepted!";
        notificationBody = `${technicianName || "Technician"} has accepted your request for "${taskTitle}".`;
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
        recipientId = customerId === afterData.cancelledBy ? technicianId : customerId;
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
        const payload = buildFcmPayload({
          title: notificationTitle,
          body: notificationBody,
          data: {
            type: "task_status",
            taskId: event.params.taskId,
            status: newStatus,
          },
        });
        await messaging.sendEachForMulticast({ tokens: fcmTokens, ...payload });
        logger.info(`Task status notification sent to ${recipientId}`);
      }
    } catch (error) {
      logger.error("Error in onTaskUpdated trigger:", error);
    }
  }
);

/**
 * 4. TRIGGER: Shop Visit Recorded (/shop_visits/{visitId})
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
        const payload = buildFcmPayload({
          title,
          body,
          data: {
            notificationId: notificationRef.id,
            merchantId: merchantId,
            visitorId: visitorId,
            type: "shop_visit",
          },
        });
        await messaging.sendEachForMulticast({ tokens: fcmTokens, ...payload });
        logger.info(`Shop visit FCM sent to merchant ${merchantId}`);
      }
    } catch (error) {
      logger.error("Error in onShopVisitCreated trigger:", error);
    }
  }
);

/**
 * 5. SCHEDULED TASK: Automated 30-Day Notification Cleanup
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
 * 6. CALLABLE FUNCTION: Mark Notification as Read / Seen
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
