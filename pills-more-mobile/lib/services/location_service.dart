import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Fetches the user's current GPS location and reverse-geocodes it to get address details.
  static Future<Map<String, String>?> getCurrentAddress() async {
    try {
      // 1. Test if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled on your device.');
      }

      // 2. Check and request location permission.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions were denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      // 3. Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Reverse geocode coordinates to list of placemarks
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        String pincode = place.postalCode ?? '';
        String city = place.locality ?? place.subAdministrativeArea ?? '';
        String state = place.administrativeArea ?? '';
        String subLocality = place.subLocality ?? '';
        String street = place.street ?? '';
        
        // Build address line
        String addressLine1 = '';
        if (street.isNotEmpty) {
          addressLine1 += street;
        }
        if (subLocality.isNotEmpty) {
          addressLine1 += (addressLine1.isNotEmpty ? ', ' : '') + subLocality;
        }

        return {
          'pincode': pincode,
          'city': city,
          'state': state,
          'addressLine1': addressLine1,
          'formattedAddress': '${addressLine1.isNotEmpty ? "$addressLine1, " : ""}$city, $state - $pincode',
        };
      }
      return null;
    } catch (e) {
      print('[LOCATION SERVICE ERROR] ${e.toString()}');
      rethrow;
    }
  }
}
