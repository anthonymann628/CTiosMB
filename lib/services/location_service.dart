import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/permissions.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    bool granted = await Permissions.ensureLocationPermission();
    if (!granted) return null;
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      return null;
    }
  }

  static Future<void> openMap(String address) async {
    if (address.isEmpty) return;
    String query = Uri.encodeComponent(address);
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
    String appleUrl = 'http://maps.apple.com/?q=$query';
    try {
      if (await canLaunch(googleUrl)) {
        await launch(googleUrl);
      } else if (await canLaunch(appleUrl)) {
        await launch(appleUrl);
      }
    } catch (e) {
      // Could not launch map
    }
  }
}
