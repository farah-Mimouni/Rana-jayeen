import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';

class UserModer {
  String? first;
  String? last;
  String? phone;
  String? id;
  String? address;

  UserModer({this.first, this.last, this.id, this.address, this.phone});

  // Constructor from Firebase DataSnapshot
  UserModer.fromSnapshot(DataSnapshot snap) {
    final data = snap.value as Map<dynamic, dynamic>?;
    phone = data?['phoneNumber']?.toString();
    first = data?['name']?.toString();
    last =
        data?['name']?.toString(); // Note: Using 'name' for both first and last
    id = data?['uid']?.toString();
    address = data?['address']?.toString();
  }

  // Constructor from JSON map
  factory UserModer.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json);
    return UserModer(
      phone: data['phoneNumber']?.toString(),
      first: data['name']?.toString(),
      last: data['name']
          ?.toString(), // Note: Using 'name' for both first and last
      id: data['uid']?.toString(),
      address: data['address']?.toString(),
    );
  }

  // Convert UserModer to JSON map
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phone,
      'name': first, // Storing first as 'name' to match fromSnapshot
      'uid': id,
      'address': address,
    };
  }
}
