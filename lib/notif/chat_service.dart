import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final SharedPreferences _prefs;
  final String userId;
  final BuildContext context;

  ChatService(this._prefs, this.userId, this.context);

  Future<List<Map<String, dynamic>>> fetchChats({
    required bool isProvider,
    required String userIdField,
    required String otherIdField,
    required String nameField,
  }) async {
    final chatsRef = _database
        .ref()
        .child('chats')
        .orderByChild('participants/$userId')
        .equalTo(true);
    final snapshot = await chatsRef.get().timeout(const Duration(seconds: 5));
    List<Map<String, dynamic>> chats = [];
    Set<String> chatIds = {};
    int unreadCount = 0;

    if (snapshot.exists && snapshot.value is Map) {
      final chatData = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in chatData.entries) {
        final chatId = entry.key;
        final chatMeta = Map<String, dynamic>.from(entry.value);
        final participants = chatMeta['participants'] as Map<dynamic, dynamic>?;
        if (participants == null || !participants.containsKey(userId)) {
          debugPrint('Invalid participants for chatId=$chatId, skipping');
          continue;
        }
        final otherId = participants.keys
            .firstWhere((key) => key != userId, orElse: () => '');
        if (otherId.isEmpty || chatIds.contains(chatId)) {
          debugPrint(
              'Invalid or duplicate otherId=$otherId for chatId=$chatId, skipping');
          continue;
        }

        String name = otherId; // Default to otherId
        String serviceType = chatMeta['serviceType']?.toString() ?? 'unknown';
        String? requestId = chatMeta['requestId']?.toString() ?? otherId;
        String contact = 'No contact info';
        String? userAddress;
        String? lastMessage = chatMeta['lastMessage']?.toString();
        bool hasUnread = chatMeta['unread_$userId'] == true;

        try {
          if (requestId!.isNotEmpty) {
            final requestRef =
                _database.ref().child('allRideRequests').child(requestId!);
            final requestSnapshot =
                await requestRef.get().timeout(const Duration(seconds: 5));
            if (requestSnapshot.exists && requestSnapshot.value is Map) {
              final requestData =
                  Map<String, dynamic>.from(requestSnapshot.value as Map);
              name = requestData[isProvider ? 'userName' : 'providerName']
                      ?.toString() ??
                  requestData['storeName']?.toString() ??
                  requestData['driver_name']?.toString() ??
                  otherId;
              serviceType =
                  requestData['serviceType']?.toString() ?? serviceType;
              contact = requestData[isProvider ? 'phone' : 'providerPhone']
                      ?.toString() ??
                  requestData['driver_phone']?.toString() ??
                  'No contact info';
              userAddress = requestData['address']?.toString();
              debugPrint(
                  'Fetched request data for requestId=$requestId, name=$name, contact=$contact');
            } else {
              debugPrint('No request data found for requestId=$requestId');
            }
          }

          if (name == otherId && !isProvider) {
            final providerRef = _database.ref().child('stores').child(otherId);
            final providerSnapshot =
                await providerRef.get().timeout(const Duration(seconds: 5));
            if (providerSnapshot.exists && providerSnapshot.value is Map) {
              final providerData =
                  Map<String, dynamic>.from(providerSnapshot.value as Map);
              name = providerData['storeName']?.toString() ??
                  providerData['name']?.toString() ??
                  otherId;
              contact =
                  providerData['contact']?.toString() ?? 'No contact info';
              serviceType = providerData['services'] != null &&
                      (providerData['services'] as List).isNotEmpty
                  ? providerData['services'][0].toString()
                  : serviceType;
              debugPrint(
                  'Fetched store data for otherId=$otherId, name=$name, contact=$contact');
            } else {
              debugPrint('No store data found for otherId=$otherId');
            }
          }

          if (hasUnread) {
            unreadCount++;
          }
        } catch (e, stackTrace) {
          debugPrint("Error fetching chat data: $e\n$stackTrace");
        }

        final chatDatas = {
          'chatId': chatId,
          userIdField: userId,
          otherIdField: otherId,
          nameField: name,
          'serviceType': serviceType,
          'contact': contact,
          'lastMessage': lastMessage,
          'unread': hasUnread,
          'userAddress': userAddress,
          'requestId': requestId,
          'lastTimestamp': chatMeta['lastTimestamp'] is int
              ? chatMeta['lastTimestamp']
              : DateTime.now().millisecondsSinceEpoch,
        };
        chats.add(chatDatas);
        chatIds.add(chatId);
        await _prefs.setString('chat_$chatId', jsonEncode(chatDatas));
      }
      chats.sort((a, b) => (b['lastTimestamp'] as int? ?? 0)
          .compareTo(a['lastTimestamp'] as int? ?? 0));
    } else {
      debugPrint('No chats found for userId=$userId');
    }
    await _prefs.setInt('unreadCount_$userId', unreadCount);
    await _prefs.setString('chat_$userId', jsonEncode(chats));
    debugPrint('Fetched ${chats.length} chats for userId=$userId: $chatIds');
    return chats;
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      final ref = _database.ref().child('messages').child(chatId);
      final snapshot = await ref.get().timeout(const Duration(seconds: 5));
      if (snapshot.exists && snapshot.value is Map) {
        final messages = Map<String, dynamic>.from(snapshot.value as Map);
        for (var entry in messages.entries) {
          if (entry.value['senderId'] != userId &&
              (entry.value['read'] ?? false) == false) {
            await ref.child(entry.key).update({'read': true});
          }
        }
      }
      await _database.ref().child('chats').child(chatId).update({
        'unread_$userId': false,
      });
      final notifications = _prefs.getStringList('notifications_$userId') ?? [];
      notifications.remove('notification_$chatId');
      int unreadCount = _prefs.getInt('unreadCount_$userId') ?? 0;
      if (unreadCount > 0) unreadCount--;
      await _prefs.setStringList('notifications_$userId', notifications);
      await _prefs.setInt('unreadCount_$userId', unreadCount);
      await _prefs.setBool('notified_${userId}_$chatId', false);
      debugPrint(
          'Marked chat as read: chatId=$chatId, unreadCount=$unreadCount');
    } catch (e, stackTrace) {
      debugPrint("Error marking chat as read: $e\n$stackTrace");
    }
  }

  Future<void> loadOfflineChats({
    required String cachePrefix,
    required String idField,
    required Function(List<Map<String, dynamic>>, int) onChatsLoaded,
  }) async {
    try {
      List<Map<String, dynamic>> chats = [];
      // Load individual chat entries
      final chatKeys = _prefs
          .getKeys()
          .where((key) => key.startsWith(cachePrefix) && key != 'chat_$userId');
      for (var key in chatKeys) {
        final json = _prefs.getString(key);
        if (json != null) {
          try {
            final data = jsonDecode(json) as Map<String, dynamic>;
            if (data[idField] == userId && data['chatId'] != null) {
              // Ensure name uses otherId as fallback
              if (data['displayName'] == null || data['displayName'].isEmpty) {
                data['displayName'] =
                    data['providerId'] ?? data['storeId'] ?? data[idField];
              }
              chats.add({'chatId': key.replaceFirst(cachePrefix, ''), ...data});
            }
          } catch (e) {
            debugPrint('Invalid cache data for key=$key, removing');
            _prefs.remove(key);
          }
        }
      }
      // Load chat list
      final listJson = _prefs.getString('chat_$userId');
      if (listJson != null) {
        try {
          final listData = jsonDecode(listJson);
          if (listData is List<dynamic>) {
            chats = listData.cast<Map<String, dynamic>>().where((data) {
              if (data[idField] == userId && data['chatId'] != null) {
                // Ensure name uses otherId as fallback
                if (data['displayName'] == null ||
                    data['displayName'].isEmpty) {
                  data['displayName'] =
                      data['providerId'] ?? data['storeId'] ?? data[idField];
                }
                return true;
              }
              return false;
            }).toList();
          }
        } catch (e) {
          debugPrint('Invalid chat list cache for userId=$userId, removing');
          _prefs.remove('chat_$userId');
        }
      }
      final unreadCount = chats.where((chat) => chat['unread'] == true).length;
      chats.sort((a, b) => (b['lastTimestamp'] as int? ?? 0)
          .compareTo(a['lastTimestamp'] as int? ?? 0));
      onChatsLoaded(chats, unreadCount);
      debugPrint('Loaded ${chats.length} offline chats for userId=$userId');
    } catch (e, stackTrace) {
      debugPrint("Error loading offline chats: $e\n$stackTrace");
    }
  }

  Future<void> clearStaleCache(Duration maxAge) async {
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith('chat_'));
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var key in keys) {
        final json = _prefs.getString(key);
        if (json == null) continue;
        try {
          final decoded = jsonDecode(json);
          if (key == 'chat_$userId' && decoded is List<dynamic>) {
            // Handle chat list
            final chats = decoded.cast<Map<String, dynamic>>();
            final updatedChats = chats.where((data) {
              final timestamp =
                  data['lastTimestamp'] is int ? data['lastTimestamp'] : 0;
              return now - timestamp < maxAge.inMilliseconds;
            }).toList();
            if (updatedChats.isEmpty) {
              _prefs.remove(key);
            } else {
              _prefs.setString(key, jsonEncode(updatedChats));
            }
          } else if (decoded is Map<String, dynamic>) {
            // Handle individual chat
            final timestamp =
                decoded['lastTimestamp'] is int ? decoded['lastTimestamp'] : 0;
            if (now - timestamp > maxAge.inMilliseconds) {
              _prefs.remove(key);
            }
          } else {
            debugPrint('Invalid cache data for key=$key, removing');
            _prefs.remove(key);
          }
        } catch (e) {
          debugPrint('Error processing cache for key=$key: $e, removing');
          _prefs.remove(key);
        }
      }
      debugPrint('Cleared stale cache for userId=$userId');
    } catch (e, stackTrace) {
      debugPrint("Error clearing stale cache: $e\n$stackTrace");
    }
  }
}
