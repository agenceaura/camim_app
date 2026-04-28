import 'package:flutter/material.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? get profileData => _profileData;

  void updateProfile(Map<String, dynamic>? data) {
    _profileData = data;
    notifyListeners();
  }
}
