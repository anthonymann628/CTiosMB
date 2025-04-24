import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum StorageFolder { photo, signature }

class StorageService {
  static Future<File> saveFile(XFile file, StorageFolder folder) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folderName = folder == StorageFolder.photo ? 'photos' : 'signatures';
    final dirPath = Directory('${appDir.path}/$folderName');
    if (!await dirPath.exists()) {
      await dirPath.create(recursive: true);
    }
    final fileName = file.path.split('/').last;
    final newPath = '${dirPath.path}/$fileName';
    await file.saveTo(newPath);
    return File(newPath);
  }

  static Future<File> saveBytes(List<int> bytes, StorageFolder folder) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folderName = folder == StorageFolder.photo ? 'photos' : 'signatures';
    final dirPath = Directory('${appDir.path}/$folderName');
    if (!await dirPath.exists()) {
      await dirPath.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${dirPath.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }
}
