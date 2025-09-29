import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rana_jayeen/page/tips.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rana_jayeen/constants.dart' as AppColors;

class MapScreen extends StatefulWidget {
  static const routeName = '/map';

  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Map<String, Map<String, dynamic>> _activeDrivers = {};
  final Map<String, Map<String, dynamic>> _driverDetails = {};
  Position? _currentPosition;
  String? _selectedDriverId;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
    _loadDrivers();
    _loadDriverDetails();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorToast(AppLocalizations.of(context)!.locationDisabled);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorToast(AppLocalizations.of(context)!.locationPermissionDenied);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorToast(
          AppLocalizations.of(context)!.locationPermissionDeniedForever);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      _showErrorToast(AppLocalizations.of(context)!.locationError);
    }
  }

  void _loadDrivers() {
    DatabaseReference driversRef =
        FirebaseDatabase.instance.ref().child('activeDrivers');
    driversRef.onValue.listen((event) {
      _markers.clear();
      _activeDrivers.clear();
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          final driverData = Map<String, dynamic>.from(value);
          if (driverData.containsKey('l') &&
              driverData['l'] is List &&
              driverData['l'].length >= 2) {
            final lat = double.tryParse(driverData['l'][0].toString()) ?? 0.0;
            final lng = double.tryParse(driverData['l'][1].toString()) ?? 0.0;
            _activeDrivers[key] = driverData;
            _markers.add(
              Marker(
                markerId: MarkerId(key),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure),
                onTap: () {
                  setState(() {
                    _selectedDriverId = key;
                  });
                  _slideController.forward(from: 0);
                  _scaleController.forward(from: 0);
                },
                infoWindow: InfoWindow(
                  title: _driverDetails[key]?['username'] as String? ??
                      AppLocalizations.of(context)!.unknown,
                  snippet: _driverDetails[key]?['job'] as String? ??
                      AppLocalizations.of(context)!.unknown,
                ),
              ),
            );
          }
        });
        setState(() {});
      }
    }, onError: (error) {
      debugPrint('Error loading drivers: $error');
      _showErrorToast(AppLocalizations.of(context)!.dataError);
    });
  }

  void _loadDriverDetails() {
    DatabaseReference detailsRef =
        FirebaseDatabase.instance.ref().child('driver_users');
    detailsRef.get().then((snapshot) {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          _driverDetails[key] = Map<String, dynamic>.from(value);
        });
        setState(() {});
      }
    }).catchError((error) {
      debugPrint('Error loading driver details: $error');
      _showErrorToast(AppLocalizations.of(context)!.dataError);
    });
  }

  void _showErrorToast(String message) {
    final loc = AppLocalizations.of(context)!;
    Fluttertoast.showToast(
      msg: '${loc.error}: $message',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 5,
      backgroundColor: AppColors.kEmergency,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: 'center',
      webBgColor: '#E57373',
    );
  }

  void _showSuccessToast(String message) {
    final loc = AppLocalizations.of(context)!;
    Fluttertoast.showToast(
      msg: '${loc.success}: $message',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: AppColors.kSuccess,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: 'center',
      webBgColor: '#4CAF50',
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final loc = AppLocalizations.of(context)!;
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _showSuccessToast(loc.call_initiated);
    } else {
      debugPrint('Could not launch $phoneNumber');
      _showErrorToast(loc.callError);
    }
  }

  Future<void> _copyContact(String contact) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await Clipboard.setData(ClipboardData(text: contact));
      _showSuccessToast("contact Copied");
    } catch (e) {
      debugPrint('Error copying contact: $e');
      //_showErrorToast(loc.copyError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.kPrimaryGradientColor,
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude)
                      : const LatLng(36.7538, 3.0588), // Default: Algiers
                  zoom: 12,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (_currentPosition != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude),
                      ),
                    );
                  }
                },
              ),
              if (_selectedDriverId != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildDriverInfoBottomSheet(isLightMode),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoBottomSheet(bool isLightMode) {
    final loc = AppLocalizations.of(context)!;
    final driver = _driverDetails[_selectedDriverId] ?? {};
    final location = _activeDrivers[_selectedDriverId];
    if (driver.isEmpty && location == null) return const SizedBox.shrink();

    final String username = driver['username'] as String? ?? loc.unknown;
    final String contact = driver['contact'] as String? ?? loc.unknown;
    final String job = driver['job'] as String? ?? loc.unknown;
    final String status = driver['newRideStatus'] as String? ?? loc.unknown;
    final String? avatarUrl = driver['avatarUrl'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface.withOpacity(0.95),
        borderRadius: AppColors.kBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  loc.driverInfo,
                  style: AppColors.textTheme(context).titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextPrimary,
                      ),
                  textDirection: loc.localeName == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
              ),
              IconButton(
                icon:
                    Icon(Symbols.close_rounded, color: AppColors.kPrimaryColor),
                onPressed: () {
                  setState(() {
                    _selectedDriverId = null;
                  });
                  _slideController.reverse();
                },
                tooltip: loc.close,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.kPrimaryColor.withOpacity(0.2),
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              username.substring(0, 1).toUpperCase(),
                              style: AppColors.textTheme(context)
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.kTextPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: AppColors.textTheme(context).titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextPrimary,
                          ),
                      textDirection: loc.localeName == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job,
                      style: AppColors.textTheme(context).bodyMedium?.copyWith(
                            color: AppColors.kTextSecondary,
                          ),
                      textDirection: loc.localeName == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Symbols.phone_rounded,
            label: loc.contact,
            value: contact,
            onTap: contact != loc.unknown ? () => _copyContact(contact) : null,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Symbols.directions_car_rounded,
            label: loc.status,
            value: status,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (contact != loc.unknown)
                _buildButton(
                  onPressed: () => _makePhoneCall(contact),
                  icon: Symbols.phone_rounded,
                  text: loc.callDriver,
                  isLightMode: isLightMode,
                ),
              _buildButton(
                onPressed: () {
                  Navigator.pushNamed(context, CarFixesTipsScreen.routeName);
                },
                icon: Symbols.person_rounded,
                text: loc.view_providers,
                isLightMode: isLightMode,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.kPrimaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppColors.textTheme(context).bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kPrimaryColor,
                      ),
                  textDirection: loc.localeName == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppColors.bodyLargeAccessible.copyWith(
                    color: AppColors.kTextPrimary,
                  ),
                  textDirection: loc.localeName == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Symbols.content_copy_rounded,
              color: AppColors.kTextSecondary,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required bool isLightMode,
  }) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        onPressed();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: AppColors.kPrimaryGradientColor,
            borderRadius: AppColors.kBorderRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: AppColors.textTheme(context).bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                textDirection: loc.localeName == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
