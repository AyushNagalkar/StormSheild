import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/shelter.dart';
import '../services/shelter_service.dart';

/// Screen showing nearby shelters with safe routes
class SheltersScreen extends StatefulWidget {
  final double userLat;
  final double userLon;
  final String? disasterType;

  const SheltersScreen({
    super.key,
    required this.userLat,
    required this.userLon,
    this.disasterType,
  });

  @override
  State<SheltersScreen> createState() => _SheltersScreenState();
}

class _SheltersScreenState extends State<SheltersScreen> {
  final _shelterService = ShelterService();
  List<Shelter> _shelters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShelters();
  }

  Future<void> _loadShelters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shelters = await _shelterService.findNearestShelters(
        latitude: widget.userLat,
        longitude: widget.userLon,
        maxDistanceKm: 50,
        limit: 20,
        disasterType: widget.disasterType,
      );

      setState(() {
        _shelters = shelters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToShelter(Shelter shelter) async {
    // Open in Google Maps
    final url = 'https://www.google.com/maps/dir/?api=1&origin=${widget.userLat},${widget.userLon}&destination=${shelter.latitude},${shelter.longitude}&travelmode=driving';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e')),
        );
      }
    }
  }

  Future<void> _callShelter(String? phoneNumber) async {
    if (phoneNumber == null) return;
    
    final url = 'tel:$phoneNumber';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make call: $e')),
        );
      }
    }
  }

  void _showShelterDetails(Shelter shelter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _buildShelterDetails(
          shelter,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildShelterDetails(Shelter shelter, ScrollController scrollController) {
    final occupancyColor = shelter.occupancyRate < 0.7
        ? Colors.green
        : shelter.occupancyRate < 0.9
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Shelter name and type
          Row(
            children: [
              Text(
                shelter.getShelterTypeDisplay().split(' ')[0],
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelter.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      shelter.getShelterTypeDisplay(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Distance
          if (shelter.distanceKm != null)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      '${shelter.distanceKm!.abs().toStringAsFixed(1)} km away',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '~${(shelter.distanceKm!.abs() / 40 * 60).toInt()} min',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Capacity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Capacity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${shelter.availableSpace}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: occupancyColor,
                              ),
                            ),
                            Text(
                              'Available',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${shelter.currentOccupancy}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Occupied',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${shelter.capacity}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: shelter.occupancyRate,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: occupancyColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Facilities
          if (shelter.facilities.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Facilities',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: shelter.facilities.map((facility) {
                        return Chip(
                          label: Text(_getFacilityName(facility)),
                          avatar: Text(_getFacilityIcon(facility)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Address
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Address'),
              subtitle: Text('${shelter.address}\n${shelter.district}${shelter.village != null ? ', ${shelter.village}' : ''}'),
              isThreeLine: true,
            ),
          ),

          // Contact
          if (shelter.contactNumber != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Contact'),
                subtitle: Text(shelter.contactNumber!),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _callShelter(shelter.contactNumber),
                ),
              ),
            ),

          if (shelter.managerName != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Manager'),
                subtitle: Text(shelter.managerName!),
              ),
            ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _navigateToShelter(shelter),
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              if (shelter.contactNumber != null) ...[
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _callShelter(shelter.contactNumber),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getFacilityName(String facility) {
    final names = {
      'water': 'Water',
      'electricity': 'Power',
      'medical': 'Medical',
      'food': 'Food',
      'blankets': 'Bedding',
    };
    return names[facility] ?? facility;
  }

  String _getFacilityIcon(String facility) {
    final icons = {
      'water': '💧',
      'electricity': '⚡',
      'medical': '🏥',
      'food': '🍽️',
      'blankets': '🛏️',
    };
    return icons[facility] ?? '✓';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Shelters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShelters,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load shelters',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loadShelters,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _shelters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.home_work_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No shelters found nearby',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try expanding your search radius or check again later',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Summary banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: Colors.blue.shade50,
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Found ${_shelters.length} shelter${_shelters.length == 1 ? '' : 's'} within 50 km',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Shelters list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _shelters.length,
                            itemBuilder: (context, index) {
                              final shelter = _shelters[index];
                              return _buildShelterCard(shelter);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildShelterCard(Shelter shelter) {
    final occupancyColor = shelter.occupancyRate < 0.7
        ? Colors.green
        : shelter.occupancyRate < 0.9
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showShelterDetails(shelter),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    shelter.getShelterTypeDisplay().split(' ')[0],
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shelter.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shelter.district,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Distance and facilities
              Row(
                children: [
                  if (shelter.distanceKm != null) ...[
                    const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${shelter.distanceKm!.abs().toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Text(
                    shelter.getFacilitiesDisplay(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Capacity bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${shelter.availableSpace} spaces available',
                              style: TextStyle(
                                fontSize: 12,
                                color: occupancyColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(shelter.occupancyRate * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: shelter.occupancyRate,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: occupancyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
