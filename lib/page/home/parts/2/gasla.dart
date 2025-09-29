import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:http/http.dart' as http;
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/l10n/app_localizations_en.dart';
import 'package:rana_jayeen/globel/assistant_methods.dart';
import 'package:rana_jayeen/globel/geofireAssisten.dart';
import 'package:rana_jayeen/globel/var_glob.dart';
import 'package:rana_jayeen/infoHandller/app_info.dart';
import 'package:rana_jayeen/models/activerdriver.dart';
import 'package:rana_jayeen/models/direction.dart';
import 'package:rana_jayeen/notif/NotificationService.dart';
import 'package:rana_jayeen/notif/chats.dart';
import 'package:rana_jayeen/notif/chat_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum CarWashType { stationary, mobile }

enum WashType { exterior, full }

enum RequestType { urgent, scheduled }

class CarWashPage extends StatefulWidget {
  const CarWashPage({super.key});

  @override
  State<CarWashPage> createState() => _CarWashPageState();
}

class _CarWashPageState extends State<CarWashPage>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _userLocation;
  String _currentAddress = "";
  Set<Marker> _markers = {};
  BitmapDescriptor? _userMarkerIcon;
  BitmapDescriptor? _storeMarkerIcon;
  BitmapDescriptor? _providerMarkerIcon;
  List<Map<String, dynamic>> _nearbyStores = [];
  List<Map<String, dynamic>> _offlineStoreData = [];
  List<ActiveDrivers> _nearbyProviders = [];
  List<Map<String, dynamic>> _offlineProviderData = [];
  String? _currentRequestId;
  StreamSubscription<DatabaseEvent>? _requestStatusSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<dynamic>? _geofireSubscription;
  String _providerName = "";
  String _providerPhone = "";
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isProviderAssigned = false;
  bool _isOfflineMode = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  WashType? _selectedWashType;
  DateTime? _selectedDate;
  RequestType _requestType = RequestType.urgent;
  Map<String, dynamic>? _selectedStore;
  CarWashType _selectedCarWashType = CarWashType.stationary;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  AnimationController? _bottomSheetController;
  Animation<double>? _bottomSheetAnimation;
  Timer? _debounceTimer;
  SharedPreferences? _prefs;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 14.0,
  );

  static const Color _primaryColor = Color(0xFF1E88E5);
  static const Color _secondaryColor = Color(0xFF64B5F6);
  static const Color _errorColor = Color(0xFFE57373);
  static const Color _backgroundColor = Color(0xFFF5F7FA);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF212121);
  static const Color _textSecondaryColor = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  void _initializeAnimations() {
    try {
      _animationController = AnimationController(
        vsync: this,
        duration: kAnimationDuration ?? const Duration(milliseconds: 400),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
      );
      _bottomSheetController = AnimationController(
        vsync: this,
        duration: kAnimationDuration ?? const Duration(milliseconds: 400),
      );
      _bottomSheetAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _bottomSheetController!, curve: Curves.easeInOut),
      );
      if (!_isDisposed && mounted) {
        _animationController!.forward();
        _bottomSheetController!.forward();
      }
    } catch (e, stackTrace) {
      debugPrint("Error initializing animations: $e\n$stackTrace");
    }
  }

  Future<void> _initializeApp() async {
    if (_isInitialized || _isDisposed || !mounted) return;
    _isInitialized = true;
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _initializePreferences(),
        _checkLocationPermission(),
        _getCurrentLocation(),
        _createMarkerIcons(),
        _checkConnectivity(),
      ]);
      if (!_isOfflineMode) {
        await _syncData();
        await _syncOfflineRequests();
      }
      await _loadCachedData();
      if (_selectedCarWashType == CarWashType.mobile) {
        _initializeGeoFire();
      } else {
        await _fetchNearbyStores();
      }
    } catch (e, stackTrace) {
      debugPrint("Error initializing app: $e\n$stackTrace");
      setState(() => _isOfflineMode = true);
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e, stackTrace) {
      debugPrint("Error initializing SharedPreferences: $e\n$stackTrace");
    }
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

  Future<void> _checkConnectivity() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      final hasInternet = await _hasInternetAccess();
      _handleConnectivityResult(result, hasInternet);
      _connectivitySubscription?.cancel();
      _connectivitySubscription =
          connectivity.onConnectivityChanged.listen((result) async {
        if (_isDisposed || !mounted) return;
        final hasInternet = await _hasInternetAccess();
        _handleConnectivityResult(result, hasInternet);
      });
    } catch (e, stackTrace) {
      debugPrint("Error checking connectivity: $e\n$stackTrace");
      if (mounted && !_isDisposed) {
        setState(() => _isOfflineMode = true);
      }
    }
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
        _syncData();
        _syncOfflineRequests();
        if (_selectedCarWashType == CarWashType.stationary) {
          _fetchNearbyStores();
        } else {
          _initializeGeoFire();
        }
      } else {
        _loadCachedData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang(context).offline_mode,
              style: GoogleFonts.poppins(
                  color: kTextSecondary ?? _textSecondaryColor),
            ),
          ),
        );
      }
    }
  }

  Future<void> _syncData() async {
    if (_isOfflineMode || _isDisposed || !mounted) return;
    try {
      await Future.wait([
        _syncStoreData(),
        _syncProviderData(),
      ]);
    } catch (e, stackTrace) {
      debugPrint("Error syncing data: $e\n$stackTrace");
    }
  }

  Future<void> _syncStoreData() async {
    if (_isOfflineMode || _isDisposed || !mounted) return;
    try {
      final storeRef = FirebaseDatabase.instance.ref().child("stores");
      final storeSnapshot =
          await storeRef.get().timeout(const Duration(seconds: 5));
      if (storeSnapshot.exists && storeSnapshot.value is Map) {
        final storeData = Map<String, dynamic>.from(storeSnapshot.value as Map);
        _offlineStoreData = storeData.entries.map((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          return {
            'storeId': entry.key,
            'storeName': data['storeName']?.toString() ?? lang(context).unknown,
            'contact': data['contact']?.toString() ??
                lang(context).phone_not_available,
            'latitude': data['location']?['latitude']?.toDouble() ?? 0.0,
            'longitude': data['location']?['longitude']?.toDouble() ?? 0.0,
            'address':
                data['address']?.toString() ?? lang(context).unknown_location,
            'rating': data['rating']?.toDouble() ?? 4.0,
            'services':
                (data['services'] as List<dynamic>?)?.cast<String>() ?? [],
            'storeLogoUrl': data['storeLogoUrl']?.toString(),
          };
        }).toList();
        await _prefs?.setString('stores_car_wash_${_selectedCarWashType.name}',
            jsonEncode(_offlineStoreData));
        await _prefs?.setInt(
            'cache_timestamp_car_wash_${_selectedCarWashType.name}',
            DateTime.now().millisecondsSinceEpoch);
      } else {
        debugPrint("No store data found in Firebase");
      }
    } catch (e, stackTrace) {
      debugPrint("Error syncing store data: $e\n$stackTrace");
    }
  }

  Future<void> _syncProviderData() async {
    if (_isOfflineMode || _isDisposed || !mounted) return;
    try {
      final providerRef = FirebaseDatabase.instance.ref().child("driver_users");
      final providerSnapshot =
          await providerRef.get().timeout(const Duration(seconds: 5));
      if (providerSnapshot.exists && providerSnapshot.value is Map) {
        final providerData =
            Map<String, dynamic>.from(providerSnapshot.value as Map);
        _offlineProviderData = providerData.entries.map((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          return {
            'providerId': entry.key,
            'username': data['first']?.toString() ?? lang(context).unknown,
            'contact':
                data['phone']?.toString() ?? lang(context).phone_not_available,
            'locationLatitude':
                data['location']?['latitude']?.toDouble() ?? 0.0,
            'locationLongitude':
                data['location']?['longitude']?.toDouble() ?? 0.0,
            'rating': data['rating']?.toDouble() ?? 4.0,
            'jobs': (data['jobs'] as List<dynamic>?)?.cast<String>() ?? [],
            'newRideStatus': data['newRideStatus']?.toString() ?? 'offline',
          };
        }).toList();
        await _prefs?.setString(
            'providers_car_wash_mobile', jsonEncode(_offlineProviderData));
        await _prefs?.setInt('cache_timestamp_providers_car_wash_mobile',
            DateTime.now().millisecondsSinceEpoch);
      } else {
        debugPrint("No provider data found in Firebase");
      }
    } catch (e, stackTrace) {
      debugPrint("Error syncing provider data: $e\n$stackTrace");
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services disabled");
        throw Exception("Location services disabled");
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied");
          throw Exception("Location permission denied");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission denied forever");
        throw Exception("Location permission denied forever");
      }
    } catch (e, stackTrace) {
      debugPrint("Error checking location permission: $e\n$stackTrace");
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang(context).location_permission_denied,
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isDisposed || !mounted) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(const Duration(seconds: 10));
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
      } catch (e, stackTrace) {
        debugPrint("Error getting placemarks: $e\n$stackTrace");
      }
      final address = placemarks.isNotEmpty
          ? "${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}"
              .trim()
          : lang(context).unknown_location;
      if (mounted && !_isDisposed) {
        setState(() {
          _currentPosition = position;
          _userLocation = LatLng(position.latitude, position.longitude);
          _currentAddress =
              address.isNotEmpty ? address : lang(context).unknown_location;
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
        if (_mapController != null && _userLocation != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _userLocation!, zoom: 16),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error getting current location: $e\n$stackTrace");
      if (mounted && !_isDisposed) {
        setState(() => _isOfflineMode = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang(context).location_error,
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadCachedData() async {
    if (_isDisposed || !mounted) return;
    try {
      String? storeDataJson =
          _prefs?.getString('stores_car_wash_${_selectedCarWashType.name}');
      if (storeDataJson != null) {
        try {
          _offlineStoreData =
              List<Map<String, dynamic>>.from(jsonDecode(storeDataJson));
        } catch (e, stackTrace) {
          debugPrint("Error decoding cached store data: $e\n$stackTrace");
          _offlineStoreData = [];
        }
      }
      String? providerDataJson = _prefs?.getString('providers_car_wash_mobile');
      if (providerDataJson != null) {
        try {
          _offlineProviderData =
              List<Map<String, dynamic>>.from(jsonDecode(providerDataJson));
        } catch (e, stackTrace) {
          debugPrint("Error decoding cached provider data: $e\n$stackTrace");
          _offlineProviderData = [];
        }
      }
      if (_selectedCarWashType == CarWashType.stationary) {
        _nearbyStores = _offlineStoreData
            .where((store) =>
                (store['services'] as List<dynamic>?)?.contains('carWash') ??
                false)
            .map((store) {
          final distance = _currentPosition != null
              ? Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  store['latitude']?.toDouble() ?? 0.0,
                  store['longitude']?.toDouble() ?? 0.0,
                )
              : 0.0;
          return {...store, 'distance': distance};
        }).toList();
        _nearbyStores.sort((a, b) => a['distance'].compareTo(b['distance']));
        await _updateStoreMarkers();
      } else {
        _nearbyProviders = _offlineProviderData
            .where((provider) =>
                (provider['jobs'] as List<dynamic>?)
                    ?.contains('mobileCarWash') ??
                false && provider['newRideStatus'] == 'idle')
            .map((provider) => ActiveDrivers()
              ..providerId = provider['providerId']
              ..locationLatitude = provider['locationLatitude']
              ..locationLongitude = provider['locationLongitude'])
            .toList();
        await _updateProviderMarkers();
      }
    } catch (e, stackTrace) {
      debugPrint("Error loading cached data: $e\n$stackTrace");
    }
  }

  Future<void> _cacheStores() async {
    if (_isDisposed || !mounted || _prefs == null) return;
    try {
      await _prefs!.setString('stores_car_wash_${_selectedCarWashType.name}',
          jsonEncode(_nearbyStores));
      await _prefs!.setInt(
          'cache_timestamp_car_wash_${_selectedCarWashType.name}',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e, stackTrace) {
      debugPrint("Error caching stores: $e\n$stackTrace");
    }
  }

  Future<void> _cacheProviders() async {
    if (_isDisposed || !mounted || _prefs == null) return;
    try {
      await _prefs!.setString(
        'providers_car_wash_mobile',
        jsonEncode(_nearbyProviders
            .map((provider) => {
                  'providerId': provider.providerId,
                  'locationLatitude': provider.locationLatitude,
                  'locationLongitude': provider.locationLongitude,
                  'username': _providerName.isNotEmpty
                      ? _providerName
                      : lang(context).unknown,
                  'contact': _providerPhone.isNotEmpty
                      ? _providerPhone
                      : lang(context).phone_not_available,
                  'rating': 4.0,
                  'jobs': ['mobileCarWash'],
                  'newRideStatus': 'idle',
                })
            .toList()),
      );
      await _prefs!.setInt('cache_timestamp_providers_car_wash_mobile',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e, stackTrace) {
      debugPrint("Error caching providers: $e\n$stackTrace");
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty ||
        _debounceTimer?.isActive == true ||
        _isDisposed ||
        !mounted) return;
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      try {
        final locations = await locationFromAddress(query)
            .timeout(const Duration(seconds: 5));
        if (locations.isNotEmpty && mounted && !_isDisposed) {
          final location = locations.first;
          List<Placemark> placemarks = [];
          try {
            placemarks = await placemarkFromCoordinates(
                location.latitude, location.longitude);
          } catch (e, stackTrace) {
            debugPrint("Error getting placemarks for search: $e\n$stackTrace");
          }
          final address = placemarks.isNotEmpty
              ? "${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}"
                  .trim()
              : query;
          setState(() {
            _userLocation = LatLng(location.latitude, location.longitude);
            _currentAddress =
                address.isNotEmpty ? address : lang(context).unknown_location;
            _currentPosition = Position(
              latitude: location.latitude,
              longitude: location.longitude,
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
          try {
            Provider.of<AppInfo>(context, listen: false)
                .updatePickUpLocationAddress(
              Directions()
                ..locationLatitude = location.latitude
                ..locationLongitude = location.longitude
                ..locationName = address,
            );
          } catch (e, stackTrace) {
            debugPrint("Error updating AppInfo for search: $e\n$stackTrace");
          }
          await _updateUserMarker();
          if (_mapController != null && _userLocation != null) {
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: _userLocation!, zoom: 16),
              ),
            );
          }
          if (_selectedCarWashType == CarWashType.mobile) {
            _initializeGeoFire();
          } else {
            await _fetchNearbyStores();
          }
        } else {
          debugPrint("No results found for search query: $query");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang(context).no_results_found,
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        debugPrint("Error searching location: $e\n$stackTrace");
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang(context).search_error,
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      } finally {
        if (mounted && !_isDisposed) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _updateUserMarker() async {
    if (_isDisposed ||
        !mounted ||
        _userMarkerIcon == null ||
        _userLocation == null) return;
    try {
      setState(() {
        _markers
            .removeWhere((marker) => marker.markerId.value == "user_location");
        _markers.add(
          Marker(
            markerId: const MarkerId("user_location"),
            position: _userLocation!,
            icon: _userMarkerIcon!,
            infoWindow: InfoWindow(title: lang(context).your_location),
          ),
        );
      });
    } catch (e, stackTrace) {
      debugPrint("Error updating user marker: $e\n$stackTrace");
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
          fontFamily: icon.fontFamily,
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
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _createMarkerIcons() async {
    if (_isDisposed || !mounted) return;
    try {
      _userMarkerIcon = await _createCustomMarker(
          Icons.location_on, kError ?? _errorColor, 100.0);
      _storeMarkerIcon = await _createCustomMarker(
          Icons.local_car_wash, kPrimaryColor ?? _primaryColor, 80.0);
      _providerMarkerIcon = await _createCustomMarker(
          Icons.directions_car, kAccent ?? _secondaryColor, 80.0);
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      debugPrint("Error creating marker icons: $e\n$stackTrace");
      _userMarkerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _storeMarkerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _providerMarkerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    }
  }

  Future<void> _fetchNearbyStores() async {
    if (_isDisposed || !mounted || _currentPosition == null) return;
    setState(() => _isLoading = true);
    try {
      if (_isOfflineMode) {
        _nearbyStores = _offlineStoreData
            .where((store) =>
                (store['services'] as List<dynamic>?)?.contains('carWash') ??
                false)
            .map((store) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            store['latitude']?.toDouble() ?? 0.0,
            store['longitude']?.toDouble() ?? 0.0,
          );
          return {...store, 'distance': distance};
        }).toList();
        _nearbyStores.sort((a, b) => a['distance'].compareTo(b['distance']));
      } else {
        final ref = FirebaseDatabase.instance.ref().child("stores");
        final snapshot = await ref.get().timeout(const Duration(seconds: 5));
        if (!snapshot.exists || snapshot.value == null) {
          debugPrint("No stores available in Firebase");
          _nearbyStores = [];
        } else {
          final storesData = Map<String, dynamic>.from(snapshot.value as Map);
          _nearbyStores = storesData.entries.where((entry) {
            final store = Map<String, dynamic>.from(entry.value);
            return (store['services'] as List<dynamic>?)?.contains('carWash') ??
                false;
          }).map((entry) {
            final store = Map<String, dynamic>.from(entry.value);
            final distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              store['location']?['latitude']?.toDouble() ?? 0.0,
              store['location']?['longitude']?.toDouble() ?? 0.0,
            );
            return {
              'storeId': entry.key,
              'storeName':
                  store['storeName']?.toString() ?? lang(context).unknown,
              'latitude': store['location']?['latitude']?.toDouble() ?? 0.0,
              'longitude': store['location']?['longitude']?.toDouble() ?? 0.0,
              'services':
                  (store['services'] as List<dynamic>?)?.cast<String>() ?? [],
              'contact': store['contact']?.toString() ??
                  lang(context).phone_not_available,
              'distance': distance,
              'address': store['address']?.toString() ??
                  lang(context).unknown_location,
              'rating': store['rating']?.toDouble() ?? 4.0,
              'storeLogoUrl': store['storeLogoUrl']?.toString(),
            };
          }).toList();
          _nearbyStores.sort((a, b) => a['distance'].compareTo(b['distance']));
          _offlineStoreData = _nearbyStores;
          await _cacheStores();
        }
      }
      await _updateStoreMarkers();
    } catch (e, stackTrace) {
      debugPrint("Error fetching nearby stores: $e\n$stackTrace");
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang(context).error_fetching_stores,
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeGeoFire() {
    if (_isDisposed || !mounted || _currentPosition == null) {
      debugPrint("Cannot initialize GeoFire: Disposed or no location");
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isOfflineMode) {
        _nearbyProviders = _offlineProviderData
            .where((provider) =>
                (provider['jobs'] as List<dynamic>?)
                    ?.contains('mobileCarWash') ??
                false && provider['newRideStatus'] == 'idle')
            .map((provider) => ActiveDrivers()
              ..providerId = provider['providerId']
              ..locationLatitude = provider['locationLatitude']
              ..locationLongitude = provider['locationLongitude'])
            .toList();
        _updateProviderMarkers();
      } else {
        Geofire.initialize('activeDrivers');
        final query = Geofire.queryAtLocation(
            _currentPosition!.latitude, _currentPosition!.longitude, 15);
        _geofireSubscription?.cancel();
        _geofireSubscription = query?.listen((map) async {
          if (map == null || _isDisposed || !mounted) return;
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
            try {
              final callBack = map['callBack'];
              switch (callBack) {
                case Geofire.onKeyEntered:
                  final activeDriver = ActiveDrivers()
                    ..providerId = map['key']
                    ..locationLatitude = map['latitude']
                    ..locationLongitude = map['longitude'];
                  if (await _isProviderOnline(activeDriver.providerId!)) {
                    GeofireAssistant.activeNearbyDriverList.add(activeDriver);
                    await _updateProviderMarkers();
                  }
                  break;
                case Geofire.onKeyExited:
                  GeofireAssistant.deleteOfflineDriverFromList(map["key"]);
                  await _updateProviderMarkers();
                  break;
                case Geofire.onKeyMoved:
                  final activeDriver = ActiveDrivers()
                    ..providerId = map["key"]
                    ..locationLatitude = map["latitude"]
                    ..locationLongitude = map["longitude"];
                  if (await _isProviderOnline(activeDriver.providerId!)) {
                    GeofireAssistant.updateActiveDriverLocation(activeDriver);
                    await _updateProviderMarkers();
                  }
                  break;
                case Geofire.onGeoQueryReady:
                  await _updateProviderMarkers();
                  break;
              }
            } catch (e, stackTrace) {
              debugPrint("Error processing GeoFire event: $e\n$stackTrace");
            }
          });
        }, onError: (error, stackTrace) {
          debugPrint("GeoFire query error: $error\n$stackTrace");
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error initializing GeoFire: $e\n$stackTrace");
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _isProviderOnline(String providerId) async {
    if (_isDisposed || !mounted) return false;
    try {
      if (_isOfflineMode) {
        final provider = _offlineProviderData.firstWhere(
          (p) => p['providerId'] == providerId,
          orElse: () => {},
        );
        return provider.isNotEmpty &&
            provider['newRideStatus'] == 'idle' &&
            (provider['jobs'] as List<dynamic>?)?.contains('mobileCarWash') ==
                true;
      }
      final ref = FirebaseDatabase.instance
          .ref()
          .child("driver_users")
          .child(providerId);
      final snapshot = await ref.get().timeout(const Duration(seconds: 5));
      if (!snapshot.exists || snapshot.value == null) return false;
      final providerData = Map<String, dynamic>.from(snapshot.value as Map);
      return providerData['newRideStatus'] == 'idle' &&
          (providerData['jobs'] as List<dynamic>?)?.contains('mobileCarWash') ==
              true;
    } catch (e, stackTrace) {
      debugPrint("Error checking provider status: $e\n$stackTrace");
      return false;
    }
  }

  Future<void> _updateStoreMarkers() async {
    if (_isDisposed || !mounted) return;
    try {
      final storeMarkers = _nearbyStores
          .where((store) =>
              store['latitude'] != null && store['longitude'] != null)
          .map((store) {
        return Marker(
          markerId: MarkerId(store['storeId']),
          position: LatLng(
              store['latitude']!.toDouble(), store['longitude']!.toDouble()),
          icon: _storeMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: store['storeName'],
            snippet:
                '${(store['distance'] / 1000).toStringAsFixed(2)} ${lang(context).km}\n${store['address']}',
          ),
          onTap: () {
            if (mounted && !_isDisposed) {
              setState(() {
                _selectedStore = store;
                _bottomSheetController?.forward(from: 0.0);
              });
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(store['latitude']!.toDouble(),
                          store['longitude']!.toDouble()),
                      zoom: 16,
                    ),
                  ),
                );
              }
            }
          },
        );
      }).toSet();
      if (mounted && !_isDisposed) {
        setState(() {
          _markers = {
            if (_userLocation != null && _userMarkerIcon != null)
              Marker(
                markerId: const MarkerId("user_location"),
                position: _userLocation!,
                icon: _userMarkerIcon!,
                infoWindow: InfoWindow(title: lang(context).your_location),
              ),
            ...storeMarkers,
          };
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error updating store markers: $e\n$stackTrace");
    }
  }

  Future<void> _updateProviderMarkers() async {
    if (_isDisposed || !mounted) return;
    try {
      final providerMarkers = _nearbyProviders
          .where((provider) =>
              provider.locationLatitude != null &&
              provider.locationLongitude != null)
          .map((provider) {
        return Marker(
          markerId: MarkerId(provider.providerId!),
          position:
              LatLng(provider.locationLatitude!, provider.locationLongitude!),
          icon: _providerMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: lang(context).mobile_car_wash_provider),
        );
      }).toSet();
      if (mounted && !_isDisposed) {
        setState(() {
          _markers = {
            if (_userLocation != null && _userMarkerIcon != null)
              Marker(
                markerId: const MarkerId("user_location"),
                position: _userLocation!,
                icon: _userMarkerIcon!,
                infoWindow: InfoWindow(title: lang(context).your_location),
              ),
            ...providerMarkers,
          };
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error updating provider markers: $e\n$stackTrace");
    }
  }

  Future<void> _submitRequest([Map<String, dynamic>? store]) async {
    if (_isDisposed || !mounted || _isLoading || _formKey.currentState == null)
      return;
    if (!_formKey.currentState!.validate()) {
      debugPrint("Form validation failed");
      return;
    }
    if (_userLocation == null) {
      debugPrint("User location is null");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang(context).location_error,
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }
    if (_requestType == RequestType.scheduled && _selectedDate == null) {
      debugPrint("Scheduled request missing date");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang(context).schedule_date_error,
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_selectedCarWashType == CarWashType.stationary && store != null) {
        await _startChat(store['storeId'], store['storeName'], store);
        return;
      }
      AssistantMethodes.readCurrentOnlineUser();
      final ref =
          FirebaseDatabase.instance.ref().child("allRideRequests").push();
      _currentRequestId = ref.key;
      final requestData = {
        "origin": {
          "latitude": _userLocation!.latitude,
          "longitude": _userLocation!.longitude,
        },
        "address": _currentAddress,
        "userId": userModelCurrentInfo?.id ?? lang(context).unknown,
        "userName": userModelCurrentInfo?.first ?? lang(context).unknown,
        "userPhone":
            userModelCurrentInfo?.phone ?? lang(context).phone_not_available,
        "serviceType": _selectedCarWashType == CarWashType.stationary
            ? "carWash"
            : "mobileCarWash",
        "washType": _selectedWashType!.name,
        "description": _descriptionController.text,
        "requestType": _requestType.name,
        "scheduleDate": _requestType == RequestType.urgent
            ? DateTime.now().toIso8601String()
            : _selectedDate!.toIso8601String(),
        "status": "pending",
        "createdAt": DateTime.now().toIso8601String(),
        if (store != null) "storeId": store['storeId'],
      };
      if (_isOfflineMode) {
        await _prefs?.setString(
            'request_$_currentRequestId', jsonEncode(requestData));
        debugPrint("Request stored offline: $_currentRequestId");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang(context).request_queued,
              style: GoogleFonts.poppins(),
            ),
            action: SnackBarAction(
              label: lang(context).retry,
              onPressed: _syncOfflineRequests,
            ),
          ),
        );
      } else {
        await ref.set(requestData).timeout(const Duration(seconds: 5));
        if (_selectedCarWashType == CarWashType.mobile) {
          setState(() => _isSearching = true);
          await _searchNearestProvider();
        }
        _listenToRequestStatus();
      }
    } catch (e, stackTrace) {
      debugPrint("Error submitting request: $e\n$stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang(context).requestError,
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchNearestProvider() async {
    if (_isDisposed || !mounted || _nearbyProviders.isEmpty) {
      setState(() {
        _isSearching = false;
        _isProviderAssigned = false;
      });
      debugPrint("No nearby providers available");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang(context).no_providers_available,
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }
    try {
      for (final provider in _nearbyProviders) {
        if (provider.providerId == null) continue;
        Map<String, dynamic> providerData;
        if (_isOfflineMode) {
          providerData = _offlineProviderData.firstWhere(
            (p) => p['providerId'] == provider.providerId,
            orElse: () => {},
          );
          if (providerData.isEmpty) continue;
          if ((providerData['jobs'] as List<dynamic>?)
                      ?.contains('mobileCarWash') ==
                  true &&
              providerData['newRideStatus'] == 'idle') {
            setState(() {
              _providerName = providerData['username'] ?? lang(context).unknown;
              _providerPhone =
                  providerData['contact'] ?? lang(context).phone_not_available;
              _isSearching = false;
              _isProviderAssigned = true;
            });
            await _cacheProviders();
            if (!_isOfflineMode && _currentRequestId != null) {
              await FirebaseDatabase.instance
                  .ref()
                  .child("allRideRequests")
                  .child(_currentRequestId!)
                  .update({
                "providerId": provider.providerId,
                "status": "notified",
                "providerName": _providerName,
                "providerPhone": _providerPhone,
                "providerRating": providerData['rating']?.toDouble() ?? 4.0,
              });
            }
            await _startChat(provider.providerId!, _providerName, {
              'contact': _providerPhone,
              'rating': providerData['rating']?.toDouble() ?? 4.0,
            });
            return;
          }
          continue;
        }
        final ref = FirebaseDatabase.instance
            .ref()
            .child("driver_users")
            .child(provider.providerId!);
        final snapshot = await ref.get().timeout(const Duration(seconds: 5));
        if (!snapshot.exists || snapshot.value == null) continue;
        providerData = Map<String, dynamic>.from(snapshot.value as Map);
        final providerJobs = providerData["jobs"];
        bool jobMatch = false;
        if (providerJobs is List<dynamic>) {
          jobMatch = providerJobs.contains('mobileCarWash') &&
              providerData['newRideStatus'] == 'idle';
        }
        if (jobMatch) {
          await FirebaseDatabase.instance
              .ref()
              .child("allRideRequests")
              .child(_currentRequestId!)
              .update({
            "providerId": provider.providerId,
            "status": "notified",
            "providerName": providerData["first"] ?? lang(context).unknown,
            "providerPhone":
                providerData["phone"] ?? lang(context).phone_not_available,
            "providerRating": providerData["rating"]?.toDouble() ?? 4.0,
          });
          if (mounted && !_isDisposed) {
            setState(() {
              _providerName = providerData["first"] ?? lang(context).unknown;
              _providerPhone =
                  providerData["phone"] ?? lang(context).phone_not_available;
              _isSearching = false;
              _isProviderAssigned = true;
            });
            await _cacheProviders();
            await _startChat(provider.providerId!, _providerName, {
              'contact':
                  providerData["phone"] ?? lang(context).phone_not_available,
              'rating': providerData["rating"]?.toDouble() ?? 4.0,
            });
            return;
          }
        }
      }
      if (mounted && !_isDisposed) {
        setState(() {
          _isSearching = false;
          _isProviderAssigned = false;
        });
        debugPrint("No suitable providers found");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang(context).no_providers_available,
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Error searching nearest provider: $e\n$stackTrace");
      if (mounted && !_isDisposed) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang(context).failed_to_initialize_provider_search,
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _startChat(String recipientId, String recipientName,
      [Map<String, dynamic>? data]) async {
    // Start a chat with the recipient
    if (_isDisposed || !mounted) return;
    try {
      if (_isOfflineMode &&
          data != null &&
          data['contact'] != null &&
          data['contact'] != lang(context).phone_not_available) {
        debugPrint("Offline mode: Attempting to call ${data['contact']}");
        final phoneUrl = Uri.parse('tel:${data['contact']}');
        if (await canLaunchUrl(phoneUrl)) {
          await launchUrl(phoneUrl);
        } else {
          debugPrint("Cannot make phone call: Invalid phone number");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang(context).error_phone_call,
                style: TextStyle(fontFamily: font ?? 'Roboto'),
              ),
            ),
          );
        }
        return;
      }
      final userId = userModelCurrentInfo?.id;
      final userName = userModelCurrentInfo?.first ?? lang(context).unknown;
      if (userId == null || userId.isEmpty || userId == 'unknown') {
        debugPrint("User not logged in");
        if (data != null &&
            data['contact'] != null &&
            data['contact'] != lang(context).phone_not_available) {
          debugPrint("Falling back to phone call: ${data['contact']}");
          final phoneUrl = Uri.parse('tel:${data['contact']}');
          if (await canLaunchUrl(phoneUrl)) {
            await launchUrl(phoneUrl);
          } else {
            debugPrint("Cannot make phone call: Invalid phone number");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  lang(context).error_phone_call,
                  style: TextStyle(fontFamily: font ?? 'Roboto'),
                ),
              ),
            );
          }
        }
        return;
      }
      final chatId = ChatUtils.getChatId(userId, recipientId);
      if (!_isOfflineMode) {
        String message = _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : "New chat initiated for car wash service";
        try {
          final requestId = _currentRequestId ?? recipientId;
          await NotificationService().sendNewMessage(
            recipientId,
            message,
            requestId,
          );
        } catch (e, stackTrace) {
          debugPrint("Error sending notification: $e\n$stackTrace");
        }
      }
      if (mounted && !_isDisposed) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Chat(
              chatId: chatId,
              providerId: recipientId,
              providerName: recipientName.isNotEmpty
                  ? recipientName
                  : lang(context).unknown,
              userId: userId,
              userName: userName,
              serviceType: _selectedCarWashType == CarWashType.stationary
                  ? 'carWash'
                  : 'mobileCarWash',
              requestId: _currentRequestId,
              storeId: data?['storeId'],
              storeName: data?['storeName'],
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Error starting chat: $e\n$stackTrace");
      if (data != null &&
          data['contact'] != null &&
          data['contact'] != lang(context).phone_not_available) {
        debugPrint("Falling back to phone call: ${data['contact']}");
        final phoneUrl = Uri.parse('tel:${data['contact']}');
        if (await canLaunchUrl(phoneUrl)) {
          await launchUrl(phoneUrl);
        } else {
          debugPrint("Cannot make phone call: Invalid phone number");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang(context).error_phone_call,
                style: TextStyle(fontFamily: font ?? 'Roboto'),
              ),
            ),
          );
        }
      }
    }
  }

  void _listenToRequestStatus() {
    if (_isDisposed || !mounted || _currentRequestId == null) return;
    _requestStatusSubscription?.cancel();
    _requestStatusSubscription = FirebaseDatabase.instance
        .ref()
        .child("allRideRequests")
        .child(_currentRequestId!)
        .onValue
        .listen((event) {
      if (!mounted || _isDisposed || event.snapshot.value == null) {
        debugPrint(
            "Request data deleted or component disposed: $_currentRequestId");
        if (mounted && !_isDisposed) {
          setState(() {
            _isSearching = false;
            _isProviderAssigned = false;
            _currentRequestId = null;
            _selectedStore = null;
          });
        }
        return;
      }
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (data["status"] == "accepted") {
          if (mounted && !_isDisposed) {
            setState(() {
              _isSearching = false;
              _isProviderAssigned = true;
              _providerName = data["providerName"] ?? lang(context).unknown;
              _providerPhone =
                  data["providerPhone"] ?? lang(context).phone_not_available;
            });
            if (_selectedCarWashType == CarWashType.mobile) {
              _startChat(
                data["providerId"] ?? data["storeId"],
                _providerName,
                {
                  'contact': data["providerPhone"] ??
                      lang(context).phone_not_available,
                  'rating': data["providerRating"]?.toDouble() ?? 4.0,
                },
              );
            }
          }
        } else if (data["status"] == "cancelled") {
          if (mounted && !_isDisposed) {
            setState(() {
              _isSearching = false;
              _isProviderAssigned = false;
              _currentRequestId = null;
              _selectedStore = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  lang(context).request_cancelled,
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        debugPrint("Error processing request status: $e\n$stackTrace");
      }
    }, onError: (e, stackTrace) {
      debugPrint("Error listening to request status: $e\n$stackTrace");
    });
  }

  void _switchCarWashType(CarWashType type) async {
    if (_isDisposed || !mounted || _selectedCarWashType == type) return;
    setState(() {
      _selectedCarWashType = type;
      _selectedStore = null;
      _markers.clear();
      _nearbyStores.clear();
      _nearbyProviders.clear();
      _isSearching = false;
      _isProviderAssigned = false;
      _currentRequestId = null;
      _descriptionController.clear();
      _selectedWashType = null;
      _selectedDate = null;
      _requestType = RequestType.urgent;
      _isLoading = true;
    });
    try {
      await _loadCachedData();
      if (_selectedCarWashType == CarWashType.mobile) {
        _initializeGeoFire();
      } else {
        await _fetchNearbyStores();
      }
      await _updateUserMarker();
    } catch (e, stackTrace) {
      debugPrint("Error switching car wash type: $e\n$stackTrace");
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  AppLocalizations lang(BuildContext? context) => context != null
      ? AppLocalizations.of(context) ?? AppLocalizationsEn()
      : AppLocalizationsEn();

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final localizations = lang(context);
    final isRtl = localizations.localeName == 'ar';
    return Scaffold(
      backgroundColor: kBackground?.withOpacity(0.95) ?? _backgroundColor,
      appBar: AppBar(
        title: Text(
          _isOfflineMode
              ? "${localizations.carWash} (${localizations.offline_mode})"
              : localizations.carWash,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: kTextPrimary ?? _textPrimaryColor,
          ),
          textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        backgroundColor: kSurface ?? _surfaceColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isOfflineMode)
            IconButton(
              icon: Icon(Icons.refresh, color: kPrimaryColor ?? _primaryColor),
              onPressed: () async => await _checkConnectivity(),
              tooltip: localizations.refresh,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SegmentedButton<CarWashType>(
                  segments: [
                    ButtonSegment(
                      value: CarWashType.stationary,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            localizations.stationary_car_wash,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color:
                                  _selectedCarWashType == CarWashType.stationary
                                      ? Colors.white
                                      : kPrimaryColor ?? _primaryColor,
                            ),
                            textDirection: isRtl
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                    ButtonSegment(
                      value: CarWashType.mobile,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            localizations.mobile_car_wash,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: _selectedCarWashType == CarWashType.mobile
                                  ? Colors.white
                                  : kPrimaryColor ?? _primaryColor,
                            ),
                            textDirection: isRtl
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                  ],
                  selected: {_selectedCarWashType},
                  onSelectionChanged: (newSelection) =>
                      _switchCarWashType(newSelection.first),
                  style: SegmentedButton.styleFrom(
                    backgroundColor: kBackground ?? _backgroundColor,
                    foregroundColor: kPrimaryColor ?? _primaryColor,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: kPrimaryColor ?? _primaryColor,
                    side: BorderSide(color: kPrimaryColor ?? _primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _initialPosition,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: _markers,
                      onMapCreated: (controller) {
                        if (!_isDisposed &&
                            !_mapControllerCompleter.isCompleted) {
                          _mapController = controller;
                          _mapControllerCompleter.complete(controller);
                          if (_userLocation != null) {
                            controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                    target: _userLocation!, zoom: 16),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: kPrimaryGradientColor ??
                              LinearGradient(
                                colors: [
                                  (kPrimaryColor ?? _primaryColor)
                                      .withOpacity(0.1),
                                  (kPrimaryColor ?? _primaryColor)
                                      .withOpacity(0.3),
                                ],
                              ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: localizations.search_location,
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              color: kTextSecondary ?? _textSecondaryColor,
                            ),
                            prefixIcon: Icon(Icons.search,
                                color: kPrimaryColor ?? _primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear,
                                  color: kTextSecondary ?? _textSecondaryColor),
                              onPressed: () {
                                _searchController.clear();
                                _getCurrentLocation();
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: kSurface ?? _surfaceColor,
                          ),
                          textDirection: isRtl
                              ? ui.TextDirection.rtl
                              : ui.TextDirection.ltr,
                          style: GoogleFonts.poppins(fontSize: 16),
                          onSubmitted: _searchLocation,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(_bottomSheetAnimation ??
                            AlwaysStoppedAnimation(1.0)),
                        child: AnimatedContainer(
                          duration: kAnimationDuration ??
                              const Duration(milliseconds: 400),
                          height: _calculateBottomSheetHeight(),
                          decoration: BoxDecoration(
                            color:
                                (kSurface ?? _surfaceColor).withOpacity(0.95),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, -6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 5,
                                margin: const EdgeInsets.only(top: 12),
                                decoration: BoxDecoration(
                                  color: (kTextSecondary ?? _textSecondaryColor)
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                              Expanded(
                                child: _buildBottomSheetContent(localizations),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading || _isSearching)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: Center(
                    child: Lottie.asset(
                      'assets/images/BU7EikdAtg.json',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateBottomSheetHeight() {
    if (_isSearching) return 220;
    if (_isProviderAssigned) return 280;
    if (_selectedCarWashType == CarWashType.stationary &&
        _selectedStore != null) return 340;
    return _selectedCarWashType == CarWashType.mobile ? 480 : 340;
  }

  Widget _buildBottomSheetContent(AppLocalizations lang) {
    if (_isSearching) return _buildSearchingWidget(lang);
    if (_isProviderAssigned) return _buildProviderAssignedWidget(lang);
    if (_selectedCarWashType == CarWashType.stationary &&
        _selectedStore != null) {
      return _buildStoreDetailsWidget(lang, store: _selectedStore!);
    }
    return _buildServiceForm(lang, store: _selectedStore);
  }

  Widget _buildStoreDetailsWidget(AppLocalizations lang,
      {required Map<String, dynamic> store}) {
    final isRtl = lang.localeName == 'ar';
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store['storeName'] ?? lang.unknown,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kTextPrimary ?? _textPrimaryColor,
              ),
              textDirection:
                  isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            Text(
              '${(store['distance'] / 1000).toStringAsFixed(2)} ${lang.km}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextSecondary ?? _textSecondaryColor,
              ),
              textDirection:
                  isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            Text(
              store['address'] ?? lang.unknown_location,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextSecondary ?? _textSecondaryColor,
              ),
              textDirection:
                  isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  store['rating']?.toStringAsFixed(1) ?? '4.0',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: kTextSecondary ?? _textSecondaryColor,
                  ),
                  textDirection:
                      isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ],
            ),
            if (_isOfflineMode)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  lang.offline_mode,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: kError ?? _errorColor,
                    fontStyle: FontStyle.italic,
                  ),
                  textDirection:
                      isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: lang.request_details,
                      labelStyle: GoogleFonts.poppins(
                        color: kTextSecondary ?? _textSecondaryColor,
                      ),
                      prefixIcon: Icon(Icons.description,
                          color: kPrimaryColor ?? _primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          (kBackground ?? _backgroundColor).withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                    ),
                    maxLines: 4,
                    validator: (value) => value == null || value.isEmpty
                        ? lang.request_details_error
                        : null,
                    textDirection:
                        isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                          parent: _animationController!,
                          curve: Curves.easeInOut),
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        if (mounted && !_isDisposed) {
                          setState(() {
                            _selectedStore = null;
                            _descriptionController.clear();
                            _bottomSheetController?.forward(from: 0.0);
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: kTextSecondary ?? _textSecondaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        lang.cancel,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary ?? _textSecondaryColor,
                        ),
                        textDirection:
                            isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                          parent: _animationController!,
                          curve: Curves.easeInOut),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: kPrimaryGradientColor ??
                            LinearGradient(
                                colors: [_primaryColor, _secondaryColor]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : () => _submitRequest(store),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          lang.submit,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
            if (_isOfflineMode) ...[
              const SizedBox(height: 12),
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                        parent: _animationController!, curve: Curves.easeInOut),
                  ),
                  child: OutlinedButton(
                    onPressed: () async => await _checkConnectivity(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPrimaryColor ?? _primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      lang.refresh,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor ?? _primaryColor,
                      ),
                      textDirection:
                          isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceForm(AppLocalizations lang,
      {Map<String, dynamic>? store}) {
    final isRtl = lang.localeName == 'ar';
    if (_selectedCarWashType == CarWashType.stationary) {
      return Column(
        children: [
          Expanded(
            child: _nearbyStores.isEmpty
                ? Center(
                    child: Text(
                      lang.no_stores_available,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: kTextPrimary ?? _textPrimaryColor,
                      ),
                      textDirection:
                          isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _nearbyStores.length,
                    itemBuilder: (context, index) {
                      final store = _nearbyStores[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (mounted && !_isDisposed) {
                              setState(() {
                                _selectedStore = store;
                                _bottomSheetController?.forward(from: 0.0);
                              });
                              if (_mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: LatLng(
                                          store['latitude']!.toDouble(),
                                          store['longitude']!.toDouble()),
                                      zoom: 16,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      (kPrimaryColor ?? _primaryColor)
                                          .withOpacity(0.1),
                                  radius: 24,
                                  child: Icon(
                                    Icons.local_car_wash,
                                    color: kPrimaryColor ?? _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store['storeName'] ?? lang.unknown,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              kTextPrimary ?? _textPrimaryColor,
                                        ),
                                        textDirection: isRtl
                                            ? ui.TextDirection.rtl
                                            : ui.TextDirection.ltr,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(store['distance'] / 1000).toStringAsFixed(2)} ${lang.km}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: kTextSecondary ??
                                              _textSecondaryColor,
                                        ),
                                        textDirection: isRtl
                                            ? ui.TextDirection.rtl
                                            : ui.TextDirection.ltr,
                                      ),
                                      Text(
                                        store['address'] ??
                                            lang.unknown_location,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: kTextSecondary ??
                                              _textSecondaryColor,
                                        ),
                                        textDirection: isRtl
                                            ? ui.TextDirection.rtl
                                            : ui.TextDirection.ltr,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              color: Colors.amber, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            store['rating']
                                                    ?.toStringAsFixed(1) ??
                                                '4.0',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: kTextSecondary ??
                                                  _textSecondaryColor,
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
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.mobile_car_wash,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary ?? _textPrimaryColor,
                ),
                textDirection:
                    isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              ),
              if (_isOfflineMode)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    lang.offline_mode,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: kError ?? _errorColor,
                      fontStyle: FontStyle.italic,
                    ),
                    textDirection:
                        isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                lang.wash_type,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary ?? _textPrimaryColor,
                ),
                textDirection:
                    isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        lang.exterior_wash,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _selectedWashType == WashType.exterior
                              ? Colors.white
                              : kTextPrimary ?? _textPrimaryColor,
                        ),
                        textDirection:
                            isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                      selected: _selectedWashType == WashType.exterior,
                      selectedColor: kPrimaryColor ?? _primaryColor,
                      backgroundColor:
                          (kBackground ?? _backgroundColor).withOpacity(0.5),
                      onSelected: (selected) {
                        if (selected && mounted && !_isDisposed) {
                          setState(() => _selectedWashType = WashType.exterior);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        lang.full_wash,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _selectedWashType == WashType.full
                              ? Colors.white
                              : kTextPrimary ?? _textPrimaryColor,
                        ),
                        textDirection:
                            isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                      selected: _selectedWashType == WashType.full,
                      selectedColor: kPrimaryColor ?? _primaryColor,
                      backgroundColor:
                          (kBackground ?? _backgroundColor).withOpacity(0.5),
                      onSelected: (selected) {
                        if (selected && mounted && !_isDisposed) {
                          setState(() => _selectedWashType = WashType.full);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                lang.request_type,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary ?? _textPrimaryColor,
                ),
                textDirection:
                    isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        lang.urgent,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _requestType == RequestType.urgent
                              ? Colors.white
                              : kTextPrimary ?? _textPrimaryColor,
                        ),
                        textDirection:
                            isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                      selected: _requestType == RequestType.urgent,
                      selectedColor: kPrimaryColor ?? _primaryColor,
                      backgroundColor:
                          (kBackground ?? _backgroundColor).withOpacity(0.5),
                      onSelected: (selected) {
                        if (selected && mounted && !_isDisposed) {
                          setState(() {
                            _requestType = RequestType.urgent;
                            _selectedDate = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        lang.scheduled,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _requestType == RequestType.scheduled
                              ? Colors.white
                              : kTextPrimary ?? _textPrimaryColor,
                        ),
                        textDirection:
                            isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                      selected: _requestType == RequestType.scheduled,
                      selectedColor: kPrimaryColor ?? _primaryColor,
                      backgroundColor:
                          (kBackground ?? _backgroundColor).withOpacity(0.5),
                      onSelected: (selected) {
                        if (selected && mounted && !_isDisposed) {
                          setState(() => _requestType = RequestType.scheduled);
                          _selectDateTime(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_requestType == RequestType.scheduled &&
                  _selectedDate != null) ...[
                const SizedBox(height: 12),
                Text(
                  "${lang.schedule_date}: ${DateFormat('yyyy-MM-dd – HH:mm').format(_selectedDate!)}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: kTextSecondary ?? _textSecondaryColor,
                  ),
                  textDirection:
                      isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: lang.request_details,
                  labelStyle: GoogleFonts.poppins(
                    color: kTextSecondary ?? _textSecondaryColor,
                  ),
                  prefixIcon: Icon(Icons.description,
                      color: kPrimaryColor ?? _primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: (kBackground ?? _backgroundColor).withOpacity(0.5),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? lang.request_details_error
                    : null,
                textDirection:
                    isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                      parent: _animationController!, curve: Curves.easeInOut),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradientColor ??
                        LinearGradient(
                            colors: [_primaryColor, _secondaryColor]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ||
                            _selectedWashType == null ||
                            (_requestType == RequestType.scheduled &&
                                _selectedDate == null)
                        ? null
                        : () => _submitRequest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: Text(
                      lang.submit,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textDirection:
                          isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                  ),
                ),
              ),
              if (_isOfflineMode) ...[
                const SizedBox(height: 12),
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                          parent: _animationController!,
                          curve: Curves.easeInOut),
                    ),
                    child: OutlinedButton(
                      onPressed: () async => await _checkConnectivity(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kPrimaryColor ?? _primaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        lang.refresh,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor ?? _primaryColor,
                        ),
                        textDirection:
                            isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingWidget(AppLocalizations lang) {
    final isRtl = lang.localeName == 'ar';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/images/searching.json',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            lang.searching_for_provider,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary ?? _textPrimaryColor,
            ),
            textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          ),
          const SizedBox(height: 12),
          ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(
                  parent: _animationController!, curve: Curves.easeInOut),
            ),
            child: OutlinedButton(
              onPressed: () async {
                if (_currentRequestId != null && !_isOfflineMode) {
                  try {
                    await FirebaseDatabase.instance
                        .ref()
                        .child("allRideRequests")
                        .child(_currentRequestId!)
                        .update({"status": "cancelled"});
                  } catch (e, stackTrace) {
                    debugPrint("Error cancelling request: $e\n$stackTrace");
                  }
                }
                if (mounted && !_isDisposed) {
                  setState(() {
                    _isSearching = false;
                    _isProviderAssigned = false;
                    _currentRequestId = null;
                    _selectedStore = null;
                  });
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kError ?? _errorColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                lang.cancel,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kError ?? _errorColor,
                ),
                textDirection:
                    isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderAssignedWidget(AppLocalizations lang) {
    final isRtl = lang.localeName == 'ar';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor:
                  (kPrimaryColor ?? _primaryColor).withOpacity(0.1),
              child: Icon(
                Icons.directions_car,
                size: 48,
                color: kPrimaryColor ?? _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "${lang.provider_assigned}: $_providerName",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextPrimary ?? _textPrimaryColor,
              ),
              textDirection:
                  isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            const SizedBox(height: 8),
            Text(
              _providerPhone.isNotEmpty
                  ? _providerPhone
                  : lang.phone_not_available,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextSecondary ?? _textSecondaryColor,
              ),
              textDirection:
                  isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                        parent: _animationController!, curve: Curves.easeInOut),
                  ),
                  child: OutlinedButton(
                    onPressed: () async {
                      if (_currentRequestId != null && !_isOfflineMode) {
                        try {
                          await FirebaseDatabase.instance
                              .ref()
                              .child("allRideRequests")
                              .child(_currentRequestId!)
                              .update({"status": "cancelled"});
                        } catch (e, stackTrace) {
                          debugPrint(
                              "Error cancelling request: $e\n$stackTrace");
                        }
                      }
                      if (mounted && !_isDisposed) {
                        setState(() {
                          _isSearching = false;
                          _isProviderAssigned = false;
                          _currentRequestId = null;
                          _selectedStore = null;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kError ?? _errorColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      lang.cancel,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kError ?? _errorColor,
                      ),
                      textDirection:
                          isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                        parent: _animationController!, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: kPrimaryGradientColor ??
                          LinearGradient(
                              colors: [_primaryColor, _secondaryColor]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _startChat(
                        _currentRequestId ?? 'unknown',
                        _providerName,
                        {
                          'contact': _providerPhone,
                          'rating':
                              4.0, // Placeholder, as rating is already handled in _searchNearestProvider
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        lang.chatNow,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textDirection:
                            isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    if (_isDisposed || !mounted) return;
    final localizations = lang(context);
    try {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        locale: Locale(localizations.localeName),
      );
      if (pickedDate == null || !mounted || _isDisposed) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime == null || !mounted || _isDisposed) return;
      final selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (selectedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.schedule_date_error,
              style: GoogleFonts.poppins(),
            ),
          ),
        );
        return;
      }
      setState(() => _selectedDate = selectedDateTime);
    } catch (e, stackTrace) {
      debugPrint("Error selecting date/time: $e\n$stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.error,
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  Future<void> _syncOfflineRequests() async {
    if (_isOfflineMode || _isDisposed || !mounted || _prefs == null) return;
    try {
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('request_')).toList();
      for (final key in keys) {
        final requestJson = _prefs!.getString(key);
        if (requestJson != null) {
          try {
            final requestData = jsonDecode(requestJson) as Map<String, dynamic>;
            final ref =
                FirebaseDatabase.instance.ref().child("allRideRequests").push();
            await ref.set(requestData).timeout(const Duration(seconds: 5));
            await _prefs!.remove(key);
            debugPrint("Synced offline request: $key");
            if (requestData['serviceType'] == 'mobileCarWash' &&
                mounted &&
                !_isDisposed) {
              setState(() {
                _currentRequestId = ref.key;
                _isSearching = true;
              });
              await _searchNearestProvider();
            }
          } catch (e, stackTrace) {
            debugPrint("Error syncing request $key: $e\n$stackTrace");
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error syncing offline requests: $e\n$stackTrace");
    }
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _animationController?.dispose();
      _bottomSheetController?.dispose();
      _descriptionController.dispose();
      _searchController.dispose();
      _requestStatusSubscription?.cancel();
      _connectivitySubscription?.cancel();
      _geofireSubscription?.cancel();
      _debounceTimer?.cancel();
      _mapController?.dispose();
      super.dispose();
      debugPrint("CarWashPage disposed");
    }
    super.dispose();
  }
}
