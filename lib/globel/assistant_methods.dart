import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rana_jayeen/globel/RequestAssistant.dart';
import 'package:rana_jayeen/globel/var_glob.dart';
import 'package:rana_jayeen/infoHandller/app_info.dart';
import 'package:rana_jayeen/l10n/app_localizations.dart';
import 'package:rana_jayeen/l10n/app_localizations_en.dart';
import 'package:rana_jayeen/models/derectionDetail_info.dart';
import 'package:rana_jayeen/models/direction.dart';
import 'package:rana_jayeen/models/userModel.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:googleapis_auth/auth_io.dart';

class AssistantMethodes {
  static final Logger _logger = Logger(printer: PrettyPrinter());

  static void readCurrentOnlineUse() async {
    DatabaseReference Userref = FirebaseDatabase.instance
        .ref()
        .child("auth_user")
        .child(currentUser!.uid);
    Userref.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModer.fromSnapshot(snap.snapshot);
      }
    });
  }

  static void readCurrentOnlineUser() async {
    try {
      print(currentUser);
      DatabaseReference Userref = FirebaseDatabase.instance
          .ref()
          .child("auth_user")
          .child(currentUser!.uid);

      DatabaseEvent event = await Userref.once();
      DataSnapshot snap = event.snapshot;

      if (snap.value != null) {
        userModelCurrentInfo = UserModer.fromSnapshot(snap);
      } else {
        _logger.w("No user data found for UID: ${currentUser!.uid}");
      }
    } catch (error) {
      _logger.e("Error reading current online user: $error");
    }
  }

  static Future<String> searchAdreessForGeographiCoOridinate(
      Position position, context) async {
    String apiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googlemap";

    String humanReadableAddress = "";

    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);
    if (requestResponse != "error occured .faild No response") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationName = humanReadableAddress;
      Provider.of<AppInfo>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }
    return humanReadableAddress;
  }

  static Future<DirectionDetailsInfo?>
      obtainOriginToDestinationDirectionDetails(
    LatLng originPosition,
    LatLng destinationPosition,
    BuildContext context, {
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (originPosition.latitude == 0.0 ||
        originPosition.longitude == 0.0 ||
        destinationPosition.latitude == 0.0 ||
        destinationPosition.longitude == 0.0) {
      _logger.e(
          'Invalid coordinates: origin=$originPosition, destination=$destinationPosition');
      _showToast(
        context: context,
        title: lang(context).error,
        description: lang(context).error_invalid_coordinates,
        type: ToastificationType.error,
        icon: Icons.error,
        backgroundColor: const Color(0xFFD32F2F),
      );
      return null;
    }

    final cacheKey =
        'directions_${originPosition.latitude}_${originPosition.longitude}_${destinationPosition.latitude}_${destinationPosition.longitude}';
    final prefs = await SharedPreferences.getInstance();

    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final json = jsonDecode(cachedData);
        _logger.i('Retrieved cached directions for $cacheKey');
        return DirectionDetailsInfo.fromJson(json);
      } catch (e, stackTrace) {
        _logger.w('Error parsing cached directions: $e',
            error: e, stackTrace: stackTrace);
      }
    }

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$googlemap';

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await RequestAssistant.receiveRequest(url).timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('Directions API request timed out');
          },
        );

        if (response == 'error occurred. failed. No response' ||
            response['status'] != 'OK') {
          _logger.w(
              'Directions API error: ${response['error_message'] ?? 'Unknown error'}');
          if (attempt == maxRetries) {
            _showToast(
              context: context,
              title: lang(context).error,
              description: lang(context).error_fetching_directions ??
                  'Failed to fetch directions',
              type: ToastificationType.error,
              icon: Icons.error,
              backgroundColor: const Color(0xFFD32F2F),
            );
            return null;
          }
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        final directionDetailsInfo = DirectionDetailsInfo()
          ..e_point = response['routes'][0]['overview_polyline']['points']
          ..distance_text = response['routes'][0]['legs'][0]['distance']['text']
          ..distance_value =
              response['routes'][0]['legs'][0]['distance']['value']
          ..duration_text = response['routes'][0]['legs'][0]['duration']['text']
          ..duration_value =
              response['routes'][0]['legs'][0]['duration']['value'];

        try {
          await prefs.setString(
              cacheKey, jsonEncode(directionDetailsInfo.toJson()));
          _logger.i('Cached directions for $cacheKey');
        } catch (e, stackTrace) {
          _logger.w('Error caching directions: $e',
              error: e, stackTrace: stackTrace);
        }

        return directionDetailsInfo;
      } catch (e, stackTrace) {
        _logger.e('Error fetching directions (attempt $attempt): $e',
            error: e, stackTrace: stackTrace);
        if (attempt == maxRetries) {
          _showToast(
            context: context,
            title: lang(context).error,
            description: lang(context).error_fetching_directions ??
                'Failed to fetch directions: $e',
            type: ToastificationType.error,
            icon: Icons.error,
            backgroundColor: const Color(0xFFD32F2F),
          );
          return null;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return null;
  }

  static Future<bool> sendNotificationToDriverNow(
    String? deviceRegisterToken,
    String userRideRequestId,
    BuildContext context,
  ) async {
    if (deviceRegisterToken == null || deviceRegisterToken.isEmpty) {
      _logger.e("Error: Driver token is null or empty");
      _showToast(
        context: context,
        title: lang(context).error,
        description: "Driver token is not available",
        type: ToastificationType.error,
        icon: Icons.error,
        backgroundColor: const Color(0xFFD32F2F),
      );
      return false;
    }

    // Basic validation of token format (FCM tokens are typically long strings)
    if (deviceRegisterToken.length < 100) {
      _logger.w("Suspicious FCM token length: $deviceRegisterToken");
      _showToast(
        context: context,
        title: lang(context).error,
        description: "Cannot send notification: Invalid driver token",
        type: ToastificationType.error,
        icon: Icons.error,
        backgroundColor: const Color(0xFFD32F2F),
      );
      return false;
    }

    final appInfo = Provider.of<AppInfo>(context, listen: false);
    String destinationAddress =
        appInfo.userPickUplocation?.locationName ?? "Unknown location";

    final title = "New Service Request";
    final body =
        "${"Destination"}: $destinationAddress\n${"Request ID"}: #$userRideRequestId";

    final data = {
      'type': 'service_request',
      'rideRequestId': userRideRequestId,
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'destination_address': destinationAddress,
    };

    try {
      await sendFCMNotification(
        deviceToken: deviceRegisterToken,
        userRideRequestId: userRideRequestId,
        title: title,
        body: body,
        data: data,
        context: context,
      );
      _showToast(
        context: context,
        title: lang(context).success ?? "Success",
        description:
            lang(context).notificationSent ?? "Notification sent successfully",
        type: ToastificationType.success,
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e, stackTrace) {
      _logger.e("Error sending notification: $e",
          error: e, stackTrace: stackTrace);
      _showToast(
        context: context,
        title: lang(context).error,
        description: lang(context).failed_to_send_notification ??
            "Failed to send notification",
        type: ToastificationType.error,
        icon: Icons.error,
        backgroundColor: const Color(0xFFD32F2F),
      );
      return false;
    }
  }

  static Future<void> sendFCMNotification({
    required String deviceToken,
    required String userRideRequestId,
    required String title,
    required String body,
    required Map<String, String> data,
    required BuildContext context,
  }) async {
    const String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/newme-f9c0a/messages:send';
    final String? accessToken = await _getAccessToken();
    if (accessToken == null) {
      _logger.e("Failed to obtain access token for FCM");
      throw Exception("Failed to obtain access token");
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOffline = !(await _hasInternetAccess());

    if (isOffline) {
      _logger.w(
          'Offline mode: Queuing FCM notification for ride $userRideRequestId');
      await _queueNotification(
        deviceToken: deviceToken,
        userRideRequestId: userRideRequestId,
        title: title,
        body: body,
        data: data,
        context: context,
      );
      _showToast(
        context: context,
        title: lang(context).offline_mode ?? "Offline Mode",
        description: lang(context).message_queued ??
            "Notification queued for later delivery",
        type: ToastificationType.warning,
        icon: Icons.warning,
        backgroundColor: const Color(0xFFD32F2F),
      );
      return;
    }

    const int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(fcmEndpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode({
                'message': {
                  'token': deviceToken,
                  'notification': {
                    'title': title,
                    'body': body,
                  },
                  'data': data,
                  'android': {
                    'priority': 'high',
                    'notification': {
                      'sound': 'default',
                      'channel_id': 'ride_notifications',
                    },
                  },
                  'apns': {
                    'payload': {
                      'aps': {
                        'sound': 'default',
                        'badge': 1,
                      },
                    },
                  },
                },
              }),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          _logger.i(
              'FCM notification sent successfully for ride $userRideRequestId');
          return;
        } else {
          _logger.w(
              'FCM notification attempt $attempt failed: ${response.statusCode} - ${response.body}');
          if (attempt == maxRetries) {
            if (response.body.contains("INVALID_ARGUMENT") &&
                response.body.contains("registration token")) {
              _logger.w("Invalid FCM token detected: $deviceToken");
              throw Exception("Invalid FCM registration token");
            }
            throw Exception(
                'Failed to send FCM notification: ${response.body}');
          }
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e, stackTrace) {
        _logger.e('Error sending FCM notification (attempt $attempt): $e',
            error: e, stackTrace: stackTrace);
        if (attempt == maxRetries) {
          await _queueNotification(
            deviceToken: deviceToken,
            userRideRequestId: userRideRequestId,
            title: title,
            body: body,
            data: data,
            context: context,
          );
          if (e.toString().contains("Invalid FCM registration token")) {
            _showToast(
              context: context,
              title: lang(context).error,
              description: "Cannot send notification: Invalid driver token",
              type: ToastificationType.error,
              icon: Icons.error,
              backgroundColor: const Color(0xFFD32F2F),
            );
          } else {
            _showToast(
              context: context,
              title: lang(context).error,
              description: lang(context).failed_to_send_notification ??
                  "Failed to send notification",
              type: ToastificationType.error,
              icon: Icons.error,
              backgroundColor: const Color(0xFFD32F2F),
            );
          }
        } else {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  static Future<void> _queueNotification({
    required String deviceToken,
    required String userRideRequestId,
    required String title,
    required String body,
    required Map<String, String> data,
    required BuildContext context,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final queuedNotifications =
          prefs.getStringList('queued_notifications') ?? [];
      final notificationData = jsonEncode({
        'deviceToken': deviceToken,
        'userRideRequestId': userRideRequestId,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      queuedNotifications.add(notificationData);
      await prefs.setStringList('queued_notifications', queuedNotifications);
      _logger.i('Queued FCM notification for ride $userRideRequestId');
    } catch (e, stackTrace) {
      _logger.e('Error queuing notification: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  static Future<void> processQueuedNotifications(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final queuedNotifications =
        prefs.getStringList('queued_notifications') ?? [];
    if (queuedNotifications.isEmpty) return;

    final List<String> remainingNotifications = [];
    final now = DateTime.now();
    for (final notificationData in queuedNotifications) {
      try {
        final data = jsonDecode(notificationData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        // Skip notifications older than 24 hours
        if (now.difference(timestamp).inHours > 24) {
          _logger.w('Skipping expired queued notification: $notificationData');
          continue;
        }
        final String deviceToken = data['deviceToken'] as String;
        final String userRideRequestId = data['userRideRequestId'] as String;
        final String title = data['title'] as String;
        final String body = data['body'] as String;
        final Map<String, String> notificationDataMap =
            Map<String, String>.from(data['data'] as Map);

        await sendFCMNotification(
          deviceToken: deviceToken,
          userRideRequestId: userRideRequestId,
          title: title,
          body: body,
          data: notificationDataMap,
          context: context,
        );
        _logger.i('Processed queued notification for ride $userRideRequestId');
      } catch (e, stackTrace) {
        _logger.e('Error processing queued notification: $e',
            error: e, stackTrace: stackTrace);
        remainingNotifications.add(notificationData);
      }
    }
    await prefs.setStringList('queued_notifications', remainingNotifications);
  }

  static Future<bool> _hasInternetAccess() async {
    try {
      final response = await http
          .get(Uri.parse('https://dns.google.com/resolve?name=google.com'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      _logger.e('Internet access check failed: $e',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  static Future<String?> _getAccessToken() async {
    try {
      final serviceAccountJson =
          await rootBundle.loadString('assets/newme-f9c0a-038c8891ddb8.json');
      final serviceAccount = jsonDecode(serviceAccountJson);
      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccount);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final accessToken = await client.credentials.accessToken;
      if (accessToken.expiry.isAfter(DateTime.now())) {
        return accessToken.data;
      } else {
        _logger.e("Access token expired");
        return null;
      }
    } catch (e, stackTrace) {
      _logger.e("Error getting access token: $e",
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static void _showToast({
    required BuildContext context,
    required String title,
    required String description,
    required ToastificationType type,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final isRtl = lang(context).localeName == 'ar';
    toastification.showCustom(
      builder: (context, item) => Container(
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
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Icon(icon, color: const Color(0xFFFFFFFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      direction: isRtl ? TextDirection.rtl : TextDirection.ltr,
    );
  }

  static AppLocalizations lang(BuildContext? context) => context != null
      ? AppLocalizations.of(context) ?? AppLocalizationsEn()
      : AppLocalizationsEn();
}
