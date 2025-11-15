import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shelter.dart';
import '../config/supabase_config.dart';
import 'mock_shelter_data.dart';

/// Service for shelter and location management
class ShelterService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  bool _useMockData = false; // Flag to determine if using mock data

  /// Find nearest shelters to a location
  Future<List<Shelter>> findNearestShelters({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 50,
    int limit = 10,
    String? disasterType,
  }) async {
    try {
      print('🏠 Finding nearest shelters...');
      
      // Try Supabase first
      if (!_useMockData) {
        try {
          final response = await _supabase
              .rpc('find_nearest_shelters', params: {
            'user_lat': latitude,
            'user_lon': longitude,
            'max_distance_km': maxDistanceKm,
            'limit_count': limit,
          }).timeout(const Duration(seconds: 5));

          print('✅ Found ${response.length} shelters from Supabase');

          // Properly handle the response as List<dynamic>
          List<Shelter> shelters = (response as List<dynamic>)
              .map((json) => Shelter.fromJson(json as Map<String, dynamic>))
              .toList();

          // Filter by disaster type if specified
          if (disasterType != null) {
            shelters = shelters
                .where((s) => s.disasterTypes.contains(disasterType))
                .toList();
          }

          if (shelters.isNotEmpty) {
            return shelters;
          }
        } catch (e) {
          print('⚠️ Supabase unavailable, using mock data: $e');
          _useMockData = true;
        }
      }

      // Use mock data as fallback
      print('📦 Using mock shelter data');
      List<Shelter> mockShelters = MockShelterData.getMockShelters(
        latitude,
        longitude,
      );

      // Filter by disaster type if specified
      if (disasterType != null) {
        mockShelters = mockShelters
            .where((s) => s.disasterTypes.contains(disasterType))
            .toList();
      }

      // Apply distance filter and limit
      mockShelters = mockShelters
          .where((s) => (s.distanceKm ?? double.infinity) <= maxDistanceKm)
          .take(limit)
          .toList();

      print('✅ Found ${mockShelters.length} mock shelters');
      return mockShelters;
    } catch (e) {
      print('❌ Error finding shelters: $e');
      // Return mock data even on error
      return MockShelterData.getMockShelters(latitude, longitude)
          .where((s) => (s.distanceKm ?? double.infinity) <= maxDistanceKm)
          .take(limit)
          .toList();
    }
  }

  /// Get all shelters in a district
  Future<List<Shelter>> getSheltersByDistrict(String district) async {
    try {
      // Try Supabase first
      if (!_useMockData) {
        try {
          final response = await _supabase
              .from('shelters')
              .select()
              .eq('district', district)
              .eq('is_active', true)
              .order('name')
              .timeout(const Duration(seconds: 5));

          print('✅ Found ${response.length} shelters in district from Supabase');

          List<Shelter> shelters = response
              .map((json) => Shelter.fromJson(json))
              .toList();

          if (shelters.isNotEmpty) {
            return shelters;
          }
        } catch (e) {
          print('⚠️ Supabase unavailable for district query, using mock data: $e');
          _useMockData = true;
        }
      }

      // Use mock data as fallback
      print('📦 Using mock district data');
      // For mock data, return all shelters (no district filtering available)
      return MockShelterData.getMockShelters(0, 0); // Dummy coords, returns all
    } catch (e) {
      print('❌ Error getting shelters by district: $e');
      return MockShelterData.getMockShelters(0, 0);
    }
  }

  /// Get shelter by ID with full details
  Future<Shelter?> getShelterById(String id) async {
    try {
      // Try Supabase first
      if (!_useMockData) {
        try {
          final response = await _supabase
              .from('shelters')
              .select()
              .eq('id', id)
              .single()
              .timeout(const Duration(seconds: 5));

          return Shelter.fromJson(response);
        } catch (e) {
          print('⚠️ Supabase unavailable for shelter lookup, using mock data: $e');
          _useMockData = true;
        }
      }

      // Use mock data as fallback
      print('📦 Using mock shelter lookup');
      final allShelters = MockShelterData.getMockShelters(0, 0);
      return allShelters.firstWhere(
        (s) => s.id == id,
        orElse: () => allShelters.first,
      );
    } catch (e) {
      print('❌ Error getting shelter: $e');
      return null;
    }
  }

  /// Get all districts
  Future<List<District>> getDistricts() async {
    try {
      // Try Supabase first
      if (!_useMockData) {
        try {
          final response = await _supabase
              .from('districts')
              .select()
              .order('name')
              .timeout(const Duration(seconds: 5));

          List<District> districts = response
              .map((json) => District.fromJson(json))
              .toList();

          if (districts.isNotEmpty) {
            return districts;
          }
        } catch (e) {
          print('⚠️ Supabase unavailable for districts, using mock data: $e');
          _useMockData = true;
        }
      }

      // Use mock data as fallback
      print('📦 Using mock district data');
      return MockShelterData.getMockDistricts();
    } catch (e) {
      print('❌ Error getting districts: $e');
      return MockShelterData.getMockDistricts();
    }
  }

  /// Get villages in a district
  Future<List<Village>> getVillagesByDistrict(String districtName) async {
    try {
      // Try Supabase first
      if (!_useMockData) {
        try {
          final response = await _supabase
              .from('villages')
              .select()
              .eq('district_name', districtName)
              .order('name')
              .timeout(const Duration(seconds: 5));

          List<Village> villages = response
              .map((json) => Village.fromJson(json))
              .toList();

          if (villages.isNotEmpty) {
            return villages;
          }
        } catch (e) {
          print('⚠️ Supabase unavailable for villages, using mock data: $e');
          _useMockData = true;
        }
      }

      // Use mock data as fallback
      print('📦 Using mock village data');
      return MockShelterData.getMockVillages(districtName);
    } catch (e) {
      print('❌ Error getting villages: $e');
      return MockShelterData.getMockVillages(districtName);
    }
  }

  /// Save user location
  Future<SavedLocation?> saveUserLocation({
    required String userId,
    required String locationName,
    String? address,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    try {
      // If setting as primary, unset other primary locations
      if (isPrimary) {
        await _supabase
            .from('user_locations')
            .update({'is_primary': false})
            .eq('user_id', userId);
      }

      final response = await _supabase
          .from('user_locations')
          .insert({
            'user_id': userId,
            'location_name': locationName,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'is_primary': isPrimary,
          })
          .select()
          .single();

      return SavedLocation.fromJson(response);
    } catch (e) {
      print('❌ Error saving location: $e');
      return null;
    }
  }

  /// Get user's saved locations
  Future<List<SavedLocation>> getUserLocations(String userId) async {
    try {
      final response = await _supabase
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SavedLocation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting user locations: $e');
      return [];
    }
  }

  /// Delete saved location
  Future<bool> deleteUserLocation(String locationId) async {
    try {
      await _supabase
          .from('user_locations')
          .delete()
          .eq('id', locationId);
      return true;
    } catch (e) {
      print('❌ Error deleting location: $e');
      return false;
    }
  }

  /// Update shelter occupancy (for real-time tracking)
  Future<bool> updateShelterOccupancy(String shelterId, int occupancy) async {
    try {
      await _supabase
          .from('shelters')
          .update({'current_occupancy': occupancy})
          .eq('id', shelterId);
      return true;
    } catch (e) {
      print('❌ Error updating occupancy: $e');
      return false;
    }
  }

  /// Calculate safe route (basic implementation - can be enhanced with routing API)
  Future<Map<String, dynamic>> calculateSafeRoute({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) async {
    // Calculate straight-line distance
    final distance = _calculateDistance(fromLat, fromLon, toLat, toLon);
    
    // Calculate estimated time (assuming 40 km/h average speed)
    final estimatedTimeMinutes = (distance / 40 * 60).round();

    return {
      'distance_km': distance,
      'estimated_time_minutes': estimatedTimeMinutes,
      'route_points': [
        {'lat': fromLat, 'lon': fromLon},
        {'lat': toLat, 'lon': toLon},
      ],
      'warnings': _getRouteWarnings(distance),
    };
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  List<String> _getRouteWarnings(double distanceKm) {
    final warnings = <String>[];
    if (distanceKm > 30) {
      warnings.add('Long distance - ensure adequate fuel/battery');
    }
    if (distanceKm > 50) {
      warnings.add('Consider rest stops along the way');
    }
    return warnings;
  }
}
