import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rana_jayeen/page/home/parts/3/UserTripScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rana_jayeen/infoHandller/app_info.dart';
import 'package:rana_jayeen/models/activerdriver.dart';
import 'package:rana_jayeen/models/direction.dart';
import 'package:rana_jayeen/models/userRideRequs.dart';
import 'package:rana_jayeen/page/change_address.dart';
import 'package:rana_jayeen/page/home/parts/3/pay_fare_amount.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';

class GeoFireAssistant {
  static List<ActiveDrivers> activeNearByAvailableDriversList = [];

  static void deleteOfflineDriverFromList(String driverId) {
    activeNearByAvailableDriversList
        .removeWhere((driver) => driver.providerId == driverId);
  }

  static void updateActiveNearByDriverLocation(ActiveDrivers activeDriver) {
    int index = activeNearByAvailableDriversList
        .indexWhere((driver) => driver.providerId == activeDriver.providerId);
    if (index != -1) {
      activeNearByAvailableDriversList[index] = activeDriver;
    } else {
      activeNearByAvailableDriversList.add(activeDriver);
    }
  }
}

class DynamicServicePage extends StatefulWidget {
  static const String routeName = "/dynamic_service";
  final String? serviceType;
  final String? serviceTitle;
  final String? serviceImage;

  const DynamicServicePage({
    Key? key,
    this.serviceType,
    this.serviceTitle,
    this.serviceImage,
  }) : super(key: key);

  @override
  _DynamicServicePageState createState() => _DynamicServicePageState();
}

class _DynamicServicePageState extends State<DynamicServicePage>
    with SingleTickerProviderStateMixin {
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 14.0,
  );

  final Completer<GoogleMapController> _googleController = Completer();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _pickLocation;
  Set<Marker> _markerSet = {};
  Set<Circle> _circleSet = {};
  Set<Polyline> _polylineSet = {};
  BitmapDescriptor? _activeDriverIcon;
  BitmapDescriptor? _userLocationIcon;
  bool _activeNearDriverKeyLog = false;
  List<ActiveDrivers> _onlineNearByAvailableDriversList = [];
  StreamSubscription<DatabaseEvent>? _tripRideRequestInfoStreamSubsc;
  DatabaseReference? _referenceRideRequest;
  String _userRideRequestStatus = "";
  bool _isRequestingService = false;
  bool _isDriverAssigned = false;
  AnimationController? _animationController;
  List<Map<String, dynamic>> _driverList = [];
  String _driverRideStatus = "";
  String _driverName = "";
  String _driverPhone = "";
  String? _rideRequestId;
  String _driverJobDetails = "";
  StreamSubscription<DatabaseEvent>? _rideStatusSubscription;
  bool _isLoadingLocation = true;
  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isLoadingOfflineProviders = false;
  String _sortBy = 'distance';
  List<String> _contactedDrivers = [];
  Timer? _retryTimer;
  Timer? _connectionCheckTimer;
  StreamSubscription? _geoFireSubscription;
  Timer? _debounceTimer;
  static const int _driverResponseTimeout = 20;
  static const int _maxSearchRadius = 100;
  static const int _maxRetries = 3;
  int _currentSearchRadius = 10;
  int _connectionRetryCount = 0;
  int _locationRetryCount = 0;
  int _requestRetryCount = 0;
  int _searchRetryCount = 0;
  static const int _maxConnectionRetries = 5;
  bool _isOfflineMode = false;
  int _providersContactedCount = 0;
  List<Map<String, dynamic>> _offlineDriverData = [];
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializePreferences();
      await _restoreState();
      await _getCurrentLocation();
      await _syncDriverData();
      await _initializeGeoFireListen();
    });
    _startConnectionMonitoring();
    _initializeNotifications();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    String? driverDataJson = _prefs!.getString('offline_driver_data');
    if (driverDataJson != null) {
      _offlineDriverData =
          List<Map<String, dynamic>>.from(jsonDecode(driverDataJson));
      debugPrint('Loaded ${_offlineDriverData.length} drivers from cache');
    }
  }

  Future<void> _syncDriverData() async {
    if (_isOfflineMode) return;
    try {
      final driverRef = FirebaseDatabase.instance.ref().child("driver_users");
      final driverSnapshot = await driverRef.get();
      if (driverSnapshot.exists) {
        final driverData = driverSnapshot.value as Map<dynamic, dynamic>? ?? {};
        _offlineDriverData = driverData.entries.map((entry) {
          final data = entry.value as Map<dynamic, dynamic>;
          final location = data['location'] != null
              ? {
                  'latitude': double.tryParse(
                          data['location']['latitude'].toString()) ??
                      0.0,
                  'longitude': double.tryParse(
                          data['location']['longitude'].toString()) ??
                      0.0,
                }
              : null;
          final distance = location != null && _pickLocation != null
              ? Geolocator.distanceBetween(
                  _pickLocation!.latitude,
                  _pickLocation!.longitude,
                  location['latitude']!,
                  location['longitude']!,
                ).toInt()
              : null;
          return {
            'driverId': entry.key,
            'username': data['username']?.toString() ?? 'Unknown',
            'phone': data['phone']?.toString() ?? 'N/A',
            'jobs': (data['jobs'] as List<dynamic>?)?.cast<String>() ?? [],
            'location': location,
            'distance': distance,
          };
        }).toList();
        await _prefs!
            .setString('offline_driver_data', jsonEncode(_offlineDriverData));
        debugPrint('Synced ${_offlineDriverData.length} drivers to cache');
      }
    } catch (e) {
      debugPrint('Error syncing driver data: $e');
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_sync_driver_data ??
              "Failed to sync driver data",
          Colors.red[700]!);
    }
  }

  Future<void> _restoreState() async {
    if (_prefs == null) return;
    try {
      final double? lat = _prefs!.getDouble('last_user_lat');
      final double? lng = _prefs!.getDouble('last_user_lng');
      final String? address = _prefs!.getString('last_user_address');
      final String? status = _prefs!.getString('ride_request_status');
      final String? rideId = _prefs!.getString('ride_request_id');
      final bool isOffline = _prefs!.getBool('is_offline_mode') ?? false;
      final int? cacheTimestamp = _prefs!.getInt('cache_timestamp');

      if (cacheTimestamp != null &&
          DateTime.now().millisecondsSinceEpoch - cacheTimestamp > 3600000) {
        await _prefs!.clear();
        return;
      }

      if (lat != null && lng != null) {
        setState(() {
          _currentPosition = Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          _pickLocation = LatLng(lat, lng);
          _isLoadingLocation = false;
        });
        await _updateUserLocationMarker();
        await _moveMapToLocation();
        if (address != null) {
          final Directions userPickUpAddress = Directions()
            ..locationLatitude = lat
            ..locationLongitude = lng
            ..locationName = address;
          Provider.of<AppInfo>(context, listen: false)
              .updatePickUpLocationAddress(userPickUpAddress);
        }
      }

      setState(() {
        _isOfflineMode = isOffline;
      });

      if (status != null && rideId != null) {
        setState(() {
          _userRideRequestStatus = status;
          _rideRequestId = rideId;
          _referenceRideRequest = FirebaseDatabase.instance
              .ref()
              .child("allRideRequests")
              .child(rideId);
          _isRequestingService = status == "requested" || status == "notified";
          _isDriverAssigned = status == "accepted" || status == "ontrip";
        });
        await _listenToRideStatus();
      }
    } catch (e) {
      debugPrint("Error restoring state: $e");
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_restore_state ??
              "Failed to restore state",
          Colors.red[700]!);
    }
  }

  Future<void> _cacheState() async {
    if (_prefs == null) return;
    try {
      if (_currentPosition != null) {
        await _prefs!.setDouble('last_user_lat', _currentPosition!.latitude);
        await _prefs!.setDouble('last_user_lng', _currentPosition!.longitude);
        final address = Provider.of<AppInfo>(context, listen: false)
            .userPickUplocation
            ?.locationName;
        if (address != null) {
          await _prefs!.setString('last_user_address', address);
        }
      }
      if (_rideRequestId != null) {
        await _prefs!.setString('ride_request_id', _rideRequestId!);
        await _prefs!.setString('ride_request_status', _userRideRequestStatus);
      }
      await _prefs!.setBool('is_offline_mode', _isOfflineMode);
      await _prefs!
          .setInt('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("Error caching state: $e");
    }
  }

  Future<void> _initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('ic_notification');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && mounted) {
        _showNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['rideRequestId'] != null && mounted) {
        setState(() {
          _rideRequestId = message.data['rideRequestId'];
          _referenceRideRequest = FirebaseDatabase.instance
              .ref()
              .child("allRideRequests")
              .child(_rideRequestId!);
        });
        _listenToRideStatus();
      }
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_channel',
      'Ride Updates',
      channelDescription: 'Notifications for ride updates',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      color: Colors.teal,
    );
    const iosDetails = DarwinNotificationDetails(sound: 'notification.wav');
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Service Update',
      message.notification?.body ?? 'New update for your service request',
      notificationDetails,
      payload: message.data['rideRequestId'],
    );
  }

  Future<void> _showLocalNotification(
      String title, String body, String? payload) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_channel',
      'Ride Updates',
      channelDescription: 'Notifications for ride updates',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      color: Colors.teal,
    );
    const iosDetails = DarwinNotificationDetails(sound: 'notification.wav');
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textDirection: AppLocalizations.of(context)?.localeName == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await http
          .get(Uri.parse('https://dns.google.com/resolve?name=google.com'))
          .timeout(const Duration(seconds: 3));
      return result.statusCode == 200;
    } catch (e) {
      debugPrint("Internet access check failed: $e");
      return false;
    }
  }

  Future<void> _startConnectionMonitoring() async {
    final connectivity = Connectivity();
    final initialResult = await connectivity.checkConnectivity();
    final hasInternet = await _hasInternetAccess();
    _handleConnectivityResult(initialResult, hasInternet);

    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen((result) async {
      final hasInternet = await _hasInternetAccess();
      if (mounted) {
        _handleConnectivityResult(result, hasInternet);
      }
    });

    _connectionCheckTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      final result = await connectivity.checkConnectivity();
      final hasInternet = await _hasInternetAccess();
      if (mounted) {
        _handleConnectivityResult(result, hasInternet);
      }
    });
  }

  void _handleConnectivityResult(
      List<ConnectivityResult> result, bool hasInternet) {
    final isConnected = (result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.mobile)) &&
        hasInternet;

    if (!mounted) return;
    setState(() {
      _isOfflineMode = !isConnected;
      _driverRideStatus = isConnected
          ? (AppLocalizations.of(context)?.searching_for_driver ??
              "Searching for provider...")
          : (AppLocalizations.of(context)?.offline_mode ?? "Offline Mode");
    });
    _cacheState();

    if (!isConnected && _connectionRetryCount < _maxConnectionRetries) {
      _connectionRetryCount++;
      debugPrint("Connection issue, retry count: $_connectionRetryCount");
      _retryTimer?.cancel();
      _retryTimer =
          Timer(Duration(seconds: 2 * _connectionRetryCount), () async {
        if (mounted && _isRequestingService && !_isOfflineMode) {
          final hasInternet = await _hasInternetAccess();
          final newResult = await Connectivity().checkConnectivity();
          _handleConnectivityResult(newResult, hasInternet);
        }
      });
    } else if (!isConnected) {
      setState(() {
        _isOfflineMode = true;
        _driverRideStatus =
            AppLocalizations.of(context)?.offline_mode ?? "Offline Mode";
      });
      _cacheState();
      _displayOfflineProviders();
      _showSnackBar(
          AppLocalizations.of(context)?.offline_mode ??
              "Using cached providers. Tap 'Retry' to reconnect.",
          Colors.orange[700]!);
    } else if (isConnected && _isOfflineMode) {
      setState(() {
        _isOfflineMode = false;
        _connectionRetryCount = 0;
        _driverList.clear();
        _contactedDrivers.clear();
        _currentSearchRadius = 10;
        _providersContactedCount = 0;
        _driverRideStatus =
            AppLocalizations.of(context)?.searching_for_driver ??
                "Searching for provider...";
      });
      _cacheState();
      _syncDriverData();
      if (_isRequestingService) {
        _retrySearchWithConnection();
      }
      _showSnackBar(
          AppLocalizations.of(context)?.connection_restored ??
              "Connection restored",
          Colors.teal[600]!);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_locationRetryCount >= _maxRetries) {
      _showSnackBar(
          AppLocalizations.of(context)?.unable_to_get_location ??
              "Unable to get location. Using default location.",
          Colors.red[700]!);
      setState(() {
        _isLoadingLocation = false;
        _pickLocation = _defaultLocation.target;
      });
      await _updateUserLocationMarker();
      await _moveMapToLocation();
      await _getAddressFromLatLng();
      await _cacheState();
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationRetryCount++;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar(
            AppLocalizations.of(context)?.location_services_disabled ??
                "Please enable location services.",
            Colors.blue[700]!);
        setState(() {
          _isLoadingLocation = false;
          _pickLocation = _defaultLocation.target;
        });
        await _updateUserLocationMarker();
        await _moveMapToLocation();
        await _getAddressFromLatLng();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar(
              AppLocalizations.of(context)?.location_permission_denied ??
                  "Location permission denied.",
              Colors.blue[700]!);
          setState(() {
            _isLoadingLocation = false;
            _pickLocation = _defaultLocation.target;
          });
          await _updateUserLocationMarker();
          await _moveMapToLocation();
          await _getAddressFromLatLng();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
            AppLocalizations.of(context)?.location_permission_denied_forever ??
                "Location permission permanently denied.",
            Colors.blue[700]!);
        setState(() {
          _isLoadingLocation = false;
          _pickLocation = _defaultLocation.target;
        });
        await _updateUserLocationMarker();
        await _moveMapToLocation();
        await _getAddressFromLatLng();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _currentPosition = position;
        _pickLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _locationRetryCount = 0;
      });

      await _updateUserLocationMarker();
      await _moveMapToLocation();
      await _getAddressFromLatLng();
      await _cacheState();
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() {
        _isLoadingLocation = false;
      });
      _showSnackBar(
          AppLocalizations.of(context)?.retrying_location ??
              "Retrying location...",
          Colors.blue[700]!);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _getCurrentLocation();
      });
    }
  }

  Future<void> _updateMapTheme(GoogleMapController controller) async {
    try {
      final styleExists =
          await DefaultAssetBundle.of(context).loadStructuredData(
        'assets/map_style.json',
        (value) async => true,
      );
      if (styleExists) {
        String mapStyle = await DefaultAssetBundle.of(context)
            .loadString('assets/map_style.json');
        await controller.setMapStyle(mapStyle);
      }
    } catch (e) {
      debugPrint("Error setting map style: $e");
    }
  }

  Future<void> _moveMapToLocation() async {
    if (_mapController == null || _pickLocation == null) return;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _pickLocation!,
            zoom: 16.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error moving map: $e");
    }
  }

  Future<void> _getAddressFromLatLng() async {
    if (_pickLocation == null) return;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _pickLocation!.latitude,
        _pickLocation!.longitude,
      ).timeout(const Duration(seconds: 5));
      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();
      String address =
          "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
      if (address.trim().isEmpty)
        address = AppLocalizations.of(context)?.unknown_location ??
            "Unknown location";
      final Directions userPickUpAddress = Directions()
        ..locationLatitude = _pickLocation!.latitude
        ..locationLongitude = _pickLocation!.longitude
        ..locationName = address;
      Provider.of<AppInfo>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
      if (mounted) setState(() {});
      await _cacheState();
    } catch (e) {
      debugPrint("Error getting address: $e");
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_get_address ??
              "Failed to get address.",
          Colors.blue[700]!);
    }
  }

  Future<void> _updateUserLocationMarker() async {
    if (_pickLocation == null) return;
    try {
      if (_userLocationIcon == null) {
        final iconExists =
            await DefaultAssetBundle.of(context).loadStructuredData(
          'assets/images/user_marker.png',
          (value) async => true,
        );
        _userLocationIcon = iconExists
            ? await BitmapDescriptor.fromAssetImage(
                const ImageConfiguration(size: Size(48, 48)),
                'assets/images/user_marker.png',
              )
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
      setState(() {
        _markerSet
            .removeWhere((marker) => marker.markerId.value == "user_location");
        _markerSet.add(
          Marker(
            markerId: const MarkerId("user_location"),
            position: _pickLocation!,
            icon: _userLocationIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
                title: AppLocalizations.of(context)?.your_location ??
                    "Your Location"),
          ),
        );
      });
    } catch (e) {
      debugPrint("Error updating user marker: $e");
    }
  }

  Future<void> _initializeGeoFireListen() async {
    if (_pickLocation == null) return;
    await _geoFireSubscription?.cancel();
    try {
      await Geofire.initialize("activeDrivers");
      _geoFireSubscription = Geofire.queryAtLocation(
        _pickLocation!.latitude,
        _pickLocation!.longitude,
        _currentSearchRadius.toDouble(),
      )?.listen((map) {
        if (map == null || !mounted) return;
        var callBack = map['callBack'];
        switch (callBack) {
          case Geofire.onKeyEntered:
            ActiveDrivers activeDriver = ActiveDrivers(
              providerId: map['key'],
              locationLatitude: map['latitude'],
              locationLongitude: map['longitude'],
            );
            GeoFireAssistant.activeNearByAvailableDriversList.add(activeDriver);
            if (_activeNearDriverKeyLog && mounted) {
              setState(() {
                _onlineNearByAvailableDriversList =
                    GeoFireAssistant.activeNearByAvailableDriversList;
              });
              _displayActiveDriversOnMap();
            }
            break;
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map['key']);
            if (mounted) {
              setState(() {
                _onlineNearByAvailableDriversList =
                    GeoFireAssistant.activeNearByAvailableDriversList;
              });
              _displayActiveDriversOnMap();
            }
            break;
          case Geofire.onKeyMoved:
            GeoFireAssistant.updateActiveNearByDriverLocation(
              ActiveDrivers(
                providerId: map['key'],
                locationLatitude: map['latitude'],
                locationLongitude: map['longitude'],
              ),
            );
            if (mounted) {
              setState(() {
                _onlineNearByAvailableDriversList =
                    GeoFireAssistant.activeNearByAvailableDriversList;
              });
              _displayActiveDriversOnMap();
            }
            break;
          case Geofire.onGeoQueryReady:
            if (mounted) {
              setState(() {
                _activeNearDriverKeyLog = true;
                _onlineNearByAvailableDriversList =
                    GeoFireAssistant.activeNearByAvailableDriversList;
              });
              _displayActiveDriversOnMap();
              if (_isRequestingService) _searchNearestOnlineDrivers();
            }
            break;
        }
      });
    } catch (e) {
      debugPrint("GeoFire initialization error: $e");
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_initialize_provider_search ??
              "Failed to initialize provider search.",
          Colors.red[700]!);
    }
  }

  Future<void> _displayActiveDriversOnMap() async {
    try {
      if (_activeDriverIcon == null) {
        final iconExists =
            await DefaultAssetBundle.of(context).loadStructuredData(
          'assets/images/driver_marker.png',
          (value) async => true,
        );
        _activeDriverIcon = iconExists
            ? await BitmapDescriptor.fromAssetImage(
                const ImageConfiguration(size: Size(48, 48)),
                'assets/images/driver_marker.png',
              )
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      }
      setState(() {
        _markerSet
            .removeWhere((marker) => marker.markerId.value != "user_location");
        for (ActiveDrivers driver in _onlineNearByAvailableDriversList) {
          if (driver.locationLatitude == null ||
              driver.locationLongitude == null) continue;
          LatLng driverPosition =
              LatLng(driver.locationLatitude!, driver.locationLongitude!);
          _markerSet.add(
            Marker(
              markerId: MarkerId(driver.providerId!),
              position: driverPosition,
              icon: _activeDriverIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(
                  title:
                      "${AppLocalizations.of(context)?.provider ?? "Provider"} ${driver.providerId}"),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("Error displaying drivers: $e");
    }
  }

  Future<void> _searchNearestOnlineDrivers() async {
    if (!_isRequestingService || _isDriverAssigned || _isOfflineMode) return;

    if (_searchRetryCount >= _maxRetries) {
      setState(() {
        _isRequestingService = false;
        _driverRideStatus = "";
      });
      _showSnackBar(
          AppLocalizations.of(context)?.no_providers_found ??
              "No providers found after max retries.",
          Colors.red[700]!);
      return;
    }

    if (_onlineNearByAvailableDriversList.isEmpty) {
      if (_currentSearchRadius < _maxSearchRadius) {
        setState(() {
          _currentSearchRadius += 10;
          _driverRideStatus =
              "${AppLocalizations.of(context)?.expanding_search ?? "Expanding search radius to"} ${_currentSearchRadius}km...";
          _searchRetryCount++;
        });
        await _initializeGeoFireListen();
      } else {
        setState(() {
          _contactedDrivers.clear();
          _currentSearchRadius = 10;
          _providersContactedCount = 0;
          _driverRideStatus =
              "${AppLocalizations.of(context)?.search_continued ?? "Continuing search for providers..."}";
          _searchRetryCount++;
        });
        _showSnackBar(
            AppLocalizations.of(context)?.no_providers_found_searching ??
                "No providers found. Continuing search...",
            Colors.teal[600]!);
        await _initializeGeoFireListen();
      }
      return;
    }

    List<ActiveDrivers> availableDrivers = [];
    for (var driver in _onlineNearByAvailableDriversList) {
      if (_contactedDrivers.contains(driver.providerId)) continue;

      final driverRef = FirebaseDatabase.instance
          .ref()
          .child("driver_users")
          .child(driver.providerId!);
      final driverSnapshot = await driverRef.get();
      if (!driverSnapshot.exists) continue;

      final driverData = driverSnapshot.value as Map<dynamic, dynamic>? ?? {};
      final driverJobs =
          (driverData['jobs'] as List<dynamic>?)?.cast<String>() ?? [];
      final isOnline = driverData['isOnline'] == true;

      if (isOnline &&
          (driverJobs.isEmpty || driverJobs.contains(widget.serviceType))) {
        availableDrivers.add(driver);
      }
    }

    availableDrivers.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(
        _pickLocation!.latitude,
        _pickLocation!.longitude,
        a.locationLatitude!,
        a.locationLongitude!,
      );
      double distanceB = Geolocator.distanceBetween(
        _pickLocation!.latitude,
        _pickLocation!.longitude,
        b.locationLatitude!,
        b.locationLongitude!,
      );
      return distanceA.compareTo(distanceB);
    });

    if (availableDrivers.isEmpty) {
      if (_currentSearchRadius < _maxSearchRadius) {
        setState(() {
          _currentSearchRadius += 10;
          _driverRideStatus =
              "${AppLocalizations.of(context)?.expanding_search ?? "Expanding search radius to"} ${_currentSearchRadius}km...";
          _searchRetryCount++;
        });
        await _initializeGeoFireListen();
      } else {
        setState(() {
          _contactedDrivers.clear();
          _currentSearchRadius = 10;
          _providersContactedCount = 0;
          _driverRideStatus =
              "${AppLocalizations.of(context)?.search_continued ?? "Continuing search for providers..."}";
          _searchRetryCount++;
        });
        _showSnackBar(
            AppLocalizations.of(context)?.no_providers_found_searching ??
                "No providers found. Continuing search...",
            Colors.teal[600]!);
        await _initializeGeoFireListen();
      }
      return;
    }

    final driverToContact = availableDrivers.first;
    _contactedDrivers.add(driverToContact.providerId!);
    _providersContactedCount++;

    setState(() {
      _driverRideStatus =
          "${AppLocalizations.of(context)?.contactProvider ?? "Contacting"} ${_providersContactedCount} ${AppLocalizations.of(context)?.providers ?? "providers"}...";
    });

    await _sendRequestToDriver(driverToContact.providerId!);

    if (_referenceRideRequest != null) {
      Timer(const Duration(seconds: _driverResponseTimeout), () async {
        if (mounted && _isRequestingService && !_isDriverAssigned) {
          final requestSnapshot = await _referenceRideRequest!.get();
          if (requestSnapshot.exists) {
            final data = requestSnapshot.value as Map<dynamic, dynamic>? ?? {};
            final status = data['status'] as String?;
            if (status == 'notified' || status == 'requested') {
              await _referenceRideRequest!.update({
                'status': 'timeout',
                'timeoutAt': DateTime.now().toIso8601String(),
              });
              _showSnackBar(
                  AppLocalizations.of(context)?.providers_no_response ??
                      "Provider did not respond. Trying another provider...",
                  Colors.teal[600]!);
              await _searchNearestOnlineDrivers();
            } else if (status == 'declined') {
              _showSnackBar(
                  AppLocalizations.of(context)?.providers_declined ??
                      "Provider declined. Trying another provider...",
                  Colors.teal[600]!);
              await _searchNearestOnlineDrivers();
            }
          } else {
            setState(() {
              _isRequestingService = false;
              _driverRideStatus = "";
            });
          }
        }
      });
    }
  }

  Future<void> _sendRequestToDriver(String driverId) async {
    try {
      if (_isDriverAssigned) return;

      if (_isOfflineMode) {
        final driverData = _offlineDriverData.firstWhere(
          (driver) => driver['driverId'] == driverId,
          orElse: () => {},
        );
        if (driverData.isEmpty) {
          debugPrint("Offline driver $driverId not found");
          _showSnackBar(
              AppLocalizations.of(context)?.provider_not_found ??
                  "Provider not found in offline data",
              Colors.red[600]!);
          return;
        }

        String driverName = driverData['username']?.toString() ?? "Unknown";
        String driverPhone = driverData['phone']?.toString() ?? "N/A";
        List<String> driverJobs = driverData['jobs']?.cast<String>() ?? [];

        if (!driverJobs.isEmpty && !driverJobs.contains(widget.serviceType)) {
          debugPrint(
              "Offline driver $driverId does not offer ${widget.serviceType}");
          _showSnackBar(
              AppLocalizations.of(context)?.provider_no_service ??
                  "Provider does not offer this service",
              Colors.teal[600]!);
          return;
        }

        final rideUpdate = {
          "driverId": driverId,
          "status": "notified",
          "notifiedAt": DateTime.now().toIso8601String(),
          "rider_uid": FirebaseAuth.instance.currentUser?.uid ?? "",
          "rider_name":
              FirebaseAuth.instance.currentUser?.displayName ?? "User",
          "rider_phone":
              FirebaseAuth.instance.currentUser?.phoneNumber ?? "N/A",
          "driver_name": driverName,
          "driver_phone": driverPhone,
          "driver_job_details": driverJobs.join(", "),
        };
        await _prefs!
            .setString('ride_request_$_rideRequestId', jsonEncode(rideUpdate));
        _showSnackBar(
            "${AppLocalizations.of(context)?.request_stored ?? "Request stored for"} $driverName. ${AppLocalizations.of(context)?.contact ?? "Contact"}: $driverPhone",
            Colors.teal[600]!);
      } else {
        final driverRef = FirebaseDatabase.instance
            .ref()
            .child("driver_users")
            .child(driverId);
        final driverSnapshot = await driverRef.get();
        if (!driverSnapshot.exists) {
          debugPrint("Driver $driverId does not exist");
          return;
        }

        final driverData = driverSnapshot.value as Map<dynamic, dynamic>? ?? {};
        String? fcmToken = driverData['fcmToken']?.toString();
        String driverName = driverData['username']?.toString() ?? "Unknown";
        String driverPhone = driverData['phone']?.toString() ?? "N/A";
        List<String> driverJobs =
            (driverData['jobs'] as List<dynamic>?)?.cast<String>() ?? [];

        if (!driverJobs.isEmpty && !driverJobs.contains(widget.serviceType)) {
          debugPrint("Driver $driverId does not offer ${widget.serviceType}");
          return;
        }

        if (_referenceRideRequest != null) {
          final requestSnapshot = await _referenceRideRequest!.get();
          if (requestSnapshot.exists) {
            final data = requestSnapshot.value as Map<dynamic, dynamic>? ?? {};
            final status = data['status'] as String?;
            if (status == 'accepted' || status == 'ontrip') {
              setState(() {
                _isDriverAssigned = true;
                _isRequestingService = false;
              });
              return;
            }
          }
        }

        final rideUpdate = {
          "driverId": driverId,
          "status": "notified",
          "notifiedAt": DateTime.now().toIso8601String(),
          "rider_uid": FirebaseAuth.instance.currentUser?.uid ?? "",
          "driver_name": driverName,
          "driver_phone": driverPhone,
          "driver_job_details": driverJobs.join(", "),
        };
        await FirebaseDatabase.instance
            .ref()
            .child("allRideRequests")
            .child(_rideRequestId!)
            .update(rideUpdate);

        if (fcmToken != null && fcmToken.isNotEmpty) {
          int fcmRetryCount = 0;
          while (fcmRetryCount < _maxRetries) {
            try {
              final fcmPayload = {
                "message": {
                  "token": fcmToken,
                  "notification": {
                    "title": "${widget.serviceTitle ?? 'Service'} Request",
                    "body":
                        "${AppLocalizations.of(context)?.new_request_at ?? "New"} ${widget.serviceType ?? 'service'} ${AppLocalizations.of(context)?.request_at ?? "request at"} ${Provider.of<AppInfo>(context, listen: false).userPickUplocation?.locationName ?? 'your location'}",
                  },
                  "data": {
                    "rideRequestId": _rideRequestId ?? "",
                    "service_type": widget.serviceType ?? "",
                    "origin_address":
                        Provider.of<AppInfo>(context, listen: false)
                                .userPickUplocation
                                ?.locationName ??
                            "",
                    "latitude": _pickLocation!.latitude.toString(),
                    "longitude": _pickLocation!.longitude.toString(),
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                  },
                  "android": {
                    "priority": "high",
                    "notification": {
                      "sound": "default",
                      "channel_id": "high_importance_channel",
                    }
                  },
                  "apns": {
                    "payload": {
                      "aps": {
                        "sound": "default",
                        "badge": 1,
                      }
                    }
                  }
                }
              };

              final response = await http.post(
                Uri.parse(
                    "https://fcm.googleapis.com/v1/projects/newme-f9c0a/messages:send"),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer ${await _getAccessToken()}",
                },
                body: jsonEncode(fcmPayload),
              );

              if (response.statusCode == 200) {
                debugPrint(
                    "FCM notification sent to driver: $driverId for ride: $_rideRequestId");
                break;
              } else {
                debugPrint("FCM notification failed: ${response.body}");
                fcmRetryCount++;
                await Future.delayed(const Duration(seconds: 2));
              }
            } catch (e) {
              debugPrint("FCM error for driver $driverId: $e");
              fcmRetryCount++;
              await Future.delayed(const Duration(seconds: 2));
            }
          }
          if (fcmRetryCount >= _maxRetries) {
            _showSnackBar(
                "${AppLocalizations.of(context)?.failed_to_notify_provider ?? "Failed to notify provider"} $driverName.",
                Colors.teal[600]!);
          }
        } else {
          debugPrint("No FCM token for driver: $driverId");
          _showSnackBar(
              "${AppLocalizations.of(context)?.provider_notification_unavailable ?? "Provider"} $driverName ${AppLocalizations.of(context)?.notification_unavailable ?? "notification unavailable."}",
              Colors.teal[600]!);
        }
      }
    } catch (e) {
      debugPrint("Error sending request to driver $driverId: $e");
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_send_request ??
              "Failed to send request to provider.",
          Colors.teal[600]!);
    }
  }

  Future<String?> _getAccessToken() async {
    try {
      final serviceAccountJson = await DefaultAssetBundle.of(context)
          .loadString('assets/newme-f9c0a-038c8891ddb8.json');
      final serviceAccount = jsonDecode(serviceAccountJson);
      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccount);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final accessToken = await client.credentials.accessToken;
      if (accessToken.expiry.isAfter(DateTime.now())) {
        return accessToken.data;
      } else {
        debugPrint("Access token expired");
        return null;
      }
    } catch (e) {
      debugPrint("Error getting access token: $e");
      return null;
    }
  }

  Future<void> _saveRequestInformation() async {
    if (_requestRetryCount >= _maxRetries) {
      _showSnackBar(
          AppLocalizations.of(context)?.unable_to_create_request ??
              "Unable to create request. Please try again later.",
          Colors.red[700]!);
      setState(() {
        _isRequestingService = false;
      });
      return;
    }

    if (_pickLocation == null) {
      _showSnackBar(
          AppLocalizations.of(context)?.select_location_first ??
              "Please select a location first.",
          Colors.blue[700]!);
      setState(() {
        _isRequestingService = false;
      });
      return;
    }

    if (_isOfflineMode) {
      _showSnackBar(
          AppLocalizations.of(context)?.offline_request_not_allowed ??
              "Cannot send request in offline mode. View cached providers instead.",
          Colors.orange[700]!);
      setState(() {
        _isRequestingService = false;
      });
      return;
    }

    setState(() {
      _isRequestingService = true;
      _driverRideStatus = AppLocalizations.of(context)?.searching_for_driver ??
          "Searching for provider...";
      _requestRetryCount++;
    });

    try {
      _referenceRideRequest =
          FirebaseDatabase.instance.ref().child("allRideRequests").push();

      Map<String, dynamic> rideInfo = {
        "service_type": widget.serviceType,
        "origin_latitude": _pickLocation!.latitude,
        "origin_longitude": _pickLocation!.longitude,
        "origin_address": Provider.of<AppInfo>(context, listen: false)
            .userPickUplocation
            ?.locationName,
        "status": "requested",
        "created_at": DateTime.now().toIso8601String(),
        "rider_uid": FirebaseAuth.instance.currentUser?.uid ?? "",
        "rider_name": FirebaseAuth.instance.currentUser?.displayName ?? "User",
        "rider_phone": FirebaseAuth.instance.currentUser?.phoneNumber ?? "N/A",
      };

      await _referenceRideRequest!.set(rideInfo);
      setState(() {
        _rideRequestId = _referenceRideRequest!.key;
        _userRideRequestStatus = "requested";
        _requestRetryCount = 0;
      });
      await _cacheState();
      await _listenToRideStatus();
      await _initializeGeoFireListen();
    } catch (e) {
      setState(() {
        _isRequestingService = false;
        _driverRideStatus = "";
      });
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_create_request ??
              "Failed to create request. Retrying...",
          Colors.blue[700]!);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _saveRequestInformation();
      });
    }
  }

  Future<void> _listenToRideStatus() async {
    if (_referenceRideRequest == null) return;
    _rideStatusSubscription?.cancel();
    _rideStatusSubscription =
        _referenceRideRequest!.onValue.listen((event) async {
      if (event.snapshot.value == null || !mounted) return;
      final data =
          Map<String, dynamic>.from(event.snapshot.value as Map? ?? {});
      final status = data['status'] ?? "";
      setState(() {
        _userRideRequestStatus = status;
        _isRequestingService = status == "requested" || status == "notified";
        _isDriverAssigned = status == "accepted" || status == "ontrip";

        if (_isDriverAssigned) {
          _driverName = data['driver_name'] ?? "Unknown";
          _driverPhone = data['driver_phone'] ?? "N/A";
          _driverJobDetails = data['driver_job_details'] ?? "N/A";
          _driverRideStatus = status == "accepted"
              ? (AppLocalizations.of(context)?.provider_on_way ??
                  "Provider is on the way")
              : (AppLocalizations.of(context)?.trip_in_progress ??
                  "Service in progress");
          _contactedDrivers.clear();
        }
      });

      if (status == "accepted" && mounted) {
        final rideDetails = UserRideRequestInformation()
          ..rideRequestId = _rideRequestId
          ..username = data['rider_name'] ?? "User"
          ..userPhone = data['rider_phone'] ?? "N/A"
          ..originAddress = data['origin_address'] ?? "Unknown"
          ..job = widget.serviceType
          ..driverId = data['driverId'] ?? "unknown"
          ..originLatLng = LatLng(
            double.tryParse(data['origin_latitude'].toString()) ?? 0.0,
            double.tryParse(data['origin_longitude'].toString()) ?? 0.0,
          )
          ..status = status;

        _showLocalNotification(
          AppLocalizations.of(context)?.provider_assigned ??
              "Provider Assigned",
          "${AppLocalizations.of(context)?.provider_assigned_body ?? "Provider"} $_driverName ${AppLocalizations.of(context)?.assigned_to_request ?? "is assigned to your request!"}",
          _rideRequestId,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UserTripScreen(rideRequestDetails: rideDetails),
          ),
        );
      } else if (status == "completed" && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayFareAmount(
              rideRequestId: _rideRequestId!,
            ),
          ),
        );
      } else if (status == "cancelled" ||
          status == "ended" ||
          status == "timeout" ||
          status == "declined") {
        setState(() {
          _isRequestingService = false;
          _isDriverAssigned = false;
          _driverRideStatus = "";
          _driverName = "";
          _driverPhone = "";
          _driverJobDetails = "";
          _contactedDrivers.clear();
          _providersContactedCount = 0;
          _currentSearchRadius = 10;
        });
        _showSnackBar(
            AppLocalizations.of(context)?.ride_status_updated ??
                "Ride status updated: $status",
            Colors.blue[700]!);
        await _cacheState();
        if (status == "declined" || status == "timeout") {
          _searchNearestOnlineDrivers();
        }
      }
    }, onError: (e) {
      debugPrint("Error listening to ride status: $e");
      _showSnackBar(
          "${AppLocalizations.of(context)?.failed_to_receive_ride_updates ?? "Failed to receive ride updates"}: $e",
          Colors.red[700]!);
    });
  }

  Future<void> _displayOfflineProviders() async {
    setState(() {
      _isLoadingOfflineProviders = true;
    });
    try {
      if (_offlineDriverData.isEmpty) {
        setState(() {
          _driverList = [];
          _isLoadingOfflineProviders = false;
        });
        _showSnackBar(
            AppLocalizations.of(context)?.no_cached_providers ??
                "No cached providers available.",
            Colors.blue[700]!);
        return;
      }

      setState(() {
        _driverList = _offlineDriverData
            .where((driver) =>
                driver['jobs'] == null ||
                (driver['jobs'] as List<dynamic>).contains(widget.serviceType))
            .toList();
        if (_sortBy == 'name') {
          _driverList.sort(
              (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''));
        } else {
          _driverList.sort(
              (a, b) => (a['distance'] ?? 0).compareTo(b['distance'] ?? 0));
        }
        _isLoadingOfflineProviders = false;
      });

      await _displayActiveDriversOnMap();
    } catch (e) {
      setState(() {
        _isLoadingOfflineProviders = false;
      });
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_load_providers ??
              "Failed to load providers.",
          Colors.blue[700]!);
    }
  }

  Future<void> _showOfflineProvidersSheet() async {
    final localizations = AppLocalizations.of(context);
    final isRtl = localizations?.localeName == 'ar';
    await _displayOfflineProviders();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations?.cached_providers ?? "Cached Providers",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal[900],
                      ),
                      textDirection:
                          isRtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    if (_driverList.isNotEmpty)
                      DropdownButton<String>(
                        value: _sortBy,
                        dropdownColor: Colors.teal[600],
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        iconEnabledColor: Colors.white,
                        items: [
                          DropdownMenuItem(
                            value: 'distance',
                            child: Text(
                              localizations?.sort_by_distance ??
                                  "Sort by Distance",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text(
                              localizations?.sort_by_name ?? "Sort by Name",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null && mounted) {
                            setState(() {
                              _sortBy = value;
                              _driverList.sort((a, b) => _sortBy == 'name'
                                  ? (a['username'] ?? '')
                                      .compareTo(b['username'] ?? '')
                                  : (a['distance'] ?? 0)
                                      .compareTo(b['distance'] ?? 0));
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingOfflineProviders
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: 3,
                          itemBuilder: (context, index) => Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    : _driverList.isEmpty
                        ? Center(
                            child: Text(
                              localizations?.no_cached_providers ??
                                  "No cached providers available.",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                              textDirection:
                                  isRtl ? TextDirection.rtl : TextDirection.ltr,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _driverList.length,
                            itemBuilder: (context, index) {
                              final driver = _driverList[index];
                              final distance = driver['distance'] != null
                                  ? "${(driver['distance'] / 1000).toStringAsFixed(2)} km"
                                  : 'N/A';
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.teal[100],
                                    child: const Icon(Icons.person,
                                        color: Colors.teal, size: 28),
                                  ),
                                  title: Text(
                                    driver['username'] ?? 'Unknown',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal[900],
                                    ),
                                    textDirection: isRtl
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${localizations?.phone ?? "Phone"}: ${driver['phone'] ?? 'N/A'}",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        textDirection: isRtl
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                      ),
                                      Text(
                                        "${localizations?.distance ?? "Distance"}: $distance",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        textDirection: isRtl
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                      ),
                                      Text(
                                        "${localizations?.services ?? "Services"}: ${(driver['jobs'] as List<dynamic>?)?.join(", ") ?? 'N/A'}",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        textDirection: isRtl
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                  trailing: ScaleTransition(
                                    scale: Tween<double>(begin: 0.95, end: 1.0)
                                        .animate(
                                      CurvedAnimation(
                                        parent: _animationController!,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        backgroundColor: Colors.teal[600],
                                        foregroundColor: Colors.white,
                                        textStyle: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _makePhoneCall(driver['phone'] ?? ''),
                                      child:
                                          Text(localizations?.call ?? "Call"),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _retrySearchWithConnection() async {
    if (_searchRetryCount >= _maxRetries) {
      _showSnackBar(
          AppLocalizations.of(context)?.max_retries_reached ??
              "Max retries reached for search.",
          Colors.red[700]!);
      return;
    }

    try {
      if (_isRequestingService && !_isDriverAssigned) {
        final hasInternet = await _hasInternetAccess();
        if (hasInternet) {
          await _initializeGeoFireListen();
          await _searchNearestOnlineDrivers();
        } else {
          await _displayOfflineProviders();
        }
        _searchRetryCount++;
      }
    } catch (e) {
      debugPrint("Retry search error: $e");
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_search_providers ??
              "Failed to search for providers.",
          Colors.blue[700]!);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _retrySearchWithConnection();
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar(
            "${AppLocalizations.of(context)?.cannot_make_call ?? "Cannot make call to"} $phoneNumber",
            Colors.blue[700]!);
      }
    } catch (e) {
      debugPrint("Phone call error: $e");
      _showSnackBar(
          "${AppLocalizations.of(context)?.failed_to_make_call ?? "Failed to make call"}: $e",
          Colors.blue[700]!);
    }
  }

  Future<void> _cancelRequest() async {
    try {
      if (_referenceRideRequest != null) {
        await _referenceRideRequest!.remove();
        setState(() {
          _isRequestingService = false;
          _isDriverAssigned = false;
          _rideRequestId = null;
          _driverRideStatus = "";
          _driverName = "";
          _driverPhone = "";
          _driverJobDetails = "";
          _contactedDrivers.clear();
          _providersContactedCount = 0;
          _currentSearchRadius = 10;
          _searchRetryCount = 0;
        });
        _tripRideRequestInfoStreamSubsc?.cancel();
        _rideStatusSubscription?.cancel();
        await _cacheState();
        _showSnackBar(
            AppLocalizations.of(context)?.request_cancelled ??
                "Request cancelled.",
            Colors.teal[600]!);
      }
    } catch (e) {
      debugPrint("Error cancelling request: $e");
      _showSnackBar(
          AppLocalizations.of(context)?.failed_to_cancel_request ??
              "Failed to cancel request.",
          Colors.blue[700]!);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _cancelRequest();
      });
    }
  }

  void _debounceCameraUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (mounted && !_isRequestingService && !_isDriverAssigned) {
        await _getAddressFromLatLng();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isRtl = localizations?.localeName == 'ar';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultLocation,
            myLocationEnabled: _currentPosition != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markerSet,
            circles: _circleSet,
            polylines: _polylineSet,
            onMapCreated: (GoogleMapController controller) async {
              _googleController.complete(controller);
              _mapController = controller;
              await _updateMapTheme(controller);
              if (_pickLocation != null) {
                await _moveMapToLocation();
              } else {
                await _getCurrentLocation();
              }
            },
            onCameraMove: (position) {
              if (!_isRequestingService && !_isDriverAssigned) {
                setState(() {
                  _pickLocation = position.target;
                });
                _debounceCameraUpdate();
              }
            },
          ),
          Positioned(
            top: 48,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 20),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, size: 20),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (widget.serviceImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          widget.serviceImage!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Icon(
                        Icons.build,
                        color: Colors.teal[600],
                        size: 40,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.serviceTitle ?? 'Service',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.teal[900],
                        ),
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _isRequestingService
                  ? _buildSearchingContainer(theme, localizations, screenHeight)
                  : _isDriverAssigned
                      ? _buildDriverInfoContainer(
                          theme, localizations, screenHeight)
                      : _buildLocationContainer(
                          theme, localizations, screenHeight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContainer(
      ThemeData theme, AppLocalizations? localizations, double screenHeight) {
    final isRtl = localizations?.localeName == 'ar';
    return Container(
      key: const ValueKey('location'),
      height: screenHeight * 0.35,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[600]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoadingLocation
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.build_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.serviceTitle ?? 'Service',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textDirection:
                                  isRtl ? TextDirection.rtl : TextDirection.ltr,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isOfflineMode
                            ? (localizations?.offline_mode ?? "Offline Mode")
                            : (localizations?.yourLocation ??
                                "Select Location"),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Provider.of<AppInfo>(context)
                                .userPickUplocation
                                ?.locationName ??
                            (localizations?.fetching_location ??
                                "Fetching location..."),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ScaleTransition(
                              scale:
                                  Tween<double>(begin: 0.95, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _animationController!,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.teal[800],
                                  elevation: 2,
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChangeLocation(),
                                    ),
                                  );
                                  if (result is LatLng && mounted) {
                                    setState(() {
                                      _pickLocation = result;
                                      _currentPosition = Position(
                                        latitude: result.latitude,
                                        longitude: result.longitude,
                                        timestamp: DateTime.now(),
                                        accuracy: 10.0,
                                        altitude: 0.0,
                                        heading: 0.0,
                                        speed: 0.0,
                                        speedAccuracy: 0.0,
                                        altitudeAccuracy: 0.0,
                                        headingAccuracy: 0.0,
                                      );
                                    });
                                    await _updateUserLocationMarker();
                                    await _moveMapToLocation();
                                    await _getAddressFromLatLng();
                                    await _cacheState();
                                  }
                                },
                                child: Text(localizations?.change_location ??
                                    "Change Location"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ScaleTransition(
                              scale:
                                  Tween<double>(begin: 0.95, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _animationController!,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: _isOfflineMode
                                      ? Colors.grey[400]
                                      : Colors.teal[700],
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: _isOfflineMode ||
                                        _isRequestingService ||
                                        _isDriverAssigned
                                    ? null
                                    : () async {
                                        await _saveRequestInformation();
                                      },
                                child: _isRequestingService
                                    ? const SpinKitFadingCircle(
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : Text(localizations?.request_service ??
                                        "Request Service"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isOfflineMode) ...[
                        const SizedBox(height: 12),
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController!,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: _offlineDriverData.isNotEmpty
                                  ? Colors.teal[700]
                                  : Colors.grey[400],
                              foregroundColor: Colors.white,
                              elevation: 2,
                              textStyle: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: _offlineDriverData.isNotEmpty
                                ? _showOfflineProvidersSheet
                                : null,
                            child: Text(localizations?.view_providers ??
                                "View Cached Providers"),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingContainer(
      ThemeData theme, AppLocalizations? localizations, double screenHeight) {
    final isRtl = localizations?.localeName == 'ar';
    return Container(
      key: const ValueKey('searching'),
      height: screenHeight * 0.28,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[600]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.build_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.serviceTitle ?? 'Service',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  localizations?.findingProvider ?? "Finding a Provider",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 8),
                Text(
                  _driverRideStatus,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.6),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.teal[200]!),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController!,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        elevation: 2,
                        textStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _cancelRequest,
                      child: Text(
                          localizations?.cancel_request ?? "Cancel Request"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoContainer(
      ThemeData theme, AppLocalizations? localizations, double screenHeight) {
    final isRtl = localizations?.localeName == 'ar';
    return Container(
      key: const ValueKey('driver_info'),
      height: screenHeight * 0.35,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[600]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _driverName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _driverRideStatus,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 8),
                Text(
                  "${localizations?.phone ?? "Phone"}: $_driverPhone",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 8),
                Text(
                  "${localizations?.services ?? "Services"}: $_driverJobDetails",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController!,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal[800],
                            elevation: 2,
                            textStyle: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => _makePhoneCall(_driverPhone),
                          child: Text(
                              localizations?.call_provider ?? "Call Provider"),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController!,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            elevation: 2,
                            textStyle: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _cancelRequest,
                          child: Text(localizations?.cancel_request ??
                              "Cancel Request"),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _googleController.future.then((controller) => controller.dispose());
    _animationController?.dispose();
    _tripRideRequestInfoStreamSubsc?.cancel();
    _rideStatusSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _geoFireSubscription?.cancel();
    _retryTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
