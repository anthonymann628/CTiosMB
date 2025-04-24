import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/photo.dart';
import '../utils/permissions.dart';
import 'storage_service.dart';

class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  static Future<Photo?> takePhoto() async {
    bool granted = await Permissions.ensureCameraPermission();
    if (!granted) return null;
    try {
      XFile? file = await _picker.pickImage(source: ImageSource.camera);
      if (file == null) return null;
      // Save the captured image to persistent storage
      File saved = await StorageService.saveFile(file, StorageFolder.photo);
      return Photo(filePath: saved.path);
    } catch (e) {
      return null;
    }
  }
}
