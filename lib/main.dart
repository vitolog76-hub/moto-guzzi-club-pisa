import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // AGGIUNTO PER ORIENTAMENTO
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/app_update_service.dart';
import 'services/event_service.dart';
import 'services/participation_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Top-level background message handler for Android/iOS.
// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FORZA ORIENTAMENTO ORIZZONTALE
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkForUpdateAndReloadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          Provider(create: (_) => EventService()),
          Provider(create: (_) => ParticipationService()),
        ],
        child: MaterialApp(
          title: 'Moto Guzzi Club Pisa - Aquile Alfee',
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authService.isLoggedIn()) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}