import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<bool> ensureLocationPermission() async {
    var status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> ensureCameraPermission() async {
    var status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }
}
