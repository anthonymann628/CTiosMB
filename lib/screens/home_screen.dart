// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../services/sync_service.dart';
import '../widgets/loading_indicator.dart'; // If you have a custom loading widget
// Otherwise, just remove references and use CircularProgressIndicator

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Please wait...')
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  ElevatedButton(
                    onPressed: _downloadRoute,
                    child: const Text('Download Route'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _syncData,
                    child: const Text('Sync Pending Data'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (appState.isLoggedIn) {
                        Navigator.pushNamed(context, '/routeSelect');
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: const Text('Go to Next'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _downloadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // You can call a method from SyncService or RouteService if relevant
      // e.g. await RouteService.instance.fetchRoutes();
      // For now, just simulate
      await Future.delayed(const Duration(seconds: 1));
      // If success, no error
    } catch (e) {
      setState(() => _error = 'Failed to download route. $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _syncData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final success = await SyncService.syncPendingData();
      if (!success) {
        setState(() => _error = 'Data sync failed.');
      }
    } catch (e) {
      setState(() => _error = 'Data sync error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
}
