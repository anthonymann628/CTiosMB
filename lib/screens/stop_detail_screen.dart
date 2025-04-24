// lib/screens/stop_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stop.dart';
import '../services/route_service.dart';
import '../services/delivery_service.dart';
import 'barcode_scanner_screen.dart';
import 'camera_screen.dart';
import 'signature_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class StopDetailScreen extends StatefulWidget {
  static const routeName = '/stopDetail';
  const StopDetailScreen({Key? key}) : super(key: key);

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  Stop? _stop;
  late TextEditingController _notesController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stopId = ModalRoute.of(context)?.settings.arguments as int?;
    if (stopId != null) {
      final routeService = context.read<RouteService>();
      _stop = routeService.stops.firstWhere(
        (s) => s.id == stopId,
        orElse: () => throw Exception('Stop $stopId not found'),
      );
      _notesController = TextEditingController(text: _stop!.notes);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    if (_stop == null) return;
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null) {
      await context.read<DeliveryService>().attachBarcode(_stop!, code);
      setState(() {});
    }
  }

  Future<void> _takePhoto() async {
    if (_stop == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (result != null && result['path'] != null) {
      final path = result['path'] as String;
      final lat = result['latitude'] as double?;
      final lng = result['longitude'] as double?;
      final cameraNote = (result['note'] as String?)?.trim() ?? '';

      // 1) update in-memory Stop
      _stop!
        ..photoPath = path
        ..latitude = lat
        ..longitude = lng;

      // 2) if camera-screen note, merge into main notes field
      if (cameraNote.isNotEmpty) {
        _stop!.notes = cameraNote;
        _notesController.text = cameraNote;
      }

      // 3) persist photo (your existing method)
      await context.read<DeliveryService>().attachPhoto(_stop!, path);

      setState(() {});
    }
    // NO auto-complete here
  }

  Future<void> _captureSignature() async {
    if (_stop == null) return;
    final signaturePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SignatureScreen()),
    );
    if (signaturePath != null) {
      await context.read<DeliveryService>().attachSignature(_stop!, signaturePath);
      setState(() {});
    }
  }

  void _onNotesChanged(String text) {
    if (_stop == null) return;
    setState(() => _stop!.notes = text);
  }

  Future<void> _completeStop() async {
    if (_stop == null) return;
    await context.read<DeliveryService>().completeStop(_stop!);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_stop == null) {
      return const Scaffold(
        body: Center(child: Text('Stop not found')),
      );
    }

    // hide back once any work is done:
    final hasChanges = _stop!.barcodes.isNotEmpty ||
        _stop!.photoPath != null ||
        _stop!.signaturePath != null ||
        (_stop!.notes?.isNotEmpty ?? false);

    return WillPopScope(
      onWillPop: () async => !hasChanges,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stop Detail'),
          automaticallyImplyLeading: !hasChanges,
        ),
        bottomNavigationBar: const CarrierTrackBottomNav(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAddressSection(),
              const SizedBox(height: 16),
              _buildMainCard(context),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    _stop!.completed ? 'Stop Completed' : 'Complete & Save Stop',
                  ),
                  onPressed: _stop!.completed ? null : _completeStop,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_stop!.address, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );

  Widget _buildMainCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barcodes
            Text('Scanned Barcodes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_stop!.barcodes.isEmpty ? 'None' : _stop!.barcodes.join(', ')),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
              onPressed: _scanBarcode,
            ),

            const Divider(height: 24),

            // Photo
            Text('Photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            _buildPhotoPreview(),
            if (_stop!.photoPath != null && _stop!.latitude != null && _stop!.longitude != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Lat: ${_stop!.latitude!.toStringAsFixed(5)}, '
                  'Lng: ${_stop!.longitude!.toStringAsFixed(5)}',
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_stop!.photoPath == null ? 'Take Photo' : 'Retake Photo'),
              onPressed: _takePhoto,
            ),

            const Divider(height: 24),

            // Signature
            Text('Signature', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            _buildSignaturePreview(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.draw),
              label: Text(_stop!.signaturePath == null ? 'Capture Signature' : 'Retake Signature'),
              onPressed: _captureSignature,
            ),

            const Divider(height: 24),

            // Notes
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Enter any delivery notes here…',
                border: OutlineInputBorder(),
              ),
              onChanged: _onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    if (_stop!.photoPath == null) return const Text('No Photo');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(_stop!.photoPath!),
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSignaturePreview() {
    if (_stop!.signaturePath == null) return const Text('No Signature');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(_stop!.signaturePath!),
        width: double.infinity,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }
}
