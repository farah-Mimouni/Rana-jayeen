import 'package:rana_jayeen/models/activerdriver.dart';

class GeofireAssistant {
  static List<ActiveDrivers> activeNearDriverlist = [];
  static void deleteofflineDriverformlist(String driverId) {
    int indexNumber = activeNearDriverlist
        .indexWhere((element) => element.providerId == driverId);
    activeNearDriverlist.removeAt(indexNumber);
  }

  static List<ActiveDrivers> activeNearbyDriverList = [];

  /// Removes a driver from the active nearby drivers list by their driver ID.
  static void deleteOfflineDriverFromList(String? driverId) {
    if (driverId == null) return;

    final index = activeNearbyDriverList
        .indexWhere((element) => element.providerId == driverId);
    if (index != -1) {
      activeNearbyDriverList.removeAt(index);
    }
  }

  /// Updates the location of an active driver in the nearby drivers list.
  static void updateActiveDriverLocation(ActiveDrivers driver) {
    if (driver.providerId == null ||
        driver.locationLatitude == null ||
        driver.locationLongitude == null) return;

    final index = activeNearbyDriverList
        .indexWhere((element) => element.providerId == driver.providerId);
    if (index != -1) {
      activeNearbyDriverList[index].locationLatitude = driver.locationLatitude;
      activeNearbyDriverList[index].locationLongitude =
          driver.locationLongitude;
    }
  }

  /// Updates the location of an active driver in the nearby drivers list.

  static void updateActivedriverlocation(ActiveDrivers driverwhompve) {
    int indexNumber = activeNearDriverlist.indexWhere(
        (element) => element.providerId == driverwhompve.providerId);
    activeNearDriverlist[indexNumber].locationLatitude =
        driverwhompve.locationLatitude;
    activeNearDriverlist[indexNumber].locationLongitude =
        driverwhompve.locationLongitude;
  }
}
