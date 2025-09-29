import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rana_jayeen/constants.dart' as AppColors;
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/l10n/app_localizations_en.dart';
import 'package:rana_jayeen/notif/chat_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rana_jayeen/globel/var_glob.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Function(String)? onChatOpened;
  bool _isInitialized = false;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) {
      debugPrint("NotificationService already initialized");
      return;
    }
    debugPrint("Initializing NotificationService...");

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentSound: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    try {
      // Initialize notification channel
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'Chat Notifications',
        description:
            'Notifications for new chat messages and accepted requests',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
      );
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Initialize local notifications
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) async {
          if (response.payload == null || !context.mounted) {
            debugPrint("Invalid notification payload or context not mounted");
            return;
          }
          await _handleNotificationTap(context, response.payload!);
        },
      );

      // Store FCM token
      await _storeFcmToken();

      // Setup token refresh
      _setupTokenRefresh();

      // Request permissions
      await _requestPermissions(context);

      // Setup Firebase listeners
      _setupFirebaseListeners(context);

      debugPrint("NotificationService initialized successfully");
      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint("Error initializing NotificationService: $e\n$stackTrace");
      _isInitialized = false;
    }
  }

  Future<void> _storeFcmToken() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          final userRef = _database.ref().child('auth_user').child(userId);
          final snapshot = await userRef.get();
          String role = 'user';
          if (snapshot.exists && snapshot.value is Map) {
            role = (snapshot.value as Map)['role'] ?? 'user';
          }
          await _database
              .ref()
              .child(role == 'provider' ? 'driver_users' : 'auth_user')
              .child(userId)
              .update({
            'fcmToken': token,
            'lastUpdated': ServerValue.timestamp,
          });
          debugPrint("Stored FCM token for user $userId (role: $role)");
        } else {
          debugPrint("FCM token is null for user $userId");
        }
      } else {
        debugPrint("No authenticated user found for storing FCM token");
      }
    } catch (e, stackTrace) {
      debugPrint("Error storing FCM token: $e\n$stackTrace");
    }
  }

  void _setupTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((token) async {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final userRef = _database.ref().child('auth_user').child(userId);
          final snapshot = await userRef.get();
          String role = 'user';
          if (snapshot.exists && snapshot.value is Map) {
            role = (snapshot.value as Map)['role'] ?? 'user';
          }
          await _database
              .ref()
              .child(role == 'provider' ? 'driver_users' : 'auth_user')
              .child(userId)
              .update({
            'fcmToken': token,
            'lastUpdated': ServerValue.timestamp,
          });
          debugPrint("Refreshed FCM token for user $userId (role: $role)");
        }
      } catch (e, stackTrace) {
        debugPrint("Error refreshing FCM token: $e\n$stackTrace");
      }
    });
  }

  Future<void> _requestPermissions(BuildContext context) async {
    try {
      final iosSettings = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      final androidSettings = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (!(iosSettings ?? true) || !(androidSettings ?? true)) {
        debugPrint("Notification permissions denied");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.enable_notifications ??
                    'Please enable notifications',
                style: TextStyle(
                  fontFamily: AppLocalizations.of(context)?.localeName == 'kab'
                      ? 'NotoSansTifinagh'
                      : AppLocalizations.of(context)?.localeName == 'ar'
                          ? 'NotoSansArabic'
                          : 'Inter',
                  color: AppColors.kTextPrimary,
                ),
              ),
              action: SnackBarAction(
                label: AppLocalizations.of(context)?.settings ?? 'Settings',
                onPressed: () => openAppSettings(),
                textColor: AppColors.kPrimary,
              ),
              backgroundColor: AppColors.kBackground,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
      } else {
        debugPrint("Notification permissions granted");
      }
    } catch (e, stackTrace) {
      debugPrint("Error requesting permissions: $e\n$stackTrace");
    }
  }

  Future<void> _setupFirebaseListeners(BuildContext context) async {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();

    // Handle foreground messages
    _onMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      if (data.containsKey('type') && context.mounted) {
        debugPrint("Received FCM message: $data");
        await _showNotification(context, data);
      }
    });

    // Handle messages opened from background
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) async {
      final data = message.data;
      if (data.containsKey('type') && context.mounted) {
        debugPrint("FCM message opened: $data");
        await _handleNotificationTap(context, jsonEncode(data));
      }
    });

    // Handle initial message (app opened from terminated state)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && context.mounted) {
      debugPrint("Initial FCM message: ${initialMessage.data}");
      await _handleNotificationTap(context, jsonEncode(initialMessage.data));
    }

    // Listen for request updates and chat messages
    _listenToRequestUpdates(context);
    _listenToChatMessages(context);
  }

  void _listenToRequestUpdates(BuildContext context) {
    final userId = userModelCurrentInfo?.id;
    if (userId == null) {
      debugPrint("User ID is null, skipping request update listener");
      return;
    }
    final ref = _database
        .ref()
        .child("allRideRequests")
        .orderByChild('userId')
        .equalTo(userId);
    ref.onChildChanged.listen((event) async {
      if (!context.mounted) return;
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (data['status'] == 'accepted') {
          final providerId = data['providerId'] ?? data['driverId'];
          final chatId = data['chatId'] as String? ??
              ChatUtils.getChatId(userId, providerId);
          if (providerId == null) {
            debugPrint("Provider ID is null, skipping request notification");
            return;
          }
          final notificationData = {
            'type': 'request_accepted',
            'chatId': chatId,
            'requestId': event.snapshot.key ?? '',
            'providerId': providerId,
            'providerName': data['providerName'] ??
                data['storeName'] ??
                data['driver_name'] ??
                (context.mounted
                    ? AppLocalizations.of(context)?.unknown ?? 'Unknown'
                    : 'Unknown'),
            'serviceType': data['serviceType'] ?? 'unknown',
            'userId': userId,
            'userName': userModelCurrentInfo?.first ??
                (context.mounted
                    ? AppLocalizations.of(context)?.user1 ?? 'User'
                    : 'User'),
          };
          debugPrint("Request update notification: $notificationData");
          await _showNotification(context, notificationData);
          await _cacheNotification(notificationData);
        }
      } catch (e, stackTrace) {
        debugPrint("Error listening to request updates: $e\n$stackTrace");
      }
    });
  }

  void _listenToChatMessages(BuildContext context) {
    final userId = userModelCurrentInfo?.id;
    if (userId == null) {
      debugPrint("User ID is null, skipping chat message listener");
      return;
    }
    final ref = _database
        .ref()
        .child("chats")
        .orderByChild('participants/$userId')
        .equalTo(true);
    ref.onChildAdded.listen((event) async {
      if (context.mounted) {
        await _handleNewChatMessage(context, event);
      }
    }, onError: (e, stackTrace) {
      debugPrint("Error listening for new chats: $e\n$stackTrace");
    });

    ref.onChildChanged.listen((event) async {
      if (context.mounted) {
        await _handleNewChatMessage(context, event);
      }
    }, onError: (e, stackTrace) {
      debugPrint("Error listening for chat updates: $e\n$stackTrace");
    });
  }

  Future<void> _handleNewChatMessage(
      BuildContext context, DatabaseEvent event) async {
    final userId = userModelCurrentInfo?.id;
    if (!context.mounted || userId == null) return;
    try {
      final chatId = event.snapshot.key;
      if (chatId == null) {
        debugPrint("Chat ID is null, skipping message handling");
        return;
      }
      final chatData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final providerId = chatData['participants'] != null
          ? Map<String, dynamic>.from(chatData['participants'])
              .keys
              .firstWhere((k) => k != userId, orElse: () => "null")
          : null;
      if (providerId == null || providerId == "null") {
        debugPrint(
            "Provider ID is null or invalid for chatId=$chatId, skipping");
        return;
      }
      if (!(chatData['unread_$userId'] ?? false)) {
        debugPrint(
            "No unread messages for userId=$userId in chatId=$chatId, skipping");
        return;
      }

      final messagesRef = _database.ref().child("messages").child(chatId);
      final messagesSnapshot =
          await messagesRef.orderByChild('timestamp').limitToLast(1).get();
      if (messagesSnapshot.exists && messagesSnapshot.value is Map) {
        final messages =
            Map<String, dynamic>.from(messagesSnapshot.value as Map);
        final latestMessages = messages.entries
            .map((e) => MapEntry(e.key, Map<String, dynamic>.from(e.value)))
            .toList()
          ..sort((a, b) => (b.value['timestamp'] as int? ?? 0)
              .compareTo(a.value['timestamp'] as int? ?? 0));
        if (latestMessages.isNotEmpty) {
          final message = latestMessages.first.value;
          final messageId = latestMessages.first.key;
          if (message['senderId'] != userId &&
              message['read'] == false &&
              !(message['notificationSent'] ?? false)) {
            final requestId = chatData['requestId'] as String? ?? '';
            String serviceType = chatData['serviceType'] ?? 'unknown';
            String providerName = context.mounted
                ? AppLocalizations.of(context)?.unknown ?? 'Unknown'
                : 'Unknown';

            if (requestId.isNotEmpty) {
              final requestRef =
                  _database.ref().child("allRideRequests").child(requestId);
              final requestSnapshot = await requestRef.get();
              if (requestSnapshot.exists && requestSnapshot.value is Map) {
                final requestData =
                    Map<String, dynamic>.from(requestSnapshot.value as Map);
                serviceType = requestData['serviceType'] ?? serviceType;
                providerName = requestData['providerName'] ??
                    requestData['storeName'] ??
                    requestData['driver_name'] ??
                    providerName;
              }
            }

            final notificationData = {
              'type': 'new_message',
              'chatId': chatId,
              'messageId': messageId,
              'requestId': requestId,
              'providerId': providerId,
              'providerName': providerName,
              'serviceType': serviceType,
              'message': message['message']?.toString() ?? '',
              'userId': userId,
              'userName': userModelCurrentInfo?.first ??
                  (context.mounted
                      ? AppLocalizations.of(context)?.user1 ?? 'User'
                      : 'User'),
            };
            if (ModalRoute.of(context)?.settings.name != '/chat') {
              debugPrint("New chat message notification: $notificationData");
              await _showNotification(context, notificationData);
              await _cacheNotification(notificationData);
              // Mark notification as sent
              await messagesRef
                  .child(messageId)
                  .update({'notificationSent': true});
            } else {
              debugPrint(
                  "Skipping notification: User is on chat screen for chatId=$chatId");
              await _markNotificationAsRead(chatId);
            }
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error handling new chat message: $e\n$stackTrace");
    }
  }

  Future<void> _handleNotificationTap(
      BuildContext context, String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final providerId = data['providerId'] as String?;
      final serviceType = data['serviceType'] as String?;
      final providerName = data['providerName'] ??
          (context.mounted
              ? AppLocalizations.of(context)?.unknown ?? 'Unknown'
              : 'Unknown');
      final userId = userModelCurrentInfo?.id ?? '';
      final chatId = data['chatId'] as String? ??
          ChatUtils.getChatId(userId, providerId ?? '');
      if (providerId == null ||
          serviceType == null ||
          userId.isEmpty ||
          chatId.isEmpty) {
        debugPrint(
            "Missing required notification data: providerId=$providerId, serviceType=$serviceType, userId=$userId, chatId=$chatId");
        return;
      }
      await _markNotificationAsRead(chatId);
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'providerId': providerId,
            'providerName': providerName,
            'userId': userId,
            'userName': userModelCurrentInfo?.first ??
                (context.mounted
                    ? AppLocalizations.of(context)?.user1 ?? 'User'
                    : 'User'),
            'serviceType': serviceType,
            'requestId': data['requestId'] ?? '',
          },
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Error handling notification tap: $e\n$stackTrace");
    }
  }

  Future<void> _showNotification(
      BuildContext context, Map<String, dynamic> data) async {
    try {
      final title = data['type'] == 'request_accepted'
          ? AppLocalizations.of(context)?.request_accepted_title ??
              'Request Accepted'
          : AppLocalizations.of(context)?.new_message_title ?? 'New Message';
      final body = data['type'] == 'request_accepted'
          ? '${data['providerName'] ?? (AppLocalizations.of(context)?.unknown ?? 'Unknown')} ${AppLocalizations.of(context)?.request_accepted ?? 'accepted your request'}'
          : '${data['providerName'] ?? (AppLocalizations.of(context)?.unknown ?? 'Unknown')}: ${data['message'].length > 50 ? '${data['message'].substring(0, 47)}...' : data['message']}';
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Chat Notifications',
        channelDescription:
            'Notifications for new chat messages and accepted requests',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        sound: 'notification_sound.wav',
        badgeNumber: 1,
        presentSound: true,
      );
      const platformDetails =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.show(
        (data['messageId'] ?? data['requestId'] ?? data['type']).hashCode,
        title,
        body,
        platformDetails,
        payload: jsonEncode(data),
      );
      debugPrint("Displayed notification: $title - $body");
    } catch (e, stackTrace) {
      debugPrint("Error showing notification: $e\n$stackTrace");
    }
  }

  Future<void> showBackgroundNotification(Map<String, dynamic> data) async {
    try {
      final l10n = AppLocalizationsEn();
      final title = data['type'] == 'request_accepted'
          ? l10n.request_accepted_title ?? 'Request Accepted'
          : l10n.new_message_title ?? 'New Message';
      final body = data['type'] == 'request_accepted'
          ? '${data['providerName'] ?? l10n.unknown ?? 'Unknown'} ${l10n.request_accepted ?? 'accepted your request'}'
          : '${data['providerName'] ?? l10n.unknown ?? 'Unknown'}: ${data['message'].length > 50 ? '${data['message'].substring(0, 47)}...' : data['message']}';

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Chat Notifications',
        channelDescription:
            'Notifications for new chat messages and accepted requests',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        sound: 'notification_sound.wav',
        badgeNumber: 1,
        presentSound: true,
      );
      const platformDetails =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.show(
        (data['messageId'] ?? data['requestId'] ?? data['type']).hashCode,
        title,
        body,
        platformDetails,
        payload: jsonEncode(data),
      );
      debugPrint("Displayed background notification: $title - $body");

      final chatId = data['chatId'] as String? ?? '';
      if (chatId.isNotEmpty) {
        await _cacheNotification(data);
      }
    } catch (e, stackTrace) {
      debugPrint("Error showing background notification: $e\n$stackTrace");
    }
  }

  Future<void> _cacheNotification(Map<String, dynamic> data) async {
    try {
      final chatId = data['chatId'] as String? ?? '';
      if (chatId.isEmpty) return;
      final notificationId = _database
          .ref()
          .child('notifications')
          .child(data['userId'])
          .push()
          .key;
      await _database
          .ref()
          .child('notifications')
          .child(data['userId'])
          .child(notificationId!)
          .set({
        'type': data['type'],
        'chatId': chatId,
        'messageId': data['messageId'] ?? '',
        'requestId': data['requestId'] ?? '',
        'content': data['message'] ?? '',
        'read': false,
        'timestamp': ServerValue.timestamp,
      });
      debugPrint("Cached notification for chatId=$chatId");
    } catch (e, stackTrace) {
      debugPrint("Error caching notification: $e\n$stackTrace");
    }
  }

  Future<void> _markNotificationAsRead(String chatId) async {
    try {
      final userId = userModelCurrentInfo?.id;
      if (userId == null) {
        debugPrint("User ID is null, cannot mark notification as read");
        return;
      }
      final chatRef = _database.ref().child('chats').child(chatId);
      await chatRef.update({'unread_$userId': false});

      final messagesRef = _database.ref().child('messages').child(chatId);
      final messagesSnapshot = await messagesRef.get();
      if (messagesSnapshot.exists && messagesSnapshot.value is Map) {
        final messages =
            Map<String, dynamic>.from(messagesSnapshot.value as Map);
        for (var entry in messages.entries) {
          final messageData = Map<String, dynamic>.from(entry.value);
          if (messageData['senderId'] != userId &&
              messageData['read'] == false) {
            await messagesRef.child(entry.key).update({'read': true});
          }
        }
      }

      final notificationsRef =
          _database.ref().child('notifications').child(userId);
      final notificationsSnapshot =
          await notificationsRef.orderByChild('chatId').equalTo(chatId).get();
      if (notificationsSnapshot.exists && notificationsSnapshot.value is Map) {
        final notifications =
            Map<String, dynamic>.from(notificationsSnapshot.value as Map);
        for (var entry in notifications.entries) {
          await notificationsRef.child(entry.key).update({'read': true});
        }
      }

      debugPrint("Marked notifications as read for chatId=$chatId");
      onChatOpened?.call(chatId);
    } catch (e, stackTrace) {
      debugPrint("Error marking notification as read: $e\n$stackTrace");
    }
  }

  Future<void> retryPendingNotifications(String recipientId) async {
    try {
      final notificationsRef =
          _database.ref().child('notifications').child(recipientId);
      final snapshot =
          await notificationsRef.orderByChild('read').equalTo(false).get();
      if (snapshot.exists && snapshot.value is Map) {
        final notifications = Map<String, dynamic>.from(snapshot.value as Map);
        final context = navigatorKey.currentContext;
        if (context == null || !context.mounted) {
          debugPrint("Context not available for retry notifications");
          return;
        }
        for (var entry in notifications.entries) {
          final data = Map<String, dynamic>.from(entry.value);
          if (!(data['read'] ?? false)) {
            await _showNotification(context, data);
          }
        }
      }
      debugPrint("Retried pending notifications for recipientId=$recipientId");
    } catch (e, stackTrace) {
      debugPrint("Error retrying pending notifications: $e\n$stackTrace");
    }
  }

  // Client-side method to trigger message sending (database write only)
  Future<void> sendNewMessage(
      String providerId, String message, String requestId) async {
    try {
      final userId = userModelCurrentInfo?.id;
      if (userId == null) {
        debugPrint("User ID is null, cannot send message");
        return;
      }
      final chatId = ChatUtils.getChatId(userId, providerId);
      final messageRef = _database.ref().child('messages').child(chatId).push();
      final messageId = messageRef.key;
      await messageRef.set({
        'senderId': userId,
        'senderName': userModelCurrentInfo?.first ?? 'User',
        'message': message,
        'timestamp': ServerValue.timestamp,
        'read': false,
        'notificationSent': false,
      });
      await _database.ref().child('chats').child(chatId).set({
        'participants': {
          userId: true,
          providerId: true,
        },
        'lastMessage': message,
        'lastTimestamp': ServerValue.timestamp,
        'unread_$userId': false,
        'unread_$providerId': true,
        'requestId': requestId,
        'serviceType':
            'unknown', // Update with actual service type if available
      });
      debugPrint("Message sent to database for chatId=$chatId");
    } catch (e, stackTrace) {
      debugPrint("Error sending message: $e\n$stackTrace");
    }
  }
}
