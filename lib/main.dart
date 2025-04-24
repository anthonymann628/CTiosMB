// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/route_select_screen.dart';
import 'screens/stops_list_screen.dart';
import 'screens/stop_detail_screen.dart';
import 'screens/device_status_screen.dart';
import 'screens/manual_sync_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/log_viewer_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/signature_screen.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/dashboard_screen.dart';

// Services
import 'services/app_state.dart';
import 'services/route_service.dart';
import 'services/delivery_service.dart';
import 'services/settings_service.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Create & load settings BEFORE runApp
  final settingsService = SettingsService();
  await settingsService.loadSettings();

  // 2) Now runApp with the providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => RouteService()),
        ChangeNotifierProvider(create: (_) => DeliveryService()),
        // Provide SettingsService so entire app can read settings
        ChangeNotifierProvider(create: (_) => settingsService),
      ],
      child: const CarrierTrackApp(),
    ),
  );
}

class CarrierTrackApp extends StatelessWidget {
  const CarrierTrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Build a modern, Material 3-style theme from a seed color
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue, // pick your brand color
        brightness: Brightness.light,
      ),
      useMaterial3: true, // enables Material 3 design
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(fontSize: 15),
      ),
    );

    return MaterialApp(
      title: 'CarrierTrack',
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      // You can change initialRoute to DashboardScreen.routeName if you prefer
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (ctx) => const SplashScreen(),
        LoginScreen.routeName: (ctx) => const LoginScreen(),
        RouteSelectScreen.routeName: (ctx) => const RouteSelectScreen(),
        StopsListScreen.routeName: (ctx) => const StopsListScreen(),
        StopDetailScreen.routeName: (ctx) => const StopDetailScreen(),
        DeviceStatusScreen.routeName: (ctx) => const DeviceStatusScreen(),
        ManualSyncScreen.routeName: (ctx) => const ManualSyncScreen(),
        SettingsScreen.routeName: (ctx) => const SettingsScreen(),
        LogViewerScreen.routeName: (ctx) => const LogViewerScreen(),
        ToolsScreen.routeName: (ctx) => const ToolsScreen(),
        CameraScreen.routeName: (ctx) => const CameraScreen(),
        SignatureScreen.routeName: (ctx) => const SignatureScreen(),
        BarcodeScannerScreen.routeName: (ctx) => const BarcodeScannerScreen(),
        DashboardScreen.routeName: (ctx) => const DashboardScreen(),
      },
    );
  }
}
