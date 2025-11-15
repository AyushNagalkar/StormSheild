import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/disaster_provider.dart';
import '../models/disaster_type.dart';

/// Map screen showing disaster zones with OpenStreetMap (FREE)
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  final Map<DisasterType, bool> _layerVisibility = {
    for (final t in DisasterType.values) t: true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disaster Map'),
      ),
      body: Consumer<DisasterProvider>(
        builder: (context, provider, child) {
          if (provider.currentPosition == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading location...'),
                ],
              ),
            );
          }

          final lat = provider.currentPosition!.latitude;
          final lon = provider.currentPosition!.longitude;

          final center = LatLng(lat, lon);

          final baseTileLayer = TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.stormshield.app',
          );

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 10.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  baseTileLayer,

                  // Your location marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getRiskColor(provider.overallRisk),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_pin,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Your Location',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Risk overlays per disaster type
                  CircleLayer(circles: _buildRiskCircles(provider, center)),

                  // OSM attribution (required)
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap contributors',
                        onTap: () async {
                          final uri = Uri.parse('https://www.openstreetmap.org/copyright');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Legend
              Positioned(
                top: 16,
                right: 16,
                child: _buildLegend(context, provider),
              ),

              // Base layer switcher
              Positioned(
                top: 16,
                left: 16,
                child: _buildBaseSwitcher(),
              ),

              // Layer visibility controls
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildLayerToggles(),
              ),

              // Recenter & Refresh FABs
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'recenter',
                      onPressed: () {
                        _mapController.move(center, 12.0);
                      },
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 12),
                    Consumer<DisasterProvider>(
                      builder: (context, p, _) => FloatingActionButton.small(
                        heroTag: 'refresh',
                        onPressed: p.isLoading ? null : () => p.refresh(),
                        child: p.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                      ),
                    ),
                  ],
                ),
              ),

              // Disclaimer
              Positioned(
                bottom: 16,
                right: 80,
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Risk layers are indicative and based on free public APIs',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context, DisasterProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Risk Levels',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...DisasterType.values.map((type) {
              final risk = provider.getRiskScore(type);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getRiskColor(risk),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getDisasterIcon(type)} ${type.name}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseSwitcher() {
    return const SizedBox.shrink();
  }

  Widget _buildLayerToggles() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Layers',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            for (final type in DisasterType.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: _layerVisibility[type] ?? true,
                    onChanged: (v) => setState(() => _layerVisibility[type] = v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(_getDisasterIcon(type)),
                  const SizedBox(width: 6),
                  Text(type.name),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<CircleMarker> _buildRiskCircles(DisasterProvider provider, LatLng center) {
    final List<CircleMarker> circles = [];

    Color colorFor(DisasterType t) {
      switch (t) {
        case DisasterType.flood:
          return Colors.blueAccent;
        case DisasterType.cyclone:
          return Colors.redAccent;
        case DisasterType.earthquake:
          return Colors.orangeAccent;
        case DisasterType.wildfire:
          return Colors.deepOrange;
        case DisasterType.heatwave:
          return Colors.pinkAccent;
        case DisasterType.drought:
          return Colors.brown;
      }
    }

    for (final type in DisasterType.values) {
      if (!(_layerVisibility[type] ?? true)) continue;
      final risk = provider.getRiskScore(type);
      if (risk <= 0.1) continue; // hide negligible risk

      // Radius from 10km (low) to 60km (critical)
      final radiusKm = 10 + (risk * 50);
      final color = colorFor(type);

      circles.add(
        CircleMarker(
          point: center,
          radius: radiusKm * 1000,
          useRadiusInMeter: true,
          color: color.withOpacity(0.12),
          borderColor: color.withOpacity(0.8),
          borderStrokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  String _getDisasterIcon(DisasterType type) {
    switch (type) {
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

  Color _getRiskColor(double risk) {
    if (risk < 0.3) return Colors.green;
    if (risk < 0.6) return Colors.orange;
    if (risk < 0.8) return Colors.deepOrange;
    return Colors.red;
  }
}
