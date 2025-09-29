import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/globel/var_glob.dart';
import 'package:rana_jayeen/infoHandller/app_info.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/l10n/app_localizations_en.dart';
import 'package:rana_jayeen/models/direction.dart';
import 'package:rana_jayeen/notif/NotificationService.dart';
import 'package:rana_jayeen/notif/chats.dart';
import 'package:rana_jayeen/notif/chat_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

const double paddingSmall = 8.0;
const double paddingMedium = 16.0;
const double paddingLarge = 24.0;
const double borderRadius = 24.0;
const double chatButtonSize = 52.0;
const double bottomSheetMinHeight = 0.1;
const double bottomSheetInitialHeight = 0.4;
const double bottomSheetMaxHeight = 0.95;

class DynamicServicePage extends StatefulWidget {
  final String serviceType;
  final String serviceTitle;
  final String? serviceImage;

  const DynamicServicePage({
    super.key,
    required this.serviceType,
    required this.serviceTitle,
    this.serviceImage,
  });

  @override
  State<DynamicServicePage> createState() => _DynamicServicePageState();
}

class _DynamicServicePageState extends State<DynamicServicePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _userLocation;
  String _currentAddress = "Loading...";
  final ValueNotifier<Set<Marker>> _markersNotifier =
      ValueNotifier<Set<Marker>>({});
  static BitmapDescriptor? _cachedUserMarkerIcon;
  static BitmapDescriptor? _cachedStoreMarkerIcon;
  static BitmapDescriptor? _cachedGasStationMarkerIcon;
  final ValueNotifier<List<Map<String, dynamic>>> _nearbyStoresNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  List<Map<String, dynamic>> _offlineStoreData = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  String? _currentRequestId;
  StreamSubscription<DatabaseEvent>? _requestStatusSubscription;
  StreamSubscription<DatabaseEvent>? _chatMessageSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isLoading = false;
  bool _isOfflineMode = false;
  bool _hasSentAcceptanceNotification = false;
  Map<String, dynamic>? _selectedStore;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _lottieController;
  late Animation<double> _lottieFadeAnimation;
  late AnimationController _modalAnimationController;
  late Animation<double> _modalFadeAnimation;
  late Animation<Offset> _modalSlideAnimation;
  SharedPreferences? _prefs;
  Timer? _debounceTimer;
  Offset _chatButtonPosition = const Offset(20, 100);
  bool _isDraggingChatButton = false;
  bool _isInitialized = false;
  bool _isFetchingStores = false;
  int _lastCacheTimestamp = 0;
  static const int _cacheValidityDuration = 3600000;
  bool _isBottomSheetVisible = true;
  int _connectionRetryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  bool _isCameraMoving = false;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(36.7538, 3.0588),
    zoom: 14.0,
  );

  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _secondaryColor = const Color(0xFF64B5F6);
  final Color _errorColor = const Color(0xFFE57373);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _textPrimaryColor = const Color(0xFF212121);
  final Color _textSecondaryColor = const Color(0xFF757575);
  final Color _surfaceColor = Colors.white;

  AppLocalizations get lang =>
      AppLocalizations.of(context) ?? AppLocalizationsEn();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isInitialized && mounted) {
        await _initializeApp();
      }
    });
    _nearbyStoresNotifier.addListener(() {
      if (mounted) {
        _updateStoreMarkers();
      }
    });
  }

  void _initializeAnimations() {
    try {
      _animationController = AnimationController(
        vsync: this,
        duration: kAnimationDuration ?? const Duration(milliseconds: 300),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutCubic),
      );
      _lottieController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      );
      _lottieFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _lottieController, curve: Curves.easeInOut),
      );
      _modalAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _modalFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _modalAnimationController, curve: Curves.easeOutCubic),
      );
      _modalSlideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
            parent: _modalAnimationController, curve: Curves.easeOutCubic),
      );
      if (mounted) {
        _animationController.forward();
        _lottieController.repeat();
      }
    } catch (e, stackTrace) {
      debugPrint("Error initializing animations: $e\n$stackTrace");
    }
  }

  Future<void> _initializeApp() async {
    if (_isInitialized || !mounted) return;
    _isInitialized = true;
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        NotificationService().initialize(context),
        _initializePreferences(),
        _createMarkerIcons(),
        _loadCachedLocation(),
      ]);
      await _checkLocationPermission();
      await _getCurrentLocation();
      await _syncStoreData();
      await _loadCachedStores();
      await _startConnectionMonitoring();
      if (!_isOfflineMode && _nearbyStoresNotifier.value.isEmpty) {
        await _fetchNearbyStores();
      }
    } catch (e, stackTrace) {
      debugPrint("Initialization error: $e\n$stackTrace");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      String? storeDataJson = _prefs!.getString('stores_${widget.serviceType}');
      String? pendingRequestsJson = _prefs!.getString('pending_requests');
      _lastCacheTimestamp =
          _prefs!.getInt('cache_timestamp_${widget.serviceType}') ?? 0;
      if (storeDataJson != null) {
        try {
          _offlineStoreData =
              List<Map<String, dynamic>>.from(jsonDecode(storeDataJson));
        } catch (e, stackTrace) {
          debugPrint("Error decoding cached store data: $e\n$stackTrace");
          _offlineStoreData = [];
        }
      }
      if (pendingRequestsJson != null) {
        try {
          _pendingRequests =
              List<Map<String, dynamic>>.from(jsonDecode(pendingRequestsJson));
        } catch (e, stackTrace) {
          debugPrint("Error decoding cached pending requests: $e\n$stackTrace");
          _pendingRequests = [];
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error initializing SharedPreferences: $e\n$stackTrace");
    }
  }

  Future<void> _loadCachedLocation() async {
    if (_prefs == null || !mounted) return;
    try {
      final lat = _prefs!.getDouble('last_user_lat');
      final lng = _prefs!.getDouble('last_user_lng');
      final address = _prefs!.getString('last_user_address');
      if (lat != null && lng != null && address != null && mounted) {
        setState(() {
          _userLocation = LatLng(lat, lng);
          _currentAddress = address;
          _currentPosition = Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        });
        await _updateUserMarker();
        await _moveMapToLocation();
      }
    } catch (e, stackTrace) {
      debugPrint("Error loading cached location: $e\n$stackTrace");
    }
  }

  Future<void> _syncStoreData() async {
    if (_isOfflineMode || !mounted) return;
    try {
      final storeRef = FirebaseDatabase.instance.ref().child("stores");
      final event = await storeRef.once().timeout(const Duration(seconds: 5));
      final storeSnapshot = event.snapshot;
      if (storeSnapshot.exists && mounted) {
        final storeData =
            Map<String, dynamic>.from(storeSnapshot.value as Map? ?? {});
        _offlineStoreData = storeData.entries.map((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          final ratings = data['ratings'] != null
              ? Map<String, dynamic>.from(data['ratings'])
              : {};
          final averageRating = ratings.isNotEmpty
              ? ratings.values.fold(0.0, (sum, rating) => sum + rating) /
                  ratings.length
              : 0.0;
          return {
            'storeId': entry.key,
            'storeName': data['storeName']?.toString() ?? lang.unknown,
            'ownerId': data['ownerId']?.toString(),
            'contact': data['contact']?.toString() ?? lang.phone_not_available,
            'latitude': data['latitude']?.toDouble() ?? 0.0,
            'longitude': data['longitude']?.toDouble() ?? 0.0,
            'address': data['address']?.toString() ?? lang.noAddressFound,
            'rating': averageRating,
            'services':
                (data['services'] as List<dynamic>?)?.cast<String>() ?? [],
            'storeLogoUrl': data['storeLogoUrl']?.toString(),
          };
        }).toList();
        await _prefs!.setString(
            'stores_${widget.serviceType}', jsonEncode(_offlineStoreData));
        _lastCacheTimestamp = DateTime.now().millisecondsSinceEpoch;
        await _prefs!.setInt(
            'cache_timestamp_${widget.serviceType}', _lastCacheTimestamp);
      }

      if (_pendingRequests.isNotEmpty && mounted) {
        for (var request in List.from(_pendingRequests)) {
          if (request['type'] == 'chat_initiation') {
            final chatId = request['chatId'];
            final userId = request['userId'];
            final providerId = request['providerId'];
            await FirebaseDatabase.instance
                .ref()
                .child('chats')
                .child(chatId)
                .update({
              'participants': {userId: true, providerId: true},
              'lastMessage': request['message'],
              'lastTimestamp': ServerValue.timestamp,
              'serviceType': widget.serviceType,
              'requestId': request['requestId'] ?? '',
            });
            await FirebaseDatabase.instance
                .ref()
                .child('messages')
                .child(chatId)
                .push()
                .set({
              'senderId': userId,
              'senderName': request['userName'] ?? lang.unknown,
              'message': request['message'],
              'timestamp': ServerValue.timestamp,
              'read': false,
            });
            await FirebaseDatabase.instance
                .ref()
                .child('userChats')
                .child(userId)
                .update({chatId: true});
            await FirebaseDatabase.instance
                .ref()
                .child('userChats')
                .child(providerId)
                .update({chatId: true});
            _pendingRequests.remove(request);
          } else if (request['type'] == 'rating') {
            await FirebaseDatabase.instance
                .ref()
                .child('stores')
                .child(request['storeId'])
                .child('ratings')
                .child(request['userId'])
                .set(request['rating']);
            _pendingRequests.remove(request);
          }
        }
        await _prefs!
            .setString('pending_requests', jsonEncode(_pendingRequests));
      }
    } catch (e, stackTrace) {
      debugPrint("Sync error: $e\n$stackTrace");
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await http
          .head(Uri.parse('https://dns.google.com/resolve?name=google.com'))
          .timeout(const Duration(seconds: 3));
      return result.statusCode == 200;
    } catch (e, stackTrace) {
      debugPrint("Internet access check failed: $e\n$stackTrace");
      return false;
    }
  }

  Future<void> _startConnectionMonitoring() async {
    _connectivitySubscription?.cancel();
    final connectivity = Connectivity();
    final initialResult = await connectivity.checkConnectivity();
    await _checkConnectivityWithRetry(initialResult);

    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen((result) async {
      if (!mounted) return;
      await _checkConnectivityWithRetry(result);
    });
  }

  Future<void> _checkConnectivityWithRetry(
      List<ConnectivityResult> result) async {
    bool isConnected = result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile);
    if (!isConnected) {
      for (int i = 0; i < _maxRetries; i++) {
        final hasInternet = await _hasInternetAccess();
        if (hasInternet) {
          isConnected = true;
          _connectionRetryCount = 0;
          break;
        }
        await Future.delayed(_retryDelay);
      }
      _connectionRetryCount = isConnected ? 0 : _connectionRetryCount + 1;
    } else {
      isConnected = await _hasInternetAccess();
      _connectionRetryCount = isConnected ? 0 : _connectionRetryCount + 1;
    }
    if (_connectionRetryCount >= _maxRetries || isConnected) {
      _handleConnectivityResult(result, isConnected);
    }
  }

  void _handleConnectivityResult(
      List<ConnectivityResult> result, bool hasInternet) {
    if (!mounted) return;
    final isConnected = (result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.mobile)) &&
        hasInternet;
    if (_isOfflineMode != !isConnected) {
      setState(() {
        _isOfflineMode = !isConnected;
      });
      if (!_isOfflineMode) {
        _syncStoreData();
        _fetchNearbyStores();
      } else {
        _loadCachedStores();
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(lang.offline_mode,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              backgroundColor: kError ?? _errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius)),
              action: SnackBarAction(
                label: lang.retry,
                textColor: Colors.white,
                onPressed: _startConnectionMonitoring,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showError(lang.location_services_disabled);
        }
        throw Exception(lang.location_services_disabled);
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showError(lang.error_location_denied);
          }
          throw Exception(lang.error_location_denied);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showError(lang.location_permission_denied_permanently);
        }
        await Geolocator.openAppSettings();
        throw Exception(lang.locationPermissionPermanentlyDenied);
      }
    } catch (e, stackTrace) {
      debugPrint("Location permission error: $e\n$stackTrace");
      if (mounted) {
        _showError(lang.error_location_denied);
      }
      throw e;
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _checkLocationPermission();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(const Duration(seconds: 15), onTimeout: () async {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          return lastPosition;
        }
        if (mounted) {
          _showError(lang.locationFetchFailed);
        }
        return Position(
          latitude: _defaultPosition.target.latitude,
          longitude: _defaultPosition.target.longitude,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      });

      if (!mounted) return;
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
                position.latitude, position.longitude)
            .timeout(const Duration(seconds: 5), onTimeout: () => []);
      } catch (e, stackTrace) {
        debugPrint("Error getting placemarks: $e\n$stackTrace");
      }
      final address = placemarks.isNotEmpty
          ? "${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.country ?? ''}"
              .trim()
          : lang.unknown;

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _userLocation = LatLng(position.latitude, position.longitude);
          _currentAddress = address.isNotEmpty ? address : lang.unknown;
          _searchController.text = _currentAddress;
        });
        try {
          Provider.of<AppInfo>(context, listen: false)
              .updatePickUpLocationAddress(
            Directions()
              ..locationLatitude = position.latitude
              ..locationLongitude = position.longitude
              ..locationName = address,
          );
        } catch (e, stackTrace) {
          debugPrint("Error updating AppInfo: $e\n$stackTrace");
        }
        await _updateUserMarker();
        await _moveMapToLocation();
        await _cacheLocation();
        if (!_isFetchingStores) {
          await _fetchNearbyStores();
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error getting current location: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          _userLocation = _defaultPosition.target;
          _currentAddress = lang.unknown;
          _searchController.text = _currentAddress;
          _currentPosition = Position(
            latitude: _defaultPosition.target.latitude,
            longitude: _defaultPosition.target.longitude,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        });
        await _updateUserMarker();
        await _moveMapToLocation();
        await _cacheLocation();
        if (!_isFetchingStores) {
          await _fetchNearbyStores();
        }
        _showError(lang.error_location_failed(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (!mounted || query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final pos = locations.first;
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _currentAddress = query;
          _searchController.text = query;
          _currentPosition = Position(
            latitude: pos.latitude,
            longitude: pos.longitude,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        });
        await _updateUserMarker();
        await _moveMapToLocation();
        await _fetchNearbyStores();
      } else {
        _showError(lang.unknown_location);
      }
    } catch (e, stackTrace) {
      debugPrint("Search location error: $e\n$stackTrace");
      _showError(lang.unknown_location);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _moveMapToLocation() async {
    if (_mapController == null ||
        _userLocation == null ||
        !mounted ||
        _isCameraMoving) return;
    _isCameraMoving = true;
    try {
      if (!_mapControllerCompleter.isCompleted) {
        await _mapControllerCompleter.future
            .timeout(const Duration(seconds: 5));
      }
      await _mapController!
          .animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _userLocation!, zoom: 16),
            ),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e, stackTrace) {
      debugPrint("Failed to move map: $e\n$stackTrace");
      if (mounted && e.toString().contains('PlatformException')) {
        try {
          await _mapController!.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _userLocation!, zoom: 16),
            ),
          );
        } catch (fallbackError, fallbackStackTrace) {
          debugPrint(
              "Fallback camera move failed: $fallbackError\n$fallbackStackTrace");
          _showError(lang.errorAddress);
        }
      }
    } finally {
      if (mounted) {
        _isCameraMoving = false;
      }
    }
  }

  Future<void> _cacheLocation() async {
    if (_prefs == null || _userLocation == null) return;
    try {
      await _prefs!.setDouble('last_user_lat', _userLocation!.latitude);
      await _prefs!.setDouble('last_user_lng', _userLocation!.longitude);
      await _prefs!.setString('last_user_address', _currentAddress);
    } catch (e, stackTrace) {
      debugPrint("Error caching location: $e\n$stackTrace");
    }
  }

  Future<void> _loadCachedStores() async {
    if (!mounted) return;
    await _initializePreferences();
    if (_offlineStoreData.isNotEmpty && mounted) {
      var stores = _offlineStoreData
          .where((store) =>
              store['services'] == null ||
              (store['services'] as List<dynamic>).contains(widget.serviceType))
          .map((store) {
        final distance = Geolocator.distanceBetween(
          _currentPosition?.latitude ?? _defaultPosition.target.latitude,
          _currentPosition?.longitude ?? _defaultPosition.target.longitude,
          store['latitude']?.toDouble() ?? 0.0,
          store['longitude']?.toDouble() ?? 0.0,
        );
        return {...store, 'distance': distance};
      }).toList();
      stores.sort((a, b) => a['distance'].compareTo(b['distance']));
      _nearbyStoresNotifier.value = stores;
      if (_nearbyStoresNotifier.value.isEmpty && mounted) {
        _showError(lang.no_stores_available);
      }
    }
  }

  Future<void> _cacheStores() async {
    if (_prefs == null || !mounted) return;
    try {
      _nearbyStoresNotifier.value
          .sort((a, b) => a['distance'].compareTo(b['distance']));
      await _prefs!.setString('stores_${widget.serviceType}',
          jsonEncode(_nearbyStoresNotifier.value));
      _lastCacheTimestamp = DateTime.now().millisecondsSinceEpoch;
      await _prefs!
          .setInt('cache_timestamp_${widget.serviceType}', _lastCacheTimestamp);
    } catch (e, stackTrace) {
      debugPrint("Error caching stores: $e\n$stackTrace");
    }
  }

  Future<void> _cachePendingRequest(Map<String, dynamic> requestData) async {
    if (_prefs == null || !mounted) return;
    try {
      _pendingRequests.add(requestData);
      await _prefs!.setString('pending_requests', jsonEncode(_pendingRequests));
    } catch (e, stackTrace) {
      debugPrint("Error caching pending request: $e\n$stackTrace");
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(
      IconData icon, Color color, double size) async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
      textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily ?? 'MaterialIcons',
          color: color,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset.zero);
      final picture = pictureRecorder.endRecording();
      final img = await picture.toImage(
          textPainter.width.toInt(), textPainter.height.toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    } catch (e, stackTrace) {
      debugPrint("Error creating custom marker: $e\n$stackTrace");
      return BitmapDescriptor.defaultMarkerWithHue(
        color == (kError ?? _errorColor)
            ? BitmapDescriptor.hueRed
            : color == (kSuccess ?? Colors.green)
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueBlue,
      );
    }
  }

  Future<void> _createMarkerIcons() async {
    if (_cachedUserMarkerIcon != null || !mounted) return;
    try {
      _cachedUserMarkerIcon = await _createCustomMarker(
          Icons.location_on, kError ?? _errorColor, 150.0);
      _cachedStoreMarkerIcon = await _createCustomMarker(
          Icons.store, kPrimaryColor ?? _primaryColor, 150.0);
      _cachedGasStationMarkerIcon = await _createCustomMarker(
          Icons.local_gas_station, kSuccess ?? Colors.green, 150.0);
    } catch (e, stackTrace) {
      debugPrint("Error creating marker icons: $e\n$stackTrace");
      _cachedUserMarkerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _cachedStoreMarkerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _cachedGasStationMarkerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<void> _fetchNearbyStores() async {
    if (_currentPosition == null || !mounted || _isFetchingStores) return;
    final lastLat =
        _prefs?.getDouble('last_user_lat') ?? _currentPosition!.latitude;
    final lastLng =
        _prefs?.getDouble('last_user_lng') ?? _currentPosition!.longitude;
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lastLat,
      lastLng,
    );
    if (!_isOfflineMode &&
        distance < 500 &&
        _nearbyStoresNotifier.value.isNotEmpty &&
        DateTime.now().millisecondsSinceEpoch - _lastCacheTimestamp <
            _cacheValidityDuration) {
      _isFetchingStores = false;
      return;
    }
    _isFetchingStores = true;
    setState(() => _isLoading = true);
    try {
      if (_isOfflineMode) {
        await _loadCachedStores();
      } else {
        final ref = FirebaseDatabase.instance.ref().child("stores");
        final event = await ref.once().timeout(const Duration(seconds: 5));
        final snapshot = event.snapshot;
        if (!snapshot.exists) {
          if (mounted) {
            _nearbyStoresNotifier.value = _offlineStoreData;
            _showError(lang.no_stores_available);
          }
          return;
        }
        if (mounted) {
          final storesData = Map<String, dynamic>.from(snapshot.value as Map);
          List<Map<String, dynamic>> tempStores = [];
          storesData.forEach((key, value) {
            final store = Map<String, dynamic>.from(value);
            if (store['latitude'] != null &&
                store['longitude'] != null &&
                store['services']?.contains(widget.serviceType) == true) {
              final distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                store['latitude']?.toDouble() ?? 0.0,
                store['longitude']?.toDouble() ?? 0.0,
              );
              final ratings = store['ratings'] != null
                  ? Map<String, dynamic>.from(store['ratings'])
                  : {};
              final averageRating = ratings.isNotEmpty
                  ? ratings.values.fold(0.0, (sum, rating) => sum + rating) /
                      ratings.length
                  : 0.0;
              tempStores.add({
                'storeId': key,
                'storeName': store['storeName'] ?? lang.unknown,
                'ownerId': store['ownerId'],
                'latitude': store['latitude']?.toDouble(),
                'longitude': store['longitude']?.toDouble(),
                'contact': store['contact'] ?? lang.phone_not_available,
                'distance': distance,
                'serviceType': widget.serviceType,
                'address': store['address'] ?? lang.noAddressFound,
                'rating': averageRating,
                'services':
                    (store['services'] as List<dynamic>?)?.cast<String>() ?? [],
                'storeLogoUrl': store['storeLogoUrl']?.toString(),
              });
            }
          });
          tempStores.sort((a, b) => a['distance'].compareTo(b['distance']));
          _nearbyStoresNotifier.value = tempStores;
          _offlineStoreData = _nearbyStoresNotifier.value;
          await _cacheStores();
        }
        if (mounted && _nearbyStoresNotifier.value.isEmpty) {
          _showError(lang.no_stores_available);
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching stores: $e\n$stackTrace");
      if (mounted) {
        await _loadCachedStores();
        _showError(lang.no_stores_available);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _isFetchingStores = false;
    }
  }

  Future<void> _submitRating(String storeId, double rating) async {
    if (!mounted || userModelCurrentInfo == null) return;
    final userId = userModelCurrentInfo!.id;
    try {
      final isConnected = !_isOfflineMode && await _hasInternetAccess();
      if (!isConnected) {
        await _cachePendingRequest({
          'type': 'rating',
          'storeId': storeId,
          'userId': userId,
          'rating': rating,
          'timestamp': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(lang.rating_queued,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              backgroundColor: kPrimaryColor ?? _primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius)),
              action: SnackBarAction(
                label: lang.retry,
                textColor: Colors.white,
                onPressed: _syncStoreData,
              ),
            ),
          );
        }
        return;
      }

      await FirebaseDatabase.instance
          .ref()
          .child('stores')
          .child(storeId)
          .child('ratings')
          .child(userId!)
          .set(rating);
      await _fetchNearbyStores();
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(lang.rating_submitted,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w500)),
            backgroundColor: kSuccess ?? Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius)),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Error submitting rating: $e\n$stackTrace");
      if (mounted) {
        _showError(lang.failed_to_submit_rating);
      }
    }
  }

  Future<void> _updateUserMarker() async {
    if (_userLocation == null || _cachedUserMarkerIcon == null || !mounted)
      return;
    _markersNotifier.value = {
      ..._markersNotifier.value
          .where((marker) => marker.markerId.value != "user_location"),
      Marker(
        markerId: const MarkerId("user_location"),
        position: _userLocation!,
        icon: _cachedUserMarkerIcon!,
        infoWindow: InfoWindow(title: lang.your_location),
      ),
    };
  }

  void _updateStoreMarkers() {
    if (!mounted) return;
    final BitmapDescriptor markerIcon = widget.serviceType == 'gas_station'
        ? (_cachedGasStationMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))
        : (_cachedStoreMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
    final storeMarkers = _nearbyStoresNotifier.value.where((store) {
      return store['latitude'] != null && store['longitude'] != null;
    }).map((store) {
      return Marker(
        markerId: MarkerId(store['storeId']),
        position: LatLng(
            store['latitude']!.toDouble(), store['longitude']!.toDouble()),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: store['storeName'],
          snippet:
              '${(store['distance'] / 1000).toStringAsFixed(2)} ${lang.km}\n${store['address']}',
        ),
        onTap: () {
          if (mounted) {
            setState(() => _selectedStore = store);
            _showStoreDetails(store);
          }
        },
      );
    }).toSet();
    _markersNotifier.value = {
      if (_userLocation != null && _cachedUserMarkerIcon != null)
        Marker(
          markerId: const MarkerId("user_location"),
          position: _userLocation!,
          icon: _cachedUserMarkerIcon!,
          infoWindow: InfoWindow(title: lang.your_location),
        ),
      ...storeMarkers,
    };
  }

  Future<void> _listenToChatMessages(String chatId, String userId) async {
    if (_isOfflineMode || !mounted) return;
    _chatMessageSubscription?.cancel();
    final messageRef = FirebaseDatabase.instance
        .ref()
        .child('messages')
        .child(chatId)
        .orderByChild('timestamp')
        .limitToLast(20);

    _chatMessageSubscription = messageRef.onChildAdded.listen((event) async {
      if (!mounted || event.snapshot.value == null) return;
      final messageData =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      final senderId = messageData['senderId']?.toString();
      final isRead = messageData['read'] == true;
      if (senderId != null && senderId != userId && !isRead && mounted) {
        try {
          await FirebaseDatabase.instance
              .ref()
              .child('messages')
              .child(chatId)
              .child(event.snapshot.key!)
              .update({'read': true});
        } catch (e, stackTrace) {
          debugPrint("Error marking message as read: $e\n$stackTrace");
          if (mounted) {
            //  _showError(lang.failed_to_update_message);
          }
        }
      }
    }, onError: (e, stackTrace) {
      debugPrint("Error listening to chat messages: $e\n$stackTrace");
      if (mounted) {
        _showError(lang.failed_to_load_messages);
      }
    });
  }

  Future<void> _navigateToChat() async {
    if (!mounted || _selectedStore == null) return;
    try {
      final userId = userModelCurrentInfo?.id ?? 'unknown';
      final providerId =
          _selectedStore!['ownerId'] ?? _selectedStore!['storeId'];
      final chatId = ChatUtils.getChatId(userId, providerId);
      _listenToChatMessages(chatId, userId);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chat(
            chatId: chatId,
            providerId: providerId,
            providerName: _selectedStore!['storeName'],
            userId: userId,
            userName: userModelCurrentInfo?.first ?? 'User',
            serviceType: widget.serviceType,
            requestId: _currentRequestId,
            storeId: _selectedStore!['storeId'],
            storeName: _selectedStore!['storeName'],
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint("Error navigating to chat: $e\n$stackTrace");
      if (mounted) {
        _showError(lang.failed_to_open_chat);
      }
    }
  }

  Future<void> _startChat() async {
    if (!mounted || _selectedStore == null) {
      _showError(lang.select);
      return;
    }
    setState(() => _isLoading = true);
    try {
      HapticFeedback.lightImpact();
      final isConnected = !_isOfflineMode && await _hasInternetAccess();
      final userId = userModelCurrentInfo?.id ?? 'unknown';
      final providerId =
          _selectedStore!['ownerId'] ?? _selectedStore!['storeId'];
      final chatId = ChatUtils.getChatId(userId, providerId);
      final message = _messageController.text.trim().isEmpty
          ? lang.chat_initiated(widget.serviceTitle)
          : _messageController.text.trim();

      if (!isConnected) {
        await _cachePendingRequest({
          'chatId': chatId,
          'userId': userId,
          'providerId': providerId,
          'userName': userModelCurrentInfo?.first ?? 'User',
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'chat_initiation',
          'requestId': _currentRequestId ?? '',
        });
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(lang.chat_queued,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              backgroundColor: kPrimaryColor ?? _primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius)),
              action: SnackBarAction(
                label: lang.retry,
                textColor: Colors.white,
                onPressed: _syncStoreData,
              ),
            ),
          );
          _messageController.clear();
          await _navigateToChat();
        }
        return;
      }

      final chatRef =
          FirebaseDatabase.instance.ref().child('chats').child(chatId);
      await chatRef.update({
        'participants': {userId: true, providerId: true},
        'lastMessage': message,
        'lastTimestamp': ServerValue.timestamp,
        'serviceType': widget.serviceType,
        'requestId': _currentRequestId ?? '',
      });

      final messageRef = FirebaseDatabase.instance
          .ref()
          .child('messages')
          .child(chatId)
          .push();
      await messageRef.set({
        'senderId': userId,
        'senderName': userModelCurrentInfo?.first ?? 'User',
        'message': message,
        'timestamp': ServerValue.timestamp,
        'read': false,
      });

      await FirebaseDatabase.instance
          .ref()
          .child('userChats')
          .child(userId)
          .update({chatId: true});
      await FirebaseDatabase.instance
          .ref()
          .child('userChats')
          .child(providerId)
          .update({chatId: true});

      if (mounted) {
        _messageController.clear();
        await _navigateToChat();
      }
    } catch (e, stackTrace) {
      debugPrint("Error starting chat: $e\n$stackTrace");
      if (mounted) {
        _showError(lang.failed_to_start_chat);
        await _navigateToChat();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStoreDetails(Map<String, dynamic> store) {
    if (!mounted) return;
    _messageController.clear();
    _bottomSheetController.animateTo(
      bottomSheetMinHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    _modalAnimationController.forward(from: 0.0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        final isRtl = lang.localeName == 'ar' || lang.localeName == 'kab';
        final screenWidth = MediaQuery.of(context).size.width;
        final fontScale = screenWidth < 360 ? 0.9 : 1.0;

        return SlideTransition(
          position: _modalSlideAnimation,
          child: FadeTransition(
            opacity: _modalFadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(paddingMedium),
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(borderRadius)),
                            image: DecorationImage(
                              image: store['storeLogoUrl'] != null
                                  ? CachedNetworkImageProvider(
                                      store['storeLogoUrl'] as String)
                                  : const AssetImage(
                                      'assets/images/store_placeholder.png',
                                    ) as ImageProvider,
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.2),
                                  BlendMode.darken),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: paddingMedium,
                                right: paddingMedium,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 28 * fontScale,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  tooltip: lang.close,
                                ),
                              ),
                              Positioned(
                                bottom: paddingMedium,
                                left: paddingMedium,
                                child: Text(
                                  store['storeName'] ?? lang.unknown,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24 * fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  textDirection: isRtl
                                      ? ui.TextDirection.rtl
                                      : ui.TextDirection.ltr,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(paddingLarge * fontScale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8 * fontScale,
                                runSpacing: 4,
                                textDirection: isRtl
                                    ? ui.TextDirection.rtl
                                    : ui.TextDirection.ltr,
                                children: [
                                  RatingBar.builder(
                                    initialRating: store['rating'] ?? 0.0,
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemSize: 20 * fontScale,
                                    itemPadding: EdgeInsets.symmetric(
                                        horizontal: 2.0 * fontScale),
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (rating) {
                                      _submitRating(store['storeId'], rating);
                                    },
                                  ),
                                  Text(
                                    store['rating'] == 0.0
                                        ? lang.no_ratings
                                        : store['rating'].toStringAsFixed(1),
                                    style: GoogleFonts.poppins(
                                        fontSize: 12 * fontScale,
                                        fontWeight: FontWeight.w300,
                                        color: kTextPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6 * fontScale,
                                      vertical: 2 * fontScale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (kSuccess ?? Colors.green)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6 * fontScale),
                                    ),
                                    child: Text(
                                      '${(store['distance'] / 1000).toStringAsFixed(2)} ${lang.km}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12 * fontScale,
                                        color: kSuccess ?? Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textDirection: isRtl
                                          ? ui.TextDirection.rtl
                                          : ui.TextDirection.ltr,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: paddingMedium * fontScale),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: isRtl
                                    ? ui.TextDirection.rtl
                                    : ui.TextDirection.ltr,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: kPrimaryColor ?? _primaryColor,
                                    size: 20 * fontScale,
                                  ),
                                  SizedBox(width: 6 * fontScale),
                                  Expanded(
                                    child: Text(
                                      store['address'] ?? lang.noAddressFound,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14 * fontScale,
                                        color: kTextSecondary ??
                                            _textSecondaryColor,
                                        height: 1.5,
                                      ),
                                      textDirection: isRtl
                                          ? ui.TextDirection.rtl
                                          : ui.TextDirection.ltr,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: paddingSmall * fontScale),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: isRtl
                                    ? ui.TextDirection.rtl
                                    : ui.TextDirection.ltr,
                                children: [
                                  Icon(
                                    Icons.build_outlined,
                                    color: kPrimaryColor ?? _primaryColor,
                                    size: 20 * fontScale,
                                  ),
                                  SizedBox(width: 6 * fontScale),
                                  Expanded(
                                    child: Text(
                                      '${lang.services}: ${(store['services'] as List<dynamic>?)?.join(', ') ?? widget.serviceType}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14 * fontScale,
                                        color: kTextSecondary ??
                                            _textSecondaryColor,
                                        height: 1.5,
                                      ),
                                      textDirection: isRtl
                                          ? ui.TextDirection.rtl
                                          : ui.TextDirection.ltr,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: paddingSmall * fontScale),
                              /*     Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: isRtl
                                    ? ui.TextDirection.rtl
                                    : ui.TextDirection.ltr,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    color: kPrimaryColor ?? _primaryColor,
                                    size: 20 * fontScale,
                                  ),
                                  SizedBox(width: 6 * fontScale),
                                  Expanded(
                                    child: Text(
                                      store['contact'] ??
                                          lang.phone_not_available,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14 * fontScale,
                                        color: kTextSecondary ??
                                            _textSecondaryColor,
                                        height: 1.5,
                                      ),
                                      textDirection: isRtl
                                          ? ui.TextDirection.rtl
                                          : ui.TextDirection.ltr,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),*/
                              SizedBox(height: paddingLarge * fontScale),
                              Semantics(
                                label: lang.enterText,
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: lang.enterText,
                                    hintStyle: GoogleFonts.poppins(
                                      color: kTextSecondary?.withOpacity(0.5) ??
                                          _textSecondaryColor.withOpacity(0.5),
                                      fontSize: 14 * fontScale,
                                    ),
                                    filled: true,
                                    fillColor: _surfaceColor.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          borderRadius * fontScale),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: paddingMedium * fontScale,
                                      vertical: paddingMedium * fontScale,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.message_outlined,
                                      color: kPrimaryColor ?? _primaryColor,
                                      size: 20 * fontScale,
                                    ),
                                  ),
                                  maxLines: 3,
                                  textDirection: isRtl
                                      ? ui.TextDirection.rtl
                                      : ui.TextDirection.ltr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14 * fontScale,
                                    color: kTextPrimary ?? _textPrimaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(height: paddingLarge * fontScale),
                              SizedBox(
                                width: double.infinity,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.95, end: 1.0)
                                      .animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: kPrimaryGradientColor ??
                                          LinearGradient(
                                            colors: [
                                              _primaryColor,
                                              _secondaryColor
                                            ],
                                          ),
                                      borderRadius: BorderRadius.circular(
                                          borderRadius * fontScale),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              setState(
                                                  () => _selectedStore = store);
                                              _startChat();
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              borderRadius * fontScale),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: paddingMedium * fontScale,
                                        ),
                                      ),
                                      child: _isLoading
                                          ? CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      kPrimaryColor ??
                                                          _primaryColor),
                                            )
                                          : Text(
                                              lang.send,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16 * fontScale,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                              textDirection: isRtl
                                                  ? ui.TextDirection.rtl
                                                  : ui.TextDirection.ltr,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        _modalAnimationController.reverse();
      }
    });
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: kError ?? _errorColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            action: SnackBarAction(
              label: lang.retry,
              textColor: Colors.white,
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    });
  }

  void _debounceCameraUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (mounted && _userLocation != null && !_isFetchingStores) {
        await _moveMapToLocation();
        await _fetchNearbyStores();
      }
    });
  }

  Widget _buildLoadingIndicator({double? size}) {
    return FadeTransition(
      opacity: _lottieFadeAnimation,
      child: Lottie.asset(
        'assets/images/BU7EikdAtg.json',
        width: size ?? 48,
        height: size ?? 48,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildSkeletonScreen() {
    final isRtl = lang.localeName == 'ar';
    return Stack(
      children: [
        ValueListenableBuilder<Set<Marker>>(
          valueListenable: _markersNotifier,
          builder: (context, markers, _) => GoogleMap(
            initialCameraPosition: _userLocation != null
                ? CameraPosition(
                    target: _userLocation!,
                    zoom: 16,
                  )
                : _defaultPosition,
            myLocationEnabled: _currentPosition != null,
            myLocationButtonEnabled: true,
            markers: markers,
            onMapCreated: (controller) async {
              if (!_mapControllerCompleter.isCompleted && mounted) {
                _mapController = controller;
                _mapControllerCompleter.complete(controller);
                try {
                  await controller.setMapStyle(null);
                } catch (e, stackTrace) {
                  debugPrint("Error setting map style: $e\n$stackTrace");
                }
                if (_userLocation != null) {
                  await _moveMapToLocation();
                } else {
                  await _getCurrentLocation();
                }
              }
            },
            onCameraMove: (position) {
              if (!_isLoading && !_isDraggingChatButton && mounted) {
                _userLocation = position.target;
                _debounceCameraUpdate();
              }
            },
            liteModeEnabled: false,
          ),
        ),
        Positioned(
          top: paddingLarge,
          left: paddingMedium,
          right: paddingMedium,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Semantics(
                    label: lang.search_location,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _currentAddress,
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          color: kTextSecondary?.withOpacity(0.6) ??
                              _textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: kPrimaryColor ?? _primaryColor,
                          size: 24,
                        ),
                        suffixIcon: _isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(paddingSmall),
                                child: _buildLoadingIndicator(size: 24),
                              )
                            : IconButton(
                                icon: Icon(
                                  Icons.my_location,
                                  color: kPrimaryColor ?? _primaryColor,
                                  size: 24,
                                ),
                                onPressed: _getCurrentLocation,
                                tooltip: lang.currentLocation,
                              ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: paddingMedium,
                          vertical: paddingMedium,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: kTextPrimary ?? _textPrimaryColor,
                      ),
                      textDirection:
                          isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          HapticFeedback.lightImpact();
                          _searchLocation(value);
                        }
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _debounceTimer?.cancel();
                          _debounceTimer =
                              Timer(const Duration(milliseconds: 500), () {
                            _searchLocation(value);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildBottomSheet(),
        Center(
          child: FadeTransition(
            opacity: _lottieFadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/images/BU7EikdAtg.json',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: paddingMedium),
                Text(
                  lang.loading,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: kTextPrimary ?? _textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  textDirection:
                      isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    final isRtl = lang.localeName == 'ar';
    if (!_isBottomSheetVisible) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        return DraggableScrollableSheet(
          controller: _bottomSheetController,
          initialChildSize: bottomSheetInitialHeight,
          minChildSize: bottomSheetMinHeight,
          maxChildSize: bottomSheetMaxHeight,
          snap: true,
          snapSizes: [
            bottomSheetMinHeight,
            bottomSheetInitialHeight,
            bottomSheetMaxHeight
          ],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.9),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(borderRadius)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(borderRadius)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: GestureDetector(
                          onVerticalDragUpdate: (details) {
                            _bottomSheetController.animateTo(
                              (_bottomSheetController.size -
                                      details.delta.dy / maxHeight)
                                  .clamp(bottomSheetMinHeight,
                                      bottomSheetMaxHeight),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: paddingSmall),
                            child: Center(
                              child: Container(
                                width: 48,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400]!.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        pinned: true,
                        title: Text(
                          lang.nearby_stores(widget.serviceTitle),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary ?? _textPrimaryColor,
                          ),
                          textDirection: isRtl
                              ? ui.TextDirection.rtl
                              : ui.TextDirection.ltr,
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: kTextSecondary ?? _textSecondaryColor,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() => _isBottomSheetVisible = false);
                            },
                            tooltip: lang.close,
                          ),
                        ],
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (_nearbyStoresNotifier.value.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(paddingLarge),
                                  child: Text(
                                    lang.no_stores_available,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: kTextSecondary?.withOpacity(0.7) ??
                                          _textSecondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textDirection: isRtl
                                        ? ui.TextDirection.rtl
                                        : ui.TextDirection.ltr,
                                  ),
                                ),
                              );
                            }
                            final store = _nearbyStoresNotifier.value[index];
                            return AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: GestureDetector(
                                onTap: () {
                                  if (mounted) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedStore = store);
                                    _showStoreDetails(store);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: paddingMedium,
                                    vertical: paddingSmall,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _surfaceColor.withOpacity(0.7),
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
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(borderRadius),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 5, sigmaY: 5),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(paddingMedium),
                                        leading: CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              (kPrimaryColor ?? _primaryColor)
                                                  .withOpacity(0.1),
                                          backgroundImage: store[
                                                      'storeLogoUrl'] !=
                                                  null
                                              ? CachedNetworkImageProvider(
                                                  store['storeLogoUrl']
                                                      as String)
                                              : const AssetImage(
                                                      'assets/images/store_placeholder.png')
                                                  as ImageProvider,
                                        ),
                                        title: Text(
                                          store['storeName'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: kTextPrimary ??
                                                _textPrimaryColor,
                                          ),
                                          textDirection: isRtl
                                              ? ui.TextDirection.rtl
                                              : ui.TextDirection.ltr,
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                                height: paddingSmall),
                                            Text(
                                              '${(store['distance'] / 1000).toStringAsFixed(2)} ${lang.km} • ${store['address']}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: kTextSecondary
                                                        ?.withOpacity(0.7) ??
                                                    _textSecondaryColor,
                                                height: 1.5,
                                              ),
                                              textDirection: isRtl
                                                  ? ui.TextDirection.rtl
                                                  : ui.TextDirection.ltr,
                                            ),
                                            const SizedBox(
                                                height: paddingSmall),
                                            Wrap(
                                              children: [
                                                RatingBarIndicator(
                                                  rating:
                                                      store['rating'] ?? 0.0,
                                                  itemBuilder:
                                                      (context, index) =>
                                                          const Icon(
                                                    Icons.star_rounded,
                                                    color: Colors.amber,
                                                  ),
                                                  itemCount: 5,
                                                  itemSize: 18,
                                                  direction: Axis.horizontal,
                                                ),
                                                const SizedBox(
                                                    width: paddingSmall),
                                                Text(
                                                  store['rating'] == 0.0
                                                      ? lang.no_ratings
                                                      : store['rating']
                                                          .toStringAsFixed(1),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color: kTextSecondary
                                                            ?.withOpacity(
                                                                0.7) ??
                                                        _textSecondaryColor,
                                                    fontWeight: FontWeight.w300,
                                                  ),
                                                  textDirection: isRtl
                                                      ? ui.TextDirection.rtl
                                                      : ui.TextDirection.ltr,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.all(
                                              paddingSmall),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                (kPrimaryColor ?? _primaryColor)
                                                    .withOpacity(0.1),
                                          ),
                                          child: Icon(
                                            Icons.chat_outlined,
                                            color:
                                                kPrimaryColor ?? _primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _nearbyStoresNotifier.value.isEmpty
                              ? 1
                              : _nearbyStoresNotifier.value.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatButton() {
    return Positioned(
      left: _chatButtonPosition.dx,
      top: _chatButtonPosition.dy,
      child: Draggable(
        feedback: Material(
          color: Colors.transparent,
          child: FloatingActionButton(
            onPressed: null,
            backgroundColor: (kPrimaryColor ?? _primaryColor).withOpacity(0.7),
            elevation: 8,
            child: Icon(Icons.chat_outlined, color: Colors.white, size: 28),
          ),
        ),
        childWhenDragging: Container(),
        onDragStarted: () {
          if (mounted) {
            setState(() => _isDraggingChatButton = true);
          }
        },
        onDragEnd: (details) {
          if (!mounted) return;
          final screenSize = MediaQuery.of(context).size;
          final newX = details.offset.dx.clamp(
              paddingMedium, screenSize.width - chatButtonSize - paddingMedium);
          final newY = details.offset.dy.clamp(
              paddingMedium + 60,
              screenSize.height -
                  chatButtonSize -
                  MediaQuery.of(context).padding.bottom -
                  (MediaQuery.of(context).size.height * bottomSheetMinHeight));
          setState(() {
            _chatButtonPosition = Offset(newX, newY);
            _isDraggingChatButton = false;
          });
        },
        child: FloatingActionButton(
          onPressed: _selectedStore == null ? null : _startChat,
          backgroundColor: kPrimaryColor ?? _primaryColor,
          elevation: _isDraggingChatButton ? 8 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedScale(
            scale: _isDraggingChatButton ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.chat_outlined, color: Colors.white, size: 28),
          ),
          tooltip: lang.chatNow,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isRtl = lang.localeName == 'ar';
    return Scaffold(
      key: _scaffoldMessengerKey,
      backgroundColor: kBackground?.withOpacity(0.95) ?? _backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final fontScale = constraints.maxWidth < 360 ? 0.9 : 1.0;
          return _isLoading
              ? _buildSkeletonScreen()
              : Stack(
                  children: [
                    ValueListenableBuilder<Set<Marker>>(
                      valueListenable: _markersNotifier,
                      builder: (context, markers, _) => SizedBox(
                        height: constraints.maxHeight,
                        width: constraints.maxWidth,
                        child: GoogleMap(
                          initialCameraPosition: _userLocation != null
                              ? CameraPosition(
                                  target: _userLocation!,
                                  zoom: 16,
                                )
                              : _defaultPosition,
                          myLocationEnabled: _currentPosition != null,
                          myLocationButtonEnabled: true,
                          markers: markers,
                          onMapCreated: (controller) async {
                            if (!_mapControllerCompleter.isCompleted &&
                                mounted) {
                              _mapController = controller;
                              _mapControllerCompleter.complete(controller);
                              try {
                                await controller.setMapStyle(null);
                              } catch (e, stackTrace) {
                                debugPrint(
                                    "Error setting map style: $e\n$stackTrace");
                              }
                              if (_userLocation != null) {
                                await _moveMapToLocation();
                              } else {
                                await _getCurrentLocation();
                              }
                            }
                          },
                          onCameraMove: (position) {
                            if (!_isLoading &&
                                !_isDraggingChatButton &&
                                mounted) {
                              _userLocation = position.target;
                              _debounceCameraUpdate();
                            }
                          },
                          liteModeEnabled: false,
                        ),
                      ),
                    ),
                    Positioned(
                      top: paddingLarge,
                      left: paddingMedium,
                      right: paddingMedium,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _surfaceColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Semantics(
                                label: lang.search_location,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: _currentAddress,
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 16 * fontScale,
                                      color: kTextSecondary?.withOpacity(0.6) ??
                                          _textSecondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                      color: kPrimaryColor ?? _primaryColor,
                                      size: 24 * fontScale,
                                    ),
                                    suffixIcon: _isLoading
                                        ? Padding(
                                            padding: const EdgeInsets.all(
                                                paddingSmall),
                                            child: _buildLoadingIndicator(
                                                size: 24 * fontScale),
                                          )
                                        : IconButton(
                                            icon: Icon(
                                              Icons.my_location,
                                              color: kPrimaryColor ??
                                                  _primaryColor,
                                              size: 24 * fontScale,
                                            ),
                                            onPressed: _getCurrentLocation,
                                            tooltip: lang.currentLocation,
                                          ),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: paddingMedium * fontScale,
                                      vertical: paddingMedium * fontScale,
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16 * fontScale,
                                    color: kTextPrimary ?? _textPrimaryColor,
                                  ),
                                  textDirection: isRtl
                                      ? ui.TextDirection.rtl
                                      : ui.TextDirection.ltr,
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      HapticFeedback.lightImpact();
                                      _searchLocation(value);
                                    }
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      _debounceTimer?.cancel();
                                      _debounceTimer = Timer(
                                          const Duration(milliseconds: 500),
                                          () {
                                        _searchLocation(value);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildBottomSheet(),
                    _buildChatButton(),
                  ],
                );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _lottieController.dispose();
    _modalAnimationController.dispose();
    _searchController.dispose();
    _messageController.dispose();
    _bottomSheetController.dispose();
    _requestStatusSubscription?.cancel();
    _chatMessageSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    _markersNotifier.dispose();
    _nearbyStoresNotifier.dispose();
    super.dispose();
  }
}
