/// Weather data model from OpenWeather API
class WeatherData {
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int pressure;
  final int humidity;
  final double windSpeed;
  final int windDeg;
  final String description;
  final String icon;
  final int? visibility;
  final double? rainfall; // mm in last 1h
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.pressure,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.description,
    required this.icon,
    this.visibility,
    this.rainfall,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final wind = json['wind'] ?? {};
    final weather = json['weather'] != null && (json['weather'] as List).isNotEmpty
        ? json['weather'][0]
        : {};
    final rain = json['rain'];

    return WeatherData(
      temperature: (main['temp'] ?? 0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0).toDouble(),
      tempMin: (main['temp_min'] ?? 0).toDouble(),
      tempMax: (main['temp_max'] ?? 0).toDouble(),
      pressure: main['pressure'] ?? 0,
      humidity: main['humidity'] ?? 0,
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      windDeg: wind['deg'] ?? 0,
      description: weather['description'] ?? '',
      icon: weather['icon'] ?? '',
      visibility: json['visibility'],
      rainfall: rain != null ? (rain['1h'] ?? 0).toDouble() : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] ?? 0) * 1000,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feels_like': feelsLike,
      'temp_min': tempMin,
      'temp_max': tempMax,
      'pressure': pressure,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'wind_deg': windDeg,
      'description': description,
      'icon': icon,
      'visibility': visibility,
      'rainfall': rainfall,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if conditions indicate flood risk
  bool get isFloodRisk => rainfall != null && rainfall! > 10;

  /// Check if conditions indicate cyclone risk
  bool get isCycloneRisk => windSpeed > 15 && pressure < 1000;

  /// Check if conditions indicate wildfire risk
  bool get isWildfireRisk => temperature > 35 && humidity < 30;

  /// Check if conditions indicate heatwave risk
  bool get isHeatwaveRisk => temperature > 40;
}

/// Forecast data model
class ForecastData {
  final List<WeatherData> forecasts;
  final DateTime fetchedAt;

  ForecastData({
    required this.forecasts,
    required this.fetchedAt,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List<dynamic>? ?? [];
    final forecasts = list
        .map((item) => WeatherData.fromJson(item as Map<String, dynamic>))
        .toList();

    return ForecastData(
      forecasts: forecasts,
      fetchedAt: DateTime.now(),
    );
  }

  /// Get forecast for next 24 hours
  List<WeatherData> get next24Hours {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 24));
    return forecasts.where((f) => f.timestamp.isBefore(cutoff)).toList();
  }

  /// Get forecast for next 3 days
  List<WeatherData> get next3Days {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 3));
    return forecasts.where((f) => f.timestamp.isBefore(cutoff)).toList();
  }
}
