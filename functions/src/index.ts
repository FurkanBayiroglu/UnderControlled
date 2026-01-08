import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// Helper function to send push notification
async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  try {
    await messaging.send({
      token: fcmToken,
      
      // Notification payload
      notification: {
        title: title,
        body: body,
      },
      
      // ANDROID CONFIG - Required for background notifications!
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
          icon: "launcher_icon",
        },
      },
      
      // iOS APNS config
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: "default",
            badge: 1,
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
      
      // Data payload
      data: data,
    });
    
    console.log("Push notification sent successfully");
    return true;
  } catch (error) {
    console.error("Push notification error:", error);
    return false;
  }
}

// MESSAGE NOTIFICATION
export const sendMessageNotification = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data");
      return;
    }

    const messageData = snapshot.data();
    const conversationId = event.params.conversationId;
    const senderId: string = messageData.senderId;
    const messageText: string = messageData.text || "";

    try {
      // Get conversation
      const conversationDoc = await db
        .collection("conversations")
        .doc(conversationId)
        .get();

      if (!conversationDoc.exists) {
        console.log("Conversation not found");
        return;
      }

      const conversationData = conversationDoc.data();
      const participants: string[] = conversationData?.participants || [];
      const receiverId = participants.find((id) => id !== senderId);

      if (!receiverId) {
        console.log("Receiver not found");
        return;
      }

      // Get receiver info
      const receiverDoc = await db.collection("users").doc(receiverId).get();
      if (!receiverDoc.exists) {
        console.log("Receiver user not found");
        return;
      }

      const receiverData = receiverDoc.data();
      const fcmToken: string | undefined = receiverData?.fcmToken;

      // Get sender name
      const senderDoc = await db.collection("users").doc(senderId).get();
      const senderData = senderDoc.data();
      const senderName: string = senderData?.name || "Someone";

      const truncatedMessage = messageText.length > 100 
        ? messageText.substring(0, 100) + "..." 
        : messageText;

      // Save to notifications collection
      await db.collection("notifications").add({
        type: "message",
        fromUserId: senderId,
        toUserId: receiverId,
        conversationId: conversationId,
        message: truncatedMessage,
        senderName: senderName,
        isRead: false,
        timestamp: FieldValue.serverTimestamp(),
      });

      console.log("Notification record created");

      // Send push if token exists
      if (fcmToken) {
        await sendPushNotification(
          fcmToken,
          senderName,
          truncatedMessage,
          {
            type: "message",
            conversationId: conversationId,
            senderId: senderId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          }
        );
      } else {
        console.log("No FCM token");
      }
    } catch (error) {
      console.error("Notification error:", error);
    }
  }
);

// FOLLOW REQUEST NOTIFICATION
export const sendFollowRequestNotification = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    const beforeRequests: string[] = beforeData.followRequests || [];
    const afterRequests: string[] = afterData.followRequests || [];

    // Check if new request exists
    if (afterRequests.length <= beforeRequests.length) return;

    const newRequesterId = afterRequests.find(
      (id) => !beforeRequests.includes(id)
    );

    if (!newRequesterId) return;

    const userId = event.params.userId;

    try {
      // Get requester name
      const requesterDoc = await db.collection("users").doc(newRequesterId).get();
      const requesterData = requesterDoc.data();
      const requesterName: string = requesterData?.name || "Someone";

      // Save to notifications collection
      await db.collection("notifications").add({
        type: "follow_request",
        fromUserId: newRequesterId,
        toUserId: userId,
        senderName: requesterName,
        isRead: false,
        timestamp: FieldValue.serverTimestamp(),
      });

      console.log("Follow request notification created");

      // Send push if token exists
      const fcmToken: string | undefined = afterData.fcmToken;
      if (fcmToken) {
        await sendPushNotification(
          fcmToken,
          "Yeni Takip Istegi",
          `${requesterName} seni takip etmek istiyor`,
          {
            type: "follow_request",
            requesterId: newRequesterId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          }
        );
      }
    } catch (error) {
      console.error("Notification error:", error);
    }
  }
);

// FOLLOW ACCEPTED NOTIFICATION
export const sendFollowAcceptedNotification = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    const beforeFollowing: string[] = beforeData.following || [];
    const afterFollowing: string[] = afterData.following || [];

    // Check if new follow exists
    if (afterFollowing.length <= beforeFollowing.length) return;

    const newFollowingId = afterFollowing.find(
      (id) => !beforeFollowing.includes(id)
    );

    if (!newFollowingId) return;

    const userId = event.params.userId;

    try {
      // Get followed user info
      const followedDoc = await db.collection("users").doc(newFollowingId).get();
      const followedData = followedDoc.data();
      const currentUserName: string = afterData?.name || "Someone";

      // Save to notifications collection
      await db.collection("notifications").add({
        type: "follow_accepted",
        fromUserId: userId,
        toUserId: newFollowingId,
        senderName: currentUserName,
        isRead: false,
        timestamp: FieldValue.serverTimestamp(),
      });

      console.log("Follow accepted notification created");

      // Send push to followed user
      const followedFcmToken: string | undefined = followedData?.fcmToken;
      if (followedFcmToken) {
        await sendPushNotification(
          followedFcmToken,
          "Takip Istegi Kabul Edildi",
          `${currentUserName} takip istegini kabul etti`,
          {
            type: "follow_accepted",
            userId: userId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          }
        );
      }
    } catch (error) {
      console.error("Notification error:", error);
    }
  }
);