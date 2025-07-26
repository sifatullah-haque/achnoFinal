import 'package:flutter/foundation.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as Math;

class GeocodingService {
  final places = GoogleMapsPlaces(
    apiKey: 'AIzaSyD3Mr3cCo8RIrkqbR-seZaUODMxFrfvLSI',
  );

  // Cache to minimize API calls
  final Map<String, Map<String, double>> _cityCoordinatesCache = {};

  // Initialize with any preloaded city coordinates
  GeocodingService() {
    _loadCachedCoordinates();
    // Preload some common US cities for testing
    _preloadCommonCities();
  }

  // Preload coordinates for common US cities to reduce API calls
  void _preloadCommonCities() {
    final commonCities = {
      'new york': {'latitude': 40.7128, 'longitude': -74.0060},
      'los angeles': {'latitude': 34.0522, 'longitude': -118.2437},
      'chicago': {'latitude': 41.8781, 'longitude': -87.6298},
      'houston': {'latitude': 29.7604, 'longitude': -95.3698},
      'phoenix': {'latitude': 33.4484, 'longitude': -112.0740},
      'philadelphia': {'latitude': 39.9526, 'longitude': -75.1652},
      'san antonio': {'latitude': 29.4241, 'longitude': -98.4936},
      'san diego': {'latitude': 32.7157, 'longitude': -117.1611},
      'dallas': {'latitude': 32.7767, 'longitude': -96.7970},
      'san jose': {'latitude': 37.3382, 'longitude': -121.8863},
      'austin': {'latitude': 30.2672, 'longitude': -97.7431},
      'miami': {'latitude': 25.7617, 'longitude': -80.1918},
      'seattle': {'latitude': 47.6062, 'longitude': -122.3321},
      'san francisco': {'latitude': 37.7749, 'longitude': -122.4194},
    };

    _cityCoordinatesCache.addAll(commonCities);
    debugPrint('Preloaded ${commonCities.length} common city coordinates');
  }

  // Load cached coordinates from SharedPreferences
  Future<void> _loadCachedCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('city_coordinates_cache');

      if (cachedData != null && cachedData.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cachedData);

        decoded.forEach((city, coords) {
          if (coords is Map<String, dynamic>) {
            _cityCoordinatesCache[city] = {
              'latitude': coords['latitude'],
              'longitude': coords['longitude'],
            };
          }
        });

        debugPrint(
            'Loaded ${_cityCoordinatesCache.length} cached city coordinates');
      }
    } catch (e) {
      debugPrint('Error loading cached coordinates: $e');
    }
  }

  // Save coordinates to SharedPreferences
  Future<void> _saveCachedCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'city_coordinates_cache', jsonEncode(_cityCoordinatesCache));
    } catch (e) {
      debugPrint('Error saving cached coordinates: $e');
    }
  }

  // Get coordinates for a city name - improved with better error handling and debugging
  Future<Map<String, double>?> getCoordinatesForCity(String cityName) async {
    if (cityName.isEmpty) {
      debugPrint('Empty city name provided');
      return null;
    }

    // Normalize city name (remove extra spaces, lowercase)
    final normalizedCityName = cityName.trim().toLowerCase();

    debugPrint(
        'Looking up coordinates for city: $cityName (normalized: $normalizedCityName)');

    // Check if we already have this city in cache
    if (_cityCoordinatesCache.containsKey(normalizedCityName)) {
      final coords = _cityCoordinatesCache[normalizedCityName]!;
      debugPrint(
          'Found cached coordinates for $normalizedCityName: ${coords['latitude']}, ${coords['longitude']}');
      return coords;
    }

    try {
      // Search for the city using Places API
      debugPrint('Calling Places API for city: $cityName');
      final response =
          await places.searchByText('$cityName city', type: 'locality');

      if (response.status == 'OK' && response.results.isNotEmpty) {
        // Get the first result (most relevant)
        final result = response.results.first;

        if (result.geometry == null) {
          debugPrint('Missing geometry in Places API response for $cityName');
          return null;
        }

        // Extract coordinates
        final coords = {
          'latitude': result.geometry!.location.lat,
          'longitude': result.geometry!.location.lng,
        };

        debugPrint(
            'Found coordinates for $cityName: ${coords['latitude']}, ${coords['longitude']}');

        // Cache the result
        _cityCoordinatesCache[normalizedCityName] = coords;

        // Save to persistent cache
        _saveCachedCoordinates();

        return coords;
      } else {
        debugPrint(
            'No results found for city: $cityName (status: ${response.status})');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting coordinates for $cityName: $e');
      return null;
    }
  }

  // Calculate distance between two cities - with improved logging
  Future<double?> calculateDistanceBetweenCities(
    String cityA,
    String cityB,
  ) async {
    debugPrint('Calculating distance between "$cityA" and "$cityB"');

    if (cityA.isEmpty || cityB.isEmpty) {
      debugPrint('One or both city names are empty');
      return null;
    }

    // If cities are the same, distance is 0
    if (cityA.trim().toLowerCase() == cityB.trim().toLowerCase()) {
      debugPrint('Cities are the same, distance is 0');
      return 0.0;
    }

    try {
      final coordsA = await getCoordinatesForCity(cityA);
      final coordsB = await getCoordinatesForCity(cityB);

      if (coordsA == null) {
        debugPrint('Could not get coordinates for city A: $cityA');
        return null;
      }

      if (coordsB == null) {
        debugPrint('Could not get coordinates for city B: $cityB');
        return null;
      }

      // Calculate using Haversine formula
      double distance = _calculateHaversineDistance(
        coordsA['latitude']!,
        coordsA['longitude']!,
        coordsB['latitude']!,
        coordsB['longitude']!,
      );

      debugPrint('Distance between $cityA and $cityB: $distance km');
      return distance;
    } catch (e) {
      debugPrint('Error calculating distance between $cityA and $cityB: $e');
      return null;
    }
  }

  // Calculate distance using Haversine formula - with improved accuracy
  double _calculateHaversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Radius of earth in kilometers
    const double earthRadius = 6371.0;

    // Convert degrees to radians
    lat1 = _degreesToRadians(lat1);
    lon1 = _degreesToRadians(lon1);
    lat2 = _degreesToRadians(lat2);
    lon2 = _degreesToRadians(lon2);

    // Haversine formula
    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;
    double a = Math.pow(Math.sin(dlat / 2), 2) +
        Math.cos(lat1) * Math.cos(lat2) * Math.pow(Math.sin(dlon / 2), 2);

    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * Math.pi / 180.0;
  }
}
