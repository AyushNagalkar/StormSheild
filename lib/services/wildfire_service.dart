import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/env_config.dart';

/// Wildfire/hotspot model
class Wildfire {
  final double latitude;
  final double longitude;
  final double brightness; // Temperature in Kelvin
  final double confidence; // 0-100
  final DateTime detectTime;
  final String satellite;
  final double? frp; // Fire Radiative Power

  Wildfire({
    required this.latitude,
    required this.longitude,
    required this.brightness,
    required this.confidence,
    required this.detectTime,
    required this.satellite,
    this.frp,
  });

  factory Wildfire.fromCsv(List<String> row) {
    // NASA FIRMS CSV format: lat, lon, brightness, scan, track, acq_date, acq_time, satellite, confidence, version, bright_t31, frp, daynight
    return Wildfire(
      latitude: double.tryParse(row[0]) ?? 0.0,
      longitude: double.tryParse(row[1]) ?? 0.0,
      brightness: double.tryParse(row[2]) ?? 0.0,
      confidence: _parseConfidence(row[8]),
      detectTime: _parseDateTime(row[5], row[6]),
      satellite: row[7],
      frp: double.tryParse(row[11]),
    );
  }

  static double _parseConfidence(String conf) {
    // NASA FIRMS uses 'n' (nominal), 'l' (low), 'h' (high)
    switch (conf.toLowerCase()) {
      case 'h':
        return 90.0;
      case 'n':
        return 70.0;
      case 'l':
        return 50.0;
      default:
        return double.tryParse(conf) ?? 70.0;
    }
  }

  static DateTime _parseDateTime(String date, String time) {
    try {
      // date format: YYYY-MM-DD, time format: HHMM
      final hour = time.substring(0, 2);
      final minute = time.substring(2, 4);
      return DateTime.parse('$date $hour:$minute:00');
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Check if this is a significant fire (high confidence and brightness)
  bool get isSignificant => confidence > 70 && brightness > 350;
}

/// Wildfire service using NASA FIRMS API (FREE - Unlimited)
class WildfireService {
  final String _apiKey = EnvConfig.nasaFirmsApiKey;

  /// Get active wildfires near a location
  Future<List<Wildfire>> getActiveWildfires({
    required double lat,
    required double lon,
    int days = 7,
  }) async {
    try {
      final url = ApiConfig.buildFirmsUrl(_apiKey, lat, lon, days);

      final response = await http.get(
        Uri.parse(url),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final csvData = response.body;
        final lines = const LineSplitter().convert(csvData);
        
        // Skip header line
        if (lines.isEmpty || lines.length < 2) {
          return [];
        }

        final wildfires = <Wildfire>[];
        for (int i = 1; i < lines.length; i++) {
          try {
            final row = lines[i].split(',');
            if (row.length >= 12) {
              wildfires.add(Wildfire.fromCsv(row));
            }
          } catch (e) {
            print('Error parsing wildfire row: $e');
          }
        }

        return wildfires;
      } else {
        throw Exception('Failed to load wildfire data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching wildfire data: $e');
    }
  }

  /// Calculate wildfire risk based on active fires
  Future<double> calculateWildfireRisk({
    required double lat,
    required double lon,
  }) async {
    try {
      final wildfires = await getActiveWildfires(
        lat: lat,
        lon: lon,
        days: 7,
      );

      if (wildfires.isEmpty) {
        return 0.0;
      }

      double risk = 0.0;

      // Realistic wildfire risk based on NASA FIRMS data
      // Count significant fires (high confidence, high FRP)
      final significantCount = wildfires.where((fire) => fire.isSignificant).length;
      if (significantCount > 0) {
        // Scale based on number of significant fires (max at 20 fires)
        risk += (0.25 * (significantCount / 20)).clamp(0.0, 0.25);
      }

      // Recent fire activity (last 24 hours) is more concerning
      final recent = DateTime.now().subtract(const Duration(hours: 24));
      final recentCount = wildfires.where((fire) => fire.detectTime.isAfter(recent)).length;
      
      if (recentCount > 10) {
        risk += 0.20; // Many recent fires
      } else if (recentCount > 5) {
        risk += 0.12; // Several recent fires
      } else if (recentCount > 0) {
        risk += 0.06; // Some recent fires
      }

      // Calculate distance to nearest fire
      double minDistance = double.infinity;
      for (var fire in wildfires) {
        final distance = _calculateDistance(lat, lon, fire.latitude, fire.longitude);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      // Distance-based risk (realistic threat zones)
      if (minDistance < 5) {
        risk += 0.30; // Very close - immediate danger
      } else if (minDistance < 10) {
        risk += 0.20; // Close - high concern
      } else if (minDistance < 25) {
        risk += 0.12; // Nearby - moderate concern
      } else if (minDistance < 50) {
        risk += 0.06; // Within monitoring range
      }
      // Fires beyond 50km have minimal direct threat

      return risk.clamp(0.0, 1.0);
    } catch (e) {
      print('Error calculating wildfire risk: $e');
      return 0.0;
    }
  }

  /// Get wildfire statistics for a location
  Future<Map<String, dynamic>> getWildfireStats({
    required double lat,
    required double lon,
    int days = 7,
  }) async {
    try {
      final wildfires = await getActiveWildfires(
        lat: lat,
        lon: lon,
        days: days,
      );

      if (wildfires.isEmpty) {
        return {
          'total_count': 0,
          'significant_count': 0,
          'nearest_distance_km': null,
          'avg_confidence': 0.0,
        };
      }

      final significantCount = wildfires.where((fire) => fire.isSignificant).length;
      
      final avgConfidence = wildfires
          .map((fire) => fire.confidence)
          .reduce((a, b) => a + b) / wildfires.length;

      // Find nearest fire
      double minDistance = double.infinity;
      for (var fire in wildfires) {
        final distance = _calculateDistance(lat, lon, fire.latitude, fire.longitude);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      return {
        'total_count': wildfires.length,
        'significant_count': significantCount,
        'nearest_distance_km': minDistance,
        'avg_confidence': avgConfidence,
        'wildfires': wildfires,
      };
    } catch (e) {
      print('Error getting wildfire stats: $e');
      return {
        'total_count': 0,
        'significant_count': 0,
        'nearest_distance_km': null,
        'avg_confidence': 0.0,
      };
    }
  }

  /// Calculate distance between two coordinates in km (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
