import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/globel/var_glob.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/l10n/app_localizations_en.dart';
import 'package:rana_jayeen/notif/NotificationService.dart';
import 'package:rana_jayeen/notif/chat_service.dart';
import 'package:rana_jayeen/notif/chats.dart';
import 'package:rana_jayeen/notif/chat_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

const defaultDuration = Duration(milliseconds: 250);
const double paddingSmall = 8.0;
const double paddingMedium = 16.0;
const double borderRadius = 12.0;

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _chatProviders = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  final Set<String> _chatIds = {};
  bool _isLoading = true;
  bool _isOfflineMode = false;
  bool _isLoadingMore = false;
  bool _isDisposed = false;
  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<DatabaseEvent>? _chatSubscription;
  int _unreadCount = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggerController;
  List<Animation<double>> _staggerAnimations = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late ChatService _chatService;
  DateTime? _lastNavigationTime;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(_loadMoreChats);
    _searchController.addListener(() => _filterChats(_searchController.text));
    _initializeApp();
    _startConnectionMonitoring();
    NotificationService().onChatOpened = _markChatAsRead;
    _fadeController.forward();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: kAnimationDuration ?? defaultDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCubic),
    );
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _setupStaggerAnimations();
  }

  void _setupStaggerAnimations() {
    if (_isDisposed) return;
    _staggerAnimations = List.generate(
      _filteredProviders.length.clamp(0, 10),
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(index * 0.1, (index + 1) * 0.1,
              curve: Curves.easeOutCubic),
        ),
      ),
    );
  }

  Future<void> _initializeApp() async {
    if (_isDisposed || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await NotificationService().initialize(context);
      _prefs = await SharedPreferences.getInstance();
      final userId =
          userModelCurrentInfo?.id ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user logged in, loading offline chats');
        await _loadOfflineChats(null);
        return;
      }
      _chatService = ChatService(_prefs!, userId, context);
      await _chatService.clearStaleCache(const Duration(days: 30));
      await _fetchChatProviders(userId);
      _listenForNewChats(userId);
      debugPrint('ChatsScreen initialized for userId: $userId');
    } catch (e, stackTrace) {
      debugPrint("Error initializing ChatsScreen: $e\n$stackTrace");
      await _loadOfflineChats(null);
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _processChatData(String chatId,
      Map<String, dynamic> chatData, String userId, String providerId) async {
    final requestId = chatData['requestId']?.toString() ?? '';
    String providerName = providerId; // Default to providerId
    String storeName = providerId; // Default to providerId
    String storeId = '';

    try {
      // Fetch cached provider data first
      final cachedProviderData = _prefs?.getString('provider_$providerId');
      if (cachedProviderData != null) {
        final providerData =
            Map<String, dynamic>.from(jsonDecode(cachedProviderData));
        providerName = providerData['username']?.toString() ??
            providerData['shopName']?.toString() ??
            providerId;
        debugPrint(
            'Used cached provider data for providerId: $providerId, name: $providerName');
      } else {
        // Fetch from Firebase if not cached
        final providerSnapshot = await FirebaseDatabase.instance
            .ref()
            .child('driver_users')
            .child(providerId)
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint(
              'Timeout fetching provider data for providerId: $providerId');
          return DataSnapshotMock();
        });
        if (providerSnapshot.exists && providerSnapshot.value is Map) {
          final providerData =
              Map<String, dynamic>.from(providerSnapshot.value as Map);
          providerName = providerData['username']?.toString() ??
              providerData['shopName']?.toString() ??
              providerId;
          await _prefs?.setString(
              'provider_$providerId', jsonEncode(providerData));
          debugPrint(
              'Fetched provider data for providerId: $providerId, name: $providerName');
        } else {
          debugPrint(
              'No provider data found for providerId: $providerId, using providerId as fallback');
        }
      }
    } catch (e, stackTrace) {
      debugPrint(
          'Error fetching provider data for providerId: $providerId: $e\n$stackTrace');
    }

    if (requestId.isNotEmpty) {
      try {
        // Fetch cached request data first
        final cachedRequestData = _prefs?.getString('request_$requestId');
        if (cachedRequestData != null) {
          final requestData =
              Map<String, dynamic>.from(jsonDecode(cachedRequestData));
          storeName = requestData['storeName']?.toString() ??
              requestData['userName']?.toString() ??
              providerId;
          storeId = requestData['storeId']?.toString() ?? '';
          debugPrint(
              'Used cached request data for requestId: $requestId, storeName: $storeName');
        } else {
          // Fetch from Firebase if not cached
          final requestSnapshot = await FirebaseDatabase.instance
              .ref()
              .child('allRideRequests')
              .child(requestId)
              .get()
              .timeout(const Duration(seconds: 5), onTimeout: () {
            debugPrint(
                'Timeout fetching request data for requestId: $requestId');
            return DataSnapshotMock();
          });
          if (requestSnapshot.exists && requestSnapshot.value is Map) {
            final requestData =
                Map<String, dynamic>.from(requestSnapshot.value as Map);
            storeName = requestData['storeName']?.toString() ??
                requestData['userName']?.toString() ??
                providerId;
            storeId = requestData['storeId']?.toString() ?? '';
            await _prefs?.setString(
                'request_$requestId', jsonEncode(requestData));
            debugPrint(
                'Fetched request data for requestId: $requestId, storeName: $storeName');
          } else {
            debugPrint(
                'No request data found for requestId: $requestId, using providerId as fallback');
          }
        }
      } catch (e, stackTrace) {
        debugPrint(
            'Error fetching request data for requestId: $requestId: $e\n$stackTrace');
      }
    }

    // Fetch store data if storeId is available and storeName is still providerId
    if (storeId.isNotEmpty && storeName == providerId) {
      try {
        final cachedStoreData = _prefs?.getString('store_$storeId');
        if (cachedStoreData != null) {
          final storeData =
              Map<String, dynamic>.from(jsonDecode(cachedStoreData));
          storeName = storeData['storeName']?.toString() ?? providerId;
          debugPrint(
              'Used cached store data for storeId: $storeId, storeName: $storeName');
        } else {
          final storeSnapshot = await FirebaseDatabase.instance
              .ref()
              .child('stores')
              .child(storeId)
              .get()
              .timeout(const Duration(seconds: 5), onTimeout: () {
            debugPrint('Timeout fetching store data for storeId: $storeId');
            return DataSnapshotMock();
          });
          if (storeSnapshot.exists && storeSnapshot.value is Map) {
            final storeData =
                Map<String, dynamic>.from(storeSnapshot.value as Map);
            storeName = storeData['storeName']?.toString() ?? providerId;
            await _prefs?.setString('store_$storeId', jsonEncode(storeData));
            debugPrint(
                'Fetched store data for storeId: $storeId, storeName: $storeName');
          } else {
            debugPrint(
                'No store data found for storeId: $storeId, using providerId as fallback');
          }
        }
      } catch (e, stackTrace) {
        debugPrint(
            'Error fetching store data for storeId: $storeId: $e\n$stackTrace');
      }
    }

    // Determine displayName: prioritize storeName, then providerName, then providerId
    final displayName = storeName != providerId
        ? storeName
        : providerName != providerId
            ? providerName
            : providerId;

    return {
      'chatId': chatId,
      'userId': userId,
      'providerId': providerId,
      'providerName': providerName,
      'storeName': storeName,
      'storeId': storeId,
      'displayName': displayName,
      'serviceType': chatData['serviceType']?.toString() ?? 'unknown',
      'requestId': requestId,
      'lastMessage': chatData['lastMessage']?.toString() ?? '',
      'lastTimestamp':
          chatData['lastTimestamp'] is int ? chatData['lastTimestamp'] : 0,
      'unread': chatData['unread_$userId'] == true,
    };
  }

  Future<void> _fetchChatProviders(String userId) async {
    if (_isLoading || _isDisposed || !mounted) return;
    setState(() => _isLoading = true);
    try {
      if (_isOfflineMode) {
        await _loadOfflineChats(userId);
        return;
      }
      _chatProviders = await _chatService.fetchChats(
        isProvider: false,
        userIdField: 'userId',
        otherIdField: 'providerId',
        nameField: 'displayName',
      );
      _chatIds.clear();
      _chatIds.addAll(_chatProviders.map((chat) => chat['chatId'] as String));
      if (mounted && !_isDisposed) {
        setState(() {
          _filteredProviders = _chatProviders;
          _unreadCount = _prefs!.getInt('unreadCount_$userId') ?? 0;
          _setupStaggerAnimations();
          _staggerController.reset();
          _staggerController.forward();
          debugPrint("Fetched ${_chatProviders.length} chats: $_chatIds");
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching chat providers: $e\n$stackTrace");
      await _loadOfflineChats(userId);
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _listenForNewChats(String userId) async {
    if (_isDisposed || !mounted) return;
    _chatSubscription?.cancel();
    final ref = FirebaseDatabase.instance
        .ref()
        .child('chats')
        .orderByChild('participants/$userId')
        .equalTo(true);
    _chatSubscription = ref.onChildAdded.listen((event) async {
      if (!mounted || _isDisposed || event.snapshot.value == null) return;
      final chatId = event.snapshot.key!;
      if (_chatIds.contains(chatId)) return;

      final chatData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final providerId = chatData['participants'] is Map
          ? chatData['participants'].keys.firstWhere(
                (key) => key != userId,
                orElse: () => '',
              )
          : '';
      if (providerId.isEmpty) {
        debugPrint('Invalid providerId for chatId: $chatId, skipping');
        return;
      }

      final chatInfo =
          await _processChatData(chatId, chatData, userId, providerId);
      if (chatInfo == null) return;

      if (mounted && !_isDisposed) {
        setState(() {
          _chatProviders.add(chatInfo);
          _chatIds.add(chatId);
          _chatProviders.sort((a, b) => (b['lastTimestamp'] as int? ?? 0)
              .compareTo(a['lastTimestamp'] as int? ?? 0));
          _filteredProviders = _chatProviders;
          if (chatInfo['unread']) _unreadCount++;
          _prefs!.setInt('unreadCount_$userId', _unreadCount);
          _prefs!.setString('chat_$userId', jsonEncode(_chatProviders));
          _setupStaggerAnimations();
          _staggerController.reset();
          _staggerController.forward();
          debugPrint(
              "Added new chat: chatId=$chatId, providerId=$providerId, displayName=${chatInfo['displayName']}");
        });
      }
    }, onError: (e, stackTrace) {
      debugPrint("Error listening for new chats: $e\n$stackTrace");
      _loadOfflineChats(userId);
    });

    ref.onChildChanged.listen((event) async {
      if (!mounted || _isDisposed || event.snapshot.value == null) return;
      final chatId = event.snapshot.key!;
      final chatData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final providerId = chatData['participants'] is Map
          ? chatData['participants'].keys.firstWhere(
                (key) => key != userId,
                orElse: () => '',
              )
          : '';
      if (providerId.isEmpty) {
        debugPrint('Invalid providerId for updated chatId: $chatId, skipping');
        return;
      }

      final chatInfo =
          await _processChatData(chatId, chatData, userId, providerId);
      if (chatInfo == null) return;

      if (mounted && !_isDisposed) {
        setState(() {
          _chatProviders = _chatProviders.map((chat) {
            if (chat['chatId'] == chatId) return chatInfo;
            return chat;
          }).toList();
          _chatProviders.sort((a, b) => (b['lastTimestamp'] as int? ?? 0)
              .compareTo(a['lastTimestamp'] as int? ?? 0));
          _filteredProviders = _chatProviders;
          _unreadCount = _prefs!.getInt('unreadCount_$userId') ?? 0;
          _prefs!.setString('chat_$userId', jsonEncode(_chatProviders));
          _setupStaggerAnimations();
          _staggerController.reset();
          _staggerController.forward();
          debugPrint(
              "Updated chat: chatId=$chatId, providerId=$providerId, displayName=${chatInfo['displayName']}");
        });
      }
    }, onError: (e, stackTrace) {
      debugPrint("Error listening for chat updates: $e\n$stackTrace");
      _loadOfflineChats(userId);
    });
  }

  Future<void> _loadMoreChats() async {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        mounted &&
        !_isDisposed) {
      setState(() => _isLoadingMore = true);
      final userId =
          userModelCurrentInfo?.id ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user logged in, cannot load more chats');
        setState(() => _isLoadingMore = false);
        return;
      }
      try {
        final oldestTimestamp = _chatProviders.isNotEmpty
            ? _chatProviders.last['lastTimestamp'] ??
                DateTime.now().millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch;
        final ref = FirebaseDatabase.instance
            .ref()
            .child('chats')
            .orderByChild('participants/$userId')
            .equalTo(true);
        final snapshot =
            await ref.get().timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('Timeout loading more chats for userId: $userId');
          return DataSnapshotMock();
        });
        final newChats = <Map<String, dynamic>>[];
        if (snapshot.exists && snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          for (final entry in data.entries) {
            final chatId = entry.key;
            if (_chatIds.contains(chatId)) continue;
            final chatData = Map<String, dynamic>.from(entry.value);
            final providerId = chatData['participants'] is Map
                ? chatData['participants'].keys.firstWhere(
                      (key) => key != userId,
                      orElse: () => '',
                    )
                : '';
            if (providerId.isEmpty) continue;
            final chatInfo =
                await _processChatData(chatId, chatData, userId, providerId);
            if (chatInfo != null &&
                chatInfo['lastTimestamp'] < oldestTimestamp) {
              newChats.add(chatInfo);
              _chatIds.add(chatId);
            }
          }
          newChats.sort((a, b) => (b['lastTimestamp'] as int? ?? 0)
              .compareTo(a['lastTimestamp'] as int? ?? 0));
        } else {
          debugPrint(
              'No more chats to load for userId: $userId or snapshot is empty');
        }
        if (mounted && !_isDisposed) {
          setState(() {
            _chatProviders.addAll(newChats);
            _filteredProviders = _chatProviders;
            _unreadCount = _prefs!.getInt('unreadCount_$userId') ?? 0;
            _prefs!.setString('chat_$userId', jsonEncode(_chatProviders));
            _setupStaggerAnimations();
            _staggerController.reset();
            _staggerController.forward();
            _isLoadingMore = false;
            debugPrint("Loaded ${newChats.length} more chats: $_chatIds");
          });
        }
      } catch (e, stackTrace) {
        debugPrint("Error loading more chats: $e\n$stackTrace");
        setState(() => _isLoadingMore = false);
        await _loadOfflineChats(userId);
      }
    }
  }

  Future<void> _loadOfflineChats(String? userId) async {
    if (_isDisposed || !mounted || userId == null) return;
    try {
      await _chatService.loadOfflineChats(
        cachePrefix: 'chat_',
        idField: 'userId',
        onChatsLoaded: (chats, unreadCount) {
          if (mounted && !_isDisposed) {
            setState(() {
              _chatProviders = chats;
              _chatIds.clear();
              _chatIds.addAll(chats.map((chat) => chat['chatId'] as String));
              for (var chat in _chatProviders) {
                final providerDataJson =
                    _prefs?.getString('provider_${chat['providerId']}');
                final requestDataJson =
                    _prefs?.getString('request_${chat['requestId']}');
                final storeDataJson =
                    _prefs?.getString('store_${chat['storeId']}');
                String providerName = chat['providerId'];
                String storeName = chat['providerId'];
                String storeId = chat['storeId']?.toString() ?? '';
                if (providerDataJson != null) {
                  final providerData =
                      Map<String, dynamic>.from(jsonDecode(providerDataJson));
                  providerName = providerData['username']?.toString() ??
                      providerData['shopName']?.toString() ??
                      chat['providerId'];
                  chat['providerName'] = providerName;
                }
                if (requestDataJson != null) {
                  final requestData =
                      Map<String, dynamic>.from(jsonDecode(requestDataJson));
                  storeName = requestData['storeName']?.toString() ??
                      requestData['userName']?.toString() ??
                      chat['providerId'];
                  storeId = requestData['storeId']?.toString() ?? '';
                  chat['storeName'] = storeName;
                  chat['storeId'] = storeId;
                }
                if (storeDataJson != null && storeName == chat['providerId']) {
                  final storeData =
                      Map<String, dynamic>.from(jsonDecode(storeDataJson));
                  storeName =
                      storeData['storeName']?.toString() ?? chat['providerId'];
                  chat['storeName'] = storeName;
                }
                chat['displayName'] = storeName != chat['providerId']
                    ? storeName
                    : providerName != chat['providerId']
                        ? providerName
                        : chat['providerId'];
              }
              _filteredProviders = _chatProviders;
              _unreadCount = unreadCount;
              _setupStaggerAnimations();
              _staggerController.reset();
              _staggerController.forward();
              debugPrint(
                  "Loaded ${_chatProviders.length} chats from cache: $_chatIds");
            });
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint("Error loading offline chats: $e\n$stackTrace");
      await _prefs?.remove('chat_$userId');
    }
  }

  Future<void> _markChatAsRead(String chatId) async {
    if (_isDisposed || !mounted) return;
    try {
      await _chatService.markChatAsRead(chatId);
      if (mounted && !_isDisposed) {
        setState(() {
          _unreadCount = _prefs!.getInt(
                  'unreadCount_${userModelCurrentInfo?.id ?? FirebaseAuth.instance.currentUser?.uid}') ??
              0;
          _chatProviders = _chatProviders.map((chat) {
            if (chat['chatId'] == chatId) {
              return {...chat, 'unread': false};
            }
            return chat;
          }).toList();
          _filteredProviders = _filteredProviders.map((chat) {
            if (chat['chatId'] == chatId) {
              return {...chat, 'unread': false};
            }
            return chat;
          }).toList();
          _prefs!.setString(
              'chat_${userModelCurrentInfo?.id ?? FirebaseAuth.instance.currentUser?.uid}',
              jsonEncode(_chatProviders));
          debugPrint(
              "Marked chat as read: chatId=$chatId, unreadCount=$_unreadCount");
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error marking chat as read: $e\n$stackTrace");
    }
  }

  Future<void> _navigateToChat(Map<String, dynamic> provider) async {
    if (_isDisposed || !mounted) return;
    final now = DateTime.now();
    if (_lastNavigationTime != null &&
        now.difference(_lastNavigationTime!).inMilliseconds < 1000) {
      debugPrint('Navigation debounced for chatId: ${provider['chatId']}');
      return;
    }
    _lastNavigationTime = now;
    HapticFeedback.lightImpact();

    try {
      await _markChatAsRead(provider['chatId']);
      final currentUserId =
          userModelCurrentInfo?.id ?? FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        debugPrint('No user logged in, cannot navigate to chat');
        return;
      }
      if (_isOfflineMode) {
        debugPrint(
            'Cannot navigate to chat in offline mode: chatId=${provider['chatId']}');
        return;
      }

      String currentName = userModelCurrentInfo?.first ?? 'User';
      try {
        final currentRef = FirebaseDatabase.instance
            .ref()
            .child('auth_user')
            .child(currentUserId);
        final currentSnapshot = await currentRef
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint(
              'Timeout fetching current user data for userId: $currentUserId');
          return DataSnapshotMock();
        });
        if (currentSnapshot.exists && currentSnapshot.value is Map) {
          final currentData =
              Map<String, dynamic>.from(currentSnapshot.value as Map);
          currentName = currentData['name']?.toString() ?? 'User';
          await _prefs?.setString(
              'user_$currentUserId', jsonEncode(currentData));
        }
      } catch (e, stackTrace) {
        debugPrint('Error fetching current user data: $e\n$stackTrace');
      }

      final chatId = provider['chatId']?.toString() ?? '';
      final providerId = provider['providerId']?.toString() ?? '';
      final displayName = provider['displayName']?.toString() ?? providerId;
      final serviceType = provider['serviceType']?.toString() ?? 'unknown';
      final requestId = provider['requestId']?.toString() ?? '';
      final storeName = provider['storeName']?.toString() ?? providerId;
      final storeId = provider['storeId']?.toString() ?? '';

      if (chatId.isEmpty || providerId.isEmpty) {
        debugPrint(
            'Invalid chatId or providerId: chatId=$chatId, providerId=$providerId');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chat(
            chatId: chatId,
            userId: currentUserId,
            userName: currentName,
            providerId: providerId,
            providerName: displayName,
            serviceType: serviceType,
            requestId: requestId.isNotEmpty ? requestId : null,
            storeId: storeId.isNotEmpty ? storeId : null,
            storeName: storeName != providerId ? storeName : null,
          ),
        ),
      );
      debugPrint(
          'Navigated to ChatScreen: chatId=$chatId, userId=$currentUserId, providerId=$providerId, displayName=$displayName, storeId=$storeId');
    } catch (e, stackTrace) {
      debugPrint(
          "Error navigating to chat for chatId: ${provider['chatId']}: $e\n$stackTrace");
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final response = await http
          .get(Uri.parse('https://dns.google.com/resolve?name=google.com'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Internet access check failed: $e");
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
    setState(() => _isOfflineMode = !isConnected);
    final userId =
        userModelCurrentInfo?.id ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('No user logged in, loading offline chats');
      _loadOfflineChats(null);
      return;
    }
    _chatService = ChatService(_prefs!, userId, context);
    if (!_isOfflineMode) {
      _fetchChatProviders(userId);
      _listenForNewChats(userId);
    } else {
      _loadOfflineChats(userId);
    }
  }

  void _filterChats(String query) {
    if (_isDisposed || !mounted) return;
    setState(() {
      _filteredProviders = _chatProviders.where((provider) {
        final displayName =
            provider['displayName']?.toString().toLowerCase() ?? '';
        final serviceType =
            provider['serviceType']?.toString().toLowerCase() ?? '';
        return displayName.contains(query.toLowerCase()) ||
            serviceType.contains(query.toLowerCase());
      }).toList();
      _setupStaggerAnimations();
      _staggerController.reset();
      _staggerController.forward();
    });
  }

  Widget _buildShimmerChatItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: paddingMedium, vertical: paddingSmall),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(paddingMedium),
          leading: CircleAvatar(radius: 24, backgroundColor: Colors.grey[200]),
          title: Container(height: 16, width: 150, color: Colors.grey[200]),
          subtitle: Container(height: 12, width: 100, color: Colors.grey[200]),
        ),
      ),
    );
  }

  AppLocalizations get lang {
    return AppLocalizations.of(context) ?? AppLocalizationsEn();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = lang.localeName == 'ar' || lang.localeName == 'kab';
    return Scaffold(
      backgroundColor: kBackground?.withOpacity(0.95) ?? Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          HapticFeedback.lightImpact();
          setState(() => _isLoading = true);
          final connectivity = await Connectivity().checkConnectivity();
          final hasInternet = await _hasInternetAccess();
          _handleConnectivityResult(connectivity, hasInternet);
        },
        backgroundColor: kPrimaryColor ?? Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: lang.refresh,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(paddingMedium),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: lang.search,
                  hintStyle: GoogleFonts.poppins(
                    color: kTextSecondary?.withOpacity(0.6) ?? Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search,
                      color: kTextSecondary ?? Colors.grey[600]),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: paddingMedium, horizontal: paddingMedium),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: kTextPrimary ?? Colors.black87,
                ),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                onChanged: _filterChats,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(paddingMedium),
                    itemCount: 5,
                    itemBuilder: (context, index) => _buildShimmerChatItem(),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _filteredProviders.isEmpty
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
                                const SizedBox(height: paddingMedium),
                                Text(
                                  _isOfflineMode
                                      ? lang.no_chats_found
                                      : lang.no_chats_available,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: kTextSecondary?.withOpacity(0.7) ??
                                        Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textDirection: isRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(paddingMedium),
                            itemCount: _filteredProviders.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isLoadingMore &&
                                  index == _filteredProviders.length) {
                                return _buildShimmerChatItem();
                              }
                              if (index >= _staggerAnimations.length) {
                                _setupStaggerAnimations();
                              }
                              final provider = _filteredProviders[index];
                              final serviceType =
                                  provider['serviceType']?.toString() ??
                                      'unknown';
                              return FadeTransition(
                                opacity: _staggerAnimations[index],
                                child: GestureDetector(
                                  onTap: () => _navigateToChat(provider),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: paddingSmall),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      borderRadius:
                                          BorderRadius.circular(borderRadius),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.all(paddingMedium),
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            (kPrimaryColor ?? Colors.blue)
                                                .withOpacity(0.1),
                                        radius: 24,
                                        child: Icon(
                                          ChatUtils.getServiceIcon(serviceType),
                                          color: kPrimaryColor ?? Colors.blue,
                                          size: 28,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              provider['displayName']
                                                      ?.toString() ??
                                                  provider['providerId'],
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: kTextPrimary ??
                                                    Colors.black87,
                                              ),
                                              textDirection: isRtl
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                            ),
                                          ),
                                          if (provider['unread'] == true)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: kError ?? Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                lang.new_message_title,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${lang.service}: ${ChatUtils.getLocalizedServiceTitle(lang, serviceType)}',
                                            style: GoogleFonts.poppins(
                                              color: kTextSecondary
                                                      ?.withOpacity(0.7) ??
                                                  Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            textDirection: isRtl
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                          if (provider['lastMessage'] != null)
                                            Text(
                                              provider['lastMessage'].length >
                                                      40
                                                  ? '${provider['lastMessage'].substring(0, 37)}...'
                                                  : provider['lastMessage'],
                                              style: GoogleFonts.poppins(
                                                color: kTextSecondary
                                                        ?.withOpacity(0.7) ??
                                                    Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textDirection: isRtl
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                            ),
                                          Text(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                    provider['lastTimestamp'] ??
                                                        0)
                                                .toString()
                                                .substring(0, 16),
                                            style: GoogleFonts.poppins(
                                              color: kTextSecondary
                                                      ?.withOpacity(0.7) ??
                                                  Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                            textDirection: isRtl
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    _chatSubscription?.cancel();
    NotificationService().onChatOpened = null;
    _fadeController.dispose();
    _staggerController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    debugPrint('ChatsScreen disposed');
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
