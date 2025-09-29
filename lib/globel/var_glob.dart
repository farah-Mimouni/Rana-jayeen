import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rana_jayeen/models/userModel.dart';

UserModer? userModelCurrentInfo;
User? currentUser;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
String username = "";
String googlemap = "AIzaSyDSbm0rw1Z03VR3n5t_Rn_h8WqJaZG3Beg";
const CameraPosition googleplexinitial = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
