import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserRideRequestInformation {
  String? rideRequestId;
  String? username;
  String? originAddress;
  String? userPhone;
  String? job;
  LatLng? originLatLng;
  LatLng? driverLatLng;
  String? status;
  String? driverId;
  String? serviceType;

  UserRideRequestInformation(
      {this.rideRequestId,
      this.username,
      this.originAddress,
      this.userPhone,
      this.job,
      this.originLatLng,
      this.driverLatLng,
      this.driverId,
      this.status,
      this.serviceType});
}
