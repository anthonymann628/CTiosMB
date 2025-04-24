import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/app_state.dart';
import 'login_screen.dart';
import 'route_select_screen.dart';

// Permissions
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // record start time
    final start = DateTime.now();

    // 1) Request permissions
    await _requestAllPermissions();

    // 2) Load saved token / user
    await AuthService.loadSavedToken();

    // 3) Ensure at least 1.5s of splash
    final elapsed = DateTime.now().difference(start);
    const minSplash = Duration(milliseconds: 1500);
    if (elapsed < minSplash) {
      await Future.delayed(minSplash - elapsed);
    }

    // 4) Navigate
    final appState = context.read<AppState>();
    if (appState.isLoggedIn) {
      Navigator.pushReplacementNamed(context, RouteSelectScreen.routeName);
    } else {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  Future<void> _requestAllPermissions() async {
    // Location
    var locPerm = await Geolocator.checkPermission();
    if (locPerm == LocationPermission.denied ||
        locPerm == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
    // Camera
    if (!await Permission.camera.isGranted) {
      await Permission.camera.request();
    }
    // Microphone
    if (!await Permission.microphone.isGranted) {
      await Permission.microphone.request();
    }
    // Add more if needed
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
