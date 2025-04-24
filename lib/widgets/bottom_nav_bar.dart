// lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../screens/login_screen.dart';
import '../screens/route_select_screen.dart';

class CarrierTrackBottomNav extends StatelessWidget {
  const CarrierTrackBottomNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Route Select',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
      ],
      currentIndex: 0, // no dynamic highlight with only 2 items
      onTap: (index) {
        if (index == 0) {
          // Route Select
          Navigator.pushReplacementNamed(context, RouteSelectScreen.routeName);
        } else {
          // Logout
          context.read<AppState>().clearUser();
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      },
    );
  }
}
