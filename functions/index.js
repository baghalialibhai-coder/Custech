// functions/index.js

// ============================================================
// IMPORTS
// ============================================================
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

const {onRequest} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ============================================================
// GLOBAL OPTIONS
// ============================================================
setGlobalOptions({
  maxInstances: 10,
});

// ============================================================
// HELPER: GET ADMIN IDS
// ============================================================

/**
 * Get all admin document IDs.
 *
 * @return {Promise<string[]>} Admin user IDs.
 */
async function getAdminIds() {
  try {
    const snapshot = await db.collection("admins").get();

    if (snapshot.empty) {
      logger.warn(
          "No admin users found in admins collection",
      );
      return [];
    }

    return snapshot.docs.map((doc) => doc.id);
  } catch (error) {
    logger.error(
        "Error fetching admin IDs:",
        error,
    );

    return [];
  }
}

// ============================================================
// HELPER: GET USER DATA
// ============================================================

/**
 * Get user data from Firestore.
 *
 * @param {string} userId User ID.
 * @return {Promise<Object|null>} User data.
 */
async function getUserData(userId) {
  if (!userId) {
    return null;
  }

  try {
    const doc = await db
        .collection("users")
        .doc(userId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  } catch (error) {
    logger.error(
        "Error getting user data for " + userId + ":",
        error,
    );

    return null;
  }
}

// ============================================================
// HELPER: GET FCM TOKENS
// ============================================================

/**
 * Get all FCM tokens for a user.
 *
 * @param {string} userId User ID.
 * @return {Promise<string[]>} FCM tokens.
 */
async function getFcmTokens(userId) {
  const user = await getUserData(userId);

  if (!user) {
    return [];
  }

  const tokens = [];

  if (Array.isArray(user.fcmTokens)) {
    user.fcmTokens.forEach((token) => {
      if (token && !tokens.includes(token)) {
        tokens.push(token);
      }
    });
  }

  // Backward compatibility with single token.
  if (
    user.fcmToken &&
    !tokens.includes(user.fcmToken)
  ) {
    tokens.push(user.fcmToken);
  }

  return tokens;
}

// ============================================================
// HELPER: SEND NOTIFICATION
// ============================================================

/**
 * Send an FCM notification to all user devices.
 *
 * @param {Object} params Notification parameters.
 * @return {Promise<Array>} Notification send results.
 */
async function sendNotification(params) {
  const userId = params.userId;
  const title = params.title;
  const body = params.body;
  const type = params.type || "general";
  const event = params.event || "general";
  const data = params.data || {};
  const imageUrl = params.imageUrl || null;
  const sound = params.sound || "custech_notification";
  const channelId =
    params.channelId || "custech_notifications";

  if (!userId) {
    logger.warn(
        "No userId provided for notification",
    );
    return [];
  }

  const tokens = await getFcmTokens(userId);

  if (tokens.length === 0) {
    logger.warn(
        "No FCM tokens found for user: " + userId,
    );
    return [];
  }

  logger.info(
      "Sending notification to " +
      tokens.length +
      " devices for user: " +
      userId,
  );

  const notificationPayload = {
    title: title,
    body: body,
  };

  if (imageUrl) {
    notificationPayload.imageUrl = imageUrl;
  }

  const payload = {
    notification: notificationPayload,

    data: {
      type: String(type),
      event: String(event),
      userId: String(userId),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },

    android: {
      priority: "high",

      notification: {
        channelId: channelId,
        sound: sound,
      },
    },

    apns: {
      payload: {
        aps: {
          sound: sound + ".wav",
          badge: 1,
        },
      },
    },
  };

  // Add image to Android notification.
  if (imageUrl) {
    payload.android.notification.imageUrl = imageUrl;
  }

  // Add custom data.
  Object.keys(data).forEach((key) => {
    payload.data[key] = String(data[key]);
  });

  const results = [];
  const invalidTokens = [];

  // ==========================================================
  // SEND TO EACH DEVICE
  // ==========================================================

  for (const token of tokens) {
    try {
      const sendPayload = {
        ...payload,
        token: token,
      };

      const result = await messaging.send(sendPayload);

      results.push({
        token: token,
        result: result,
        success: true,
      });
    } catch (error) {
      logger.error(
          "Failed to send to token " + token + ":",
          error,
      );

      if (
        error.code ===
          "messaging/registration-token-not-registered" ||
        error.code ===
          "messaging/invalid-registration-token"
      ) {
        invalidTokens.push(token);
      }

      results.push({
        token: token,
        error: error.message,
        success: false,
      });
    }
  }

  // ==========================================================
  // REMOVE INVALID TOKENS
  // ==========================================================

  if (invalidTokens.length > 0) {
    try {
      await db
          .collection("users")
          .doc(userId)
          .update({
            fcmTokens:
              admin.firestore.FieldValue.arrayRemove(
                  ...invalidTokens,
              ),
          });

      logger.info(
          "Removed " +
          invalidTokens.length +
          " invalid tokens for user: " +
          userId,
      );
    } catch (error) {
      logger.error(
          "Error removing invalid tokens:",
          error,
      );
    }
  }

  // ==========================================================
  // COUNT RESULTS
  // ==========================================================

  let successCount = 0;

  results.forEach((result) => {
    if (result.success) {
      successCount++;
    }
  });

  const failedCount =
    results.length - successCount;

  // ==========================================================
  // SAVE NOTIFICATION HISTORY
  // ==========================================================

  try {
    await db.collection("notifications").add({
      userId: userId,
      type: type,
      event: event,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      isRead: false,
      createdAt:
        admin.firestore.FieldValue.serverTimestamp(),
      sentAt:
        admin.firestore.FieldValue.serverTimestamp(),
      tokensSent: successCount,
      tokensFailed: failedCount,
    });
  } catch (error) {
    logger.error(
        "Error saving notification history:",
        error,
    );
  }

  logger.info(
      "Notification sent to " +
      successCount +
      " devices",
  );

  return results;
}

// ============================================================
// 1. ACCOUNT CREATED
// ============================================================

exports.onUserCreated = onDocumentCreated(
    "users/{userId}",
    async (event) => {
      const userId = event.params.userId;
      const data = event.data.data();

      logger.info(
          "New user created: " +
          userId +
          " (" +
          (data.role || "unknown") +
          ")",
      );

      try {
        let welcomeMessage = "Welcome";

        if (data.language === "ur") {
          welcomeMessage = "خوش آمدید";
        } else if (data.language === "ar") {
          welcomeMessage = "مرحباً";
        }

        let welcomeBody;

        if (data.role === "technician") {
          welcomeBody =
            "Your technician account has been created. " +
            "Complete your profile to start getting jobs.";
        } else {
          welcomeBody =
            "Your account has been created. " +
            "Post your first task now!";
        }

        await sendNotification({
          userId: userId,
          title: welcomeMessage + " to Custech! 🎉",
          body: welcomeBody,
          type: "account",
          event: "created",
          data: {
            userId: userId,
            role: data.role || "user",
          },
        });

        // Notify admins.
        const adminIds = await getAdminIds();

        for (const adminId of adminIds) {
          await sendNotification({
            userId: adminId,
            title: "👤 New User Registered",
            body:
              (data.displayName || "New user") +
              " (" +
              (data.role || "user") +
              ") has created an account.",
            type: "admin",
            event: "new_user",
            data: {
              userId: userId,
              role: data.role || "user",
            },
          });
        }
      } catch (error) {
        logger.error(
            "Error in onUserCreated:",
            error,
        );
      }

      return null;
    },
);

// ============================================================
// 2. TASK CREATED
// ============================================================

exports.onTaskCreated = onDocumentCreated(
    "tasks/{taskId}",
    async (event) => {
      const taskId = event.params.taskId;
      const data = event.data.data();

      logger.info(
          "New task created: " +
          taskId +
          " (" +
          (data.category || "unknown") +
          ")",
      );

      try {
        let status = "open";

        if (data.status) {
          status = String(data.status).toLowerCase();
        }

        if (status !== "open") {
          logger.info(
              "Task " +
              taskId +
              " status is not open. " +
              "Skipping technician notifications.",
          );

          return null;
        }

        // Validate customer location.
        if (
          typeof data.latitude !== "number" ||
          typeof data.longitude !== "number"
        ) {
          logger.warn(
              "Task " +
              taskId +
              " has invalid location",
          );

          return null;
        }

        const customerLat = data.latitude;
        const customerLng = data.longitude;

        // Find matching technicians.
        const techniciansSnapshot = await db
            .collection("technicians")
            .where(
                "categories",
                "array-contains",
                data.category,
            )
            .where("isAvailable", "==", true)
            .where("isOnline", "==", true)
            .get();

        if (techniciansSnapshot.empty) {
          logger.info(
              "No matching technicians found for task " +
              taskId,
          );

          return null;
        }

        logger.info(
            "Found " +
            techniciansSnapshot.docs.length +
            " potential technicians",
        );

        let notifiedCount = 0;

        for (const doc of techniciansSnapshot.docs) {
          const techData = doc.data();
          const techDocId = doc.id;

          const technicianUserId =
            techData.userId || techDocId;

          // Get technician location.
          const techLat =
            techData.currentLatitude !== undefined ?
              techData.currentLatitude :
              techData.baseLatitude;

          const techLng =
            techData.currentLongitude !== undefined ?
              techData.currentLongitude :
              techData.baseLongitude;

          if (
            typeof techLat !== "number" ||
            typeof techLng !== "number"
          ) {
            logger.warn(
                "Technician " +
                techDocId +
                " has invalid location. Skipping.",
            );

            continue;
          }

          const radius =
            typeof techData.serviceRadius === "number" ?
              techData.serviceRadius :
              15;

          const distance = haversineDistance(
              customerLat,
              customerLng,
              techLat,
              techLng,
          );

          if (distance > radius) {
            logger.info(
                "Technician " +
                techDocId +
                " is " +
                distance.toFixed(1) +
                "km away. Radius: " +
                radius +
                "km",
            );

            continue;
          }

          logger.info(
              "Notifying technician " +
              technicianUserId +
              " (" +
              distance.toFixed(1) +
              "km)",
          );

          let taskImage = null;

          if (
            Array.isArray(data.images) &&
            data.images.length > 0
          ) {
            taskImage = data.images[0];
          }

          await sendNotification({
            userId: technicianUserId,
            title: "🔔 New Job Available!",
            body:
              data.category +
              " job is available " +
              distance.toFixed(1) +
              "km away.",
            type: "task",
            event: "open",
            imageUrl: taskImage,
            data: {
              taskId: taskId,
              category: data.category || "",
              distance: distance.toFixed(1),
              status: "open",
            },
          });

          notifiedCount++;
        }

        logger.info(
            "Notified " +
            notifiedCount +
            " technicians for task " +
            taskId,
        );
      } catch (error) {
        logger.error(
            "Error in onTaskCreated for " +
            taskId +
            ":",
            error,
        );
      }

      return null;
    },
);

// ============================================================
// 3. TASK STATUS UPDATED
// ============================================================

exports.onTaskUpdated = onDocumentUpdated(
    "tasks/{taskId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      // Ignore updates where status did not change.
      if (before.status === after.status) {
        return null;
      }

      const taskId = event.params.taskId;

      let oldStatus = "unknown";
      let newStatus = "unknown";

      if (before.status) {
        oldStatus = String(before.status).toLowerCase();
      }

      if (after.status) {
        newStatus = String(after.status).toLowerCase();
      }

      logger.info(
          "Task " +
          taskId +
          ": " +
          oldStatus +
          " → " +
          newStatus,
      );

      try {
        let taskImage = null;

        if (
          Array.isArray(after.images) &&
          after.images.length > 0
        ) {
          taskImage = after.images[0];
        }

        // ======================================================
        // ACCEPTED
        // ======================================================

        if (newStatus === "accepted") {
          const technicianName =
            after.technicianName || "Technician";

          await sendNotification({
            userId: after.customerId,
            title: "✅ Task Accepted!",
            body:
              technicianName +
              " has accepted your task.",
            type: "task",
            event: "accepted",
            imageUrl: taskImage,
            data: {
              taskId: taskId,
              status: "accepted",
              technicianId:
                after.technicianId || "",
            },
          });

          if (after.technicianId) {
            await sendNotification({
              userId: after.technicianId,
              title: "✅ You Accepted the Task",
              body:
                "You have accepted the " +
                (after.category || "") +
                " task.",
              type: "task",
              event: "accepted_confirm",
              data: {
                taskId: taskId,
                status: "accepted",
              },
            });
          }

          return null;
        }

        // ======================================================
        // IN PROGRESS
        // ======================================================

        if (newStatus === "inprogress") {
          await sendNotification({
            userId: after.customerId,
            title: "🚗 Technician is on the way!",
            body:
              "Your technician has started the job. " +
              "They will arrive soon.",
            type: "task",
            event: "in_progress",
            imageUrl: taskImage,
            data: {
              taskId: taskId,
              status: "inProgress",
              technicianId:
                after.technicianId || "",
            },
          });

          return null;
        }

        // ======================================================
        // TECHNICIAN ARRIVED
        // ======================================================

        if (newStatus === "technicianarrived") {
          await sendNotification({
            userId: after.customerId,
            title: "📍 Technician has arrived!",
            body:
              "Your technician is at your location.",
            type: "task",
            event: "arrived",
            imageUrl: taskImage,
            data: {
              taskId: taskId,
              status: "technicianArrived",
            },
          });

          return null;
        }

        // ======================================================
        // COMPLETED
        // ======================================================

        if (newStatus === "completed") {
          await sendNotification({
            userId: after.customerId,
            title: "✅ Job Completed!",
            body:
              "Your " +
              (after.category || "") +
              " service has been completed.",
            type: "task",
            event: "completed",
            imageUrl: taskImage,
            data: {
              taskId: taskId,
              status: "completed",
            },
          });

          if (after.technicianId) {
            await sendNotification({
              userId: after.technicianId,
              title: "✅ Job Completed Successfully",
              body:
                "You have completed the " +
                (after.category || "") +
                " job.",
              type: "task",
              event: "completed_tech",
              data: {
                taskId: taskId,
                status: "completed",
              },
            });
          }

          return null;
        }

        // ======================================================
        // CANCELLED
        // ======================================================

        if (newStatus === "cancelled") {
          const reason =
            after.cancellationReason ||
            "No reason provided";

          await sendNotification({
            userId: after.customerId,
            title: "❌ Task Cancelled",
            body:
              "Your task has been cancelled. " +
              "Reason: " +
              reason,
            type: "task",
            event: "cancelled",
            data: {
              taskId: taskId,
              status: "cancelled",
              reason: reason,
            },
          });

          if (after.technicianId) {
            await sendNotification({
              userId: after.technicianId,
              title: "❌ Task Cancelled",
              body:
                "The task has been cancelled. " +
                "Reason: " +
                reason,
              type: "task",
              event: "cancelled",
              data: {
                taskId: taskId,
                status: "cancelled",
                reason: reason,
              },
            });
          }

          return null;
        }

        // ======================================================
        // PAYMENT COMPLETED
        // ======================================================

        if (newStatus === "paymentcompleted") {
          const amount = after.budget || 0;

          await sendNotification({
            userId: after.customerId,
            title: "💳 Payment Successful",
            body:
              "Your payment of " +
              amount +
              " has been completed.",
            type: "payment",
            event: "completed",
            data: {
              taskId: taskId,
              amount: amount,
            },
          });

          if (after.technicianId) {
            await sendNotification({
              userId: after.technicianId,
              title: "💳 Payment Received",
              body:
                "You have received payment for " +
                (after.category || "") +
                " job.",
              type: "payment",
              event: "received",
              data: {
                taskId: taskId,
                amount: amount,
              },
            });
          }

          return null;
        }

        // ======================================================
        // DISPUTED
        // ======================================================

        if (newStatus === "disputed") {
          const adminIds = await getAdminIds();

          for (const adminId of adminIds) {
            await sendNotification({
              userId: adminId,
              title: "⚠️ Dispute Raised",
              body:
                "Task " +
                taskId +
                " has been disputed by " +
                (after.customerName || "customer") +
                ".",
              type: "admin",
              event: "dispute",
              data: {
                taskId: taskId,
              },
            });
          }

          return null;
        }

        logger.info(
            "Unhandled status change: " +
            newStatus,
        );
      } catch (error) {
        logger.error(
            "Error in onTaskUpdated for " +
            taskId +
            ":",
            error,
        );
      }

      return null;
    },
);

// ============================================================
// 4. NEW CHAT MESSAGE
// ============================================================

exports.onMessageCreated = onDocumentCreated(
    "messages/{messageId}",
    async (event) => {
      const data = event.data.data();
      const messageId = event.params.messageId;

      logger.info(
          "New message: " + messageId,
      );

      try {
        const receiverId = data.receiverId;
        const senderId = data.senderId;
        const senderName =
          data.senderName || "User";
        const message =
          data.message || "";
        const imageUrl =
          data.imageUrl || null;

        if (
          !receiverId ||
          receiverId === senderId
        ) {
          return null;
        }

        const sender = await getUserData(senderId);

        const senderRole =
          sender && sender.role ?
            sender.role :
            "user";

        const receiver =
          await getUserData(receiverId);

        let title = "💬 New Message";

        let body =
          senderName +
          ": " +
          message.substring(0, 100);

        if (message.length > 100) {
          body += "...";
        }

        if (imageUrl) {
          body =
            "📷 " +
            senderName +
            " sent a photo";

          if (message) {
            body +=
              ": " +
              message.substring(0, 50) +
              "...";
          }
        }

        if (
          senderRole === "customer" &&
          receiver &&
          receiver.role === "technician"
        ) {
          title = "🔧 Customer Message";
        }

        if (
          senderRole === "technician" &&
          receiver &&
          receiver.role === "customer"
        ) {
          title = "👤 Technician Message";
        }

        await sendNotification({
          userId: receiverId,
          title: title,
          body: body,
          type: "chat",
          event: "new_message",
          imageUrl: imageUrl,
          data: {
            messageId: messageId,
            senderId: senderId || "",
            senderName: senderName,
            taskId: data.taskId || "",
            chatId: data.chatId || "",
          },
        });
      } catch (error) {
        logger.error(
            "Error in onMessageCreated:",
            error,
        );
      }

      return null;
    },
);

// ============================================================
// 5. HAVERSINE DISTANCE
// ============================================================

/**
 * Calculate distance between two coordinates.
 *
 * @param {number} lat1 First latitude.
 * @param {number} lon1 First longitude.
 * @param {number} lat2 Second latitude.
 * @param {number} lon2 Second longitude.
 * @return {number} Distance in kilometers.
 */
function haversineDistance(
    lat1,
    lon1,
    lat2,
    lon2,
) {
  const earthRadius = 6371;

  const dLat =
    (lat2 - lat1) *
    Math.PI /
    180;

  const dLon =
    (lon2 - lon1) *
    Math.PI /
    180;

  const lat1Rad =
    lat1 * Math.PI / 180;

  const lat2Rad =
    lat2 * Math.PI / 180;

  const a =
    Math.sin(dLat / 2) *
      Math.sin(dLat / 2) +
    Math.cos(lat1Rad) *
      Math.cos(lat2Rad) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c =
    2 *
    Math.atan2(
        Math.sqrt(a),
        Math.sqrt(1 - a),
    );

  return earthRadius * c;
}

// ============================================================
// 6. HEALTH CHECK
// ============================================================

exports.healthCheck = onRequest(
    {maxInstances: 1},
    (req, res) => {
      res.status(200).json({
        status: "healthy",
        timestamp:
          new Date().toISOString(),
        version: "1.0.0",
      });
    },
);

// ============================================================
// 7. TEST NOTIFICATION
// ============================================================

exports.testNotification = onRequest(
    {maxInstances: 1},
    async (req, res) => {
      const userId = req.query.userId;

      if (!userId) {
        res.status(400).json({
          error: "userId is required",
        });

        return;
      }

      try {
        await sendNotification({
          userId: userId,
          title: "🔔 Test Notification",
          body:
            "This is a test notification " +
            "from Custech.",
          type: "test",
          event: "test",
          data: {
            test: true,
          },
        });

        res.status(200).json({
          success: true,
          message:
            "Test notification sent",
        });
      } catch (error) {
        res.status(500).json({
          error: error.message,
        });
      }
    },
);

// ============================================================
// 8. MERCHANT SHOP VISIT & NOTIFICATION FUNCTIONS
// ============================================================
const merchantNotification = require("./merchantNotification");
exports.onShopVisitCreated = merchantNotification.onShopVisitCreated;
exports.cleanupOldNotifications = merchantNotification.cleanupOldNotifications;
exports.markNotificationSeen = merchantNotification.markNotificationSeen;

