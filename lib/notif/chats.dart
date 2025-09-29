import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/l10n/app_localizations_en.dart';
import 'package:rana_jayeen/notif/NotificationService.dart';
import 'package:rana_jayeen/notif/chat_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class Chat extends StatefulWidget {
  final String chatId;
  final String providerId;
  final String providerName;
  final String userId;
  final String userName;
  final String serviceType;
  final String? requestId;
  final String? storeId;
  final String? storeName;

  const Chat({
    Key? key,
    required this.chatId,
    required this.providerId,
    required this.providerName,
    required this.userId,
    required this.userName,
    required this.serviceType,
    this.requestId,
    this.storeId,
    this.storeName,
  }) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _messageIds = {};
  StreamSubscription<DatabaseEvent>? _messageSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggerController;
  List<Animation<double>> _staggerAnimations = [];
  bool _isLoading = true;
  bool _isOfflineMode = false;
  bool _isLoadingMore = false;
  bool _isDisposed = false;
  Map<String, dynamic>? _providerDetails;
  SharedPreferences? _prefs;
  final List<Map<String, dynamic>> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    if (widget.userId.isEmpty || widget.userId == 'unknown') {
      debugPrint('Invalid userId: ${widget.userId}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.error,
              style: TextStyle(fontFamily: font ?? 'Roboto'),
            ),
          ),
        );
        Navigator.pop(context);
      });
      return;
    }
    _fadeController = AnimationController(
      vsync: this,
      duration: kAnimationDuration ?? const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCubic),
    );
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrollController.addListener(_loadMoreMessages);
    _initializeApp();
    _startConnectionMonitoring();
    NotificationService().onChatOpened = (chatId) {
      if (chatId == widget.chatId && mounted && !_isDisposed) {
        _clearUnreadCount();
      }
    };
    _fadeController.forward();
    debugPrint(
        'ChatScreen initialized: chatId=${widget.chatId}, providerId=${widget.providerId}, userId=${widget.userId}');
  }

  Future<void> _initializeApp() async {
    if (_isDisposed || !mounted) return;
    setState(() => _isLoading = true);
    try {
      _prefs = await SharedPreferences.getInstance();
      await Future.wait([
        _fetchProviderDetails(),
        _loadCachedMessages(),
      ]);
      if (!_isOfflineMode) {
        await _syncMessages();
        _listenToMessages();
      }
      _setupStaggerAnimations();
      _staggerController.forward();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _markMessagesAsRead());
    } catch (e, stackTrace) {
      debugPrint("Error initializing ChatScreen: $e\n$stackTrace");
      await _loadCachedMessages();
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupStaggerAnimations() {
    if (_isDisposed) return;
    _staggerAnimations = List.generate(
      _messages.length.clamp(0, 20),
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            (index * 0.05).clamp(0.0, 0.95),
            ((index + 1) * 0.05).clamp(0.05, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  Future<void> _syncMessages() async {
    if (_isDisposed || !mounted || _isOfflineMode) return;
    try {
      _messages.clear();
      _messageIds.clear();
      final ref = FirebaseDatabase.instance
          .ref()
          .child('messages')
          .child(widget.chatId)
          .orderByChild('timestamp')
          .limitToLast(20);
      final snapshot =
          await ref.get().timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Timeout syncing messages for chatId=${widget.chatId}');
        return DataSnapshotMock();
      });
      if (snapshot.exists && snapshot.value is Map) {
        final messages = Map<String, dynamic>.from(snapshot.value as Map);
        for (var entry in messages.entries) {
          final message = Map<String, dynamic>.from(entry.value);
          final messageId = entry.key;
          if (!_messageIds.contains(messageId)) {
            _messages.add({
              ...message,
              'messageId': messageId,
            });
            _messageIds.add(messageId);
          }
        }
        _messages.sort((a, b) => (a['timestamp'] as int? ?? 0)
            .compareTo(b['timestamp'] as int? ?? 0));
        await _prefs?.setString(
            'messages_${widget.chatId}', jsonEncode(_messages));
        debugPrint(
            'Synced ${_messages.length} messages for chatId=${widget.chatId}');
      } else {
        debugPrint(
            'No messages found for chatId=${widget.chatId}, loading cached');
        await _loadCachedMessages();
      }
      await _syncPendingMessages();
      if (mounted && !_isDisposed) {
        setState(() {
          _setupStaggerAnimations();
          _staggerController.reset();
          _staggerController.forward();
        });
        if (_messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error syncing messages: $e\n$stackTrace");
      await _loadCachedMessages();
    }
  }

  Future<void> _loadCachedMessages() async {
    try {
      final messagesJson = _prefs?.getString('messages_${widget.chatId}');
      if (messagesJson != null) {
        final cachedMessages = jsonDecode(messagesJson) as List<dynamic>;
        for (var message in cachedMessages.cast<Map<String, dynamic>>()) {
          final messageId = message['messageId']?.toString() ??
              'temp_${message['timestamp']?.toString() ?? DateTime.now().millisecondsSinceEpoch}';
          if (!_messageIds.contains(messageId)) {
            _messages.add(message);
            _messageIds.add(messageId);
          }
        }
        _messages.sort((a, b) => (a['timestamp'] as int? ?? 0)
            .compareTo(b['timestamp'] as int? ?? 0));
        debugPrint(
            'Loaded ${_messages.length} cached messages for chatId=${widget.chatId}');
      }
      if (mounted && !_isDisposed) {
        setState(() {
          _setupStaggerAnimations();
          _staggerController.reset();
          _staggerController.forward();
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error loading cached messages: $e\n$stackTrace");
    }
  }

  Future<void> _syncPendingMessages() async {
    if (_pendingMessages.isEmpty || _isOfflineMode) return;
    try {
      final ref = FirebaseDatabase.instance
          .ref()
          .child('messages')
          .child(widget.chatId);
      for (var message in List.from(_pendingMessages)) {
        final messageId = ref.push().key;
        if (messageId == null) continue;
        await ref.child(messageId).set({
          ...message,
          'messageId': messageId,
          'timestamp': ServerValue.timestamp,
          'read': false,
          'notificationSent': false,
        });
        await FirebaseDatabase.instance
            .ref()
            .child('chats')
            .child(widget.chatId)
            .update({
          'lastMessage': message['message'],
          'lastTimestamp': ServerValue.timestamp,
          'unread_${widget.providerId}': true,
          'unread_${widget.userId}': false,
          'participants': {
            widget.userId: true,
            widget.providerId: true,
          },
          'requestId': widget.requestId ?? '',
          'serviceType': widget.serviceType,
        });
        _pendingMessages.remove(message);
      }
      await _prefs?.setString(
          'pending_messages_${widget.chatId}', jsonEncode(_pendingMessages));
      debugPrint(
          'Synced ${_pendingMessages.length} pending messages for chatId=${widget.chatId}');
    } catch (e, stackTrace) {
      debugPrint("Error syncing pending messages: $e\n$stackTrace");
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_scrollController.position.pixels <= 0 &&
        !_isLoadingMore &&
        mounted &&
        !_isDisposed &&
        !_isOfflineMode) {
      setState(() => _isLoadingMore = true);
      try {
        final oldestTimestamp = _messages.isNotEmpty
            ? _messages.first['timestamp'] ??
                DateTime.now().millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch;
        final ref = FirebaseDatabase.instance
            .ref()
            .child('messages')
            .child(widget.chatId)
            .orderByChild('timestamp')
            .endBefore(oldestTimestamp)
            .limitToLast(20);
        final snapshot =
            await ref.get().timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint(
              'Timeout loading more messages for chatId=${widget.chatId}');
          return DataSnapshotMock();
        });
        if (snapshot.exists && snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final newMessages = data.entries.map((entry) {
            return Map<String, dynamic>.from(entry.value)
              ..['messageId'] = entry.key;
          }).toList();
          if (mounted && !_isDisposed) {
            setState(() {
              for (var message in newMessages) {
                if (!_messageIds.contains(message['messageId'])) {
                  _messages.add(message);
                  _messageIds.add(message['messageId']);
                }
              }
              _messages.sort((a, b) => (a['timestamp'] as int? ?? 0)
                  .compareTo(b['timestamp'] as int? ?? 0));
              _setupStaggerAnimations();
              _staggerController.reset();
              _staggerController.forward();
              _isLoadingMore = false;
              debugPrint(
                  'Loaded ${newMessages.length} more messages for chatId=${widget.chatId}');
            });
            await _prefs?.setString(
                'messages_${widget.chatId}', jsonEncode(_messages));
          }
        }
      } catch (e, stackTrace) {
        debugPrint("Error loading more messages: $e\n$stackTrace");
      } finally {
        if (mounted && !_isDisposed) {
          setState(() => _isLoadingMore = false);
        }
      }
    }
  }

  Future<void> _fetchProviderDetails() async {
    if (_isDisposed || !mounted) return;
    try {
      setState(() => _isLoading = true);
      Map<String, dynamic>? requestData;
      if (!_isOfflineMode && widget.requestId != null) {
        final requestRef = FirebaseDatabase.instance
            .ref()
            .child('allRideRequests')
            .child(widget.requestId!);
        final requestSnapshot = await requestRef
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint(
              'Timeout fetching provider details for requestId=${widget.requestId}');
          return DataSnapshotMock();
        });
        if (requestSnapshot.exists && requestSnapshot.value is Map) {
          requestData = Map<String, dynamic>.from(requestSnapshot.value as Map);
        }
      }
      if (requestData == null) {
        final cachedData = _prefs?.getString('provider_${widget.providerId}');
        if (cachedData != null) {
          requestData = jsonDecode(cachedData) as Map<String, dynamic>;
        }
      }
      if (mounted && !_isDisposed) {
        setState(() {
          _providerDetails = {
            'providerName':
                requestData?['providerName']?.toString() ?? widget.providerName,
            'serviceType':
                requestData?['serviceType']?.toString() ?? widget.serviceType,
            'contact': requestData?['providerPhone']?.toString() ??
                lang.phone_not_available,
          };
          _prefs?.setString(
              'provider_${widget.providerId}', jsonEncode(_providerDetails));
          debugPrint('Fetched provider details: ${_providerDetails}');
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching provider details: $e\n$stackTrace");
      if (mounted && !_isDisposed) {
        setState(() {
          _providerDetails = {
            'providerName': widget.providerName,
            'serviceType': widget.serviceType,
            'contact': lang.phone_not_available,
          };
          _prefs?.setString(
              'provider_${widget.providerId}', jsonEncode(_providerDetails));
        });
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_isDisposed || !mounted || _isOfflineMode) return;
    try {
      final ref = FirebaseDatabase.instance
          .ref()
          .child('messages')
          .child(widget.chatId);
      final snapshot =
          await ref.get().timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint(
            'Timeout marking messages as read for chatId=${widget.chatId}');
        return DataSnapshotMock();
      });
      if (snapshot.exists && snapshot.value is Map) {
        final messages = Map<String, dynamic>.from(snapshot.value as Map);
        final updates = <String, dynamic>{};
        for (var entry in messages.entries) {
          if (entry.value['senderId'] != widget.userId &&
              entry.value['read'] == false) {
            updates['${entry.key}/read'] = true;
          }
        }
        if (updates.isNotEmpty) {
          await ref.update(updates);
        }
        await FirebaseDatabase.instance
            .ref()
            .child('chats')
            .child(widget.chatId)
            .update({
          'unread_${widget.userId}': false,
        });
        await _clearUnreadCount();
        debugPrint('Marked messages as read for chatId=${widget.chatId}');
      }
    } catch (e, stackTrace) {
      debugPrint("Error marking messages as read: $e\n$stackTrace");
    }
  }

  Future<void> _clearUnreadCount() async {
    if (_isDisposed || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsKey = 'notifications_${widget.userId}';
      final unreadCountKey = 'unreadCount_${widget.userId}';
      List<String> notifications = prefs.getStringList(notificationsKey) ?? [];
      notifications.remove('notification_${widget.chatId}');
      int unreadCount = prefs.getInt(unreadCountKey) ?? 0;
      unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
      await prefs.setStringList(notificationsKey, notifications);
      await prefs.setInt(unreadCountKey, unreadCount);
      debugPrint(
          'Cleared unread count for chatId=${widget.chatId}, new unreadCount=$unreadCount');
    } catch (e, stackTrace) {
      debugPrint("Error clearing unread count: $e\n$stackTrace");
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty ||
        _isLoading ||
        _isDisposed ||
        !mounted ||
        widget.userId.isEmpty ||
        widget.userId == 'unknown') {
      debugPrint(
          "Skipping sendMessage: empty message, invalid state, or invalid userId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.error,
            style: TextStyle(fontFamily: font ?? 'Roboto'),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final messageText = _messageController.text.trim();
      if (_isOfflineMode) {
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        _pendingMessages.add({
          'senderId': widget.userId,
          'senderName': widget.userName,
          'recipientId': widget.providerId,
          'message': messageText,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'read': false,
          'notificationSent': false,
          'messageId': tempId,
        });
        setState(() {
          _messages.add(_pendingMessages.last);
          _messageIds.add(tempId);
          _prefs?.setString('messages_${widget.chatId}', jsonEncode(_messages));
          _prefs?.setString('pending_messages_${widget.chatId}',
              jsonEncode(_pendingMessages));
          _messageController.clear();
          _setupStaggerAnimations();
          _staggerController.reset();
          _staggerController.forward();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.message_queued,
                style: TextStyle(fontFamily: font ?? 'Roboto')),
            action: SnackBarAction(
                label: lang.retry, onPressed: _syncPendingMessages),
          ),
        );
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          });
        }
        debugPrint('Queued message for chatId=${widget.chatId}');
        return;
      }
      await NotificationService().sendNewMessage(
        widget.providerId,
        messageText,
        widget.requestId ?? '',
      );
      if (mounted && !_isDisposed) {
        setState(() {
          _messageController.clear();
          _setupStaggerAnimations();
          _staggerController.reset();
          _staggerController.forward();
        });
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error sending message: $e\n$stackTrace");
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      _pendingMessages.add({
        'senderId': widget.userId,
        'senderName': widget.userName,
        'recipientId': widget.providerId,
        'message': _messageController.text.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': false,
        'notificationSent': false,
        'messageId': tempId,
      });
      setState(() {
        _messages.add(_pendingMessages.last);
        _messageIds.add(tempId);
        _prefs?.setString('messages_${widget.chatId}', jsonEncode(_messages));
        _prefs?.setString(
            'pending_messages_${widget.chatId}', jsonEncode(_pendingMessages));
        _messageController.clear();
        _setupStaggerAnimations();
        _staggerController.reset();
        _staggerController.forward();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.message_queued,
              style: TextStyle(fontFamily: font ?? 'Roboto')),
          action: SnackBarAction(
              label: lang.retry, onPressed: _syncPendingMessages),
        ),
      );
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        });
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _listenToMessages() async {
    if (_isOfflineMode || _isDisposed || !mounted) return;
    final ref = FirebaseDatabase.instance
        .ref()
        .child('messages')
        .child(widget.chatId)
        .orderByChild('timestamp')
        .limitToLast(20);
    _messageSubscription?.cancel();
    _messageSubscription = ref.onChildAdded.listen((event) async {
      if (event.snapshot.value != null && !_isDisposed && mounted) {
        final message = Map<String, dynamic>.from(event.snapshot.value as Map);
        final messageId = event.snapshot.key;
        if (messageId != null && !_messageIds.contains(messageId)) {
          if (mounted && !_isDisposed) {
            setState(() {
              _messages.add({
                ...message,
                'messageId': messageId,
              });
              _messageIds.add(messageId);
              _prefs?.setString(
                  'messages_${widget.chatId}', jsonEncode(_messages));
              _setupStaggerAnimations();
              _staggerController.reset();
              _staggerController.forward();
            });
            if (_messages.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
            if (message['senderId'] != widget.userId) {
              await _markMessagesAsRead();
            }
          }
        }
      }
    }, onError: (e, stackTrace) {
      debugPrint("Error listening to messages: $e\n$stackTrace");
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.offline_mode,
                style: TextStyle(fontFamily: font ?? 'Roboto')),
          ),
        );
      }
    });
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      debugPrint("Internet access check failed: $e\n$stackTrace");
      return false;
    }
  }

  Future<void> _startConnectionMonitoring() async {
    if (_isDisposed || !mounted) return;
    _connectivitySubscription?.cancel();
    final connectivity = Connectivity();
    final initialResult = await connectivity.checkConnectivity();
    final hasInternet = await _hasInternetAccess();
    _handleConnectivityResult(initialResult, hasInternet);
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen((result) async {
      if (_isDisposed || !mounted) return;
      final hasInternet = await _hasInternetAccess();
      _handleConnectivityResult(result, hasInternet);
    });
  }

  void _handleConnectivityResult(
      List<ConnectivityResult> result, bool hasInternet) {
    if (_isDisposed || !mounted) return;
    final isConnected = (result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.mobile)) &&
        hasInternet;
    if (_isOfflineMode != !isConnected) {
      setState(() => _isOfflineMode = !isConnected);
      if (!_isOfflineMode) {
        _syncMessages();
        _syncPendingMessages();
        _listenToMessages();
      } else {
        _loadCachedMessages();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.offline_mode,
                style: TextStyle(fontFamily: font ?? 'Roboto')),
          ),
        );
      }
    }
  }

  Widget _buildShimmerMessage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(height: 12, width: 100, color: Colors.grey[200]),
              const SizedBox(height: 8),
              Container(height: 16, width: 150, color: Colors.grey[200]),
              const SizedBox(height: 8),
              Container(height: 10, width: 50, color: Colors.grey[200]),
            ],
          ),
        ),
      ),
    );
  }

  AppLocalizations get lang =>
      AppLocalizations.of(context) ?? AppLocalizationsEn();

  @override
  Widget build(BuildContext context) {
    final isRtl = lang.localeName == 'ar';
    return Scaffold(
      backgroundColor: kBackground?.withOpacity(0.95) ?? Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (!_isDisposed && mounted) {
              _clearUnreadCount();
              Navigator.pop(context);
            }
          },
          splashRadius: 24,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (kPrimaryColor ?? Colors.blue).withOpacity(0.1),
              child: Icon(ChatUtils.getServiceIcon(widget.serviceType),
                  color: kPrimaryColor ?? Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _providerDetails?['providerName'] ?? widget.providerName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: font ?? 'Roboto',
                    ),
                    textDirection:
                        isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ChatUtils.getLocalizedServiceTitle(lang,
                        _providerDetails?['serviceType'] ?? widget.serviceType),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: font ?? 'Roboto',
                    ),
                    textDirection:
                        isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: kPrimaryGradientColor ??
                LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_providerDetails != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.request_details,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: kTextPrimary ?? Colors.black87,
                      fontFamily: font ?? 'Roboto',
                    ),
                    textDirection:
                        isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${lang.service_type}: ${ChatUtils.getLocalizedServiceTitle(lang, _providerDetails!['serviceType'])}',
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextSecondary ?? Colors.grey[600],
                      fontFamily: font ?? 'Roboto',
                    ),
                    textDirection:
                        isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  if (_providerDetails!['contact'] != lang.phone_not_available)
                    Text(
                      '${lang.contact}: ${_providerDetails!['contact']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextSecondary ?? Colors.grey[600],
                        fontFamily: font ?? 'Roboto',
                      ),
                      textDirection:
                          isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Text(
                lang.driver_info_not_found,
                style: TextStyle(
                  fontSize: 14,
                  color: kTextSecondary ?? Colors.grey[600],
                  fontFamily: font ?? 'Roboto',
                ),
                textDirection:
                    isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              ),
            ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (context, index) => _buildShimmerMessage(),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 60,
                                  color: kTextSecondary?.withOpacity(0.7) ??
                                      Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isOfflineMode
                                      ? lang.offline_mode
                                      : lang.new_message_body,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: kTextSecondary?.withOpacity(0.7) ??
                                        Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontFamily: font ?? 'Roboto',
                                  ),
                                  textDirection: isRtl
                                      ? ui.TextDirection.rtl
                                      : ui.TextDirection.ltr,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                _messages.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isLoadingMore && index == _messages.length) {
                                return _buildShimmerMessage();
                              }
                              if (index >= _staggerAnimations.length) {
                                _setupStaggerAnimations();
                              }
                              final message =
                                  _messages[_messages.length - 1 - index];
                              final isUserMessage =
                                  message['senderId'] == widget.userId;
                              final timestamp = message['timestamp'] is int
                                  ? DateTime.fromMillisecondsSinceEpoch(
                                      message['timestamp'])
                                  : DateTime.now();
                              final isPending = message['messageId']
                                  .toString()
                                  .startsWith('temp_');
                              return FadeTransition(
                                opacity: _staggerAnimations[index],
                                child: Align(
                                  alignment: isUserMessage
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.75),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isUserMessage
                                          ? (kPrimaryColor ?? Colors.blue)
                                              .withOpacity(0.9)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                            isUserMessage ? 12 : 4),
                                        topRight: Radius.circular(
                                            isUserMessage ? 4 : 12),
                                        bottomLeft: const Radius.circular(12),
                                        bottomRight: const Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isUserMessage
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['senderName']?.toString() ??
                                              lang.unknown,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isUserMessage
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                            fontFamily: font ?? 'Roboto',
                                          ),
                                          textDirection: isRtl
                                              ? ui.TextDirection.rtl
                                              : ui.TextDirection.ltr,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          message['message']?.toString() ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isUserMessage
                                                ? Colors.white
                                                : Colors.black87,
                                            fontFamily: font ?? 'Roboto',
                                          ),
                                          textDirection: isRtl
                                              ? ui.TextDirection.rtl
                                              : ui.TextDirection.ltr,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isPending)
                                              Icon(Icons.access_time,
                                                  size: 12,
                                                  color: isUserMessage
                                                      ? Colors.white
                                                          .withOpacity(0.6)
                                                      : Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat.jm().format(timestamp),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isUserMessage
                                                    ? Colors.white
                                                        .withOpacity(0.6)
                                                    : Colors.grey[500],
                                                fontStyle: FontStyle.italic,
                                                fontFamily: font ?? 'Roboto',
                                              ),
                                              textDirection: isRtl
                                                  ? ui.TextDirection.rtl
                                                  : ui.TextDirection.ltr,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isOfflineMode
                          ? lang.message_queued
                          : lang.type_message,
                      hintStyle: TextStyle(
                        color: kTextSecondary?.withOpacity(0.7) ??
                            Colors.grey[600],
                        fontSize: 14,
                        fontFamily: font ?? 'Roboto',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    enabled: true,
                    textDirection:
                        isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradientColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.send, color: Colors.white),
                    splashRadius: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _fadeController.dispose();
    _staggerController.dispose();
    NotificationService().onChatOpened = null;
    debugPrint('ChatScreen disposed for chatId=${widget.chatId}');
    super.dispose();
  }
}

// Mock DataSnapshot to handle timeout cases
class DataSnapshotMock implements DataSnapshot {
  @override
  String? get key => null;

  @override
  dynamic get value => null;

  @override
  bool get exists => false;

  @override
  DatabaseReference get ref => throw UnimplementedError();

  @override
  Iterable<DataSnapshot> get children => [];

  @override
  DataSnapshot child(String path) => DataSnapshotMock();

  @override
  bool hasChild(String path) => false;

  @override
  Future<dynamic> get valueAsync => Future.value(null);

  @override
  Future<bool> existsAsync() => Future.value(false);

  @override
  Future<DataSnapshot> childAsync(String path) =>
      Future.value(DataSnapshotMock());

  @override
  Future<bool> hasChildAsync(String path) => Future.value(false);

  @override
  Object? get priority => throw UnimplementedError();
}
