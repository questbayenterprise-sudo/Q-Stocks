import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/database/database_helper.dart';

class AuthRepository {
  final String baseUrl = AppConfig.baseUrl;
  final _dbHelper = DatabaseHelper.instance;
  String _generateOTP() {
    var rng = Random();
    var code = rng.nextInt(900000) + 100000; // Ensures 6 digits
    return code.toString();
  }

  Future<bool> checkUserExists(String email) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim()],
    );

    // Returns true if a record was found
    return maps.isNotEmpty;
  }

  // 2. Local "Send OTP" Logic
  Future<bool> sendOtpLocal(String email) async {
    final db = await _dbHelper.database;
    final otp = _generateOTP();

    // Set expiry to 7 minutes from now
    final expiresAt = DateTime.now()
        .add(const Duration(minutes: 7))
        .toIso8601String();

    try {
      // Save OTP to local otp_log table
      await db.insert('otp_log', {
        'emailid': email,
        'otp': otp,
        'is_verified': 0,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt,
      });

      // NOTE: In a pure offline app, you can't "send" an email easily.
      // For development, we print it to the console.
      // For production, you would use a package like 'mailer' or an API like EmailJS.
      print("DEBUG: Local OTP for $email is $otp");

      return true;
    } catch (e) {
      print("Error saving OTP: $e");
      return false;
    }
  }

  // 3. Local "Verify OTP" Logic (Matches your Go-Postgres Logic)
  Future<Map<String, dynamic>> verifyOtpLocal(String email, String otp) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    // Check if a valid, unverified, non-expired OTP exists
    final List<Map<String, dynamic>> results = await db.query(
      'otp_log',
      where: 'emailid = ? AND otp = ? AND is_verified = 0 AND expires_at > ?',
      whereArgs: [email, otp, now],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      final logId = results.first['id'];

      // Update the OTP log to verified (SQLite standard update)
      await db.update(
        'otp_log',
        {'is_verified': 1, 'verified_at': now},
        where: 'id = ?',
        whereArgs: [logId],
      );

      // Fetch user data to create the session
      final List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      return {
        'success': true,
        'data': users.isNotEmpty
            ? users.first
            : {'id': 0, 'username': 'Guest', 'usertype': 'User'},
      };
    } else {
      throw Exception("Invalid or Expired OTP");
    }
  }

  /// Handles Login/Sign In
  Future<Map<String, dynamic>> signIn(String email) async {
  final db = await DatabaseHelper.instance.database;

  // 1. Get the OTP setting from the Database
  final List<Map<String, dynamic>> settings = await db.query('tbl_general_settings', limit: 1);
  
  // SQLite stores booleans as 0 or 1. Check if enable_otp is 0 (false)
  bool isOtpDisabled = settings.isNotEmpty && settings.first['enable_otp'] == 0;

  // 2. Look for the user
  final List<Map<String, dynamic>> maps = await db.query(
    'users',
    where: 'email = ?',
    whereArgs: [email.trim()],
  );

  if (maps.isNotEmpty) {
    return {
      'success': true,
      // If DB says OTP is 0, then otp_skipped is TRUE
      'otp_skipped': isOtpDisabled, 
      'data': maps.first,
    };
  } else {
    throw Exception("User not found. Please Sign Up.");
  }
}

  /// Handles Account Creation
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String phone,
  }) async {
    if (AppConfig.isCloudDb) {
      // --- CLOUD LOGIC (Your existing Multipart code) ---
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/Create_Cususer"),
      );
      request.fields['email'] = email;
      request.fields['phoneno'] = phone;
      request.fields['username'] = username;
      request.fields['usertype'] = "Customer";
      request.fields['acccode'] = "CUST_DEFAULT";

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } else {
      // --- LOCAL SQLITE LOGIC ---
      final db = await DatabaseHelper.instance.database;

      // Insert into local users table
      final id = await db.insert('users', {
        'username': username,
        'email': email,
        'phoneno': phone,
        'is_active': 1,
      });

      return {
        'success': true,
        'otp_skipped': true,
        'data': {'id': id, 'username': username, 'usertype': 'Customer'},
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    if (AppConfig.isCloudDb) {
      // --- CLOUD LOGIC ---
      final response = await http.post(
        Uri.parse("$baseUrl/Verify_OTP"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("Verification failed. Please try again.");
    } else {
      // --- LOCAL LOGIC ---
      // In local mode, we verify the user exists in SQLite
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (maps.isNotEmpty) {
        return {'success': true, 'data': maps.first};
      }
      throw Exception("Local user record not found.");
    }
  }

  Future<void> resendOtp(String email) async {
    if (AppConfig.isCloudDb) {
      final response = await http.post(
        Uri.parse("$baseUrl/Send_OTP"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": "OTP_FLOW"}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] != true)
        throw Exception(data['message'] ?? "Resend failed");
    }
    // Local mode: No action needed as OTP is simulated/skipped
  }
}
