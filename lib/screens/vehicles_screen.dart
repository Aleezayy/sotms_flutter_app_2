import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/vehicles_widgets.dart';
import '../services/data_service.dart';
import '../models/sensor_data.dart';
import '../models/firestore_models.dart';
import '../models/vehicle_info.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _searchController = TextEditingController(); // Search needs to be disposed
  String _selectedFilter = 'All';
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VehicleInfo>>(
      stream: _dataService.getVehiclesStream(),
      builder: (context, snapshot) {
        final allVehicles = snapshot.data ?? [];

        // Filter Logic
        final filteredVehicles = allVehicles.where((vehicle) {
          // Filter by Tab
          if (_selectedFilter == 'Active' && vehicle.status != TankerStatus.active) return false;
          if (_selectedFilter == 'Idle' && vehicle.status != TankerStatus.idle) return false;
          if (_selectedFilter == 'Alert' && vehicle.status != TankerStatus.alert) return false;
          if (_selectedFilter == 'Maintenance' && vehicle.status != TankerStatus.maintenance) return false;
          
          // Filter by Search
          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            final name = vehicle.displayName.toLowerCase();
            final driver = vehicle.driverName.toLowerCase();
            
            if (!name.contains(query) && !driver.contains(query)) return false;
          }
          return true;
        }).toList();

        return SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                color: Colors.transparent,
                child: Column(
                  children: [
                    VehicleSearchBar(controller: _searchController),
                    const SizedBox(height: 16),
                    FilterTabs(
                      selectedFilter: _selectedFilter,
                      onSelect: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filteredVehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No vehicles found',
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final v = filteredVehicles[index];
                        return VehicleCard(
                          id: v.displayName,
                          realVehicleId: v.vehicleId,
                          driver: v.driverName,
                          location: v.locationText,
                          cargo: v.cargo,
                          speed: v.speedText,
                          status: v.status,
                          routeStart: v.origin,
                          routeEnd: v.destination,
                          progress: v.progress,
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}
}
