import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/disaster_provider.dart';
import '../models/disaster_type.dart';
import '../models/alert.dart';
import 'alerts_screen.dart';
import 'map_screen.dart';
import 'location_selection_screen.dart';
import 'shelters_screen.dart';
import 'chatbot_screen.dart';

/// Home screen showing disaster risk dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize disaster provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisasterProvider>().initialize().catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  context.read<DisasterProvider>().initialize();
                },
              ),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const MapScreen(),
      const AlertsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatbotScreen()),
            );
          },
          icon: const Icon(Icons.support_agent),
          label: const Text('Emergency Help'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

/// Dashboard screen content
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar - Single header only
          SliverAppBar(
            pinned: true,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🌪️', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                const Text('StormShield'),
              ],
            ),
            actions: [
              // Location selector
              Consumer<DisasterProvider>(
                builder: (context, provider, child) {
                  return IconButton(
                    icon: const Icon(Icons.location_on),
                    tooltip: 'Change Location',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationSelectionScreen(
                            onLocationSelected: (lat, lon, address) {
                              provider.setManualLocation(lat, lon, address);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Shelters nearby
              Consumer<DisasterProvider>(
                builder: (context, provider, child) {
                  if (provider.currentPosition == null) return const SizedBox();
                  return IconButton(
                    icon: const Icon(Icons.home_work),
                    tooltip: 'Find Shelters',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SheltersScreen(
                            userLat: provider.currentPosition!.latitude,
                            userLon: provider.currentPosition!.longitude,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Consumer<DisasterProvider>(
                builder: (context, provider, child) {
                  return IconButton(
                    icon: provider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.refresh(),
                    tooltip: 'Refresh',
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Content
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 24 : 16,
              vertical: 16,
            ),
            sliver: Consumer<DisasterProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.currentPosition == null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              strokeWidth: 6,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Loading disaster data...',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please enable location services',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.errorMessage != null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 80,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Oops! Something went wrong',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 32),
                            FilledButton.icon(
                              onPressed: () => provider.initialize(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (isWideScreen)
                      _buildWideScreenLayout(context, provider)
                    else
                      _buildMobileLayout(context, provider),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, DisasterProvider provider) {
    return Column(
      children: [
        // Current Location Display
        if (provider.currentPosition != null) ...[
          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: Text(provider.manualLocationAddress ?? 'Current Location'),
              subtitle: Text(
                'Lat: ${provider.currentPosition!.latitude.toStringAsFixed(4)}, '
                'Lon: ${provider.currentPosition!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationSelectionScreen(
                        onLocationSelected: (lat, lon, address) {
                          provider.setManualLocation(lat, lon, address);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Change'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // API Error Warnings
        if (provider.hasApiErrors) ...[
          _buildApiErrorsCard(context, provider),
          const SizedBox(height: 16),
        ],

        // Overall Risk Card
        _buildOverallRiskCard(context, provider),
        const SizedBox(height: 16),

        // Active Alerts
        if (provider.activeAlerts.isNotEmpty) ...[
          _buildActiveAlertsSection(context, provider),
          const SizedBox(height: 16),
        ],

        // Risk Breakdown
        _buildRiskBreakdownSection(context, provider),
        const SizedBox(height: 16),

        // Weather Information
        if (provider.currentWeather != null) ...[
          _buildWeatherCard(context, provider),
          const SizedBox(height: 16),
        ],

        // Last Update
        if (provider.lastUpdate != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Updated ${DateFormat('MMM dd, HH:mm').format(provider.lastUpdate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildWideScreenLayout(BuildContext context, DisasterProvider provider) {
    return Column(
      children: [
        // API Errors (full width)
        if (provider.hasApiErrors) ...[
          _buildApiErrorsCard(context, provider),
          const SizedBox(height: 16),
        ],
        
        // Two-column layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildOverallRiskCard(context, provider),
                  const SizedBox(height: 16),
                  if (provider.currentWeather != null)
                    _buildWeatherCard(context, provider),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Right column
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  if (provider.activeAlerts.isNotEmpty) ...[
                    _buildActiveAlertsSection(context, provider),
                    const SizedBox(height: 16),
                  ],
                  _buildRiskBreakdownSection(context, provider),
                ],
              ),
            ),
          ],
        ),
        
        // Last Update
        if (provider.lastUpdate != null) ...[
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Updated ${DateFormat('MMM dd, HH:mm').format(provider.lastUpdate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildApiErrorsCard(BuildContext context, DisasterProvider provider) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'API Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...provider.apiErrors.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Text(
              'Some features may be limited. Please check your API keys in .env file.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRiskCard(BuildContext context, DisasterProvider provider) {
    final risk = provider.overallRisk;
    final riskLevel = _getRiskLevel(risk);
    final color = _getRiskColor(risk);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Overall Risk Level',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: risk,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    color: color,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(risk * 100).toInt()}%',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          riskLevel,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (risk < 0.5) ...[
              const SizedBox(height: 16),
              Text(
                'No immediate threats detected',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.green,
                ),
              ),
            ] else if (provider.highestRiskType != null) ...[
              const SizedBox(height: 16),
              Text(
                'Highest risk: ${provider.highestRiskType!.name}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlertsSection(BuildContext context, DisasterProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...provider.activeAlerts.take(3).map((alert) {
          return Card(
            color: _getSeverityColor(alert.severity).withOpacity(0.1),
            child: ListTile(
              leading: Text(
                _getDisasterIcon(alert.disasterType),
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(alert.title),
              subtitle: Text(alert.message, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Chip(
                label: Text(
                  alert.severity.name.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _parseColor(alert.severity.color),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRiskBreakdownSection(BuildContext context, DisasterProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Breakdown',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...DisasterType.values.map((type) {
          final risk = provider.getRiskScore(type);
          final color = _getRiskColor(risk);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        type.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              type.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(risk * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: risk,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeatherCard(BuildContext context, DisasterProvider provider) {
    final weather = provider.currentWeather!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Weather',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherItem(
                  context,
                  Icons.thermostat,
                  '${weather.temperature.toStringAsFixed(1)}°C',
                  'Temperature',
                ),
                _buildWeatherItem(
                  context,
                  Icons.water_drop,
                  '${weather.humidity}%',
                  'Humidity',
                ),
                _buildWeatherItem(
                  context,
                  Icons.air,
                  '${weather.windSpeed.toStringAsFixed(1)} m/s',
                  'Wind',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getRiskLevel(double risk) {
    if (risk < 0.5) return 'No Risk';
    if (risk < 0.7) return 'Medium';
    if (risk < 0.85) return 'High';
    return 'Critical';
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.5) return Colors.green;
    if (risk < 0.7) return Colors.orange;
    if (risk < 0.85) return Colors.deepOrange;
    return Colors.red;
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
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

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.severe:
        return Colors.deepOrange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }
}
