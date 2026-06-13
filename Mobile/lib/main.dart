import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Core Imports
import 'core/navigation/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/Session/user_session.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();

  await Future.wait([
    Firebase.initializeApp(),
    UserSession().loadSession(),
    themeProvider.loadTheme(),
  ]);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // NO MultiBlocProvider here!
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
    widget.themeProvider.addListener(_onThemeChanged);
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

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
      title: 'Broiler Shop',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: widget.themeProvider.themeMode,
    );
  }
}