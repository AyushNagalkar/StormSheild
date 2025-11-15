import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for StormShield
/// Loads API keys from .env file
class EnvConfig {
  // Supabase Configuration
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? '';
  
  static String get supabaseAnonKey => 
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // OpenWeather API
  static String get openWeatherApiKey => 
      dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  // NASA FIRMS API
  static String get nasaFirmsApiKey => 
      dotenv.env['NASA_FIRMS_API_KEY'] ?? '';

  // Google Gemini AI API
  static String get geminiApiKey => 
      dotenv.env['GEMINI_API_KEY'] ?? '';

  // Hugging Face API
  static String get huggingFaceApiKey => 
      dotenv.env['HUGGINGFACE_API_KEY'] ?? '';

  // Optional: Google Maps API
  static String get googleMapsApiKey => 
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Optional: Mapbox Token
  static String get mapboxAccessToken => 
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  /// Validate that all required API keys are present
  static bool validateConfig() {
    final required = [
      supabaseUrl,
      supabaseAnonKey,
      openWeatherApiKey,
      nasaFirmsApiKey,
      geminiApiKey,
    ];

    return required.every((key) => key.isNotEmpty);
  }

  /// Get list of missing API keys
  static List<String> getMissingKeys() {
    final List<String> missing = [];

    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (openWeatherApiKey.isEmpty) missing.add('OPENWEATHER_API_KEY');
    if (nasaFirmsApiKey.isEmpty) missing.add('NASA_FIRMS_API_KEY');
    if (geminiApiKey.isEmpty) missing.add('GEMINI_API_KEY');

    return missing;
  }
}
