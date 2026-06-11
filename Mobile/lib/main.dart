import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/animated_background.dart';
import 'core/services/fcm_service.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/venues/presentation/bloc/venue_bloc.dart';
import 'features/venues/data/repositories/venue_repository.dart';
import 'features/My Venues/presentation/bloc/venue_bloc.dart';
import 'features/My Venues/data/repositories/venue_repository.dart';
import 'features/trainers/presentation/bloc/trainer_bloc.dart';
import 'features/auth/Session/user_session.dart';

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Load user session
  await UserSession().loadSession();

  // Initialize FCM (requests permission, saves token to server)
  await FcmService.init();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => VenueBloc(VenueRepository())),
        BlocProvider(create: (context) => MyVenueBloc(MyVenueRepository())),
        BlocProvider(create: (context) => HomeBloc()..add(LoadHomeData())),
        BlocProvider(create: (context) => TrainerBloc()..add(LoadTrainers())),
      ],
      child: MyApp(themeProvider: themeProvider),
    ),
  );
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

  void _onThemeChanged() {
    setState(() {});
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
      title: 'Q Sports',
      theme: ThemeProvider.lightTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      darkTheme: ThemeProvider.darkTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      themeMode: widget.themeProvider.themeMode,
      builder: (context, child) {
        return AnimatedBackground(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
