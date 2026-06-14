import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

// Core Imports
import 'core/navigation/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/Session/user_session.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() {
  // 1. Ensure bindings are initialized before any plugin calls.
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();

  // 2. Kick off initialization asynchronously without 'await'ing in main.
  // This allows the Dart entry point to finish and the Flutter engine to 
  // begin rendering the first frame immediately, avoiding Choreographer skip warnings.
  final initFuture = _initApp(themeProvider);

  runApp(MyApp(
    themeProvider: themeProvider,
    initFuture: initFuture,
  ));
}

Future<void> _initApp(ThemeProvider themeProvider) async {
  try {
    // 1. Initialize Firebase (essential for startup)
    await Firebase.initializeApp();
    
    // 2. Load local sessions and themes
    await Future.wait([
      UserSession().loadSession(),
      themeProvider.loadTheme(),
    ]);

    // 3. Register background handler with a delay.
    // This allows the main engine to stabilize before spawning the background isolate.
    Future.delayed(const Duration(seconds: 3), () {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    });
  } catch (e) {
    debugPrint("App Initialization Error: $e");
  }
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final Future<void> initFuture;

  const MyApp({
    super.key,
    required this.themeProvider,
    required this.initFuture,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp.router(
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          title: 'q_play',
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          // Use the builder to overlay a loading screen while background 
          // initialization is in progress.
          builder: (context, child) {
            return FutureBuilder<void>(
              future: initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Material(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return child ?? const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }
}