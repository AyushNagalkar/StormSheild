import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alert.dart';
import '../models/disaster_type.dart';
import '../models/weather_data.dart';
import '../models/location.dart' as app_location;
import '../services/weather_service.dart';
import '../services/earthquake_service.dart';
import '../services/wildfire_service.dart';
import '../services/ai_prediction_service.dart';
import '../services/location_service.dart';

/// Disaster provider for managing disaster predictions and alerts
class DisasterProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final EarthquakeService _earthquakeService = EarthquakeService();
  final WildfireService _wildfireService = WildfireService();
  final AiPredictionService _aiService = AiPredictionService();
  final LocationService _locationService = LocationService();

  // State
  Position? _currentPosition;
  WeatherData? _currentWeather;
  List<Alert> _alerts = [];
  final Map<DisasterType, double> _riskScores = {};
  final Map<DisasterType, Map<String, dynamic>> _predictions = {};
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdate;
  final Map<String, String> _apiErrors = {}; // Track which APIs failed
  String? _manualLocationAddress; // Manual location address

  // Getters
  Position? get currentPosition => _currentPosition;
  WeatherData? get currentWeather => _currentWeather;
  List<Alert> get alerts => _alerts;
  List<Alert> get activeAlerts => _alerts.where((a) => a.isActive).toList();
  Map<DisasterType, double> get riskScores => _riskScores;
  Map<DisasterType, Map<String, dynamic>> get predictions => _predictions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdate => _lastUpdate;
  Map<String, String> get apiErrors => _apiErrors;
  bool get hasApiErrors => _apiErrors.isNotEmpty;
  String? get manualLocationAddress => _manualLocationAddress;

  /// Get overall risk level (0-1)
  /// Returns HIGH risk if any single disaster has high risk
  double get overallRisk {
    if (_riskScores.isEmpty) return 0.0;
    
    // Get the maximum risk (worst case scenario)
    final maxRisk = _riskScores.values.reduce((a, b) => a > b ? a : b);
    
    // If ANY disaster has high risk (>0.7), overall risk is high
    if (maxRisk > 0.7) return maxRisk;
    
    // If ANY disaster has medium-high risk (>0.5), show elevated risk
    if (maxRisk > 0.5) return maxRisk;
    
    // Otherwise, use weighted average with emphasis on highest risks
    final values = _riskScores.values.toList()..sort((a, b) => b.compareTo(a));
    
    // Weight: 50% highest, 30% second highest, 20% average of rest
    if (values.length == 1) return values[0];
    if (values.length == 2) return (values[0] * 0.7 + values[1] * 0.3);
    
    final highest = values[0];
    final secondHighest = values[1];
    final restAverage = values.skip(2).reduce((a, b) => a + b) / (values.length - 2);
    
    return (highest * 0.5 + secondHighest * 0.3 + restAverage * 0.2).clamp(0.0, 1.0);
  }

  /// Get highest risk disaster type
  DisasterType? get highestRiskType {
    if (_riskScores.isEmpty) return null;
    
    DisasterType? highest;
    double maxRisk = 0.0;
    
    _riskScores.forEach((type, risk) {
      if (risk > maxRisk) {
        maxRisk = risk;
        highest = type;
      }
    });
    
    return highest;
  }

  /// Check if there are any high-risk disasters nearby
  bool get hasNearbyDangers {
    return _riskScores.values.any((risk) => risk > 0.6);
  }

  /// Get count of high-risk disasters
  int get highRiskCount {
    return _riskScores.values.where((risk) => risk > 0.6).length;
  }

  /// Get count of active fires nearby (if wildfire data available)
  int get nearbyFiresCount {
    // This will be populated when we fetch wildfire data
    return _nearbyWildfires?.length ?? 0;
  }

  /// Get count of recent earthquakes nearby
  int get nearbyEarthquakesCount {
    return _nearbyEarthquakes?.length ?? 0;
  }

  List<Wildfire>? _nearbyWildfires;
  List<Earthquake>? _nearbyEarthquakes;

  /// Initialize and load data
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to get location. Please enable location services.');
      }

      _currentPosition = position;
      
      // Load all data
      await _loadAllData();
      
      _lastUpdate = DateTime.now();
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }

  /// Set manual location (user-selected)
  Future<void> setManualLocation(double lat, double lon, String? address) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _manualLocationAddress = address;

      // Create a Position object from manual coordinates
      _currentPosition = Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      // Load all data for this location
      await _loadAllData();

      _lastUpdate = DateTime.now();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  /// Load all disaster data
  Future<void> _loadAllData() async {
    if (_currentPosition == null) return;

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;

    _apiErrors.clear(); // Clear previous errors

    try {
      // Load weather data
      try {
        _currentWeather = await _weatherService.getCurrentWeather(lat, lon);
      } catch (e) {
        _apiErrors['OpenWeather'] = 'Weather data unavailable. Check API key or internet connection.';
        print('Weather service error: $e');
      }

      // Calculate risk scores (AI-first with rule-based fallback)
      await _calculateAllRisks(lat, lon);

      // Generate alerts for high-risk disasters
      _generateAlerts();

      notifyListeners();
    } catch (e) {
      print('Error loading disaster data: $e');
      _errorMessage = 'Failed to load disaster data: $e';
      notifyListeners();
    }
  }

  /// Calculate risk scores for all disaster types
  /// NEW ARCHITECTURE: AI-first, fallback to rule-based
  Future<void> _calculateAllRisks(double lat, double lon) async {
    _riskScores.clear();

    print('🤖 Starting AI-FIRST risk assessment...');

    // Try AI predictions FIRST for all disaster types
    final aiRisks = await _tryAIPredictions(lat, lon);

    // For each disaster type, use AI if available, else fallback to rules
    for (var disasterType in DisasterType.values) {
      try {
        if (aiRisks.containsKey(disasterType) && aiRisks[disasterType] != null) {
          // AI prediction succeeded - use it!
          _riskScores[disasterType] = aiRisks[disasterType]!;
          print('✅ Using AI prediction for ${disasterType.name}: ${(aiRisks[disasterType]! * 100).toStringAsFixed(0)}%');
        } else {
          // AI failed - fallback to rule-based calculation
          print('⚠️ AI failed for ${disasterType.name}, using rule-based fallback...');
          _riskScores[disasterType] = await _calculateRuleBasedRisk(disasterType, lat, lon);
          print('📊 Rule-based result for ${disasterType.name}: ${(_riskScores[disasterType]! * 100).toStringAsFixed(0)}%');
        }
      } catch (e) {
        print('❌ Error calculating ${disasterType.name} risk: $e');
        _riskScores[disasterType] = 0.0;
      }
    }

    // IMPORTANT: Validate and adjust contradictory predictions
    _validateAndAdjustRisks();
    
    print('✅ Risk assessment complete. Final scores: $_riskScores');
  }

  /// Try to get AI predictions for all disasters
  Future<Map<DisasterType, double?>> _tryAIPredictions(double lat, double lon) async {
    final aiRisks = <DisasterType, double?>{};

    if (_currentWeather == null) {
      print('⚠️ Cannot use AI: No weather data available');
      return aiRisks;
    }

    // Get necessary data for AI context
    await _fetchContextData(lat, lon);

    // Try AI prediction for each disaster type
    for (var disasterType in DisasterType.values) {
      try {
        // Build context data
        final additionalData = await _buildContextData(disasterType, lat, lon);
        
        // Call AI
        final prediction = await _aiService.predictDisaster(
          disasterType: disasterType,
          lat: lat,
          lon: lon,
          currentWeather: _currentWeather!,
          additionalData: additionalData,
        );

        // Extract probability and convert to 0-1 scale
        final probability = prediction['probability'] ?? 0.0;
        aiRisks[disasterType] = (probability / 100.0).clamp(0.0, 1.0);
        
        // Store full prediction for later use
        _predictions[disasterType] = prediction;
        
        print('✅ AI prediction received for ${disasterType.name}: $probability%');
      } catch (e) {
        print('❌ AI prediction failed for ${disasterType.name}: $e');
        aiRisks[disasterType] = null; // Mark as failed
      }
    }

    return aiRisks;
  }

  /// Fetch contextual data needed for AI (fires, earthquakes, etc.)
  Future<void> _fetchContextData(double lat, double lon) async {
    // Get active fires (for wildfire context)
    try {
      _nearbyWildfires = await _wildfireService.getActiveWildfires(
        lat: lat,
        lon: lon,
        days: 2,
      );
    } catch (e) {
      _nearbyWildfires = null;
      print('Could not fetch wildfire data: $e');
    }

    // Get recent earthquakes (for earthquake context)
    try {
      _nearbyEarthquakes = await _earthquakeService.getRecentEarthquakes(
        lat: lat,
        lon: lon,
        days: 7,
        minMagnitude: 2.5,
      );
    } catch (e) {
      _nearbyEarthquakes = null;
      print('Could not fetch earthquake data: $e');
    }
  }

  /// Build context data for AI prediction
  Future<Map<String, dynamic>> _buildContextData(DisasterType disasterType, double lat, double lon) async {
    final additionalData = <String, dynamic>{};

    // Add disaster-specific context
    switch (disasterType) {
      case DisasterType.wildfire:
        additionalData['temperature'] = '${_currentWeather!.temperature.toStringAsFixed(1)}°C';
        additionalData['humidity'] = '${_currentWeather!.humidity}%';
        additionalData['wind_speed'] = '${_currentWeather!.windSpeed.toStringAsFixed(1)} m/s';
        
        if (_nearbyWildfires != null && _nearbyWildfires!.isNotEmpty) {
          additionalData['active_fires_detected'] = '${_nearbyWildfires!.length} hotspots';
          double closestDistance = double.infinity;
          for (var fire in _nearbyWildfires!) {
            final distance = _calculateDistance(lat, lon, fire.latitude, fire.longitude);
            if (distance < closestDistance) closestDistance = distance;
          }
          additionalData['closest_fire_distance'] = '${closestDistance.toStringAsFixed(1)} km';
        } else {
          additionalData['active_fires_detected'] = 'None detected';
        }
        break;

      case DisasterType.earthquake:
        if (_nearbyEarthquakes != null && _nearbyEarthquakes!.isNotEmpty) {
          additionalData['recent_earthquakes'] = _nearbyEarthquakes!.length;
          final significant = _nearbyEarthquakes!.where((e) => e.magnitude >= 4.0).length;
          if (significant > 0) {
            additionalData['significant_quakes_m4+'] = significant;
          }
        } else {
          additionalData['recent_earthquakes'] = 'None in past 7 days';
        }
        break;

      case DisasterType.flood:
        final rainfall = _currentWeather!.rainfall ?? 0.0;
        additionalData['current_rainfall'] = '${rainfall.toStringAsFixed(1)} mm/h';
        break;

      case DisasterType.drought:
        final forecast = await _weatherService.getForecast(lat, lon);
        final next3Days = forecast.next3Days;
        double totalRain = 0.0;
        for (var w in next3Days) {
          totalRain += w.rainfall ?? 0.0;
        }
        additionalData['forecast_3day_rainfall'] = '${totalRain.toStringAsFixed(1)} mm';
        additionalData['current_rainfall'] = '${(_currentWeather!.rainfall ?? 0.0).toStringAsFixed(1)} mm/h';
        additionalData['humidity'] = '${_currentWeather!.humidity}%';
        break;

      default:
        break;
    }

    return additionalData;
  }

  /// FALLBACK: Calculate risk using rule-based methods
  Future<double> _calculateRuleBasedRisk(DisasterType disasterType, double lat, double lon) async {
    switch (disasterType) {
      case DisasterType.flood:
        return await _weatherService.calculateFloodRisk(lat, lon);

      case DisasterType.cyclone:
        return await _weatherService.calculateCycloneRisk(lat, lon);

      case DisasterType.wildfire:
        final weatherRisk = await _weatherService.calculateWildfireRisk(lat, lon);
        final fireRisk = await _wildfireService.calculateWildfireRisk(lat: lat, lon: lon);
        double risk = ((weatherRisk + fireRisk) / 2).clamp(0.0, 1.0);
        if (_nearbyWildfires != null && _nearbyWildfires!.isNotEmpty) {
          risk = (risk + 0.3).clamp(0.0, 1.0);
        }
        return risk;

      case DisasterType.heatwave:
        return await _weatherService.calculateHeatwaveRisk(lat, lon);

      case DisasterType.earthquake:
        double risk = await _earthquakeService.calculateEarthquakeRisk(lat: lat, lon: lon);
        if (_nearbyEarthquakes != null && _nearbyEarthquakes!.isNotEmpty) {
          final significant = _nearbyEarthquakes!.where((e) => e.magnitude >= 4.0).length;
          if (significant > 0) {
            risk = (risk + 0.2).clamp(0.0, 1.0);
          }
        }
        return risk;

      case DisasterType.drought:
        return await _weatherService.calculateDroughtRisk(lat, lon);
    }
  }

  /// Generate alerts for high-risk disasters
  void _generateAlerts() {
    final newAlerts = <Alert>[];

    _predictions.forEach((disasterType, predictionData) {
      final probability = predictionData['probability'] as double;
      
      // Generate alert if probability is high
      if (probability >= 60.0) {
        final alert = Alert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          disasterType: disasterType,
          location: app_location.Location(
            id: 'current',
            name: 'Your Location',
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          ),
          title: '${disasterType.name} Alert',
          message: predictionData['explanation'] ?? 
              'High risk of ${disasterType.name.toLowerCase()} detected.',
          severity: _getSeverityFromProbability(probability),
          issuedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          status: 'active',
        );
        newAlerts.add(alert);
      }
    });

    _alerts = newAlerts;
  }

  AlertSeverity _getSeverityFromProbability(double probability) {
    if (probability >= 80) return AlertSeverity.critical;
    if (probability >= 70) return AlertSeverity.severe;
    if (probability >= 60) return AlertSeverity.warning;
    return AlertSeverity.info;
  }

  /// Get risk score for a specific disaster type
  double getRiskScore(DisasterType type) {
    return _riskScores[type] ?? 0.0;
  }

  /// Get prediction for a specific disaster type
  Map<String, dynamic>? getPrediction(DisasterType type) {
    return _predictions[type];
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validate and adjust contradictory risk predictions
  void _validateAndAdjustRisks() {
    // RULE 1: Cannot have both FLOOD and DROUGHT simultaneously
    // If flood risk is high (>0.3), drought should be near zero
    final floodRisk = _riskScores[DisasterType.flood] ?? 0.0;
    final droughtRisk = _riskScores[DisasterType.drought] ?? 0.0;
    
    if (floodRisk > 0.3 && droughtRisk > 0.1) {
      // Flooding conditions = no drought
      _riskScores[DisasterType.drought] = 0.0;
      print('⚠️ Adjusted: Flood conditions detected, drought risk set to 0');
    } else if (floodRisk > 0.2 && droughtRisk > 0.2) {
      // Moderate flood = very low drought
      _riskScores[DisasterType.drought] = 0.02;
      print('⚠️ Adjusted: High rainfall detected, drought risk reduced to 2%');
    }
    
    // RULE 2: Cannot have WILDFIRE during heavy rain/flood
    // If flood risk is high or currently raining heavily, wildfire should be near zero
    final wildfireRisk = _riskScores[DisasterType.wildfire] ?? 0.0;
    
    if (floodRisk > 0.3 && wildfireRisk > 0.1) {
      // Heavy rain = no wildfire risk
      _riskScores[DisasterType.wildfire] = 0.0;
      print('⚠️ Adjusted: Heavy rainfall detected, wildfire risk set to 0');
    } else if (floodRisk > 0.15 && wildfireRisk > 0.15) {
      // Moderate rain = very low wildfire
      _riskScores[DisasterType.wildfire] = 0.02;
      print('⚠️ Adjusted: Rainfall detected, wildfire risk reduced to 2%');
    }
    
    // RULE 3: Cannot have HEATWAVE during CYCLONE/heavy rain
    // Cyclones bring cooler air and heavy rain
    final cycloneRisk = _riskScores[DisasterType.cyclone] ?? 0.0;
    final heatwaveRisk = _riskScores[DisasterType.heatwave] ?? 0.0;
    
    if (cycloneRisk > 0.3 && heatwaveRisk > 0.2) {
      // Cyclonic conditions = no heatwave
      _riskScores[DisasterType.heatwave] = 0.0;
      print('⚠️ Adjusted: Cyclone conditions detected, heatwave risk set to 0');
    }
    
    if (floodRisk > 0.3 && heatwaveRisk > 0.2) {
      // Heavy rain = cooler temperatures
      _riskScores[DisasterType.heatwave] = (heatwaveRisk * 0.3).clamp(0.0, 0.15);
      print('⚠️ Adjusted: Heavy rainfall detected, heatwave risk reduced by 70%');
    }
    
    // RULE 4: High humidity (>75%) contradicts drought/wildfire/heatwave
    if (_currentWeather != null && _currentWeather!.humidity > 75) {
      if (droughtRisk > 0.05) {
        _riskScores[DisasterType.drought] = 0.02;
        print('⚠️ Adjusted: High humidity (${_currentWeather!.humidity}%), drought risk reduced to 2%');
      }
      if (wildfireRisk > 0.05) {
        _riskScores[DisasterType.wildfire] = 0.02;
        print('⚠️ Adjusted: High humidity (${_currentWeather!.humidity}%), wildfire risk reduced to 2%');
      }
    }
    
    // RULE 5: Currently raining = no drought, minimal wildfire
    if (_currentWeather != null) {
      final currentRain = _currentWeather!.rainfall ?? 0.0;
      if (currentRain > 1.0) {
        // Heavy current rain
        if (droughtRisk > 0.0) {
          _riskScores[DisasterType.drought] = 0.0;
          print('⚠️ Adjusted: Currently raining (${currentRain}mm/h), drought risk set to 0');
        }
        if (wildfireRisk > 0.0) {
          _riskScores[DisasterType.wildfire] = 0.0;
          print('⚠️ Adjusted: Currently raining (${currentRain}mm/h), wildfire risk set to 0');
        }
      } else if (currentRain > 0.1) {
        // Light rain
        if (droughtRisk > 0.02) {
          _riskScores[DisasterType.drought] = 0.01;
          print('⚠️ Adjusted: Light rain detected, drought risk reduced to 1%');
        }
      }
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
