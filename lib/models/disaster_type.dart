/// Disaster type enumeration
enum DisasterType {
  flood,
  cyclone,
  earthquake,
  wildfire,
  heatwave,
  drought,
}

/// Extension for disaster type properties
extension DisasterTypeExtension on DisasterType {
  String get name {
    switch (this) {
      case DisasterType.flood:
        return 'Flood';
      case DisasterType.cyclone:
        return 'Cyclone';
      case DisasterType.earthquake:
        return 'Earthquake';
      case DisasterType.wildfire:
        return 'Wildfire';
      case DisasterType.heatwave:
        return 'Heatwave';
      case DisasterType.drought:
        return 'Drought';
    }
  }

  String get icon {
    switch (this) {
      case DisasterType.flood:
        return '🌊';
      case DisasterType.cyclone:
        return '🌀';
      case DisasterType.earthquake:
        return '🏚️';
      case DisasterType.wildfire:
        return '🔥';
      case DisasterType.heatwave:
        return '🌡️';
      case DisasterType.drought:
        return '🏜️';
    }
  }

  String get color {
    switch (this) {
      case DisasterType.flood:
        return '#3B82F6'; // Blue
      case DisasterType.cyclone:
        return '#EF4444'; // Red
      case DisasterType.earthquake:
        return '#F59E0B'; // Orange
      case DisasterType.wildfire:
        return '#DC2626'; // Dark Red
      case DisasterType.heatwave:
        return '#F97316'; // Orange
      case DisasterType.drought:
        return '#A16207'; // Brown
    }
  }

  String get description {
    switch (this) {
      case DisasterType.flood:
        return 'Heavy rainfall causing water overflow and flooding';
      case DisasterType.cyclone:
        return 'Tropical storm with high winds and heavy rain';
      case DisasterType.earthquake:
        return 'Seismic activity causing ground shaking';
      case DisasterType.wildfire:
        return 'Uncontrolled fire spreading through vegetation';
      case DisasterType.heatwave:
        return 'Prolonged period of excessively hot weather';
      case DisasterType.drought:
        return 'Extended period of abnormally low rainfall';
    }
  }
}
