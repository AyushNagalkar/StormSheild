import 'disaster_type.dart';
import 'location.dart';

/// Disaster prediction model
class Prediction {
  final String id;
  final DisasterType disasterType;
  final Location location;
  final DateTime predictedFor;
  final DateTime? validUntil;
  final String severity; // low, medium, high, critical
  final double confidenceScore; // 0-100
  final double probability; // 0-100
  final String? aiExplanation;
  final String? expectedIntensity;
  final Map<String, dynamic>? inputFeatures;
  final DateTime createdAt;

  Prediction({
    required this.id,
    required this.disasterType,
    required this.location,
    required this.predictedFor,
    this.validUntil,
    required this.severity,
    required this.confidenceScore,
    required this.probability,
    this.aiExplanation,
    this.expectedIntensity,
    this.inputFeatures,
    required this.createdAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] ?? '',
      disasterType: DisasterType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['disaster_type'] ?? '').toLowerCase(),
        orElse: () => DisasterType.flood,
      ),
      location: Location.fromJson(json['location'] ?? {}),
      predictedFor: DateTime.parse(json['predicted_for']),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'])
          : null,
      severity: json['severity'] ?? 'low',
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
      probability: (json['probability'] ?? 0).toDouble(),
      aiExplanation: json['ai_explanation'],
      expectedIntensity: json['expected_intensity'],
      inputFeatures: json['input_features'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disaster_type': disasterType.name,
      'location': location.toJson(),
      'predicted_for': predictedFor.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'severity': severity,
      'confidence_score': confidenceScore,
      'probability': probability,
      'ai_explanation': aiExplanation,
      'expected_intensity': expectedIntensity,
      'input_features': inputFeatures,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get risk level (0-1) based on probability
  double get riskLevel => probability / 100;

  /// Check if prediction is still valid
  bool get isValid {
    if (validUntil == null) return true;
    return DateTime.now().isBefore(validUntil!);
  }

  /// Get severity color
  String get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return '#DC2626';
      case 'high':
        return '#F59E0B';
      case 'medium':
        return '#F97316';
      case 'low':
      default:
        return '#10B981';
    }
  }
}
