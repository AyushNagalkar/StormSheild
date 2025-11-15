import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/shelter.dart';
import '../services/shelter_service.dart';

/// Screen for manual location selection
class LocationSelectionScreen extends StatefulWidget {
  final Function(double lat, double lon, String? address) onLocationSelected;
  
  const LocationSelectionScreen({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final _shelterService = ShelterService();
  final _searchController = TextEditingController();
  
  List<District> _districts = [];
  List<Village> _villages = [];
  List<SavedLocation> _savedLocations = [];
  
  District? _selectedDistrict;
  Village? _selectedVillage;
  
  bool _isLoadingDistricts = false;
  bool _isLoadingVillages = false;
  bool _isSearching = false;
  
  double? _manualLat;
  double? _manualLon;
  String? _manualAddress;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
    _loadSavedLocations();
  }

  Future<void> _loadDistricts() async {
    setState(() => _isLoadingDistricts = true);
    try {
      final districts = await _shelterService.getDistricts();
      setState(() => _districts = districts);
    } finally {
      setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _loadVillages(String districtName) async {
    setState(() => _isLoadingVillages = true);
    try {
      final villages = await _shelterService.getVillagesByDistrict(districtName);
      setState(() => _villages = villages);
    } finally {
      setState(() => _isLoadingVillages = false);
    }
  }

  Future<void> _loadSavedLocations() async {
    try {
      // Using device ID as user ID for now
      final userId = await _getDeviceId();
      final locations = await _shelterService.getUserLocations(userId);
      setState(() => _savedLocations = locations);
    } catch (e) {
      print('Error loading saved locations: $e');
    }
  }

  Future<String> _getDeviceId() async {
    // Simple device ID - in production, use proper device identification
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        final location = locations.first;
        _manualLat = location.latitude;
        _manualLon = location.longitude;
        
        // Get address details
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _manualAddress = '${place.locality}, ${place.administrativeArea}, ${place.country}';
        }
        
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location not found: $e')),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      String? address;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address = '${place.locality}, ${place.administrativeArea}';
      }
      
      widget.onLocationSelected(position.latitude, position.longitude, address);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  void _selectDistrict(District district) {
    setState(() {
      _selectedDistrict = district;
      _selectedVillage = null;
      _villages = [];
    });
    _loadVillages(district.name);
  }

  void _selectVillage(Village village) {
    setState(() => _selectedVillage = village);
  }

  void _confirmSelection() {
    if (_manualLat != null && _manualLon != null) {
      widget.onLocationSelected(_manualLat!, _manualLon!, _manualAddress);
      Navigator.pop(context);
    } else if (_selectedVillage != null) {
      widget.onLocationSelected(
        _selectedVillage!.latitude,
        _selectedVillage!.longitude,
        '${_selectedVillage!.name}, ${_selectedVillage!.districtName}',
      );
      Navigator.pop(context);
    } else if (_selectedDistrict != null) {
      widget.onLocationSelected(
        _selectedDistrict!.latitude,
        _selectedDistrict!.longitude,
        _selectedDistrict!.name,
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Location Button
          Card(
            child: ListTile(
              leading: const Icon(Icons.my_location, color: Colors.blue),
              title: const Text('Use Current Location'),
              subtitle: const Text('Enable GPS location'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _getCurrentLocation,
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Search Location
          Text(
            'Search Location',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter city, district, or address...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _searchLocation,
                    ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _searchLocation(),
          ),
          
          if (_manualLat != null && _manualLon != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: const Text('Location Found'),
                subtitle: Text(_manualAddress ?? 'Lat: $_manualLat, Lon: $_manualLon'),
                trailing: ElevatedButton(
                  onPressed: _confirmSelection,
                  child: const Text('Use This'),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Select by District/Village
          Text(
            'Select District/Village',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          
          if (_isLoadingDistricts)
            const Center(child: CircularProgressIndicator())
          else if (_districts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'No districts available',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please use search or GPS location',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            DropdownButtonFormField<District>(
              decoration: const InputDecoration(
                labelText: 'Select District',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              value: _selectedDistrict,
              items: _districts.map((district) {
                return DropdownMenuItem(
                  value: district,
                  child: Text(district.name),
                );
              }).toList(),
              onChanged: (district) {
                if (district != null) _selectDistrict(district);
              },
            ),
            
            if (_selectedDistrict != null) ...[
              const SizedBox(height: 16),
              if (_isLoadingVillages)
                const Center(child: CircularProgressIndicator())
              else if (_villages.isNotEmpty)
                DropdownButtonFormField<Village>(
                  decoration: const InputDecoration(
                    labelText: 'Select Village (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  value: _selectedVillage,
                  items: _villages.map((village) {
                    return DropdownMenuItem(
                      value: village,
                      child: Text(village.name),
                    );
                  }).toList(),
                  onChanged: (village) {
                    if (village != null) _selectVillage(village);
                  },
                ),
            ],
          ],
          
          if (_selectedDistrict != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check),
              label: Text(_selectedVillage != null
                  ? 'Use ${_selectedVillage!.name}'
                  : 'Use ${_selectedDistrict!.name}'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
          
          // Saved Locations
          if (_savedLocations.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Saved Locations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._savedLocations.map((location) {
              return Card(
                child: ListTile(
                  leading: Icon(
                    location.isPrimary ? Icons.home : Icons.location_on,
                    color: location.isPrimary ? Colors.blue : Colors.grey,
                  ),
                  title: Text(location.locationName),
                  subtitle: Text(location.address ?? 'Custom location'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    widget.onLocationSelected(
                      location.latitude,
                      location.longitude,
                      location.address,
                    );
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
