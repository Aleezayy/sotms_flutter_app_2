import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/firestore_models.dart';
import '../models/sensor_data.dart';
import '../models/vehicle_info.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/map_widgets.dart';
import 'tanker_details_screen.dart';

class MapScreen extends StatefulWidget {
  final String? initialVehicleId;
  const MapScreen({super.key, this.initialVehicleId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final DataService _dataService = DataService();
  String? _selectedVehicleId;
  bool _hasInitialFocus = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.initialVehicleId;
  }

  static const CameraPosition _pakistan = CameraPosition(
    target: LatLng(30.3753, 69.3451),
    zoom: 5.5,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VehicleInfo>>(
      stream: _dataService.vehiclesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final vehicles = snapshot.data ?? [];
        final markers = <Marker>{};
        final polylines = <Polyline>{};

        for (final v in vehicles) {
          final position = v.position;
          
          // Initial Focus Logic
          if (!_hasInitialFocus && _selectedVehicleId != null && v.vehicleId == _selectedVehicleId) {
            _hasInitialFocus = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
            });
          }
          
          Color markerColor;
          double hue;
          switch (v.status) {
            case TankerStatus.active: 
              markerColor = Colors.green;
              hue = BitmapDescriptor.hueGreen; 
              break;
            case TankerStatus.idle: 
              markerColor = Colors.orange;
              hue = BitmapDescriptor.hueOrange; 
              break;
            default: 
              markerColor = Colors.red;
              hue = BitmapDescriptor.hueRed; 
              break;
          }

          markers.add(
            Marker(
              markerId: MarkerId(v.id),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              onTap: () {
                setState(() => _selectedVehicleId = v.vehicleId);
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
              },
            ),
          );

          if (v.routePoints.length > 1 && (_selectedVehicleId == null || _selectedVehicleId == v.vehicleId)) {
            polylines.add(
              Polyline(
                polylineId: PolylineId(v.id),
                points: v.routePoints,
                color: markerColor.withValues(alpha: 0.5),
                width: 4,
                jointType: JointType.round,
              ),
            );
          }
        }

        final selectedVehicle = vehicles.cast<VehicleInfo?>().firstWhere(
              (v) => v?.vehicleId == _selectedVehicleId,
              orElse: () => null,
            );
        
        Widget? infoPopup;
        if (selectedVehicle != null) {
          infoPopup = Positioned(
            top: 76, left: 16, right: 16,
            child: VehicleInfoPopup(
              id: selectedVehicle.displayName,
              location: selectedVehicle.locationText,
              speed: selectedVehicle.speedText,
              fuel: selectedVehicle.fuelLevel.round(),
              driverName: selectedVehicle.driverName,
              status: selectedVehicle.statusLabel,
              lastUpdated: selectedVehicle.lastUpdated,
              onClose: () => setState(() => _selectedVehicleId = null),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TankerDetailsScreen(
                      id: selectedVehicle.displayName,
                      vehicleId: selectedVehicle.vehicleId,
                      driver: selectedVehicle.driverName,
                    ),
                  ),
                );
              },
            ),
          );
        }

        final screenHeight = MediaQuery.sizeOf(context).height;
        final bottomSheetHeight = screenHeight < 700 ? 220.0 : 270.0;

        return Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _pakistan,
              onMapCreated: (controller) => _mapController = controller,
              markers: markers,
              polylines: polylines,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(4, 20),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
            ),

            if (infoPopup != null) infoPopup,
            Positioned(
              top: 16, right: 16,
              child: Column(
                children: [
                  _buildMapControl(Icons.add, () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
                  const SizedBox(height: 8),
                  _buildMapControl(Icons.remove, () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
                ],
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: bottomSheetHeight,
              child: Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.25), width: 1)),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 18, offset: const Offset(0, -6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).hintColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('tracked_vehicles'.tr(), style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('${vehicles.length} ${"total".tr()}', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: vehicles.isEmpty
                          ? Center(child: Text('No assigned routes found in Firestore.', style: TextStyle(color: Theme.of(context).hintColor)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: vehicles.length,
                              itemBuilder: (context, index) {
                                final v = vehicles[index];
                                return TrackedVehicleItem(
                                  id: v.displayName,
                                  location: '${v.origin} -> ${v.destination}',
                                  speed: v.speedText,
                                  color: v.status == TankerStatus.active ? Colors.green : (v.status == TankerStatus.idle ? Colors.orange : Colors.red),
                                  isSelected: _selectedVehicleId == v.vehicleId,
                                  onTap: () {
                                    setState(() => _selectedVehicleId = v.vehicleId);
                                    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(v.position, 14));
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.14)),
        boxShadow: AppTheme.softShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
