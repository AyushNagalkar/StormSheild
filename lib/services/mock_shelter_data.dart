import '../models/shelter.dart';

/// Mock shelter data for testing and offline mode
class MockShelterData {
  /// Get mock shelters for a location
  static List<Shelter> getMockShelters(double userLat, double userLon) {
    final mockShelters = [
      // Delhi Region
      Shelter(
        id: 'mock-1',
        name: 'Rajiv Gandhi Super Specialty Hospital Shelter',
        address: 'Tahirpur, Near GTB Nagar Metro',
        district: 'North Delhi',
        village: 'Tahirpur',
        latitude: 28.7041,
        longitude: 77.1025,
        capacity: 1200,
        currentOccupancy: 340,
        shelterType: 'government',
        facilities: ['water', 'electricity', 'medical', 'food', 'blankets'],
        contactNumber: '+91-11-2234-5678',
        managerName: 'Dr. Rajesh Kumar',
        isActive: true,
        disasterTypes: ['flood', 'cyclone', 'earthquake', 'heatwave'],
      ),
      
      Shelter(
        id: 'mock-2',
        name: 'Government Senior Secondary School Emergency Center',
        address: 'Block A, Rohini Sector 15',
        district: 'North West Delhi',
        village: 'Rohini',
        latitude: 28.7401,
        longitude: 77.0694,
        capacity: 800,
        currentOccupancy: 0,
        shelterType: 'school',
        facilities: ['water', 'electricity', 'food'],
        contactNumber: '+91-11-2765-4321',
        managerName: 'Mr. Anil Sharma',
        isActive: true,
        disasterTypes: ['flood', 'cyclone', 'earthquake'],
      ),
      
      Shelter(
        id: 'mock-3',
        name: 'Community Welfare Center Dwarka',
        address: 'Sector 10, Dwarka',
        district: 'South West Delhi',
        village: 'Dwarka',
        latitude: 28.5921,
        longitude: 77.0460,
        capacity: 500,
        currentOccupancy: 150,
        shelterType: 'community_center',
        facilities: ['water', 'food', 'blankets'],
        contactNumber: '+91-11-2508-9876',
        managerName: 'Mrs. Priya Singh',
        isActive: true,
        disasterTypes: ['flood', 'heatwave', 'cyclone'],
      ),
      
      // Mumbai Region
      Shelter(
        id: 'mock-4',
        name: 'Bandra Municipal School Disaster Relief Center',
        address: 'Hill Road, Bandra West',
        district: 'Mumbai',
        village: 'Bandra',
        latitude: 19.0596,
        longitude: 72.8295,
        capacity: 600,
        currentOccupancy: 420,
        shelterType: 'school',
        facilities: ['water', 'medical', 'food'],
        contactNumber: '+91-22-2640-1234',
        managerName: 'Mr. Suresh Patil',
        isActive: true,
        disasterTypes: ['cyclone', 'flood', 'earthquake'],
      ),
      
      Shelter(
        id: 'mock-5',
        name: 'Andheri Sports Complex Emergency Shelter',
        address: 'Veera Desai Road, Andheri West',
        district: 'Mumbai',
        village: 'Andheri',
        latitude: 19.1334,
        longitude: 72.8255,
        capacity: 1500,
        currentOccupancy: 0,
        shelterType: 'government',
        facilities: ['water', 'electricity', 'medical', 'food', 'blankets'],
        contactNumber: '+91-22-2673-5678',
        managerName: 'Mr. Ramesh Desai',
        isActive: true,
        disasterTypes: ['cyclone', 'flood', 'earthquake', 'heatwave'],
      ),
      
      // Bangalore Region
      Shelter(
        id: 'mock-6',
        name: 'Indiranagar Community Hall',
        address: '100 Feet Road, Indiranagar',
        district: 'Bangalore Urban',
        village: 'Indiranagar',
        latitude: 12.9716,
        longitude: 77.6412,
        capacity: 400,
        currentOccupancy: 80,
        shelterType: 'community_center',
        facilities: ['water', 'electricity', 'food'],
        contactNumber: '+91-80-2520-3456',
        managerName: 'Mrs. Lakshmi Rao',
        isActive: true,
        disasterTypes: ['earthquake', 'flood', 'heatwave'],
      ),
      
      Shelter(
        id: 'mock-7',
        name: 'Whitefield Government Hospital Emergency Wing',
        address: 'ITPL Main Road, Whitefield',
        district: 'Bangalore Urban',
        village: 'Whitefield',
        latitude: 12.9698,
        longitude: 77.7499,
        capacity: 900,
        currentOccupancy: 200,
        shelterType: 'government',
        facilities: ['water', 'electricity', 'medical', 'food', 'blankets'],
        contactNumber: '+91-80-2845-6789',
        managerName: 'Dr. Venkat Reddy',
        isActive: true,
        disasterTypes: ['earthquake', 'flood', 'wildfire', 'heatwave'],
      ),
      
      // Chennai Region
      Shelter(
        id: 'mock-8',
        name: 'T Nagar Corporation School Shelter',
        address: 'South Usman Road, T Nagar',
        district: 'Chennai',
        village: 'T Nagar',
        latitude: 13.0418,
        longitude: 80.2341,
        capacity: 700,
        currentOccupancy: 560,
        shelterType: 'school',
        facilities: ['water', 'food', 'medical'],
        contactNumber: '+91-44-2434-5678',
        managerName: 'Mr. Krishnan Iyer',
        isActive: true,
        disasterTypes: ['cyclone', 'flood', 'earthquake'],
      ),
      
      Shelter(
        id: 'mock-9',
        name: 'Adyar Community Relief Center',
        address: 'Lattice Bridge Road, Adyar',
        district: 'Chennai',
        village: 'Adyar',
        latitude: 13.0067,
        longitude: 80.2206,
        capacity: 550,
        currentOccupancy: 120,
        shelterType: 'community_center',
        facilities: ['water', 'electricity', 'food', 'blankets'],
        contactNumber: '+91-44-2441-2345',
        managerName: 'Mrs. Meena Rajan',
        isActive: true,
        disasterTypes: ['cyclone', 'flood', 'heatwave'],
      ),
      
      // Kolkata Region
      Shelter(
        id: 'mock-10',
        name: 'Salt Lake City Center Emergency Shelter',
        address: 'Tank No. 5, Salt Lake',
        district: 'Kolkata',
        village: 'Salt Lake',
        latitude: 22.5726,
        longitude: 88.3639,
        capacity: 1000,
        currentOccupancy: 0,
        shelterType: 'government',
        facilities: ['water', 'electricity', 'medical', 'food', 'blankets'],
        contactNumber: '+91-33-2357-8901',
        managerName: 'Mr. Amit Banerjee',
        isActive: true,
        disasterTypes: ['cyclone', 'flood', 'earthquake', 'heatwave'],
      ),
      
      // Hyderabad Region
      Shelter(
        id: 'mock-11',
        name: 'Hitech City Convention Center Shelter',
        address: 'HITEC City Main Road',
        district: 'Hyderabad',
        village: 'Madhapur',
        latitude: 17.4485,
        longitude: 78.3908,
        capacity: 1200,
        currentOccupancy: 90,
        shelterType: 'government',
        facilities: ['water', 'electricity', 'medical', 'food', 'blankets'],
        contactNumber: '+91-40-2311-4567',
        managerName: 'Mr. Ravi Chandra',
        isActive: true,
        disasterTypes: ['flood', 'earthquake', 'heatwave'],
      ),
      
      // Pune Region
      Shelter(
        id: 'mock-12',
        name: 'Kothrud Sports Complex',
        address: 'Paud Road, Kothrud',
        district: 'Pune',
        village: 'Kothrud',
        latitude: 18.5074,
        longitude: 73.8077,
        capacity: 650,
        currentOccupancy: 210,
        shelterType: 'community_center',
        facilities: ['water', 'electricity', 'food'],
        contactNumber: '+91-20-2543-2109',
        managerName: 'Mr. Sanjay Deshmukh',
        isActive: true,
        disasterTypes: ['flood', 'earthquake', 'wildfire'],
      ),
    ];

    // Calculate distances and sort
    for (var shelter in mockShelters) {
      final distance = _calculateDistance(
        userLat,
        userLon,
        shelter.latitude,
        shelter.longitude,
      );
      // Create new shelter with distance
      final index = mockShelters.indexOf(shelter);
      mockShelters[index] = Shelter(
        id: shelter.id,
        name: shelter.name,
        address: shelter.address,
        district: shelter.district,
        village: shelter.village,
        latitude: shelter.latitude,
        longitude: shelter.longitude,
        capacity: shelter.capacity,
        currentOccupancy: shelter.currentOccupancy,
        shelterType: shelter.shelterType,
        facilities: shelter.facilities,
        contactNumber: shelter.contactNumber,
        managerName: shelter.managerName,
        isActive: shelter.isActive,
        disasterTypes: shelter.disasterTypes,
        distanceKm: distance,
      );
    }

    // Sort by distance
    mockShelters.sort((a, b) => 
      (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity)
    );

    return mockShelters;
  }

  /// Calculate distance between two points (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  static double _sin(double radians) => 
      radians - (radians * radians * radians) / 6 + 
      (radians * radians * radians * radians * radians) / 120;
  static double _cos(double radians) => 
      1 - (radians * radians) / 2 + (radians * radians * radians * radians) / 24;
  static double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }
  static double _atan(double x) {
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5 - 
           (x * x * x * x * x * x * x) / 7;
  }

  /// Get mock districts
  static List<District> getMockDistricts() {
    return [
      District(
        id: 'district-1',
        name: 'North Delhi',
        state: 'Delhi',
        latitude: 28.7041,
        longitude: 77.1025,
        population: 887978,
      ),
      District(
        id: 'district-2',
        name: 'Mumbai',
        state: 'Maharashtra',
        latitude: 19.0760,
        longitude: 72.8777,
        population: 12442373,
      ),
      District(
        id: 'district-3',
        name: 'Bangalore Urban',
        state: 'Karnataka',
        latitude: 12.9716,
        longitude: 77.5946,
        population: 8443675,
      ),
      District(
        id: 'district-4',
        name: 'Chennai',
        state: 'Tamil Nadu',
        latitude: 13.0827,
        longitude: 80.2707,
        population: 4646732,
      ),
      District(
        id: 'district-5',
        name: 'Kolkata',
        state: 'West Bengal',
        latitude: 22.5726,
        longitude: 88.3639,
        population: 4496694,
      ),
      District(
        id: 'district-6',
        name: 'Hyderabad',
        state: 'Telangana',
        latitude: 17.3850,
        longitude: 78.4867,
        population: 6809970,
      ),
      District(
        id: 'district-7',
        name: 'Pune',
        state: 'Maharashtra',
        latitude: 18.5204,
        longitude: 73.8567,
        population: 3124458,
      ),
    ];
  }

  /// Get mock villages for a district
  static List<Village> getMockVillages(String districtName) {
    final villageData = {
      'North Delhi': [
        Village(
          id: 'village-1',
          name: 'Tahirpur',
          districtName: 'North Delhi',
          latitude: 28.7041,
          longitude: 77.1025,
          population: 50000,
        ),
        Village(
          id: 'village-2',
          name: 'Rohini',
          districtName: 'North Delhi',
          latitude: 28.7401,
          longitude: 77.0694,
          population: 75000,
        ),
      ],
      'Mumbai': [
        Village(
          id: 'village-3',
          name: 'Bandra',
          districtName: 'Mumbai',
          latitude: 19.0596,
          longitude: 72.8295,
          population: 226000,
        ),
        Village(
          id: 'village-4',
          name: 'Andheri',
          districtName: 'Mumbai',
          latitude: 19.1334,
          longitude: 72.8255,
          population: 389000,
        ),
      ],
      'Bangalore Urban': [
        Village(
          id: 'village-5',
          name: 'Indiranagar',
          districtName: 'Bangalore Urban',
          latitude: 12.9716,
          longitude: 77.6412,
          population: 45000,
        ),
        Village(
          id: 'village-6',
          name: 'Whitefield',
          districtName: 'Bangalore Urban',
          latitude: 12.9698,
          longitude: 77.7499,
          population: 65000,
        ),
      ],
    };

    return villageData[districtName] ?? [];
  }
}
