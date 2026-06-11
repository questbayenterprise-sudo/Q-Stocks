import 'package:shared_preferences/shared_preferences.dart';

enum UserType { user, owner, admin, guest, vendor, manager }

class UserSession {
  UserSession._internal();
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;

  String? userId;
  String? username;
  UserType? userType;
  String? city;
  String? imageUrl;

  Future<void> saveSession(String id, String? name, String? usertype) async {
    userId = id;
    username = name;

    // Convert string to enum safely
    if (usertype != null) {
      userType = UserType.values.firstWhere(
        (e) => e.name.toLowerCase() == usertype.toLowerCase(),
        orElse: () => UserType.user, // default fallback
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
    await prefs.setString('username', name ?? '');
    await prefs.setString('user_type', usertype ?? '');
    // city is loaded separately, preserve existing value
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    userId = prefs.getString('user_id');
    username = prefs.getString('username');
    city = prefs.getString('user_city');
    imageUrl = prefs.getString('user_image_url');

    final typeString = prefs.getString('user_type');
    if (typeString != null && typeString.isNotEmpty) {
      userType = UserType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeString.toLowerCase(),
        orElse: () => UserType.user,
      );
    }
  }

  Future<void> saveCity(String cityName) async {
    city = cityName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_city', cityName);
  }

  Future<void> saveImageUrl(String url) async {
    imageUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_image_url', url);
  }

  Future<void> clearSession() async {
    userId = null;
    username = null;
    userType = null;
    city = null;
    imageUrl = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('user_type');
    await prefs.remove('user_city');
    await prefs.remove('user_image_url');
  }
}
