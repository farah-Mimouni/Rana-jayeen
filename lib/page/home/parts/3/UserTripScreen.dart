import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/constants.dart' as AppColors;
import 'package:rana_jayeen/globel/assistant_methods.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/l10n/app_localizations_en.dart';
import 'package:rana_jayeen/models/userRideRequs.dart';
import 'package:rana_jayeen/notif/chats.dart';
import 'package:rana_jayeen/notif/chat_utils.dart';
import 'package:rana_jayeen/notif/NotificationService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math' as math;

class UserTripScreen extends StatefulWidget {
  static const String routeName = '/user_trip_screen';
  final UserRideRequestInformation rideRequestDetails;

  const UserTripScreen({Key? key, required this.rideRequestDetails})
      : super(key: key);

  @override
  _UserTripScreenState createState() => _UserTripScreenState();
}

class _UserTripScreenState extends State<UserTripScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _googleController =
      Completer<GoogleMapController>();
  GoogleMapController? _mapController;
  Timer? _locationTimer;
  StreamSubscription<DatabaseEvent>? _rideSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<DatabaseEvent>? _chatMessageSubscription;
  Position? _currentPosition;
  Set<Marker> _markerSet = {};
  Set<Polyline> _polylineSet = {};
  BitmapDescriptor? _providerIcon;
  BitmapDescriptor? _userIcon;
  String _providerName = "";
  String _providerPhone = "";
  String _providerJob = "";
  String _providerAddress = "";
  String? _chatId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  bool _isOfflineMode = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  SharedPreferences? _prefs;
  int? _rating;
  String? _comment;
  final Logger _logger = Logger();
  Map<String, dynamic>? _cachedProviderData;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeServices();
    _startConnectionMonitoring();
  }

  void _initializeAnimation() {
    try {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOutQuad),
      );
      _animationController.forward();
    } catch (e, stackTrace) {
      _logger.e('Error initializing animation: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    _locationTimer?.cancel();
    _rideSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _chatMessageSubscription?.cancel();
    _animationController.dispose();
    _mapController?.dispose();
    _googleController.future
        .then((controller) => controller.dispose())
        .catchError((e) {
      _logger.e('Error disposing GoogleMapController: $e', error: e);
    });
    _mapController = null;
  }

  Future<void> _initializeServices() async {
    if (_isInitialized || _isDisposed || !mounted) return;
    _isInitialized = true;
    setState(() => _isLoading = true);

    try {
      _prefs = await SharedPreferences.getInstance();
      await Future.wait([
        NotificationService().initialize(context),
        _getPermission(),
        _getCurrentLocation(),
        _createCustomMarkerIcons(),
        _fetchProviderDetails(),
      ]);
      if (!_isDisposed && mounted) {
        _listenToRideUpdates();
        _startLocationUpdates();
      }
    } catch (e, stackTrace) {
      _logger.e('Error initializing services: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_initialize);
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && !_isDisposed) {
          setState(() => _isOfflineMode = true);
          _showError(lang(context).error_location_denied);
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && !_isDisposed) {
            _showError(lang(context).error_location_denied);
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted && !_isDisposed) {
          _showError(lang(context).error_location_denied);
        }
        return;
      }
    } catch (e, stackTrace) {
      _logger.e('Error checking location permission: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).error_location_denied);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      if (mounted && !_isDisposed) {
        setState(() {
          _currentPosition = position;
          _isOfflineMode = false;
        });
        await _updateMapSafely();
      }
    } catch (e, stackTrace) {
      _logger.e('Error getting current location: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        setState(() => _isOfflineMode = true);
        _showError(lang(context).error_location_failed(e));
      }
    }
  }

  Future<void> _createCustomMarkerIcons() async {
    if (_isDisposed || !mounted) return;
    try {
      final imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(40, 40));
      bool userIconExists = await _assetExists('assets/icons/user_icon.png');
      bool providerIconExists =
          await _assetExists('assets/icons/provider_icon.png');

      _userIcon = userIconExists
          ? await BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'assets/icons/user_icon.png')
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _providerIcon = providerIconExists
          ? await BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'assets/icons/provider_icon.png')
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      if (mounted && !_isDisposed) setState(() {});
    } catch (e, stackTrace) {
      _logger.e('Error creating marker icons: $e',
          error: e, stackTrace: stackTrace);
      _userIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _providerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      if (mounted && !_isDisposed) setState(() {});
    }
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchProviderDetails() async {
    if (_isDisposed || !mounted || widget.rideRequestDetails.driverId == null)
      return;
    try {
      if (_isOfflineMode) {
        await _loadOfflineProviderDetails();
        return;
      }

      if (_cachedProviderData != null) {
        setState(() {
          _providerName =
              _cachedProviderData!['providerName'] ?? lang(context).unknown;
          _providerPhone = _cachedProviderData!['providerPhone'] ??
              lang(context).phone_not_available;
          _providerJob = _cachedProviderData!['serviceType'] ??
              lang(context).not_specified;
          _providerAddress = _cachedProviderData!['providerAddress'] ??
              lang(context).unknown_location;
          _chatId = _cachedProviderData!['chatId'];
        });
        return;
      }

      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child("allRideRequests")
          .child(widget.rideRequestDetails.rideRequestId ?? '');
      DataSnapshot snapshot =
          await ref.get().timeout(const Duration(seconds: 4));
      if (!mounted || _isDisposed) return;
      if (snapshot.exists && snapshot.value is Map) {
        var data = Map<String, dynamic>.from(snapshot.value as Map);
        _cachedProviderData = {
          'providerName': data["providerName"]?.toString() ??
              data["driver_name"]?.toString() ??
              lang(context).unknown,
          'providerPhone': data["providerPhone"]?.toString() ??
              data["rider_phone"]?.toString() ??
              lang(context).phone_not_available,
          'serviceType': data["serviceType"]?.toString() ??
              data["driver_job_details"]?.toString() ??
              lang(context).not_specified,
          'providerAddress': data["origin_address"]?.toString() ??
              lang(context).unknown_location,
          'chatId': data["chatId"]?.toString(),
        };
        setState(() {
          _providerName = _cachedProviderData!['providerName'];
          _providerPhone = _cachedProviderData!['providerPhone'];
          _providerJob = _cachedProviderData!['serviceType'];
          _providerAddress = _cachedProviderData!['providerAddress'];
          _chatId = _cachedProviderData!['chatId'];
        });
        await _prefs!.setString(
            'provider_${widget.rideRequestDetails.driverId}',
            jsonEncode(_cachedProviderData));
      } else {
        _logger.w(
            'No ride data found for ride: ${widget.rideRequestDetails.rideRequestId}');
        await _loadOfflineProviderDetails();
        if (_providerName.isEmpty && mounted && !_isDisposed) {
          Navigator.pop(context);
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error fetching provider details: $e',
          error: e, stackTrace: stackTrace);
      await _loadOfflineProviderDetails();
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_sync);
      }
    }
  }

  Future<void> _loadOfflineProviderDetails() async {
    if (_isDisposed || !mounted || widget.rideRequestDetails.driverId == null)
      return;
    try {
      final json =
          _prefs!.getString('provider_${widget.rideRequestDetails.driverId}');
      if (json != null) {
        _cachedProviderData = jsonDecode(json) as Map<String, dynamic>;
        if (mounted && !_isDisposed) {
          setState(() {
            _providerName =
                _cachedProviderData!['providerName'] ?? lang(context).unknown;
            _providerPhone = _cachedProviderData!['providerPhone'] ??
                lang(context).phone_not_available;
            _providerJob = _cachedProviderData!['serviceType'] ??
                lang(context).not_specified;
            _providerAddress = _cachedProviderData!['providerAddress'] ??
                lang(context).unknown_location;
            _chatId = _cachedProviderData!['chatId'];
          });
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error loading offline provider details: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        setState(() {
          _providerName = lang(context).unknown;
          _providerPhone = lang(context).phone_not_available;
          _providerJob = lang(context).not_specified;
          _providerAddress = lang(context).unknown_location;
        });
        _showError(lang(context).failed_to_sync);
      }
    }
  }

  Future<void> _showRatingDialog(String rideRequestId) async {
    if (!mounted || _isDisposed) return;

    setState(() {
      _rating = null;
      _comment = '';
    });

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final lang = AppLocalizations.of(context)!;
        final isRtl = lang.localeName == 'ar';
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.kSurface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.rate_service,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextPrimary,
                            ),
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starValue = index + 1;
                              return IconButton(
                                icon: Icon(
                                  _rating != null && _rating! >= starValue
                                      ? Icons.star
                                      : Icons.star_border,
                                  color:
                                      _rating != null && _rating! >= starValue
                                          ? AppColors.kPrimary
                                          : AppColors.kTextSecondary,
                                  size: 36,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    _rating = starValue;
                                  });
                                  setState(() {
                                    _rating = starValue;
                                  });
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            lang.comments_optional,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.kTextSecondary,
                            ),
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: lang.enter_comments,
                              hintStyle: GoogleFonts.poppins(
                                color:
                                    AppColors.kTextSecondary.withOpacity(0.7),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.kTextSecondary),
                              ),
                              filled: true,
                              fillColor: AppColors.kSurface.withOpacity(0.9),
                            ),
                            style: GoogleFonts.poppins(
                              color: AppColors.kTextPrimary,
                              fontSize: 16,
                            ),
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            onChanged: (value) {
                              setState(() {
                                _comment = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.kError, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    textStyle: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Text(
                                    lang.cancel,
                                    style: const TextStyle(
                                        color: AppColors.kError),
                                    textDirection: isRtl
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _rating == null
                                      ? null
                                      : () async {
                                          if (_isOfflineMode) {
                                            toastification.showCustom(
                                              builder: (context, item) =>
                                                  _buildCustomToast(
                                                context,
                                                item,
                                                title: lang.error,
                                                description: lang.offline_mode,
                                                type: ToastificationType.error,
                                                icon: Icons.error,
                                                backgroundColor:
                                                    AppColors.kError,
                                              ),
                                              alignment: Alignment.bottomCenter,
                                              autoCloseDuration:
                                                  const Duration(seconds: 4),
                                              direction: isRtl
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                            );
                                            return;
                                          }
                                          try {
                                            final userId = FirebaseAuth
                                                .instance.currentUser?.uid;
                                            if (userId == null) {
                                              throw Exception(
                                                  "No authenticated user");
                                            }
                                            await FirebaseDatabase.instance
                                                .ref()
                                                .child("allRideRequests")
                                                .child(rideRequestId)
                                                .child("rating")
                                                .set({
                                              'rating': _rating,
                                              'comment':
                                                  _comment?.trim().isNotEmpty ??
                                                          false
                                                      ? _comment
                                                      : null,
                                              'ratedBy': userId,
                                              'timestamp': DateTime.now()
                                                  .toIso8601String(),
                                            }).timeout(
                                                    const Duration(seconds: 4));
                                            if (mounted && !_isDisposed) {
                                              toastification.showCustom(
                                                builder: (context, item) =>
                                                    _buildCustomToast(
                                                  context,
                                                  item,
                                                  title: lang.rating_submitted,
                                                  description: lang
                                                      .rating_submitted_message,
                                                  type: ToastificationType
                                                      .success,
                                                  icon: Icons.check_circle,
                                                  backgroundColor:
                                                      AppColors.kSuccess,
                                                ),
                                                alignment:
                                                    Alignment.bottomCenter,
                                                autoCloseDuration:
                                                    const Duration(seconds: 3),
                                                direction: isRtl
                                                    ? TextDirection.rtl
                                                    : TextDirection.ltr,
                                              );
                                              Navigator.pop(context);
                                            }
                                          } catch (e, stackTrace) {
                                            _logger.e(
                                                'Error submitting rating: $e',
                                                error: e,
                                                stackTrace: stackTrace);
                                            if (mounted && !_isDisposed) {
                                              toastification.showCustom(
                                                builder: (context, item) =>
                                                    _buildCustomToast(
                                                  context,
                                                  item,
                                                  title: lang.error,
                                                  description: lang
                                                      .error_submitting_rating,
                                                  type:
                                                      ToastificationType.error,
                                                  icon: Icons.error,
                                                  backgroundColor:
                                                      AppColors.kError,
                                                ),
                                                alignment:
                                                    Alignment.bottomCenter,
                                                autoCloseDuration:
                                                    const Duration(seconds: 4),
                                                direction: isRtl
                                                    ? TextDirection.rtl
                                                    : TextDirection.ltr,
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.kPrimary,
                                    foregroundColor: AppColors.kSurface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    textStyle: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Text(
                                    lang.submit,
                                    textDirection: isRtl
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _listenToRideUpdates() {
    if (_isDisposed || !mounted) return;
    _rideSubscription?.cancel();
    _rideSubscription = FirebaseDatabase.instance
        .ref()
        .child("allRideRequests")
        .child(widget.rideRequestDetails.rideRequestId ?? '')
        .onValue
        .listen((event) async {
      if (!mounted || _isDisposed || event.snapshot.value == null) {
        _logger.w(
            'Ride data deleted or component disposed for rideRequestId: ${widget.rideRequestDetails.rideRequestId}');
        if (mounted && !_isDisposed) {
          Navigator.pop(context);
        }
        return;
      }
      try {
        var data = Map<String, dynamic>.from(event.snapshot.value as Map);
        String newProviderName = data["providerName"]?.toString() ??
            data["driver_name"]?.toString() ??
            _providerName;
        String newProviderPhone = data["providerPhone"]?.toString() ??
            data["rider_phone"]?.toString() ??
            _providerPhone;
        String newProviderJob = data["serviceType"]?.toString() ??
            data["driver_job_details"]?.toString() ??
            _providerJob;
        String newProviderAddress =
            data["origin_address"]?.toString() ?? _providerAddress;
        String? newChatId = data["chatId"]?.toString();
        String? newStatus = data["status"]?.toString();
        LatLng? newDriverLocation = data["driverLocation"] != null
            ? LatLng(
                double.tryParse(
                        data["driverLocation"]["latitude"]!.toString()) ??
                    widget.rideRequestDetails.originLatLng?.latitude ??
                    0.0,
                double.tryParse(
                        data["driverLocation"]["longitude"]!.toString()) ??
                    widget.rideRequestDetails.originLatLng?.longitude ??
                    0.0,
              )
            : null;

        bool needsUpdate = _providerName != newProviderName ||
            _providerPhone != newProviderPhone ||
            _providerJob != newProviderJob ||
            _providerAddress != newProviderAddress ||
            _chatId != newChatId ||
            widget.rideRequestDetails.status != newStatus ||
            (newDriverLocation != null &&
                (widget.rideRequestDetails.originLatLng?.latitude !=
                        newDriverLocation.latitude ||
                    widget.rideRequestDetails.originLatLng?.longitude !=
                        newDriverLocation.longitude));

        if (needsUpdate && mounted && !_isDisposed) {
          _cachedProviderData = {
            'providerName': newProviderName,
            'providerPhone': newProviderPhone,
            'serviceType': newProviderJob,
            'providerAddress': newProviderAddress,
            'chatId': newChatId,
          };
          setState(() {
            _providerName = newProviderName;
            _providerPhone = newProviderPhone;
            _providerJob = newProviderJob;
            _providerAddress = newProviderAddress;
            _chatId = newChatId;
            widget.rideRequestDetails.status =
                newStatus ?? widget.rideRequestDetails.status;
            if (newDriverLocation != null) {
              widget.rideRequestDetails.originLatLng = newDriverLocation;
            }
          });
          await _prefs!.setString(
              'provider_${widget.rideRequestDetails.driverId}',
              jsonEncode(_cachedProviderData));
          await _updateMapSafely();
        }

        if (newStatus == "cancelled") {
          _locationTimer?.cancel();
          if (mounted && !_isDisposed) {
            toastification.showCustom(
              builder: (context, item) => _buildCustomToast(
                context,
                item,
                title: lang(context).trip_cancelled,
                description: lang(context).trip_cancelled_message,
                type: ToastificationType.error,
                icon: Icons.cancel,
                backgroundColor: AppColors.kError,
              ),
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 4),
              direction: lang(context).localeName == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
            Navigator.pop(context);
          }
        } else if (newStatus == "ended") {
          _locationTimer?.cancel();
          if (mounted && !_isDisposed) {
            toastification.showCustom(
              builder: (context, item) => _buildCustomToast(
                context,
                item,
                title: lang(context).trip_ended,
                description: lang(context).trip_ended_message,
                type: ToastificationType.info,
                icon: Icons.info,
                backgroundColor: AppColors.kPrimary,
              ),
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 3),
              direction: lang(context).localeName == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
            await _showRatingDialog(
                widget.rideRequestDetails.rideRequestId ?? '');
            Navigator.pop(context);
          }
        } else if (newStatus == "completed") {
          _locationTimer?.cancel();
          if (mounted && !_isDisposed) {
            Navigator.pushReplacementNamed(
              context,
              '/pay_fare_amount',
              arguments: widget.rideRequestDetails.rideRequestId,
            );
          }
        }
      } catch (e, stackTrace) {
        _logger.e('Error processing ride update: $e',
            error: e, stackTrace: stackTrace);
        if (mounted && !_isDisposed) {
          _showError(lang(context).failed_to_monitor_status);
        }
      }
    }, onError: (e, stackTrace) {
      _logger.e('Error listening to ride updates: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_monitor_status);
      }
    });
  }

  void _listenToChatMessages(String chatId, String userId) {
    if (_isOfflineMode || _isDisposed || !mounted) return;
    _chatMessageSubscription?.cancel();
    final messageRef = FirebaseDatabase.instance
        .ref()
        .child('messages')
        .child(chatId)
        .orderByChild('timestamp')
        .limitToLast(20);

    _chatMessageSubscription = messageRef.onChildAdded.listen((event) async {
      if (!mounted || _isDisposed || event.snapshot.value == null) return;
      final messageData =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      final senderId = messageData['senderId']?.toString();
      final isRead = messageData['read'] == true;
      if (senderId != null &&
          senderId != userId &&
          !isRead &&
          mounted &&
          !_isDisposed) {
        try {
          await FirebaseDatabase.instance
              .ref()
              .child('messages')
              .child(chatId)
              .child(event.snapshot.key!)
              .update({'read': true}).timeout(const Duration(seconds: 4));
        } catch (e, stackTrace) {
          _logger.e('Error marking message as read: $e',
              error: e, stackTrace: stackTrace);
        }
      }
    }, onError: (e, stackTrace) {
      _logger.e('Error listening to messages: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_load_messages);
      }
    });
  }

  void _startLocationUpdates() {
    if (_isDisposed || !mounted) return;
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null && !_isDisposed) {
          await FirebaseDatabase.instance
              .ref()
              .child("auth_user")
              .child(userId)
              .update({
            "location": {
              "latitude": position.latitude.toString(),
              "longitude": position.longitude.toString(),
            },
          }).timeout(const Duration(seconds: 4));
          if (_shouldUpdatePosition(position) && mounted && !_isDisposed) {
            setState(() {
              _currentPosition = position;
              _isOfflineMode = false;
            });
            await _updateMapSafely();
          }
        }
      } catch (e, stackTrace) {
        _logger.e('Error updating user location: $e',
            error: e, stackTrace: stackTrace);
        if (mounted && !_isDisposed) {
          setState(() => _isOfflineMode = true);
          _showError(lang(context).error_location_failed(e));
        }
      }
    });
  }

  bool _shouldUpdatePosition(Position newPosition) {
    if (_currentPosition == null) return true;
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    return distance > 15; // Increased threshold for less frequent updates
  }

  Future<void> _updateMapSafely() async {
    if (_isDisposed ||
        !mounted ||
        _mapController == null ||
        _currentPosition == null ||
        widget.rideRequestDetails.originLatLng == null) return;

    try {
      Set<Marker> tempMarkers = {};
      if (_userIcon != null) {
        tempMarkers.add(
          Marker(
            markerId: const MarkerId("user"),
            position:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: _userIcon!,
            infoWindow: InfoWindow(title: lang(context).your_location),
            zIndex: 2,
          ),
        );
      }
      if (_providerIcon != null &&
          widget.rideRequestDetails.originLatLng != null) {
        tempMarkers.add(
          Marker(
            markerId: const MarkerId("provider"),
            position: widget.rideRequestDetails.originLatLng!,
            icon: _providerIcon!,
            infoWindow: InfoWindow(title: lang(context).provider_location),
            zIndex: 1,
          ),
        );
      }

      if (_markerSet != tempMarkers) {
        setState(() {
          _markerSet = tempMarkers;
        });
      }

      var directionDetails =
          await AssistantMethodes.obtainOriginToDestinationDirectionDetails(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              widget.rideRequestDetails.originLatLng!,
              context);
      if (directionDetails?.e_point != null && mounted && !_isDisposed) {
        Polyline polyline = Polyline(
          polylineId: const PolylineId("route"),
          color: AppColors.kPrimary,
          width: 6,
          points: _decodePoly(directionDetails!.e_point!),
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        );
        if (_polylineSet.isEmpty ||
            _polylineSet.first.points != polyline.points) {
          setState(() {
            _polylineSet = {polyline};
          });
        }
      } else if (mounted && !_isDisposed) {
        setState(() {
          _polylineSet = {};
        });
      }

      await _updateCameraBounds();
    } catch (e, stackTrace) {
      _logger.e('Error updating map: $e', error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).error_location_failed(e));
      }
    }
  }

  Future<void> _updateCameraBounds() async {
    if (_mapController == null ||
        _currentPosition == null ||
        widget.rideRequestDetails.originLatLng == null) return;
    try {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_currentPosition!.latitude,
              widget.rideRequestDetails.originLatLng!.latitude),
          math.min(_currentPosition!.longitude,
              widget.rideRequestDetails.originLatLng!.longitude),
        ),
        northeast: LatLng(
          math.max(_currentPosition!.latitude,
              widget.rideRequestDetails.originLatLng!.latitude),
          math.max(_currentPosition!.longitude,
              widget.rideRequestDetails.originLatLng!.longitude),
        ),
      );
      await _mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
    } catch (e, stackTrace) {
      _logger.e('Error updating camera bounds: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).error_location_failed(e));
      }
    }
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    try {
      while (index < len) {
        int b, shift = 0, result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        points.add(LatLng(lat / 1E5, lng / 1E5));
      }
    } catch (e, stackTrace) {
      _logger.e('Error decoding polyline: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).error_location_failed(e));
      }
    }
    return points;
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final response = await http
          .get(Uri.parse('https://dns.google.com/resolve?name=google.com'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty ||
        phoneNumber == lang(context).phone_not_available) {
      if (mounted && !_isDisposed) {
        _showError(lang(context).phone_not_available);
      }
      return;
    }
    try {
      Uri uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted && !_isDisposed) {
          toastification.showCustom(
            builder: (context, item) => _buildCustomToast(
              context,
              item,
              title: lang(context).call_initiated,
              description: lang(context).call_initiated_message,
              type: ToastificationType.success,
              icon: Icons.phone,
              backgroundColor: AppColors.kPrimary,
            ),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 3),
            direction: lang(context).localeName == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
        }
      } else {
        if (mounted && !_isDisposed) {
          _showError(lang(context).error_phone_call);
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Phone call error: $e', error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).error_phone_call);
      }
    }
  }

  Future<void> _startChat(
      String providerId, String providerName, String serviceType) async {
    if (_isDisposed || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final isConnected = await _hasInternetAccess();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted && !_isDisposed) {
          _showError(lang(context).failed_to_open_chat);
          _makePhoneCall(_providerPhone);
        }
        return;
      }

      String userName = 'User';
      try {
        final userRef =
            FirebaseDatabase.instance.ref().child('auth_user').child(userId);
        final userSnapshot =
            await userRef.get().timeout(const Duration(seconds: 4));
        if (userSnapshot.exists && userSnapshot.value is Map) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          userName = userData['username']?.toString() ?? 'User';
        }
      } catch (e, stackTrace) {
        _logger.e('Error fetching user data: $e',
            error: e, stackTrace: stackTrace);
      }

      String chatId = _chatId ?? ChatUtils.getChatId(userId, providerId);
      if (!isConnected) {
        await _prefs!.setString(
            'pending_chats_${widget.rideRequestDetails.rideRequestId}',
            jsonEncode({
              'chatId': chatId,
              'userId': userId,
              'providerId': providerId,
              'userName': userName,
              'providerName': providerName,
              'serviceType': serviceType,
              'message': lang(context).chat_initiated(serviceType),
              'timestamp': DateTime.now().toIso8601String(),
              'type': 'chat_initiation',
              'requestId':
                  widget.rideRequestDetails.rideRequestId ?? providerId,
            }));
        if (mounted && !_isDisposed) {
          toastification.showCustom(
            builder: (context, item) => _buildCustomToast(
              context,
              item,
              title: lang(context).offline_mode,
              description: lang(context).chat_queued,
              type: ToastificationType.warning,
              icon: Icons.warning,
              backgroundColor: AppColors.kError,
            ),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 4),
            direction: lang(context).localeName == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          _navigateToChat(
              chatId, providerId, providerName, userId, userName, serviceType);
        }
        return;
      }

      final chatRef =
          FirebaseDatabase.instance.ref().child('chats').child(chatId);
      final chatSnapshot =
          await chatRef.get().timeout(const Duration(seconds: 4));
      if (!chatSnapshot.exists) {
        await chatRef.set({
          'participants': {userId: true, providerId: true},
          'providerName': providerName.isNotEmpty ? providerName : 'Provider',
          'serviceType': serviceType.isNotEmpty ? serviceType : 'unknown',
          'requestId': widget.rideRequestDetails.rideRequestId ?? providerId,
          'lastMessage': lang(context).chat_initiated(serviceType),
          'lastTimestamp': ServerValue.timestamp,
          'unread_$userId': false,
          'unread_$providerId': false,
        }).timeout(const Duration(seconds: 4));
      }

      final messageRef = FirebaseDatabase.instance
          .ref()
          .child('messages')
          .child(chatId)
          .push();
      await Future.wait([
        messageRef.set({
          'senderId': userId,
          'senderName': userName,
          'message': lang(context).chat_initiated(serviceType),
          'timestamp': ServerValue.timestamp,
          'read': false,
        }).timeout(const Duration(seconds: 4)),
        FirebaseDatabase.instance
            .ref()
            .child('userChats')
            .child(userId)
            .update({chatId: true}).timeout(const Duration(seconds: 4)),
        FirebaseDatabase.instance
            .ref()
            .child('userChats')
            .child(providerId)
            .update({chatId: true}).timeout(const Duration(seconds: 4)),
        FirebaseDatabase.instance
            .ref()
            .child('allRideRequests')
            .child(widget.rideRequestDetails.rideRequestId ?? '')
            .update({'chatId': chatId}).timeout(const Duration(seconds: 4)),
      ]);

      await _prefs!.setString(
          'provider_$providerId',
          jsonEncode({
            'chatId': chatId,
            'providerId': providerId,
            'userId': userId,
            'providerName': providerName.isNotEmpty ? providerName : 'Provider',
            'serviceType': serviceType.isNotEmpty ? serviceType : 'unknown',
            'contact': _providerPhone.isNotEmpty
                ? _providerPhone
                : lang(context).phone_not_available,
            'lastMessage': lang(context).chat_initiated(serviceType),
            'unread': false,
            'requestId': widget.rideRequestDetails.rideRequestId ?? providerId,
          }));

      if (mounted && !_isDisposed) {
        _navigateToChat(
            chatId, providerId, providerName, userId, userName, serviceType);
      }
    } catch (e, stackTrace) {
      _logger.e('Error starting chat: $e', error: e, stackTrace: stackTrace);
      if (_providerPhone.isNotEmpty &&
          _providerPhone != lang(context).phone_not_available) {
        _makePhoneCall(_providerPhone);
      }
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_open_chat);
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToChat(
      String chatId,
      String providerId,
      String providerName,
      String userId,
      String userName,
      String serviceType) async {
    if (_isDisposed || !mounted) return;
    try {
      _listenToChatMessages(chatId, userId);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chat(
            chatId: chatId,
            providerId: providerId,
            providerName: providerName.isNotEmpty ? providerName : 'Provider',
            userId: userId,
            userName: userName,
            serviceType: serviceType.isNotEmpty ? serviceType : 'unknown',
            requestId: widget.rideRequestDetails.rideRequestId ?? providerId,
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.e('Error navigating to chat: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_open_chat);
      }
    }
  }

  Future<void> _syncPendingChats() async {
    if (_isDisposed || !mounted) return;
    try {
      final json = _prefs!.getString(
          'pending_chats_${widget.rideRequestDetails.rideRequestId}');
      if (json != null) {
        final chatData = jsonDecode(json) as Map<String, dynamic>;
        final chatId = chatData['chatId']?.toString();
        final userId = chatData['userId']?.toString();
        final providerId = chatData['providerId']?.toString();
        final message = chatData['message']?.toString();
        if (chatId != null &&
            userId != null &&
            providerId != null &&
            message != null) {
          await Future.wait([
            FirebaseDatabase.instance.ref().child('chats').child(chatId).set({
              'participants': {userId: true, providerId: true},
              'lastMessage': message,
              'lastTimestamp': ServerValue.timestamp,
              'serviceType': chatData['serviceType']?.toString() ?? 'unknown',
              'requestId': chatData['requestId']?.toString() ?? providerId,
              'providerName':
                  chatData['providerName']?.toString() ?? 'Provider',
              'unread_$userId': false,
              'unread_$providerId': false,
            }).timeout(const Duration(seconds: 4)),
            FirebaseDatabase.instance
                .ref()
                .child('messages')
                .child(chatId)
                .push()
                .set({
              'senderId': userId,
              'senderName': chatData['userName']?.toString() ?? 'User',
              'message': message,
              'timestamp': ServerValue.timestamp,
              'read': false,
            }).timeout(const Duration(seconds: 4)),
            FirebaseDatabase.instance
                .ref()
                .child('userChats')
                .child(userId)
                .update({chatId: true}).timeout(const Duration(seconds: 4)),
            FirebaseDatabase.instance
                .ref()
                .child('userChats')
                .child(providerId)
                .update({chatId: true}).timeout(const Duration(seconds: 4)),
            FirebaseDatabase.instance
                .ref()
                .child('allRideRequests')
                .child(widget.rideRequestDetails.rideRequestId ?? '')
                .update({'chatId': chatId}).timeout(const Duration(seconds: 4)),
          ]);
          await _prefs!.remove(
              'pending_chats_${widget.rideRequestDetails.rideRequestId}');
          if (mounted && !_isDisposed) {
            toastification.showCustom(
              builder: (context, item) => _buildCustomToast(
                context,
                item,
                title: lang(context).chat_synced,
                description: lang(context).chat_synced_message,
                type: ToastificationType.success,
                icon: Icons.check_circle,
                backgroundColor: AppColors.kSuccess,
              ),
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 3),
              direction: lang(context).localeName == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error syncing pending chats: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_sync);
      }
    }
  }

  Future<String?> _fetchDriverFCMToken(String driverId) async {
    try {
      final ref = FirebaseDatabase.instance
          .ref()
          .child('driver_users')
          .child(driverId)
          .child('fcmToken');
      final snapshot = await ref.get().timeout(const Duration(seconds: 4));
      if (snapshot.exists && snapshot.value is String) {
        final token = snapshot.value as String;
        if (token.isNotEmpty && token.length > 100) {
          return token;
        } else {
          await ref.remove();
          return null;
        }
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error fetching FCM token for driver $driverId: $e',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> _cancelRequest() async {
    if (_isDisposed || !mounted) return;
    try {
      final rideRequestId = widget.rideRequestDetails.rideRequestId;
      if (rideRequestId == null || rideRequestId.isEmpty) {
        _logger.e('Invalid ride request ID');
        if (mounted && !_isDisposed) {
          toastification.showCustom(
            builder: (context, item) => _buildCustomToast(
              context,
              item,
              title: lang(context).error,
              description: "invalid_request_id",
              type: ToastificationType.error,
              icon: Icons.error,
              backgroundColor: AppColors.kError,
            ),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 4),
            direction: lang(context).localeName == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
        }
        return;
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = await _hasInternetAccess();
      if (!connectivityResult.contains(ConnectivityResult.wifi) &&
              !connectivityResult.contains(ConnectivityResult.mobile) ||
          !hasInternet) {
        if (mounted && !_isDisposed) {
          toastification.showCustom(
            builder: (context, item) => _buildCustomToast(
              context,
              item,
              title: lang(context).offline_mode,
              description: lang(context).request_queued,
              type: ToastificationType.warning,
              icon: Icons.warning,
              backgroundColor: AppColors.kError,
              actionLabel: lang(context).retry,
              actionCallback: () {
                _cancelRequest();
                toastification.dismiss(item);
              },
            ),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 4),
            direction: lang(context).localeName == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
        }
        await _queueCancellation(rideRequestId);
        return;
      }

      await FirebaseDatabase.instance
          .ref()
          .child("allRideRequests")
          .child(rideRequestId)
          .update({
        "status": "cancelled",
        "cancelled_at": DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 4));

      _locationTimer?.cancel();

      if (widget.rideRequestDetails.driverId != null) {
        final fcmToken =
            await _fetchDriverFCMToken(widget.rideRequestDetails.driverId!);
        if (fcmToken != null) {
          try {
            await AssistantMethodes.sendFCMNotification(
              deviceToken: fcmToken,
              userRideRequestId: rideRequestId,
              title: lang(context).trip_cancelled,
              body: lang(context).trip_cancelled_message,
              data: {
                'type': 'ride_request',
                'requestId': rideRequestId,
                'status': 'cancelled',
              },
              context: context,
            );
          } catch (e, stackTrace) {
            _logger.e('Error sending FCM notification: $e',
                error: e, stackTrace: stackTrace);
          }
        }
      }

      if (mounted && !_isDisposed) {
        toastification.showCustom(
          builder: (context, item) => _buildCustomToast(
            context,
            item,
            title: lang(context).trip_cancelled,
            description: lang(context).trip_cancelled_message,
            type: ToastificationType.info,
            icon: Icons.info,
            backgroundColor: AppColors.kPrimary,
          ),
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 3),
          direction: lang(context).localeName == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      _logger.e('Error cancelling request: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_submit_request);
      }
    }
  }

  Future<void> _queueCancellation(String rideRequestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedCancellations =
          prefs.getStringList('queued_cancellations') ?? [];
      if (!queuedCancellations.contains(rideRequestId)) {
        queuedCancellations.add(jsonEncode({
          'rideRequestId': rideRequestId,
          'driverId': widget.rideRequestDetails.driverId,
          'timestamp': DateTime.now().toIso8601String(),
        }));
        await prefs.setStringList('queued_cancellations', queuedCancellations);
      }
    } catch (e, stackTrace) {
      _logger.e('Error queuing cancellation: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  Widget _buildCustomToast(
    BuildContext context,
    ToastificationItem item, {
    required String title,
    required String description,
    required ToastificationType type,
    required IconData icon,
    required Color backgroundColor,
    String? actionLabel,
    VoidCallback? actionCallback,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        textDirection: lang(context).localeName == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        children: [
          Icon(icon, color: AppColors.kSurface, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.kSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: AppColors.kSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && actionCallback != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: actionCallback,
              child: Text(
                actionLabel,
                style: GoogleFonts.poppins(
                  color: AppColors.kSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
    if (mounted && !_isDisposed) {
      setState(() => _isOfflineMode = !isConnected);
      if (!isConnected) {
        toastification.showCustom(
          builder: (context, item) => _buildCustomToast(
            context,
            item,
            title: lang(context).offline_mode,
            description: lang(context).offline_mode,
            type: ToastificationType.warning,
            icon: Icons.warning,
            backgroundColor: AppColors.kError,
          ),
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 4),
          direction: lang(context).localeName == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
        );
      }
    }
    if (isConnected && !_isDisposed && mounted) {
      _fetchProviderDetails();
      _listenToRideUpdates();
      _startLocationUpdates();
      _syncPendingChats();
      _processQueuedCancellations();
    } else {
      _loadOfflineProviderDetails();
    }
  }

  Future<void> _processQueuedCancellations() async {
    if (_isDisposed || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedCancellations =
          prefs.getStringList('queued_cancellations') ?? [];
      final updatedCancellations = <String>[];
      final now = DateTime.now();

      for (final cancellationJson in queuedCancellations) {
        try {
          final cancellationData =
              jsonDecode(cancellationJson) as Map<String, dynamic>;
          final rideRequestId = cancellationData['rideRequestId']?.toString();
          final driverId = cancellationData['driverId']?.toString();
          final timestampStr = cancellationData['timestamp']?.toString();
          if (rideRequestId == null ||
              driverId == null ||
              timestampStr == null) {
            continue;
          }

          final timestamp = DateTime.parse(timestampStr);
          if (now.difference(timestamp).inHours > 24) {
            continue;
          }

          await FirebaseDatabase.instance
              .ref()
              .child("allRideRequests")
              .child(rideRequestId)
              .update({
            "status": "cancelled",
            "cancelled_at": DateTime.now().toIso8601String(),
          }).timeout(const Duration(seconds: 4));

          final fcmToken = await _fetchDriverFCMToken(driverId);
          if (fcmToken != null) {
            try {
              await AssistantMethodes.sendFCMNotification(
                deviceToken: fcmToken,
                userRideRequestId: rideRequestId,
                title: lang(context).trip_cancelled,
                body: lang(context).trip_cancelled_message,
                data: {
                  'type': 'ride_request',
                  'requestId': rideRequestId,
                  'status': 'cancelled',
                },
                context: context,
              );
            } catch (e, stackTrace) {
              _logger.e('Error sending FCM for queued cancellation: $e',
                  error: e, stackTrace: stackTrace);
            }
          }
        } catch (e, stackTrace) {
          _logger.e('Error processing queued cancellation: $e',
              error: e, stackTrace: stackTrace);
          updatedCancellations.add(cancellationJson);
        }
      }

      await prefs.setStringList('queued_cancellations', updatedCancellations);
    } catch (e, stackTrace) {
      _logger.e('Error processing queued cancellations: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _updateMapTheme(GoogleMapController controller) async {
    try {
      bool styleExists =
          await _assetExists('assets/theme/modern_dark_style.json');
      if (styleExists) {
        String mapStyle = await DefaultAssetBundle.of(context)
            .loadString("assets/theme/modern_dark_style.json");
        await controller.setMapStyle(mapStyle);
      }
    } catch (e, stackTrace) {
      _logger.e('Error loading map theme: $e',
          error: e, stackTrace: stackTrace);
      if (mounted && !_isDisposed) {
        _showError(lang(context).failed_to_initialize);
      }
    }
  }

  void _showError(String message,
      {VoidCallback? actionCallback, String? actionLabel}) {
    if (mounted && !_isDisposed) {
      toastification.showCustom(
        builder: (context, item) => _buildCustomToast(
          context,
          item,
          title: lang(context).error,
          description: message,
          type: ToastificationType.error,
          icon: Icons.error,
          backgroundColor: AppColors.kError,
          actionLabel: actionLabel,
          actionCallback: actionCallback,
        ),
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 4),
        direction: lang(context).localeName == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
      );
    }
  }

  AppLocalizations lang(BuildContext? context) => context != null
      ? AppLocalizations.of(context) ?? AppLocalizationsEn()
      : AppLocalizationsEn();

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final localizations = lang(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isRtl = localizations.localeName == 'ar';

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Stack(
        children: [
          if (_isLoading || _currentPosition == null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.kSurface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  color: AppColors.kPrimary,
                  strokeWidth: 5,
                ),
              ),
            )
          else
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              initialCameraPosition: _initialPosition,
              markers: _markerSet,
              polylines: _polylineSet,
              padding: const EdgeInsets.only(bottom: 240),
              onMapCreated: (GoogleMapController controller) {
                if (!_isDisposed && !_googleController.isCompleted) {
                  _mapController = controller;
                  _updateMapTheme(controller);
                  _googleController.complete(controller);
                  _updateMapSafely();
                }
              },
            ),
          if (_isOfflineMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.kError.withOpacity(0.2),
                padding: const EdgeInsets.all(10),
                child: Text(
                  localizations.offline_mode,
                  style: GoogleFonts.poppins(
                    color: AppColors.kError,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
            ),
          Positioned(
            top: 48,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.kSurface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        color: AppColors.kPrimary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _providerAddress.isNotEmpty
                            ? _providerAddress
                            : localizations.determining_provider_location,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
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
            top: 120,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.kSurface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle,
                        color: AppColors.kPrimary, size: 32),
                    onPressed: () =>
                        _mapController?.animateCamera(CameraUpdate.zoomIn()),
                    tooltip: localizations.zoom_in,
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle,
                        color: AppColors.kPrimary, size: 32),
                    onPressed: () =>
                        _mapController?.animateCamera(CameraUpdate.zoomOut()),
                    tooltip: localizations.zoom_out,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.32,
                  minHeight: 160,
                ),
                decoration: BoxDecoration(
                  color: AppColors.kSurface.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 5,
                            margin: const EdgeInsets.only(top: 8, bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.kTextSecondary.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      localizations.provider_details,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.kTextPrimary,
                                      ),
                                      textDirection: isRtl
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.kPrimary
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        widget.rideRequestDetails.status ??
                                            localizations.in_progress,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.kPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textDirection: isRtl
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor:
                                          AppColors.kPrimary.withOpacity(0.25),
                                      child: Icon(
                                        Icons.person,
                                        color: AppColors.kPrimary,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _providerName.isNotEmpty
                                                ? _providerName
                                                : localizations.loading,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                              color: AppColors.kTextPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textDirection: isRtl
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _providerAddress.isNotEmpty
                                                ? _providerAddress
                                                : localizations.not_available,
                                            style: GoogleFonts.poppins(
                                              color: AppColors.kTextSecondary,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textDirection: isRtl
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _providerPhone.isNotEmpty
                                                ? _providerPhone
                                                : localizations
                                                    .phone_not_available,
                                            style: GoogleFonts.poppins(
                                              color: AppColors.kTextSecondary,
                                              fontSize: 16,
                                            ),
                                            textDirection: isRtl
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _providerJob.isNotEmpty
                                                ? _providerJob
                                                : localizations.not_specified,
                                            style: GoogleFonts.poppins(
                                              color: AppColors.kTextSecondary,
                                              fontSize: 16,
                                            ),
                                            textDirection: isRtl
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _providerPhone.isNotEmpty &&
                                                _providerPhone !=
                                                    localizations
                                                        .phone_not_available &&
                                                !_isOfflineMode
                                            ? () =>
                                                _makePhoneCall(_providerPhone)
                                            : null,
                                        icon: const Icon(Icons.phone, size: 20),
                                        label: Text(
                                          localizations.call,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.kPrimary,
                                          foregroundColor: AppColors.kSurface,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          textStyle: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _providerName.isNotEmpty &&
                                                widget.rideRequestDetails
                                                        .driverId !=
                                                    null &&
                                                !_isOfflineMode
                                            ? () => _startChat(
                                                  widget.rideRequestDetails
                                                      .driverId!,
                                                  _providerName,
                                                  widget.rideRequestDetails
                                                          .serviceType ??
                                                      'unknown',
                                                )
                                            : null,
                                        icon: const Icon(Icons.chat, size: 20),
                                        label: Text(
                                          localizations.chat,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.kAccent,
                                          foregroundColor: AppColors.kSurface,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          textStyle: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isOfflineMode
                                            ? null
                                            : _cancelRequest,
                                        icon: Icon(
                                          Icons.cancel,
                                          size: 20,
                                          color: AppColors.kError,
                                        ),
                                        label: Text(
                                          localizations.cancel,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: AppColors.kError,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColors.kError,
                                            width: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          textStyle: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
