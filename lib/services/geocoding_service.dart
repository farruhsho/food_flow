import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeocodingService {
  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return _formatAddress(placemark);
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  // Get coordinates from address
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }

  // Search for addresses (autocomplete)
  Future<List<String>> searchAddresses(String query) async {
    if (query.isEmpty || query.length < 3) return [];

    try {
      final locations = await locationFromAddress(query);

      final List<String> addresses = [];
      for (final location in locations) {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          final address = _formatAddress(placemarks.first);
          if (address != null) addresses.add(address);
        }
      }

      return addresses.take(5).toList(); // Limit to 5 results
    } catch (e) {
      print('Address search error: $e');
      return [];
    }
  }

  // Calculate distance between two points (in meters)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Calculate delivery fee based on distance
  double calculateDeliveryFee(double distanceInMeters) {
    const double baseFee = 5000.0; // Base fee in UZS
    const double perKmFee = 2000.0; // Fee per km

    final distanceInKm = distanceInMeters / 1000;

    if (distanceInKm <= 2.0) {
      return baseFee;
    }

    return baseFee + ((distanceInKm - 2.0) * perKmFee);
  }

  // Format placemark to readable address
  String? _formatAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  // Check if location is within delivery area
  bool isWithinDeliveryArea(
    double userLat,
    double userLng,
    double restaurantLat,
    double restaurantLng,
    double maxDeliveryDistanceKm,
  ) {
    final distance = calculateDistance(userLat, userLng, restaurantLat, restaurantLng);
    return distance <= (maxDeliveryDistanceKm * 1000);
  }

  // Get estimated delivery time based on distance
  int getEstimatedDeliveryTime(double distanceInMeters) {
    // Assuming average speed of 30 km/h
    const double averageSpeedKmPerHour = 30.0;
    final distanceInKm = distanceInMeters / 1000;
    final timeInHours = distanceInKm / averageSpeedKmPerHour;
    final timeInMinutes = (timeInHours * 60).ceil();

    // Add preparation time (15 minutes)
    return timeInMinutes + 15;
  }
}
