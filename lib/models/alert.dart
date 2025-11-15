import 'disaster_type.dart';
import 'location.dart';
import 'prediction.dart';

/// Alert severity levels
enum AlertSeverity {
  info,
  warning,
  severe,
  critical,
}

extension AlertSeverityExtension on AlertSeverity {
  String get name {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.severe:
        return 'Severe';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  String get color {
    switch (this) {
      case AlertSeverity.info:
        return '#3B82F6';
      case AlertSeverity.warning:
        return '#F59E0B';
      case AlertSeverity.severe:
        return '#EF4444';
      case AlertSeverity.critical:
        return '#DC2626';
    }
  }
}

/// Alert model for disaster warnings
class Alert {
  final String id;
  final String? predictionId;
  final DisasterType disasterType;
  final Location location;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final double? affectedRadiusKm;
  final List<String>? safetyInstructions;
  final String status; // active, expired, cancelled
  final Map<String, dynamic>? metadata;

  Alert({
    required this.id,
    this.predictionId,
    required this.disasterType,
    required this.location,
    required this.title,
    required this.message,
    required this.severity,
    required this.issuedAt,
    required this.expiresAt,
    this.affectedRadiusKm,
    this.safetyInstructions,
    this.status = 'active',
    this.metadata,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      predictionId: json['prediction_id'],
      disasterType: DisasterType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['disaster_type'] ?? '').toLowerCase(),
        orElse: () => DisasterType.flood,
      ),
      location: Location.fromJson(json['location'] ?? {}),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['severity'] ?? '').toLowerCase(),
        orElse: () => AlertSeverity.info,
      ),
      issuedAt: DateTime.parse(json['issued_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().toIso8601String()),
      affectedRadiusKm: json['affected_radius_km']?.toDouble(),
      safetyInstructions: json['safety_instructions'] != null
          ? List<String>.from(json['safety_instructions'])
          : null,
      status: json['status'] ?? 'active',
      metadata: json['metadata'],
    );
  }

  factory Alert.fromPrediction(Prediction prediction) {
    final severity = _getSeverityFromProbability(prediction.probability);
    
    return Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      predictionId: prediction.id,
      disasterType: prediction.disasterType,
      location: prediction.location,
      title: '${prediction.disasterType.name} Alert - ${prediction.severity.toUpperCase()}',
      message: prediction.aiExplanation ?? 
          'High probability of ${prediction.disasterType.name.toLowerCase()} in your area. Stay alert and follow safety guidelines.',
      severity: severity,
      issuedAt: DateTime.now(),
      expiresAt: prediction.validUntil ?? DateTime.now().add(const Duration(hours: 24)),
      safetyInstructions: _getSafetyInstructions(prediction.disasterType),
      status: 'active',
    );
  }

  static AlertSeverity _getSeverityFromProbability(double probability) {
    if (probability >= 80) return AlertSeverity.critical;
    if (probability >= 60) return AlertSeverity.severe;
    if (probability >= 40) return AlertSeverity.warning;
    return AlertSeverity.info;
  }

  static List<String> _getSafetyInstructions(DisasterType type) {
    switch (type) {
      case DisasterType.flood:
        return [
          'Move to higher ground immediately',
          'Avoid walking or driving through flood waters',
          'Keep emergency supplies ready',
          'Monitor local news for updates',
        ];
      case DisasterType.cyclone:
        return [
          'Stay indoors and away from windows',
          'Secure loose objects outside',
          'Stock up on emergency supplies',
          'Follow evacuation orders if issued',
        ];
      case DisasterType.earthquake:
        return [
          'Drop, Cover, and Hold On',
          'Stay away from windows and heavy furniture',
          'If outdoors, move away from buildings',
          'Be prepared for aftershocks',
        ];
      case DisasterType.wildfire:
        return [
          'Evacuate immediately if ordered',
          'Close all windows and doors',
          'Wear N95 mask to protect from smoke',
          'Have an evacuation route planned',
        ];
      case DisasterType.heatwave:
        return [
          'Stay hydrated and drink plenty of water',
          'Avoid outdoor activities during peak hours',
          'Stay in air-conditioned spaces',
          'Check on elderly neighbors',
        ];
      case DisasterType.drought:
        return [
          'Conserve water wherever possible',
          'Avoid outdoor burning',
          'Monitor local water restrictions',
          'Store emergency water supplies',
        ];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prediction_id': predictionId,
      'disaster_type': disasterType.name,
      'location': location.toJson(),
      'title': title,
      'message': message,
      'severity': severity.name,
      'issued_at': issuedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'affected_radius_km': affectedRadiusKm,
      'safety_instructions': safetyInstructions,
      'status': status,
      'metadata': metadata,
    };
  }

  /// Check if alert is still active
  bool get isActive => status == 'active' && DateTime.now().isBefore(expiresAt);

  /// Check if alert has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get time remaining before expiration
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  /// Get time since issued
  Duration get timeSinceIssued => DateTime.now().difference(issuedAt);
}
