import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/env_config.dart';
import '../models/disaster_type.dart';
import '../models/weather_data.dart';

/// AI Prediction service using Google Gemini API (FREE)
class AiPredictionService {
  final String _apiKey = EnvConfig.geminiApiKey;

  /// Generate disaster prediction using Gemini AI
  Future<Map<String, dynamic>> predictDisaster({
    required DisasterType disasterType,
    required double lat,
    required double lon,
    required WeatherData currentWeather,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final prompt = _buildPrompt(
        disasterType,
        lat,
        lon,
        currentWeather,
        additionalData,
      );

      final url = ApiConfig.buildGeminiUrl(_apiKey);
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 500,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(ApiConfig.requestTimeout);

      print('🌐 Gemini API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = _extractTextFromResponse(data);
        print('✅ Gemini AI response received: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
        return _parseAiResponse(text, disasterType);
      } else {
        print('❌ Gemini API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get AI prediction: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('❌ Error getting AI prediction: $e');
      // Return fallback prediction
      return _getFallbackPrediction(disasterType);
    }
  }

  /// Build prompt for AI
  String _buildPrompt(
    DisasterType disasterType,
    double lat,
    double lon,
    WeatherData weather,
    Map<String, dynamic>? additionalData,
  ) {
    final buffer = StringBuffer();
    
    // Enhanced context with location and season
    final month = DateTime.now().month;
    String season = _getSeason(month);
    String region = _getRegionInfo(lat, lon);
    
    // Get calculated risk from additional data if available
    final calculatedRisk = additionalData?['calculated_risk'] ?? 0.0;
    final riskPercentage = (calculatedRisk * 100).toStringAsFixed(0);
    
    buffer.writeln('You are an expert disaster analyst combining data-driven risk assessment with real-world context.');
    buffer.writeln('Our rule-based system has calculated a $riskPercentage% risk score for ${disasterType.name}.');
    buffer.writeln();
    buffer.writeln('Your role: Provide human-centered analysis by considering:');
    buffer.writeln('1. Local geographical vulnerabilities');
    buffer.writeln('2. Historical patterns in this region');
    buffer.writeln('3. Temporal evolution (how risk changes over hours/days)');
    buffer.writeln('4. Multiple disaster interactions');
    buffer.writeln('5. Community-specific safety guidance');
    buffer.writeln();
    buffer.writeln('LOCATION CONTEXT:');
    buffer.writeln('- Coordinates: ${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°');
    buffer.writeln('- Region: $region');
    buffer.writeln('- Current Season: $season');
    buffer.writeln();
    buffer.writeln('CURRENT CONDITIONS:');
    buffer.writeln('- Temperature: ${weather.temperature}°C');
    buffer.writeln('- Humidity: ${weather.humidity}%');
    buffer.writeln('- Wind Speed: ${weather.windSpeed} m/s (${(weather.windSpeed * 3.6).toStringAsFixed(1)} km/h)');
    buffer.writeln('- Pressure: ${weather.pressure} hPa');
    
    if (weather.rainfall != null) {
      buffer.writeln('- Rainfall: ${weather.rainfall} mm/h');
    }
    buffer.writeln();

    // Disaster-specific context
    buffer.writeln(_getDisasterSpecificPrompt(disasterType, weather, season));
    buffer.writeln();

    if (additionalData != null) {
      buffer.writeln('ADDITIONAL CONTEXT:');
      additionalData.forEach((key, value) {
        if (key != 'calculated_risk') { // Skip the risk score we already mentioned
          buffer.writeln('- $key: $value');
        }
      });
      buffer.writeln();
    }

    buffer.writeln('IMPORTANT GUIDELINES:');
    buffer.writeln('- You may ADJUST the risk score (up or down) based on contextual factors');
    buffer.writeln('- Consider local vulnerabilities (e.g., flood-prone river valleys, fire-prone forests)');
    buffer.writeln('- Account for seasonal anomalies (e.g., unseasonal rain, early heat)');
    buffer.writeln('- Provide actionable, location-specific advice (not generic tips)');
    buffer.writeln('- Explain the "why" behind the risk assessment');
    buffer.writeln();
    buffer.writeln('Provide your analysis in this format:');
    buffer.writeln('PROBABILITY: [0-100] (You can modify the $riskPercentage% baseline if context justifies it)');
    buffer.writeln('SEVERITY: [low/medium/high/critical]');
    buffer.writeln('CONFIDENCE: [0-100]');
    buffer.writeln('EXPLANATION: [2-3 sentences explaining WHY this risk exists for THIS specific location and time]');
    buffer.writeln('TIMELINE: [When will risk peak? e.g., "Risk highest in next 6 hours due to X"]');
    buffer.writeln('RECOMMENDATION: [Specific action for this location - mention nearby landmarks, resources, or evacuation routes if relevant]');
    
    return buffer.toString();
  }

  /// Get season based on month
  String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer/Monsoon';
    if (month >= 9 && month <= 11) return 'Autumn/Post-Monsoon';
    return 'Winter';
  }

  /// Get region information from coordinates
  String _getRegionInfo(double lat, double lon) {
    if (lat >= 8 && lat <= 37 && lon >= 68 && lon <= 97) {
      if (lat >= 28) return 'Northern India (Himalayan foothills)';
      if (lat >= 23) return 'Central India';
      if (lat >= 15) return 'Southern Peninsular India';
      return 'Coastal Southern India';
    }
    return 'Unknown region';
  }

  /// Get disaster-specific prompt guidance
  String _getDisasterSpecificPrompt(DisasterType type, WeatherData weather, String season) {
    switch (type) {
      case DisasterType.flood:
        return '''FLOOD RISK FACTORS TO ANALYZE (IMD Standards):
- Current rainfall >15mm/h indicates flash flood risk
- 24h accumulation: >200mm (extremely heavy), >115mm (very heavy - IMD), >65mm (heavy - IMD)
- Humidity >95% with sustained rain indicates saturation
- River proximity and monsoon season timing
- Pressure systems indicating prolonged rain
Critical: Monsoon season (June-Sept) significantly increases risk in this region
Reference: Indian Meteorological Department rainfall categories''';
        
      case DisasterType.cyclone:
        return '''CYCLONE RISK FACTORS TO ANALYZE (IMD Classification):
- Wind speed: ≥119 km/h (33m/s) = Very Severe Cyclone, ≥88 km/h (24m/s) = Severe Cyclone, ≥62 km/h (17m/s) = Cyclonic Storm
- Low pressure systems: <950 hPa (intense), <980 hPa (significant), <995 hPa (developing)
- Sustained high winds for 8+ hours indicates established system
- Sea surface temperature >26.5°C needed for formation
- Distance from coast (cyclones weaken inland)
- Seasonal timing (peak: May-June, Oct-Nov for Indian Ocean)
Critical: Check if location is within 100km of coast
Reference: IMD official cyclone classification system''';
        
      case DisasterType.heatwave:
        return '''HEATWAVE RISK FACTORS TO ANALYZE (IMD Criteria):
- Temperature ≥47°C (extreme danger), ≥45°C (severe heatwave), ≥42°C (heatwave), ≥40°C (heatwave for plains)
- Heat Index ≥52°C (extreme heat stress), ≥48°C (severe heat stress)
- High humidity making heat index dangerous (adds to thermal stress)
- Duration: 6+ days sustained heat (established heatwave), 3+ days (developing)
- Lack of precipitation and dry conditions
- High pressure systems causing stagnant air
Critical: Summer months (April-June) peak heatwave season. IMD defines heatwave as 40°C+ for plains.
Reference: Indian Meteorological Department heatwave definition''';
        
      case DisasterType.drought:
        return '''DROUGHT STRESS INDICATORS (SHORT-TERM):
NOTE: Real agricultural drought develops over weeks/months, not hours. This assesses immediate drought stress only.
- Forecast rainfall: <2mm in 3 days (very low), <5mm (low)
- Temperature: >38°C (extreme heat stress), >33°C (high heat stress) increases evaporation
- Humidity: <25% (very dry air), <35% (dry air) accelerates moisture loss
- No current precipitation with sustained dry conditions
- Soil moisture depletion indicators
IMPORTANT: This is a SHORT-TERM drought stress indicator. Actual drought requires extended periods (weeks/months) of below-normal rainfall.
Critical: Winter/Spring months most vulnerable for India. Long-term drought monitoring requires historical rainfall data.''';
        
      case DisasterType.wildfire:
        return '''WILDFIRE RISK FACTORS TO ANALYZE (Fire Danger Index):
- Temperature: ≥45°C (extreme fire danger), ≥40°C (very high), ≥35°C (high), ≥30°C (moderate)
- Humidity: <15% (extreme fire danger), <25% (very high), <35% (high) - dry air accelerates fire spread
- Wind speed: >30m/s (>108 km/h) extreme danger, >20m/s rapid spread, >15m/s moderate spread
- Active fires detected: <5km (immediate threat), <10km (nearby), <25km (regional), <50km (distant)
- Sustained dangerous conditions (6+ hours) significantly increases risk
- Dry season with no recent precipitation
- Vegetation type and fuel availability
Critical: Summer and pre-monsoon months (March-May) peak fire season. Fires beyond 50km have minimal direct threat.
Reference: Forest Fire Danger Index standards''';
        
      case DisasterType.earthquake:
        return '''EARTHQUAKE RISK FACTORS TO ANALYZE (USGS Standards):
Note: Earthquakes CANNOT be reliably predicted from weather data.
- Recent seismic activity: M≥7.0 (major earthquake occurred - rare), M≥6.5 (strong), M≥6.0 (significant damage possible), M≥5.0 (felt widely)
- Swarm activity: >20 earthquakes in 7 days (seismic swarm), >10 (elevated activity), >5 (moderate activity)
- 24-hour activity: >5 quakes (very high), >2 quakes (elevated)
- Analyze location's tectonic zone and fault line proximity
- Historical seismic activity in region (seismic hazard zone)
- Building preparedness and earthquake-resistant construction in area
Confidence should be LOW as earthquakes are unpredictable. Provide general preparedness advice based on regional seismic history.
IMPORTANT: Focus on preparedness, not prediction. Cannot forecast when/where earthquakes will occur.
Reference: USGS magnitude classifications''';
    }
  }

  /// Extract text from Gemini API response
  String _extractTextFromResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? '';
        }
      }
    } catch (e) {
      print('Error extracting text from response: $e');
    }
    return '';
  }

  /// Parse AI response text
  Map<String, dynamic> _parseAiResponse(String text, DisasterType disasterType) {
    try {
      final lines = text.split('\n');
      double probability = 50.0;
      String severity = 'medium';
      double confidence = 70.0;
      String explanation = 'Moderate risk detected based on current conditions.';
      String timeline = 'Next 24-48 hours';

      for (var line in lines) {
        final lower = line.toLowerCase();
        if (lower.contains('probability:')) {
          final match = RegExp(r'(\d+)').firstMatch(line);
          if (match != null) {
            probability = double.parse(match.group(1)!);
          }
        } else if (lower.contains('severity:')) {
          if (lower.contains('critical')) {
            severity = 'critical';
          } else if (lower.contains('high')) {
            severity = 'high';
          } else if (lower.contains('medium')) {
            severity = 'medium';
          } else if (lower.contains('low')) {
            severity = 'low';
          }
        } else if (lower.contains('confidence:')) {
          final match = RegExp(r'(\d+)').firstMatch(line);
          if (match != null) {
            confidence = double.parse(match.group(1)!);
          }
        } else if (lower.contains('explanation:')) {
          explanation = line.substring(line.indexOf(':') + 1).trim();
        } else if (lower.contains('timeline:')) {
          timeline = line.substring(line.indexOf(':') + 1).trim();
        }
      }

      return {
        'probability': probability,
        'severity': severity,
        'confidence': confidence,
        'explanation': explanation,
        'timeline': timeline,
        'disaster_type': disasterType.name,
      };
    } catch (e) {
      print('Error parsing AI response: $e');
      return _getFallbackPrediction(disasterType);
    }
  }

  /// Get fallback prediction if AI fails
  Map<String, dynamic> _getFallbackPrediction(DisasterType disasterType) {
    return {
      'probability': 50.0,
      'severity': 'medium',
      'confidence': 60.0,
      'explanation': 'Using historical data and current conditions to assess ${disasterType.name.toLowerCase()} risk.',
      'timeline': 'Next 24-48 hours',
      'disaster_type': disasterType.name,
    };
  }

  /// Generate comprehensive risk assessment for all disaster types
  Future<Map<DisasterType, Map<String, dynamic>>> assessAllRisks({
    required double lat,
    required double lon,
    required WeatherData currentWeather,
    Map<String, dynamic>? additionalData,
  }) async {
    final results = <DisasterType, Map<String, dynamic>>{};
    
    // Assess each disaster type
    for (var disasterType in DisasterType.values) {
      try {
        final prediction = await predictDisaster(
          disasterType: disasterType,
          lat: lat,
          lon: lon,
          currentWeather: currentWeather,
          additionalData: additionalData,
        );
        results[disasterType] = prediction;
      } catch (e) {
        print('Error assessing ${disasterType.name}: $e');
        results[disasterType] = _getFallbackPrediction(disasterType);
      }
    }

    return results;
  }
}
