// lib/screens/photo_confirm_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';

class PhotoConfirmScreen extends StatelessWidget {
  static const routeName = '/photoConfirm';

  final String imagePath;
  const PhotoConfirmScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Photo')),
      body: Column(
        children: [
          Expanded(
            child: file.existsSync()
                ? Image.file(file, fit: BoxFit.contain)
                : const Center(child: Text('Image not found')),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: const Text('Retake'),
                onPressed: () {
                  Navigator.pop(context, null);
                },
              ),
              ElevatedButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.pop(context, imagePath);
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
