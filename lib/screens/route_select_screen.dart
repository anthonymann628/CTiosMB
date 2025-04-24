// lib/screens/route_select_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/route_service.dart';
import '../models/route.dart';
import 'stops_list_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class RouteSelectScreen extends StatefulWidget {
  static const routeName = '/routeSelect';
  const RouteSelectScreen({Key? key}) : super(key: key);

  @override
  State<RouteSelectScreen> createState() => _RouteSelectScreenState();
}

class _RouteSelectScreenState extends State<RouteSelectScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Example local route files we can import from assets
  final List<String> localRouteFiles = [
    'assets/demoRoutes/demo_data.txt',
    'assets/demoRoutes/demo_data1.txt',
    'assets/demoRoutes/demo_data2.txt',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRoutes(); // optional: load existing routes from DB
  }

  Future<void> _fetchRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<RouteService>().fetchRoutes();
    } catch (e) {
      _errorMessage = 'Error fetching routes: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Called when tapping a local route file
  Future<void> _importLocalFile(String fileName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<RouteService>().importLocalFile(fileName);
    } catch (e) {
      _errorMessage = 'Failed to import local file: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Called when picking a route from DB
  Future<void> _selectRoute(RouteModel route) async {
    try {
      await context.read<RouteService>().selectRoute(route);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, StopsListScreen.routeName);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to select route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeService = context.watch<RouteService>();
    final routes = routeService.routes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Route'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildBody(routes),
      bottomNavigationBar: const CarrierTrackBottomNav(),
    );
  }

  Widget _buildBody(List<RouteModel> routes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Local .txt Files:', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final file in localRouteFiles)
            Card(
              child: ListTile(
                title: Text(file.split('/').last),
                subtitle: const Text('Tap to import into DB'),
                onTap: () => _importLocalFile(file),
              ),
            ),
          const Divider(height: 32),
          Text('Routes in DB:', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (routes.isEmpty)
            const Text('No routes found. Try importing.'),
          for (final r in routes)
            Card(
              child: ListTile(
                title: Text(r.name),
                subtitle: r.date != null
                    ? Text('Valid: ${r.date}')
                    : null,
                onTap: () => _selectRoute(r),
              ),
            ),
        ],
      ),
    );
  }
}
