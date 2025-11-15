/// Model for emergency shelters
class Shelter {
  final String id;
  final String name;
  final String address;
  final String district;
  final String? village;
  final double latitude;
  final double longitude;
  final int capacity;
  final int currentOccupancy;
  final String shelterType;
  final List<String> facilities;
  final String? contactNumber;
  final String? managerName;
  final bool isActive;
  final List<String> disasterTypes;
  final double? distanceKm; // Distance from user location

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    this.village,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.currentOccupancy,
    required this.shelterType,
    required this.facilities,
    this.contactNumber,
    this.managerName,
    required this.isActive,
    required this.disasterTypes,
    this.distanceKm,
  });

  int get availableSpace => capacity - currentOccupancy;
  double get occupancyRate => currentOccupancy / capacity;
  bool get hasSpace => availableSpace > 0;

  factory Shelter.fromJson(Map<String, dynamic> json) {
    return Shelter(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Shelter',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      village: json['village'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      capacity: json['capacity'] ?? 0,
      currentOccupancy: json['current_occupancy'] ?? 0,
      shelterType: json['shelter_type'] ?? 'temporary',
      facilities: (json['facilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      contactNumber: json['contact_number'],
      managerName: json['manager_name'],
      isActive: json['is_active'] ?? true,
      disasterTypes: (json['disaster_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'district': district,
      'village': village,
      'latitude': latitude,
      'longitude': longitude,
      'capacity': capacity,
      'current_occupancy': currentOccupancy,
      'shelter_type': shelterType,
      'facilities': facilities,
      'contact_number': contactNumber,
      'manager_name': managerName,
      'is_active': isActive,
      'disaster_types': disasterTypes,
      'distance_km': distanceKm,
    };
  }

  String getShelterTypeDisplay() {
    switch (shelterType) {
      case 'government':
        return '🏛️ Government Facility';
      case 'school':
        return '🏫 School';
      case 'community_center':
        return '🏘️ Community Center';
      case 'temporary':
        return '⛺ Temporary Shelter';
      default:
        return '🏠 Shelter';
    }
  }

  String getFacilitiesDisplay() {
    final Map<String, String> facilityIcons = {
      'water': '💧',
      'electricity': '⚡',
      'medical': '🏥',
      'food': '🍽️',
      'blankets': '🛏️',
    };
    return facilities
        .map((f) => facilityIcons[f] ?? '✓')
        .join(' ');
  }
}

/// Model for districts
class District {
  final String id;
  final String name;
  final String state;
  final double latitude;
  final double longitude;
  final int? population;

  District({
    required this.id,
    required this.name,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.population,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      state: json['state'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      population: json['population'],
    );
  }
}

/// Model for villages
class Village {
  final String id;
  final String name;
  final String districtName;
  final double latitude;
  final double longitude;
  final int? population;

  Village({
    required this.id,
    required this.name,
    required this.districtName,
    required this.latitude,
    required this.longitude,
    this.population,
  });

  factory Village.fromJson(Map<String, dynamic> json) {
    return Village(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      districtName: json['district_name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      population: json['population'],
    );
  }
}

/// Model for user saved locations
class SavedLocation {
  final String id;
  final String userId;
  final String locationName;
  final String? address;
  final double latitude;
  final double longitude;
  final bool isPrimary;

  SavedLocation({
    required this.id,
    required this.userId,
    required this.locationName,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.isPrimary,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      locationName: json['location_name'] ?? '',
      address: json['address'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'location_name': locationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': isPrimary,
    };
  }
}
