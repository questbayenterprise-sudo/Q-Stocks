import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Core Imports
import 'core/navigation/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/config/app_config.dart';
import 'core/database/database_helper.dart';
import 'features/auth/Session/user_session.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  // 1. Initialize Flutter Engine
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeProvider = ThemeProvider();

  // 2. Conditional Database Initialization (First Install Logic)
  if (!AppConfig.isCloudDb) {
    // Ensures SQLite DB is created and script is run before app starts
    await DatabaseHelper.instance.database;
  }

  // 3. Parallel Initialization for Speed (Firebase, Session, Theme)
  await Future.wait([
    Firebase.initializeApp(),
    UserSession().loadSession(),
    themeProvider.loadTheme(),
  ]);

  // 4. Set up FCM Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 5. Launch App (No Global MultiBlocProvider here - using Scoped Providing in Router)
  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatefulWidget {
  final ThemeProvider themeProvider;
  const MyApp({super.key, required this.themeProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Re-build app when theme is toggled
    widget.themeProvider.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      title: 'Broiler Shop Pro',
      
      // Fast, Non-animated Themes
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: widget.themeProvider.themeMode,
    );
  }
}