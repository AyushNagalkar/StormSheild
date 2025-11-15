import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Earthquake model
class Earthquake {
  final String id;
  final double magnitude;
  final double latitude;
  final double longitude;
  final double depth;
  final String place;
  final DateTime time;
  final String? url;

  Earthquake({
    required this.id,
    required this.magnitude,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.place,
    required this.time,
    this.url,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] ?? {};
    final geometry = json['geometry'] ?? {};
    final coordinates = geometry['coordinates'] as List? ?? [];

    return Earthquake(
      id: json['id'] ?? '',
      magnitude: (properties['mag'] ?? 0).toDouble(),
      latitude: coordinates.length > 1 ? coordinates[1].toDouble() : 0.0,
      longitude: coordinates.isNotEmpty ? coordinates[0].toDouble() : 0.0,
      depth: coordinates.length > 2 ? coordinates[2].toDouble() : 0.0,
      place: properties['place'] ?? '',
      time: DateTime.fromMillisecondsSinceEpoch(
        properties['time'] ?? 0,
      ),
      url: properties['url'],
    );
  }

  /// Check if earthquake is significant (magnitude >= 5.0)
  bool get isSignificant => magnitude >= 5.0;

  /// Get severity level
  String get severity {
    if (magnitude >= 7.0) return 'Major';
    if (magnitude >= 6.0) return 'Strong';
    if (magnitude >= 5.0) return 'Moderate';
    if (magnitude >= 4.0) return 'Light';
    return 'Minor';
  }
}

/// Earthquake service using USGS API (FREE - No key required)
class EarthquakeService {
  /// Get recent earthquakes near a location
  Future<List<Earthquake>> getRecentEarthquakes({
    required double lat,
    required double lon,
    double radiusKm = 200,
    int days = 7,
    double minMagnitude = 2.5,
  }) async {
    try {
      // Calculate bounding box
      final latOffset = radiusKm / 111.0; // Approximate km to degrees
      final lonOffset = radiusKm / (111.0 * (lat.abs() > 85 ? 0.1 : 1.0));

      final minLat = lat - latOffset;
      final maxLat = lat + latOffset;
      final minLon = lon - lonOffset;
      final maxLon = lon + lonOffset;

      final startTime = DateTime.now().subtract(Duration(days: days));

      final url = ApiConfig.buildEarthquakeUrl({
        'starttime': startTime.toIso8601String(),
        'minlatitude': minLat.toString(),
        'maxlatitude': maxLat.toString(),
        'minlongitude': minLon.toString(),
        'maxlongitude': maxLon.toString(),
        'minmagnitude': minMagnitude.toString(),
        'orderby': 'time',
      });

      final response = await http.get(
        Uri.parse(url),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];
        
        return features
            .map((feature) => Earthquake.fromJson(feature as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load earthquake data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching earthquake data: $e');
    }
  }

  /// Calculate earthquake risk based on recent seismic activity
  Future<double> calculateEarthquakeRisk({
    required double lat,
    required double lon,
  }) async {
    try {
      final earthquakes = await getRecentEarthquakes(
        lat: lat,
        lon: lon,
        days: 30,
        minMagnitude: 2.5,
      );

      if (earthquakes.isEmpty) {
        return 0.0;
      }

      double risk = 0.0;

      // Realistic earthquake risk assessment
      // Note: Earthquakes cannot be predicted, this assesses current seismic activity
      
      // Significant earthquakes (M5.0+) indicate active fault lines
      final significantCount = earthquakes.where((eq) => eq.magnitude >= 5.0).length;
      if (significantCount > 0) {
        // Scale realistically - even 1 M5+ quake is notable
        risk += (0.20 * (significantCount / 3)).clamp(0.0, 0.20);
      }

      // Very significant earthquakes (M6.0+)
      final verySignificantCount = earthquakes.where((eq) => eq.magnitude >= 6.0).length;
      if (verySignificantCount > 0) {
        risk += 0.15; // Major earthquake occurred
      }

      // Recent activity (last 7 days) is more relevant
      final recent = DateTime.now().subtract(const Duration(days: 7));
      final recentCount = earthquakes.where((eq) => eq.time.isAfter(recent)).length;
      
      if (recentCount > 20) {
        risk += 0.15; // Swarm activity
      } else if (recentCount > 10) {
        risk += 0.10; // Elevated activity
      } else if (recentCount > 5) {
        risk += 0.05; // Moderate activity
      }

      // Immediate activity (last 24 hours) - possible aftershocks
      final last24h = earthquakes.where(
        (eq) => eq.time.isAfter(DateTime.now().subtract(const Duration(hours: 24))),
      ).length;
      
      if (last24h > 5) {
        risk += 0.12; // Multiple recent quakes
      } else if (last24h > 2) {
        risk += 0.06; // Several recent quakes
      }

      // Maximum magnitude in the period
      final maxMagnitude = earthquakes
          .map((eq) => eq.magnitude)
          .reduce((a, b) => a > b ? a : b);
      
      if (maxMagnitude >= 7.0) {
        risk += 0.20; // Major earthquake (rare)
      } else if (maxMagnitude >= 6.5) {
        risk += 0.12; // Strong earthquake
      }

      return risk.clamp(0.0, 1.0);
    } catch (e) {
      print('Error calculating earthquake risk: $e');
      return 0.0;
    }
  }

  /// Get earthquake statistics for a location
  Future<Map<String, dynamic>> getEarthquakeStats({
    required double lat,
    required double lon,
    int days = 30,
  }) async {
    try {
      final earthquakes = await getRecentEarthquakes(
        lat: lat,
        lon: lon,
        days: days,
        minMagnitude: 2.0,
      );

      if (earthquakes.isEmpty) {
        return {
          'total_count': 0,
          'average_magnitude': 0.0,
          'max_magnitude': 0.0,
          'significant_count': 0,
        };
      }

      final avgMagnitude = earthquakes
          .map((eq) => eq.magnitude)
          .reduce((a, b) => a + b) / earthquakes.length;

      final maxMagnitude = earthquakes
          .map((eq) => eq.magnitude)
          .reduce((a, b) => a > b ? a : b);

      final significantCount = earthquakes
          .where((eq) => eq.magnitude >= 5.0)
          .length;

      return {
        'total_count': earthquakes.length,
        'average_magnitude': avgMagnitude,
        'max_magnitude': maxMagnitude,
        'significant_count': significantCount,
        'earthquakes': earthquakes,
      };
    } catch (e) {
      print('Error getting earthquake stats: $e');
      return {
        'total_count': 0,
        'average_magnitude': 0.0,
        'max_magnitude': 0.0,
        'significant_count': 0,
      };
    }
  }
}
