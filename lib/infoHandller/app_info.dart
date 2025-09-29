import 'package:flutter/cupertino.dart';
import 'package:rana_jayeen/models/direction.dart';

class AppInfo extends ChangeNotifier {
  Directions? userPickUplocation;
  int countTotalServise = 0;
  bool _isOffline = false;
  String? _currentRideId;
  bool _isOfflineMode = false;
  bool _isHighContrastMode = false;
  bool get isOfflineMode => _isOfflineMode;
  bool get isHighContrastMode => _isHighContrastMode;

  void setHighContrastMode(bool value) {
    _isHighContrastMode = value;
    notifyListeners();
  }

  bool get isOffline => _isOffline;

  String? get currentRideId => _currentRideId;

  void setOfflineMode(bool value) {
    if (_isOffline != value) {
      _isOffline = value;
      notifyListeners();
    }
  }

  void updatePickUpLocationAddress(Directions userPickUpAddress) {
    userPickUplocation = userPickUpAddress;
    notifyListeners();
  }

  void setCurrentRideId(String? rideId) {
    _currentRideId = rideId;
    notifyListeners();
  }
}
