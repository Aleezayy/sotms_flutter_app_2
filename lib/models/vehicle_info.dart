import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firestore_models.dart';
import 'sensor_data.dart';

class VehicleInfo {
  final String id; // Stable unique ID (Firestore Doc ID)
  final String displayName; // e.g., Tanker 1, Tanker 2
  final String vehicleId; // The ID from Firestore field
  final String driverName;
  final String statusLabel;
  final TankerStatus status;
  final LatLng position;
  final String locationText;
  final String speedText;
  final String coPilotName;
  final double progress;
  final double fuelLevel; // Derived from distanceCm or progress for now
  final String lastUpdated;
  final String origin;
  final String destination;
  final String cargo;
  final List<LatLng> routePoints;

  VehicleInfo({
    required this.id,
    required this.displayName,
    required this.vehicleId,
    required this.driverName,
    required this.statusLabel,
    required this.status,
    required this.position,
    required this.locationText,
    required this.speedText,
    this.coPilotName = 'None',
    required this.progress,
    required this.fuelLevel,
    required this.lastUpdated,
    required this.origin,
    required this.destination,
    required this.cargo,
    required this.routePoints,
  });
}
