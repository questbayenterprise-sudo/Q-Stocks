import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;
  bool get isLoggedIn => _userId != null;

  // Initialize and check if user is already logged in
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    notifyListeners();
  }

  // Save userId when user signs in/up
  Future<void> login(String id) async {
    _userId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', id);
    notifyListeners(); // Tells the UI to update
  }

  // Clear userId on logout
  Future<void> logout() async {
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }
}