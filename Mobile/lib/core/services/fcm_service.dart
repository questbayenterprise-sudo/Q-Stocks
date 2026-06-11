import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../../features/auth/Session/user_session.dart';

class FcmService {
  static final String _baseUrl = AppConfig.baseUrl;
  static String? _currentToken;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM — call after Firebase.initializeApp() and user login
  static Future<void> init() async {
    // Initialize local notifications
    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;

    // Request permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create Android notification channel
    await _createNotificationChannel();

    // Get token and save to server
    final token = await messaging.getToken();
    if (token != null) {
      _currentToken = token;
      debugPrint('FCM Token: $token');
      await saveTokenToServer(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      saveTokenToServer(newToken);
    });

    // Handle foreground messages — show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.data}');
    });
  }

  /// Initialize local notifications plugin
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  /// Create high-priority notification channel
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'qsports_bookings',
      'Booking Notifications',
      description: 'Notifications for booking confirmations and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show a local notification when message arrives in foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'qsports_bookings',
      'Booking Notifications',
      channelDescription: 'Notifications for booking confirmations and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  /// Save FCM token to backend (upsert per device)
  static Future<void> saveTokenToServer(String fcmToken) async {
    final userId = UserSession().userId;
    if (userId == null) return;

    try {
      final url = Uri.parse('$_baseUrl/Save_FcmToken');
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "fcm_token": fcmToken,
          "device_id": _getDeviceId(),
          "platform": Platform.isAndroid ? "android" : "ios",
        }),
      );
    } catch (e) {
      // Silent fail
    }
  }

  /// Remove FCM token on logout
  static Future<void> removeTokenFromServer() async {
    final userId = UserSession().userId;
    if (userId == null || _currentToken == null) return;

    try {
      final url = Uri.parse('$_baseUrl/Remove_FcmToken');
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "fcm_token": _currentToken,
        }),
      );
    } catch (e) {
      // Silent fail
    }
    _currentToken = null;
  }

  static String _getDeviceId() {
    return "${Platform.operatingSystem}_${Platform.localHostname}";
  }
}
