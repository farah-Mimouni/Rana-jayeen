const {onValueCreated} = require('firebase-functions/v2/database');
const {logger} = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp({
  databaseURL: 'https://newme-f9c0a-default-rtdb.firebaseio.com',
});

exports.sendNotificationV2 = onValueCreated({
  ref: '/messages/{chatId}/{messageId}',
  region: 'us-central1',
}, async (event) => {
  try {
    const snapshot = event.data;
    const messageData = snapshot.val();
    if (!messageData || messageData.notificationSent) {
      logger.log('Notification already sent or no data, skipping.');
      return null;
    }

    const {senderId, senderName, message, requestId, serviceType} = messageData;

    // Fetch chat data to get recipientId
    const chatRef = admin.database().ref(`chats/${event.params.chatId}`);
    const chatSnapshot = await chatRef.once('value');
    if (!chatSnapshot.exists()) {
      logger.error('Chat not found for chatId:', event.params.chatId);
      return null;
    }

    const chatData = chatSnapshot.val();
    const participants = chatData.participants || {};
    const receiverId = Object.keys(participants).find((id) => id !== senderId);
    if (!receiverId || !senderId || !message) {
      logger.error('Missing required message fields or receiverId:', messageData);
      return null;
    }

    logger.log('Participants:', participants, 'ReceiverId:', receiverId);

    // Fetch receiver's FCM token
    const driverRef = admin.database().ref(`driver_users/${receiverId}`);
    const userRef = admin.database().ref(`auth_user/${receiverId}`);
    let fcmToken;

    // Try driver_users first (for providers)
    const driverSnapshot = await driverRef.once('value');
    if (driverSnapshot.exists()) {
      fcmToken = driverSnapshot.val().fcmToken;
    } else {
      // Fallback to auth_user (for users)
      const userSnapshot = await userRef.once('value');
      fcmToken = userSnapshot.exists() ? userSnapshot.val().fcmToken : null;
    }

    if (!fcmToken) {
      logger.log(`No FCM token for receiverId=${receiverId}`);
      return null;
    }

    // Save to notifications node for in-app fallback
    await admin.database().ref(`notifications/${receiverId}`).push({
      type: 'new_message',
      chatId: event.params.chatId,
      messageId: event.params.messageId,
      requestId: requestId || '',
      providerId: receiverId,
      providerName: senderName || 'Unknown',
      serviceType: serviceType || 'unknown',
      message: message,
      content: message.length > 50 ? `${message.substring(0, 47)}...` : message,
      read: false,
      timestamp: admin.database.ServerValue.TIMESTAMP,
    });

    // Construct FCM payload
    const payload = {
      notification: {
        title: `New Message from ${senderName || 'User'}`,
        body: message.length > 50 ? `${message.substring(0, 47)}...` : message,
      },
      data: {
        type: 'chat_message',
        chatId: event.params.chatId,
        messageId: event.params.messageId,
        senderId: senderId,
        senderName: senderName || 'User',
        requestId: requestId || '',
        serviceType: serviceType || 'unknown',
        chatMessage: message,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
          sound: 'notification_sound',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'notification_sound.wav',
            mutableContent: true,
            badge: 1,
          },
        },
      },
      token: fcmToken,
    };

    // Send FCM notification
    await admin.messaging().send(payload);
    logger.log(`Notification sent to receiverId=${receiverId} for message ${event.params.messageId}`);

    // Update notificationSent to true
    await snapshot.ref.update({notificationSent: true});
    logger.log(`Updated notificationSent for message ${event.params.messageId}`);

    return null;
  } catch (error) {
    logger.error('Error in sendNotificationV2:', error);
    return null;
  }
});
