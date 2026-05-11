import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:real_galaxy/services/payment_expiration_service.dart';
import 'package:real_galaxy/services/fcm_service.dart';
import 'package:real_galaxy/screens/login_screen.dart';
import 'package:real_galaxy/models/user.dart' as app_user;
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:real_galaxy/utils/app_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize FCM service
  await FCMService().initialize();

  // Start payment expiration monitoring
  PaymentExpirationService().startExpirationMonitoring();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<app_user.User?>.value(
          initialData: null,
          value: AuthService().authStateChanges,
        ),
      ],
      child: MaterialApp(
        title: 'Real Galaxy FC',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: const AuthGate(),
        onGenerateRoute: AppRoute.appRoute,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<app_user.User?>(context);

    if (user == null) {
      return const LoginScreen();
    }

    String route;
    switch (user.role) {
      case Role.owner:
        route = '/owner/dashboard';
        break;
      case Role.director:
        route = '/director/dashboard';
        break;
      case Role.admin:
        route = '/admin/dashboard';
        break;
      case Role.coach:
        route = '/coach/dashboard';
        break;
      case Role.parent:
        route = '/parent/dashboard';
        break;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(
        context,
      ).pushReplacementNamed(route, arguments: {'userId': user.id.toString()});
    });

    return const Scaffold(
      backgroundColor: AppTheme.successColor,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onBackgroundColor),
        ),
      ),
    );
  }
}
