import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  static SupabaseClient? _instance;

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_instance == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
    
    _instance = Supabase.instance.client;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _instance != null;

  /// Get current user
  static User? get currentUser => _instance?.auth.currentUser;

  /// Sign in anonymously (for testing)
  static Future<AuthResponse> signInAnonymously() async {
    return await client.auth.signInAnonymously();
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
