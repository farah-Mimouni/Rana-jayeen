import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rana_jayeen/constants.dart';
import 'package:rana_jayeen/globel/var_glob.dart';
import 'package:rana_jayeen/infoHandller/app_info.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/models/direction.dart';
import 'package:shimmer/shimmer.dart';

class ChangeLocation extends StatefulWidget {
  const ChangeLocation({super.key});

  @override
  State<ChangeLocation> createState() => _ChangeLocationState();
}

class _ChangeLocationState extends State<ChangeLocation>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _googleController =
      Completer<GoogleMapController>();
  Position? _currentPosition;
  LatLng? _pickLocation;
  GoogleMapController? _mapController;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchSuggestions = [];
  bool _isSearching = false;
  bool _isLoadingLocation = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: kAnimationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController!, curve: Curves.easeOutCubic),
    );
    _searchController.addListener(_debounceSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkPermission();
      await _getCurrentLocation();
      _animationController?.forward();
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever && mounted) {
        _showSnackBar(
          AppLocalizations.of(context)?.location_permission_error ??
              'Location Permission Permanently Denied',
          actionLabel: AppLocalizations.of(context)?.settings ?? 'Settings',
          action: Geolocator.openAppSettings,
        );
      }
    } catch (e) {
      debugPrint('Permission error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _pickLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        await _updateCameraPosition();
        await _updateAddress();
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        _showSnackBar('Error getting location');
      }
    }
  }

  Future<void> _updateCameraPosition() async {
    if (_pickLocation != null && _mapController != null) {
      final cameraPosition = CameraPosition(target: _pickLocation!, zoom: 16);
      await _mapController!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    }
  }

  Future<void> _updateAddress() async {
    if (_pickLocation == null || !mounted) return;
    try {
      final placemarks = await placemarkFromCoordinates(
        _pickLocation!.latitude,
        _pickLocation!.longitude,
      ).timeout(const Duration(seconds: 5));

      String address =
          AppLocalizations.of(context)?.unknown_location ?? 'Unknown Location';
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        address = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ').trim();
      }

      final userPickUpAddress = Directions()
        ..locationLatitude = _pickLocation!.latitude
        ..locationLongitude = _pickLocation!.longitude
        ..locationName = address.isEmpty
            ? (AppLocalizations.of(context)?.unknown_location ??
                'Unknown Location')
            : address;

      if (mounted) {
        Provider.of<AppInfo>(context, listen: false)
            .updatePickUpLocationAddress(userPickUpAddress);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        _showSnackBar('Error getting address');
      }
    }
  }

  Future<void> _loadMapStyle(GoogleMapController controller) async {
    try {
      final mapStyle = await DefaultAssetBundle.of(context)
          .loadString('theme/modern_dark_style.json');
      await controller.setMapStyle(mapStyle);
    } catch (e) {
      debugPrint('Error updating map theme: $e');
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _searchAddress(_searchController.text);
    });
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final locations =
          await locationFromAddress(query).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _searchSuggestions = locations.take(5).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching address: $e');
      if (mounted) {
        setState(() {
          _searchSuggestions = [];
          _isSearching = false;
        });
        _showSnackBar('Error searching address');
      }
    }
  }

  Future<void> _selectSearchResult(Location location) async {
    setState(() {
      _pickLocation = LatLng(location.latitude, location.longitude);
      _searchSuggestions = [];
      _searchController.clear();
    });
    await _updateCameraPosition();
    await _updateAddress();
  }

  void _showSnackBar(String message,
      {String? actionLabel, VoidCallback? action}) {
    final localizations = AppLocalizations.of(context);
    final isRtl = localizations?.localeName == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
        backgroundColor: kError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: kPrimaryLightColor,
                onPressed: action,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isRtl = localizations?.localeName == 'ar';

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: _currentPosition != null,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            initialCameraPosition: googleplexinitial,
            onMapCreated: (controller) {
              _mapController = controller;
              _googleController.complete(controller);
              _loadMapStyle(controller);
              _getCurrentLocation();
            },
            onCameraMove: (position) {
              setState(() => _pickLocation = position.target);
            },
            onCameraIdle: _updateAddress,
          ),
          Positioned(
            top: 48,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: kSurface,
              foregroundColor: kTextPrimary,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 20),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: kSurface,
              foregroundColor: kTextPrimary,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, size: 20),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
            ),
          ),
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation!,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: kBorderRadius,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: localizations?.search_location ??
                                'Search for a location',
                            hintStyle: GoogleFonts.inter(
                              color: kTextSecondary,
                              fontSize: 15,
                            ),
                            prefixIcon:
                                Icon(Icons.search, color: kTextSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: kTextSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchSuggestions = []);
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: kBorderRadius,
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: kSurface.withOpacity(0.95),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          textDirection:
                              isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                      if (_isSearching)
                        Shimmer.fromColors(
                          baseColor: kTextSecondary.withOpacity(0.3),
                          highlightColor: kSurface,
                          child: Container(
                            height: 4,
                            color: kSurface,
                          ),
                        ),
                      if (_searchSuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12)),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchSuggestions.length,
                            itemBuilder: (context, index) {
                              return FutureBuilder<List<Placemark>>(
                                future: placemarkFromCoordinates(
                                  _searchSuggestions[index].latitude,
                                  _searchSuggestions[index].longitude,
                                ),
                                builder: (context, snapshot) {
                                  String address =
                                      localizations?.loading ?? 'Loading...';
                                  if (snapshot.hasData &&
                                      snapshot.data!.isNotEmpty) {
                                    final placemark = snapshot.data!.first;
                                    address = [
                                      placemark.street,
                                      placemark.subLocality,
                                      placemark.locality,
                                      placemark.administrativeArea,
                                      placemark.country,
                                    ]
                                        .where((e) => e != null && e.isNotEmpty)
                                        .join(', ')
                                        .trim();
                                    if (address.isEmpty) {
                                      address =
                                          localizations?.unknown_location ??
                                              'Unknown Location';
                                    }
                                  }
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    title: Text(
                                      address,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: kTextPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textDirection: isRtl
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                    ),
                                    onTap: () => _selectSearchResult(
                                        _searchSuggestions[index]),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Image.asset(
                'assets/images/pin.png',
                height: 48,
                width: 48,
                color: kPrimary,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation!,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: kBorderRadius,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _isLoadingLocation
                      ? Shimmer.fromColors(
                          baseColor: kTextSecondary.withOpacity(0.3),
                          highlightColor: kSurface,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: kBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : Text(
                          Provider.of<AppInfo>(context)
                                  .userPickUplocation
                                  ?.locationName ??
                              (localizations?.noAddressFound ??
                                  'No address found'),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: kTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textDirection:
                              isRtl ? TextDirection.rtl : TextDirection.ltr,
                          softWrap: true,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ScaleTransition(
              scale: _scaleAnimation!,
              child: ElevatedButton(
                onPressed: _pickLocation != null
                    ? () => Navigator.pop(context, _pickLocation)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
                  elevation: 3,
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  localizations?.setLocationButton ?? 'Confirm Location',
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
