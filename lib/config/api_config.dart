/// API endpoint configurations for StormShield
/// All using FREE API services
class ApiConfig {
  // OpenWeather API Endpoints (Backup - requires subscription after trial)
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String openWeatherCurrent = '$openWeatherBaseUrl/weather';
  static const String openWeatherForecast = '$openWeatherBaseUrl/forecast';
  static const String openWeatherAlerts = '$openWeatherBaseUrl/onecall';

  // Open-Meteo API (FREE, No key required, instant activation!)
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoForecast = '$openMeteoBaseUrl/forecast';

  // USGS Earthquake API (No key required)
  static const String usgsEarthquakeUrl = 'https://earthquake.usgs.gov/fdsnws/event/1/query';

  // NASA FIRMS Wildfire API
  static const String nasaFirmsBaseUrl = 'https://firms.modaps.eosdis.nasa.gov/api/area/csv';
  
  // Google Gemini AI API
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.0-flash'; // Fast, stable version
  
  // NOAA Weather API (No key required)
  static const String noaaBaseUrl = 'https://api.weather.gov';

  // API Request Limits (for rate limiting)
  static const int openWeatherDailyLimit = 1000;
  static const int openWeatherMinuteLimit = 60;
  static const int geminiMinuteLimit = 60;
  static const int geminiDailyLimit = 1500;

  // Cache durations (in minutes)
  static const int weatherCacheDuration = 30;
  static const int earthquakeCacheDuration = 15;
  static const int wildfireCacheDuration = 60;
  static const int predictionCacheDuration = 360; // 6 hours

  // Default request timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Build Open-Meteo URL (FREE alternative to OpenWeather)
  static String buildOpenMeteoUrl(double lat, double lon) {
    final uri = Uri.parse(openMeteoForecast);
    final params = {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,wind_speed_10m,wind_direction_10m',
      'hourly': 'temperature_2m,precipitation_probability,precipitation,weather_code,wind_speed_10m',
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,weather_code,wind_speed_10m_max',
      'timezone': 'auto',
      'forecast_days': '7',
    };
    
    return uri.replace(queryParameters: params).toString();
  }

  /// Build OpenWeather URL with API key (Backup)
  static String buildOpenWeatherUrl(String endpoint, String apiKey, Map<String, String> params) {
    final uri = Uri.parse(endpoint);
    final queryParams = Map<String, String>.from(params);
    queryParams['appid'] = apiKey;
    queryParams['units'] = 'metric'; // Use metric units
    
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Build USGS Earthquake URL
  static String buildEarthquakeUrl(Map<String, String> params) {
    final uri = Uri.parse(usgsEarthquakeUrl);
    params['format'] = 'geojson';
    
    return uri.replace(queryParameters: params).toString();
  }

  /// Build NASA FIRMS URL
  static String buildFirmsUrl(String apiKey, double lat, double lon, int days) {
    // Create bounding box around location (approximately 200km radius)
    final double latOffset = 1.8; // ~200km
    final double lonOffset = 1.8;
    
    final minLat = lat - latOffset;
    final maxLat = lat + latOffset;
    final minLon = lon - lonOffset;
    final maxLon = lon + lonOffset;
    
    return '$nasaFirmsBaseUrl/$apiKey/VIIRS_SNPP_NRT/$minLon,$minLat,$maxLon,$maxLat/$days';
  }

  /// Build Gemini AI URL
  static String buildGeminiUrl(String apiKey) {
    return '$geminiBaseUrl/models/$geminiModel:generateContent?key=$apiKey';
  }
}
