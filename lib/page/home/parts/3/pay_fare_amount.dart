import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';
import 'package:rana_jayeen/infoHandller/app_info.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';

class PayFareAmount extends StatefulWidget {
  final String rideRequestId;

  const PayFareAmount({
    Key? key,
    required this.rideRequestId,
  }) : super(key: key);

  @override
  _PayFareAmountState createState() => _PayFareAmountState();
}

class _PayFareAmountState extends State<PayFareAmount>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  bool _isLoading = true;
  double _fareAmount = 0.0;
  String _serviceType = '';
  String _driverName = '';
  String _errorMessage = '';
  SharedPreferences? _prefs;
  DatabaseReference? _rideRequestRef;
  StreamSubscription<DatabaseEvent>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController!, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializePreferences();
      await _fetchRideDetails();
      _animationController?.forward();
    });
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _fetchRideDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _rideRequestRef = FirebaseDatabase.instance
          .ref()
          .child("allRideRequests")
          .child(widget.rideRequestId);
      final snapshot = await _rideRequestRef!.get();
      if (snapshot.exists && mounted) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _fareAmount =
              double.tryParse(data['fare_amount']?.toString() ?? '0.0') ?? 0.0;
          _serviceType = data['service_type'] ?? 'Unknown';
          _driverName = data['driver_name'] ?? 'Unknown';
          _isLoading = false;
        });
        await _prefs?.setString('ride_${widget.rideRequestId}_details',
            '$_serviceType|$_driverName|$_fareAmount');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              //    AppLocalizations.of(context)?.ride_not_found ??
              "Ride not found.";
        });
        toastification.show(
          context: context,
          title: Text(AppLocalizations.of(context)?.error ?? "Error"),
          description: Text(_errorMessage),
          type: ToastificationType.error,
          style: ToastificationStyle.minimal,
          autoCloseDuration: const Duration(seconds: 5),
          backgroundColor: Colors.red[700],
        );
      }

      // Listen for real-time updates
      _rideSubscription = _rideRequestRef!.onValue.listen((event) {
        if (event.snapshot.value != null && mounted) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            _fareAmount =
                double.tryParse(data['fare_amount']?.toString() ?? '0.0') ??
                    0.0;
            _serviceType = data['service_type'] ?? 'Unknown';
            _driverName = data['driver_name'] ?? 'Unknown';
            _isLoading = false;
          });
          _prefs?.setString('ride_${widget.rideRequestId}_details',
              '$_serviceType|$_driverName|$_fareAmount');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            //AppLocalizations.of(context)?.error_fetching_details ??
            "Failed to fetch ride details.";
      });
      toastification.show(
        context: context,
        title: Text(AppLocalizations.of(context)?.error ?? "Error"),
        description: Text(_errorMessage),
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        backgroundColor: Colors.red[700],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          // localizations?.review_fare ??
          "Review Fare Details",
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        leading: Semantics(
          label: 'Go back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SlideTransition(
                position: _slideAnimation!,
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _isLoading
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 200,
                                  color: Colors.white,
                                ),
                              )
                            : _errorMessage.isNotEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _errorMessage,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            color: Colors.red[700],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Semantics(
                                          label: 'Retry fetching details',
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 24),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              backgroundColor: Colors.blue[600],
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: _fetchRideDetails,
                                            child: Text(localizations?.retry ??
                                                "Retry"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Semantics(
                                    label: 'Ride details',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          //  localizations?.ride_details ??
                                          "Ride Details",
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "${localizations?.service_type ?? "Service Type"}: $_serviceType",
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          "${localizations?.provider ?? "Provider"}: $_driverName",
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "${
                                          //localizations?.fare_amount ??
                                          "Fare Amount"}: ${_fareAmount.toStringAsFixed(2)}",
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Semantics(
                                          label: 'Back button',
                                          child: Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                        horizontal: 24),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                backgroundColor:
                                                    Colors.blue[600],
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(localizations?.back ??
                                                  "Back"),
                                            ),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _rideSubscription?.cancel();
    super.dispose();
  }
}
