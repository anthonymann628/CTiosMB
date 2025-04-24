// lib/screens/camera_screen.dart

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CameraScreen extends StatefulWidget {
  static const routeName = '/camera';
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  bool _showPreview = false;
  String? _tempImagePath;
  double? _tempLatitude;
  double? _tempLongitude;

  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _initLocation();
    _setupCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      debugPrint('Location permission denied');
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras?.isEmpty ?? true) return;
      _controller = CameraController(_cameras!.first, ResolutionPreset.medium);
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Error setting up camera: $e');
    }
  }

  /// Capture & geotag, then show preview + note field
  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final xFile = await _controller!.takePicture();
      if (!mounted) return;

      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (_) {
        pos = Position(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          headingAccuracy: 0,
          altitudeAccuracy: 0,
        );
      }

      setState(() {
        _tempImagePath = xFile.path;
        _tempLatitude = pos.latitude;
        _tempLongitude = pos.longitude;
        _showPreview = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _retakePhoto() {
    setState(() {
      _showPreview = false;
      _tempImagePath = null;
      _tempLatitude = null;
      _tempLongitude = null;
      _noteController.clear();
    });
  }

  /// Move file, then pop <path, latitude, longitude, note>
  Future<void> _confirmPhoto() async {
    if (_tempImagePath == null) return;
    try {
      final temp = File(_tempImagePath!);
      if (!await temp.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File missing!')));
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = p.join(appDir.path, name);
      await temp.rename(newPath);

      if (!mounted) return;
      Navigator.pop<Map<String, dynamic>>(context, {
        'path': newPath,
        'latitude': _tempLatitude,
        'longitude': _tempLongitude,
        'note': _noteController.text.trim(),
      });
    } catch (e) {
      debugPrint('Error confirming photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: Text('Initializing camera...')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: _showPreview ? _buildPreview() : _buildLiveView(),
      floatingActionButton: _showPreview
          ? null
          : FloatingActionButton(onPressed: _takePhoto, child: const Icon(Icons.camera_alt)),
    );
  }

  Widget _buildLiveView() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.done) {
          return CameraPreview(_controller!);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Image.file(File(_tempImagePath!), width: double.infinity, fit: BoxFit.contain),
        ),

        if (_tempLatitude != null && _tempLongitude != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Lat: ${_tempLatitude!.toStringAsFixed(5)}, '
              'Lng: ${_tempLongitude!.toStringAsFixed(5)}',
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _noteController,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Enter a note for this photo…',
              border: OutlineInputBorder(),
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _retakePhoto,
              icon: const Icon(Icons.refresh),
              label: const Text('Retake'),
            ),
            ElevatedButton.icon(
              onPressed: _confirmPhoto,
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
