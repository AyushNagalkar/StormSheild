import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/disaster_provider.dart';
import '../models/alert.dart';
import '../models/disaster_type.dart';

/// Alerts screen showing all disaster alerts
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disaster Alerts'),
      ),
      body: Consumer<DisasterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.alerts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Alerts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All clear! No disaster warnings in your area.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final activeAlerts = provider.activeAlerts;
          final expiredAlerts = provider.alerts.where((a) => !a.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeAlerts.isNotEmpty) ...[
                Text(
                  'Active Alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...activeAlerts.map((alert) => _buildAlertCard(context, alert, true)),
              ],
              if (expiredAlerts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Past Alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                ...expiredAlerts.map((alert) => _buildAlertCard(context, alert, false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Alert alert, bool isActive) {
    final severityColor = _getSeverityColor(alert.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive 
          ? severityColor.withOpacity(0.1)
          : Colors.grey.shade100,
      child: InkWell(
        onTap: () => _showAlertDetails(context, alert),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getDisasterIcon(alert.disasterType),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                alert.severity.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: severityColor,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, HH:mm').format(alert.issuedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: TextStyle(
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (isActive && alert.expiresAt.isAfter(DateTime.now())) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${DateFormat('MMM dd, HH:mm').format(alert.expiresAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(BuildContext context, Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          alert.disasterType.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.title,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                alert.disasterType.name,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.warning_amber_rounded,
                      'Severity',
                      alert.severity.name.toUpperCase(),
                      _getSeverityColor(alert.severity),
                    ),
                    _buildDetailRow(
                      Icons.schedule,
                      'Issued',
                      DateFormat('MMM dd, yyyy HH:mm').format(alert.issuedAt),
                      null,
                    ),
                    _buildDetailRow(
                      Icons.event,
                      'Expires',
                      DateFormat('MMM dd, yyyy HH:mm').format(alert.expiresAt),
                      null,
                    ),
                    if (alert.affectedRadiusKm != null)
                      _buildDetailRow(
                        Icons.location_on,
                        'Affected Radius',
                        '${alert.affectedRadiusKm!.toStringAsFixed(1)} km',
                        null,
                      ),
                    const Divider(height: 32),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.message,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (alert.safetyInstructions != null &&
                        alert.safetyInstructions!.isNotEmpty) ...[
                      const Divider(height: 32),
                      Text(
                        'Safety Instructions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...alert.safetyInstructions!.map((instruction) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  instruction,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
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
