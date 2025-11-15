import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/env_config.dart';
import '../models/weather_data.dart';

/// Seasonal context for India
enum IndianSeason {
  winter,      // Dec-Feb
  spring,      // Mar-Apr (Pre-monsoon/Summer)
  monsoon,     // Jun-Sep
  postMonsoon, // Oct-Nov
}

/// Regional climate zones in India
enum ClimateZone {
  coastal,           // High humidity, moderate temps
  tropical,          // High rainfall, humid
  arid,              // Low rainfall, high temps (Rajasthan, Gujarat)
  semiArid,          // Moderate rainfall (Deccan plateau)
  himalayan,         // Cold, high altitude
  northernPlains,    // Extreme temps, seasonal
}

/// Weather service using Open-Meteo API (FREE, No key required!)
/// Fallback to OpenWeather if preferred
class WeatherService {
  final String _apiKey = EnvConfig.openWeatherApiKey;
  final bool _useOpenMeteo = true; // Use free Open-Meteo by default
  
  /// Get current season in India
  IndianSeason _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 12 || month <= 2) return IndianSeason.winter;
    if (month >= 3 && month <= 5) return IndianSeason.spring; // Pre-monsoon/Summer
    if (month >= 6 && month <= 9) return IndianSeason.monsoon;
    return IndianSeason.postMonsoon; // Oct-Nov
  }

  /// Get climate zone for location
  ClimateZone _getClimateZone(double lat, double lon) {
    // Coastal areas
    if (_isCoastalArea(lat, lon)) {
      return ClimateZone.coastal;
    }
    
    // Himalayan region (high altitude)
    if (lat > 28.0) {
      return ClimateZone.himalayan;
    }
    
    // Arid regions (Rajasthan, parts of Gujarat)
    // Rajasthan: 24-30N, 69-78E
    if (lat >= 24.0 && lat <= 30.5 && lon >= 69.0 && lon <= 78.0) {
      return ClimateZone.arid;
    }
    
    // Tropical regions (Kerala, Karnataka coast, Northeast)
    // Kerala: 8-12N, 75-77E
    // Northeast: 23-28N, 88-97E
    if ((lat >= 8.0 && lat <= 12.0) || (lat >= 23.0 && lat <= 28.0 && lon >= 88.0)) {
      return ClimateZone.tropical;
    }
    
    // Northern plains (Punjab, Haryana, UP, Bihar)
    // 24-30N, 75-88E
    if (lat >= 24.0 && lat <= 30.0 && lon >= 75.0 && lon <= 88.0) {
      return ClimateZone.northernPlains;
    }
    
    // Default: Semi-arid (Deccan plateau)
    return ClimateZone.semiArid;
  }
  
  /// Get current weather for a location using Open-Meteo
  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    // Try Open-Meteo first (FREE, no key needed)
    if (_useOpenMeteo) {
      try {
        return await _getCurrentWeatherOpenMeteo(lat, lon);
      } catch (e) {
        print('Open-Meteo failed, trying OpenWeather: $e');
        // Fallback to OpenWeather
      }
    }
    
    // Fallback to OpenWeather
    return await _getCurrentWeatherOpenWeather(lat, lon);
  }

  /// Get current weather from Open-Meteo (FREE)
  Future<WeatherData> _getCurrentWeatherOpenMeteo(double lat, double lon) async {
    try {
      final url = ApiConfig.buildOpenMeteoUrl(lat, lon);
      final response = await http.get(
        Uri.parse(url),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOpenMeteoData(data);
      } else {
        throw Exception('Failed to load weather data from Open-Meteo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Open-Meteo data: $e');
    }
  }

  /// Parse Open-Meteo response to WeatherData
  WeatherData _parseOpenMeteoData(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;
    
    // Convert Open-Meteo weather codes to descriptions
    final weatherCode = current['weather_code'] as int? ?? 0;
    final description = _getWeatherDescription(weatherCode);
    
    // Get daily temps for min/max
    final dailyMaxTemps = daily['temperature_2m_max'] as List? ?? [];
    final dailyMinTemps = daily['temperature_2m_min'] as List? ?? [];
    
    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      tempMin: dailyMinTemps.isNotEmpty ? (dailyMinTemps[0] as num).toDouble() : 0.0,
      tempMax: dailyMaxTemps.isNotEmpty ? (dailyMaxTemps[0] as num).toDouble() : 0.0,
      pressure: 1013, // Open-Meteo doesn't provide pressure in free tier
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      windDeg: (current['wind_direction_10m'] as num?)?.toInt() ?? 0,
      description: description,
      icon: _getWeatherIcon(weatherCode),
      rainfall: (current['rain'] as num?)?.toDouble(),
      timestamp: DateTime.now(),
    );
  }

  /// Get weather icon code from WMO weather code
  String _getWeatherIcon(int code) {
    if (code == 0) return '01d'; // Clear
    if (code <= 3) return '02d'; // Partly cloudy
    if (code <= 48) return '50d'; // Fog
    if (code <= 67) return '10d'; // Rain
    if (code <= 77) return '13d'; // Snow
    if (code <= 82) return '09d'; // Showers
    if (code <= 86) return '13d'; // Snow showers
    if (code <= 99) return '11d'; // Thunderstorm
    return '01d';
  }

  /// Get weather description from WMO weather code
  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Get current weather from OpenWeather (Backup)
  Future<WeatherData> _getCurrentWeatherOpenWeather(double lat, double lon) async {
    try {
      final url = ApiConfig.buildOpenWeatherUrl(
        ApiConfig.openWeatherCurrent,
        _apiKey,
        {
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );

      final response = await http.get(
        Uri.parse(url),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  /// Get 5-day weather forecast
  Future<ForecastData> getForecast(double lat, double lon) async {
    // Try Open-Meteo first (already called in getCurrentWeather)
    if (_useOpenMeteo) {
      try {
        return await _getForecastOpenMeteo(lat, lon);
      } catch (e) {
        print('Open-Meteo forecast failed, trying OpenWeather: $e');
        // Fallback to OpenWeather
      }
    }
    
    // Fallback to OpenWeather
    return await _getForecastOpenWeather(lat, lon);
  }

  /// Get forecast from Open-Meteo (already fetched with current weather)
  Future<ForecastData> _getForecastOpenMeteo(double lat, double lon) async {
    try {
      final url = ApiConfig.buildOpenMeteoUrl(lat, lon);
      final response = await http.get(
        Uri.parse(url),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOpenMeteoForecast(data);
      } else {
        throw Exception('Failed to load forecast from Open-Meteo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Open-Meteo forecast: $e');
    }
  }

  /// Parse Open-Meteo forecast data
  ForecastData _parseOpenMeteoForecast(Map<String, dynamic> data) {
    final hourly = data['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List;
    final temps = hourly['temperature_2m'] as List;
    final precips = hourly['precipitation'] as List;
    final weatherCodes = hourly['weather_code'] as List;
    final windSpeeds = hourly['wind_speed_10m'] as List;
    
    final forecasts = <WeatherData>[];
    
    // Create forecast entries for next 5 days (3-hour intervals)
    for (int i = 0; i < times.length && i < 40; i += 3) {
      forecasts.add(WeatherData(
        temperature: (temps[i] as num).toDouble(),
        feelsLike: (temps[i] as num).toDouble(), // Approximation
        tempMin: (temps[i] as num).toDouble(),
        tempMax: (temps[i] as num).toDouble(),
        pressure: 1013,
        humidity: 50, // Default as Open-Meteo hourly doesn't include humidity
        windSpeed: (windSpeeds[i] as num).toDouble(),
        windDeg: 0,
        description: _getWeatherDescription(weatherCodes[i] as int),
        icon: _getWeatherIcon(weatherCodes[i] as int),
        rainfall: (precips[i] as num).toDouble(),
        timestamp: DateTime.parse(times[i] as String),
      ));
    }
    
    return ForecastData(
      forecasts: forecasts,
      fetchedAt: DateTime.now(),
    );
  }

  /// Get forecast from OpenWeather (Backup)
  Future<ForecastData> _getForecastOpenWeather(double lat, double lon) async {
    try {
      final url = ApiConfig.buildOpenWeatherUrl(
        ApiConfig.openWeatherForecast,
        _apiKey,
        {
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );

      final response = await http.get(
        Uri.parse(url),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ForecastData.fromJson(data);
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast data: $e');
    }
  }

  /// Check if location is in a coastal area
  /// Coastal cities: Mumbai, Chennai, Kolkata, Goa, Kerala coast, etc.
  bool _isCoastalArea(double lat, double lon) {
    // Major coastal regions in India
    // West Coast: Mumbai (19.07, 72.87), Goa (15.29, 74.12), Kerala (8-12N, 75-77E)
    // East Coast: Chennai (13.08, 80.27), Kolkata (22.57, 88.36), Visakhapatnam (17.68, 83.21)
    
    // West coast check (Arabian Sea) - longitude 72-78E
    if (lon >= 72.0 && lon <= 78.0) {
      // Check if latitude is in coastal range
      if ((lat >= 8.0 && lat <= 22.0)) { // Kerala to Maharashtra coast
        return true;
      }
    }
    
    // East coast check (Bay of Bengal) - longitude 80-90E
    if (lon >= 80.0 && lon <= 90.0) {
      // Check if latitude is in coastal range
      if ((lat >= 8.0 && lat <= 23.0)) { // Tamil Nadu to West Bengal coast
        return true;
      }
    }
    
    // Southern tip (around Kanyakumari)
    if (lat >= 7.5 && lat <= 9.0 && lon >= 76.0 && lon <= 80.0) {
      return true;
    }
    
    return false;
  }

  /// Calculate flood risk based on weather data
  Future<double> calculateFloodRisk(double lat, double lon) async {
    try {
      final current = await getCurrentWeather(lat, lon);
      final forecast = await getForecast(lat, lon);

      double risk = 0.0;

      // Realistic flood thresholds (based on IMD standards)
      // Heavy rain: 64.5-115.5 mm/day, Very heavy: 115.6-204.4 mm/day
      
      // Current rainfall rate (mm/h)
      if (current.rainfall != null && current.rainfall! > 0) {
        if (current.rainfall! > 15) {
          risk += 0.30; // Extremely heavy (>15mm/h can cause flash floods)
        } else if (current.rainfall! > 10) {
          risk += 0.20; // Very heavy
        } else if (current.rainfall! > 7.5) {
          risk += 0.12; // Heavy
        } else if (current.rainfall! > 4) {
          risk += 0.06; // Moderate to heavy
        }
      }

      // Forecast rainfall accumulation (next 24 hours)
      final next24h = forecast.next24Hours;
      double totalRainfall = 0;
      for (var weather in next24h) {
        if (weather.rainfall != null) {
          totalRainfall += weather.rainfall!;
        }
      }

      // Accumulated rainfall risk (realistic flood thresholds)
      if (totalRainfall > 200) {
        risk += 0.35; // Extremely heavy - definite flood risk
      } else if (totalRainfall > 115) {
        risk += 0.25; // Very heavy rain (IMD category)
      } else if (totalRainfall > 65) {
        risk += 0.15; // Heavy rain (IMD category)
      } else if (totalRainfall > 35) {
        risk += 0.08; // Moderate to heavy
      }

      // Very high humidity can indicate sustained rain
      if (current.humidity > 95) {
        risk += 0.08;
      } else if (current.humidity > 90) {
        risk += 0.04;
      }

      return risk.clamp(0.0, 1.0);
    } catch (e) {
      print('Error calculating flood risk: $e');
      return 0.0;
    }
  }

  /// Calculate cyclone risk based on weather data
  Future<double> calculateCycloneRisk(double lat, double lon) async {
    try {
      final current = await getCurrentWeather(lat, lon);
      final forecast = await getForecast(lat, lon);

      double risk = 0.0;

      // Get seasonal context
      final season = _getCurrentSeason();

      // SEASONAL ADJUSTMENTS: Cyclone season in India
      // Peak seasons: May-June (pre-monsoon) and Oct-Nov (post-monsoon)
      // Minimal in: Dec-Feb (winter), Jul-Aug (monsoon)
      
      // Non-coastal areas: Cyclones don't penetrate far inland
      if (!_isCoastalArea(lat, lon)) {
        // Cyclones weaken rapidly over land
        // Reduce risk by 70% for inland locations
        // (They may still experience remnant effects)
      }

      // Winter season: Very rare cyclones
      if (season == IndianSeason.winter) {
        // Cyclones are rare in winter but not impossible
        // Reduce sensitivity but don't eliminate completely
      }

      // Peak cyclone season: Pre-monsoon (Mar-May) and Post-monsoon (Oct-Nov)
      bool isPeakSeason = (season == IndianSeason.spring || season == IndianSeason.postMonsoon);

      // Realistic cyclone indicators (IMD classification)
      // Wind speed thresholds (m/s): >17 = Cyclonic storm, >24 = Severe, >33 = Very severe
      
      // Check wind speed (primary indicator)
      if (current.windSpeed > 33) {
        risk += 0.50; // Very severe cyclonic storm (>119 km/h)
      } else if (current.windSpeed > 24) {
        risk += 0.35; // Severe cyclonic storm (88-118 km/h)
      } else if (current.windSpeed > 17) {
        risk += 0.20; // Cyclonic storm (62-88 km/h)
      } else if (current.windSpeed > 10) {
        risk += 0.08; // Strong winds, possible development
      }

      // Pressure - critical cyclone indicator
      // Normal sea level: ~1013 hPa, Cyclones: <1000 hPa
      if (current.pressure < 950) {
        risk += 0.30; // Very intense cyclone
      } else if (current.pressure < 980) {
        risk += 0.20; // Intense cyclone
      } else if (current.pressure < 995) {
        risk += 0.12; // Cyclone formation
      } else if (current.pressure < 1005) {
        risk += 0.05; // Low pressure system
      }

      // Sustained high winds in forecast
      final next24h = forecast.next24Hours;
      int highWindCount = 0;
      for (var weather in next24h) {
        if (weather.windSpeed > 17) {
          highWindCount++;
        }
      }

      // Sustained winds indicate organized system
      if (highWindCount > 8) {
        risk += 0.15; // Sustained for 8+ hours
      } else if (highWindCount > 4) {
        risk += 0.08; // Sustained for 4+ hours
      }

      // Adjust based on season and location
      if (!isPeakSeason && risk < 0.3) {
        // Non-peak season, reduce minor risks
        risk *= 0.5;
      }

      if (!_isCoastalArea(lat, lon) && risk > 0) {
        // Inland location, reduce risk (cyclones weaken over land)
        risk *= 0.3;
      }

      return risk.clamp(0.0, 1.0);
    } catch (e) {
      print('Error calculating cyclone risk: $e');
      return 0.0;
    }
  }

  /// Calculate wildfire risk based on weather data
  Future<double> calculateWildfireRisk(double lat, double lon) async {
    try {
      final current = await getCurrentWeather(lat, lon);
      final forecast = await getForecast(lat, lon);

      double risk = 0.0;

      // Get seasonal and geographical context
      final season = _getCurrentSeason();
      final climateZone = _getClimateZone(lat, lon);

      // SEASONAL ADJUSTMENTS: Wildfire risk varies by season
      // Monsoon season (Jun-Sep): Minimal wildfire risk due to rain
      if (season == IndianSeason.monsoon) {
        // During monsoon, only report fires if actually detected by NASA FIRMS
        return 0.0; // Monsoon season - wet conditions
      }

      // Winter (Dec-Feb): Low wildfire risk in most regions
      if (season == IndianSeason.winter && climateZone != ClimateZone.arid) {
        // Winter has lower temperatures and some rainfall
        // Only arid regions (Rajasthan) might have some risk
        return 0.0; // Winter season - low fire risk
      }

      // CRITICAL: Coastal cities and urban areas have minimal wildfire risk
      // Check if location is coastal (within ~50km of major coastline)
      final isCoastal = _isCoastalArea(lat, lon);
      if (isCoastal) {
        // Coastal areas have high humidity, sea breeze, and less vegetation
        // Only report risk if there are actual fires nearby (handled by wildfire_service)
        return 0.0; // Coastal cities - minimal natural wildfire risk
      }

      // Himalayan region: Different fire season (Apr-May mainly)
      if (climateZone == ClimateZone.himalayan) {
        if (season != IndianSeason.spring) {
          return 0.0; // Non-spring season in mountains - minimal risk
        }
      }

      // CRITICAL: Check for recent/current rainfall - wet conditions = NO fire risk
      final currentRain = current.rainfall ?? 0.0;
      
      // Check forecast for recent/upcoming rainfall
      final next24h = forecast.next24Hours;
      double recentRainfall = currentRain;
      for (var weather in next24h.take(6)) { // Check last 6 hours of forecast
        recentRainfall += weather.rainfall ?? 0.0;
      }

      // If significant rain (>5mm), wildfire risk is near zero
      if (recentRainfall > 5.0) {
        return 0.0; // Wet conditions - no fire risk
      } else if (recentRainfall > 2.0) {
        return 0.02; // Damp conditions - minimal risk
      } else if (currentRain > 0.1) {
        return 0.0; // Currently raining - no fire risk
      }

      // High humidity regions (>70%) rarely have wildfire risk
      if (current.humidity > 70) {
        return 0.0; // Very humid climate - no fire risk (changed from 0.01)
      }

      // Very high humidity (>60%) in tropical/monsoon regions
      if (current.humidity > 60 && lat > 8 && lat < 30) {
        return 0.0; // Humid tropical region - no fire risk
      }

      // Only calculate fire risk for DRY conditions
      // Realistic wildfire conditions (based on Forest Fire Danger Index)
      
      // Temperature risk (fires mainly occur above 30°C)
      if (current.temperature > 45) {
        risk += 0.25; // Extreme heat
      } else if (current.temperature > 40) {
        risk += 0.15; // Very high heat
      } else if (current.temperature > 35) {
        risk += 0.10; // High heat
      } else if (current.temperature > 30) {
        risk += 0.05; // Moderate heat
      }

      // Humidity risk (critical factor - below 30% is high risk)
      if (current.humidity < 15) {
        risk += 0.25; // Extremely dry
      } else if (current.humidity < 25) {
        risk += 0.15; // Very dry
      } else if (current.humidity < 35) {
        risk += 0.08; // Moderately dry
      }

      // Wind speed (spreads fire - realistic thresholds)
      if (current.windSpeed > 30) {
        risk += 0.20; // Very high wind (>108 km/h)
      } else if (current.windSpeed > 20) {
        risk += 0.12; // High wind (>72 km/h)
      } else if (current.windSpeed > 15) {
        risk += 0.05; // Moderate wind
      }

      // Check forecast for sustained hot, dry conditions (3+ hours)
      int hotDryCount = 0;
      for (var weather in next24h) {
        if (weather.temperature > 32 && weather.humidity < 35) {
          hotDryCount++;
        }
      }

      // Only add risk if sustained conditions (6+ hours)
      if (hotDryCount >= 6) {
        risk += 0.10;
      } else if (hotDryCount >= 4) {
        risk += 0.05;
      }

      return risk.clamp(0.0, 1.0);
    } catch (e) {
      print('Error calculating wildfire risk: $e');
      return 0.0;
    }
  }

  /// Calculate heatwave risk based on weather data
  Future<double> calculateHeatwaveRisk(double lat, double lon) async {
    try {
      final current = await getCurrentWeather(lat, lon);
      final forecast = await getForecast(lat, lon);

      double risk = 0.0;

      // Get seasonal and geographical context
      final season = _getCurrentSeason();
      final climateZone = _getClimateZone(lat, lon);

      // SEASONAL ADJUSTMENTS: Heatwave season in India
      // Peak: Mar-Jun (Spring/Summer/Pre-monsoon)
      // Minimal: Jun-Sep (Monsoon), Oct-Feb (Post-monsoon/Winter)
      
      // Monsoon season: Heatwaves are extremely rare
      if (season == IndianSeason.monsoon) {
        return 0.0; // Monsoon brings cooler, rainy weather
      }

      // Winter season: Heatwaves don't occur
      if (season == IndianSeason.winter) {
        return 0.0; // Winter has cool/cold temperatures
      }

      // Post-monsoon: Heatwaves are very rare
      if (season == IndianSeason.postMonsoon && current.temperature < 38) {
        return 0.0; // Post-monsoon is cooler
      }

      // Coastal areas: Moderated temperatures due to sea breeze
      if (climateZone == ClimateZone.coastal && current.temperature < 40) {
        return 0.01; // Coastal areas rarely hit extreme heat
      }

      // Himalayan region: Different temperature thresholds
      if (climateZone == ClimateZone.himalayan) {
        // Mountains don't experience typical heatwaves
        if (current.temperature < 35) {
          return 0.0; // Not hot enough for mountain heatwave
        }
      }

      // CRITICAL: Heavy rain/storms reduce heatwave risk (cooler conditions)
      final currentRain = current.rainfall ?? 0.0;
      final next24h = forecast.next24Hours;
      double forecastRain = 0.0;
      for (var weather in next24h) {
        forecastRain += weather.rainfall ?? 0.0;
      }

      // If heavy rain is occurring or forecast, heatwave risk is very low
      if (currentRain > 5.0 || forecastRain > 50.0) {
        return 0.0; // Heavy rain = no heatwave
      } else if (currentRain > 2.0 || forecastRain > 20.0) {
        return 0.02; // Moderate rain = minimal heatwave risk
      }

      // Realistic heatwave criteria (IMD standards for India)
      // Heatwave: Max temp reaches 40°C+ (plains) or 4-5°C above normal
      // Severe heatwave: 45°C+ or 6°C+ above normal
      
      // Current temperature assessment
      if (current.temperature >= 47) {
        risk += 0.40; // Extreme/severe heatwave
      } else if (current.temperature >= 45) {
        risk += 0.30; // Severe heatwave threshold
      } else if (current.temperature >= 42) {
        risk += 0.20; // Heatwave conditions
      } else if (current.temperature >= 40) {
        risk += 0.12; // Heatwave threshold
      } else if (current.temperature >= 38) {
        risk += 0.06; // High heat, approaching heatwave
      }

      // Feels-like temperature (heat index) - important for health impact
      if (current.feelsLike >= 52) {
        risk += 0.20; // Extreme danger
      } else if (current.feelsLike >= 48) {
        risk += 0.12; // Danger
      } else if (current.feelsLike >= 44) {
        risk += 0.06; // Extreme caution
      }

      // Duration matters - sustained heat over multiple days
      final next3Days = forecast.next3Days;
      int heatwaveDays = 0;
      
      for (var weather in next3Days) {
        if (weather.temperature >= 42) {
          heatwaveDays++;
        }
      }

      // IMD declares heatwave when conditions persist for 2+ days
      if (heatwaveDays >= 6) {
        risk += 0.15; // 2+ days of heatwave
      } else if (heatwaveDays >= 3) {
        risk += 0.08; // 1 day of heatwave
      }

      return risk.clamp(0.0, 1.0);
    } catch (e) {
      print('Error calculating heatwave risk: $e');
      return 0.0;
    }
  }

  /// Calculate drought risk based on precipitation patterns
  Future<double> calculateDroughtRisk(double lat, double lon) async {
    try {
      final current = await getCurrentWeather(lat, lon);
      final forecast = await getForecast(lat, lon);

      double risk = 0.0;

      // Get seasonal and geographical context
      final season = _getCurrentSeason();
      final climateZone = _getClimateZone(lat, lon);

      // Realistic drought assessment (based on meteorological standards)
      // Note: Real drought develops over weeks/months, not hours
      // This is a SHORT-TERM drought stress indicator only

      // SEASONAL ADJUSTMENTS: Drought risk varies by season
      // Monsoon season (Jun-Sep): Minimal drought risk
      if (season == IndianSeason.monsoon) {
        // During monsoon, drought is extremely unlikely
        return 0.0; // Monsoon season - good rainfall expected
      }

      // Coastal and tropical zones: Rarely have drought
      if (climateZone == ClimateZone.coastal || climateZone == ClimateZone.tropical) {
        // These zones have high humidity year-round
        return 0.0; // High moisture climate - no drought
      }

      // Post-monsoon (Oct-Nov): Unlikely to have drought (recent monsoon moisture)
      if (season == IndianSeason.postMonsoon) {
        // Soil still has monsoon moisture
        return 0.01; // Post-monsoon - residual moisture
      }

      // CRITICAL: If currently raining or high humidity, NO drought risk
      final currentRain = current.rainfall ?? 0.0;
      if (currentRain > 0.5) {
        return 0.0; // Currently raining - no drought risk
      }
      
      // High humidity climates (>75%) rarely have drought stress
      if (current.humidity > 75) {
        return 0.0; // Very humid climate - no drought (changed from 0.01)
      }

      // Check forecast for prolonged dry period
      final next3Days = forecast.next3Days;
      int dryHours = 0;
      double totalRainfall = 0.0;
      
      for (var weather in next3Days) {
        final rain = weather.rainfall ?? 0.0;
        totalRainfall += rain;
        if (rain < 0.1) {
          dryHours++;
        }
      }

      // If good rainfall is forecast (>20mm), NO drought risk
      if (totalRainfall > 20.0) {
        return 0.0; // Good rainfall expected - no drought
      } else if (totalRainfall > 10.0) {
        return 0.02; // Moderate rainfall - minimal drought risk
      } else if (totalRainfall > 5.0) {
        return 0.05; // Light rainfall - very low drought risk
      }

      // Only calculate drought risk if conditions are DRY
      // No current rain is only concerning if it's part of a DRY pattern
      final rainfall1h = current.rainfall ?? 0.0;
      if (rainfall1h == 0.0 && totalRainfall < 2.0) {
        risk += 0.05; // No rain now AND very little forecast
      }

      // Dry percentage (only significant if 85%+ dry AND low total rainfall)
      final totalHours = next3Days.length;
      if (totalHours > 0) {
        final dryPercentage = dryHours / totalHours;
        if (dryPercentage > 0.95 && totalRainfall < 2.0) {
          risk += 0.15; // Almost no rain expected
        } else if (dryPercentage > 0.85 && totalRainfall < 5.0) {
          risk += 0.08; // Very little rain expected
        }
      }

      // Very low total precipitation expected (realistic threshold)
      if (totalRainfall < 2.0) {
        risk += 0.15; // Less than 2mm in 3 days
      } else if (totalRainfall < 5.0) {
        risk += 0.08; // Less than 5mm in 3 days
      }

      // High temperatures increase evaporation (realistic thresholds)
      if (current.temperature > 38) {
        risk += 0.12; // Extreme heat
      } else if (current.temperature > 33) {
        risk += 0.06; // High heat
      }

      // Low humidity indicates dry atmosphere
      if (current.humidity < 25) {
        risk += 0.10; // Very dry air
      } else if (current.humidity < 35) {
        risk += 0.05; // Dry air
      }

      return risk.clamp(0.0, 1.0);
    } catch (e) {
      print('Error calculating drought risk: $e');
      return 0.0;
    }
  }
}