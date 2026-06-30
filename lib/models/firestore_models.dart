import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'sensor_data.dart';



enum TankerStatus { active, idle, stop, maintenance, alert }

TankerStatus determineStatus(String rawStatus, SensorData? sensor) {
  final status = rawStatus.toLowerCase();
  if (status.contains('maintenance')) return TankerStatus.maintenance;
  if (status.contains('stop') || status.contains('parking') || status.contains('halt')) return TankerStatus.stop;
  if (status.contains('idle') || status.contains('pending')) return TankerStatus.idle;
  if (status.contains('alert') || status.contains('critical') || status.contains('emergency')) return TankerStatus.alert;
  
  if (sensor != null) {
    if (sensor.rssi < -85 || sensor.status.toLowerCase() == 'unknown') return TankerStatus.alert;
    // Assuming if no speed info, we rely on Firestore status, 
    // but if we had speed, we could determine 'stop' vs 'active' here.
  }
  
  return TankerStatus.active;
}

DateTime readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

String readString(Map<String, dynamic> data, List<String> keys, {String fallback = ''}) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) continue;
    if (value is Map || value is List) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

double readDouble(Map<String, dynamic> data, List<String> keys, {double fallback = 0}) {
  for (final key in keys) {
    final value = data[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

class RouteAssignment {
  final String id;
  final String vehicleId;
  final String driverName;
  final String driverId;
  final String origin;
  final String destination;
  final String status;
  final double progress;
  final String eta;
  final String cargo;
  final String coPilotName;
  final List<LatLng> points;

  const RouteAssignment({
    required this.id,
    required this.vehicleId,
    required this.driverName,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.status,
    required this.progress,
    required this.eta,
    required this.cargo,
    this.coPilotName = 'None',
    required this.points,
  });

  factory RouteAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final driver = data['driver'];
    final vehicle = data['vehicle'];

    final vehicleId = readString(
      data,
      ['vehicleId', 'tankerId', 'vehicleName', 'tankerName', 'truckId', 'truckName'],
      fallback: vehicle is Map ? readString(Map<String, dynamic>.from(vehicle), ['id', 'name', 'title'], fallback: doc.id) : doc.id,
    );

    final driverName = readString(
      data,
      ['driverName', 'assignedDriverName', 'driver', 'driver_name'],
      fallback: driver is Map ? readString(Map<String, dynamic>.from(driver), ['name', 'fullName', 'title'], fallback: 'Unassigned') : 'Unassigned',
    );

    final points = <LatLng>[];
    final rawPoints = data['points'] ?? data['routePoints'] ?? data['polyline'];
    if (rawPoints is List) {
      for (final point in rawPoints) {
        if (point is GeoPoint) {
          points.add(LatLng(point.latitude, point.longitude));
        } else if (point is Map) {
          final map = Map<String, dynamic>.from(point);
          final lat = readDouble(map, ['latitude', 'lat']);
          final lng = readDouble(map, ['longitude', 'lng']);
          if (lat != 0 || lng != 0) points.add(LatLng(lat, lng));
        }
      }
    }

    final progress = readDouble(data, ['progress', 'completion', 'completedPercent']);

    return RouteAssignment(
      id: doc.id,
      vehicleId: vehicleId,
      driverName: driverName,
      driverId: readString(data, ['driverId', 'assignedDriverId', 'driverUid']),
      origin: readString(data, ['origin', 'start', 'startLocation', 'routeStart', 'from'], fallback: 'Start not assigned'),
      destination: readString(data, ['destination', 'end', 'endLocation', 'routeEnd', 'to'], fallback: 'Destination not assigned'),
      status: readString(data, ['status', 'routeStatus', 'assignmentStatus'], fallback: 'assigned'),
      progress: (progress > 1 ? (progress / 100).clamp(0.0, 1.0) : progress.clamp(0.0, 1.0)).toDouble(),
      eta: readString(data, ['eta', 'estimatedArrival', 'arrivalTime'], fallback: 'Pending'),
      cargo: readString(data, ['cargo', 'load', 'capacity', 'cargoCapacity'], fallback: 'Not available'),
      coPilotName: readString(data, ['coPilot', 'coDriver', 'assistant', 'coPilotName', 'copilot'], fallback: 'None'),
      points: points,
    );
  }
}

class AppAlert {
  final String id;
  final String vehicleId;
  final String driverName;
  final String severity;
  final String title;
  final String description;
  final String status;
  final DateTime timestamp;

  const AppAlert({
    required this.id,
    required this.vehicleId,
    required this.driverName,
    required this.severity,
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
  });

  factory AppAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppAlert(
      id: doc.id,
      vehicleId: readString(data, ['vehicleId', 'tankerId', 'vehicleName', 'tankerName', 'vehicle'], fallback: 'Unknown Vehicle'),
      driverName: readString(data, ['driverName', 'driver'], fallback: 'Unassigned'),
      severity: readString(data, ['severity', 'type', 'level'], fallback: 'info').toUpperCase(),
      title: readString(data, ['title', 'name', 'incident'], fallback: 'System Alert'),
      description: readString(data, ['description', 'message', 'details', 'summary'], fallback: 'No alert details available'),
      status: readString(data, ['status', 'state', 'resolution'], fallback: 'Open'),
      timestamp: readDate(data['timestamp'] ?? data['createdAt'] ?? data['time'] ?? data['date']),
    );
  }
}

// ─── Driver Behavior Alert types ────────────────────────────────────────────
enum DriverAlertType {
  overspeeding,
  harshBraking,
  suddenAcceleration,
  sharpTurning,
  driverFatigue,
  idleTime,
  unsafeDriving,
  unknown,
}

enum DriverAlertSeverity { critical, warning, medium, info }

DriverAlertType _parseAlertType(String raw) {
  final v = raw.toLowerCase();
  if (v.contains('overspeed') || v.contains('speed')) return DriverAlertType.overspeeding;
  if (v.contains('harsh') && v.contains('brak')) return DriverAlertType.harshBraking;
  if (v.contains('sudden') || v.contains('acceleration')) return DriverAlertType.suddenAcceleration;
  if (v.contains('sharp') || v.contains('turn')) return DriverAlertType.sharpTurning;
  if (v.contains('fatigue') || v.contains('drowsy')) return DriverAlertType.driverFatigue;
  if (v.contains('idle')) return DriverAlertType.idleTime;
  if (v.contains('unsafe')) return DriverAlertType.unsafeDriving;
  return DriverAlertType.unknown;
}

DriverAlertSeverity _parseSeverity(String raw) {
  final v = raw.toLowerCase();
  if (v.contains('critical') || v.contains('high') || v.contains('danger') || v.contains('emergency')) return DriverAlertSeverity.critical;
  if (v.contains('warning') || v.contains('warn')) return DriverAlertSeverity.warning;
  if (v.contains('medium') || v.contains('moderate') || v.contains('low')) return DriverAlertSeverity.medium;
  return DriverAlertSeverity.info;
}

class DriverBehaviorAlert {
  final String id;
  final String tankerName;
  final String tankerId;
  final String driverName;
  final DriverAlertType alertType;
  final String alertTypeLabel;
  final DriverAlertSeverity severity;
  final DateTime timestamp;
  final String description;
  final String location;
  final String status;
  // Used for deduplication
  String get dedupeKey => '${tankerId}_${alertTypeLabel}_${timestamp.millisecondsSinceEpoch ~/ 60000}';

  const DriverBehaviorAlert({
    required this.id,
    required this.tankerName,
    required this.tankerId,
    required this.driverName,
    required this.alertType,
    required this.alertTypeLabel,
    required this.severity,
    required this.timestamp,
    required this.description,
    required this.location,
    required this.status,
  });

  factory DriverBehaviorAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawType = readString(data, ['behaviour', 'alertType', 'type', 'incidentType', 'title', 'name'], fallback: 'unknown');
    final rawSeverity = readString(data, ['severity', 'level', 'priority'], fallback: 'info');
    final acknowledged = data['acknowledged'] == true;

    return DriverBehaviorAlert(
      id: doc.id,
      tankerName: readString(data, ['tankerName', 'vehicleName', 'tanker', 'vehicle'], fallback: 'Unknown Tanker'),
      tankerId: readString(data, ['tankerId', 'vehicleId', 'tanker_id', 'vehicle_id'], fallback: doc.id),
      driverName: readString(data, ['driverName', 'driver', 'driver_name'], fallback: 'Unassigned'),
      alertType: _parseAlertType(rawType),
      alertTypeLabel: rawType,
      severity: _parseSeverity(rawSeverity),
      timestamp: readDate(data['timestamp'] ?? data['createdAt'] ?? data['time'] ?? data['date']),
      description: readString(data, ['notes', 'description', 'message', 'details', 'summary'], fallback: 'No details available'),
      location: readString(data, ['location', 'address', 'place', 'locationText'], fallback: 'Location unavailable'),
      status: acknowledged ? 'Acknowledged' : readString(data, ['status', 'state', 'resolution'], fallback: 'Open'),
    );
  }

  /// Fallback: build a DriverBehaviorAlert from an AppAlert
  factory DriverBehaviorAlert.fromAppAlert(AppAlert a) {
    final raw = '${a.title} ${a.description}';
    return DriverBehaviorAlert(
      id: a.id,
      tankerName: a.vehicleId,
      tankerId: a.vehicleId,
      driverName: a.driverName,
      alertType: _parseAlertType(raw),
      alertTypeLabel: a.title,
      severity: _parseSeverity(a.severity),
      timestamp: a.timestamp,
      description: a.description,
      location: 'Location unavailable',
      status: a.status,
    );
  }
}

class AppDriver {
  final String id;
  final String name;
  final String phone;
  final String licenseNumber;
  final String status;
  final bool insured;
  final String policyNumber;
  final String licenseExpiry;
  final double safetyScore;
  final String lastAssignment;

  const AppDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.status,
    required this.insured,
    required this.policyNumber,
    required this.licenseExpiry,
    required this.safetyScore,
    required this.lastAssignment,
  });

  factory AppDriver.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    
    return AppDriver(
      id: doc.id,
      name: readString(data, ['name', 'fullName', 'driverName'], fallback: 'Unknown Driver'),
      phone: readString(data, ['phone', 'phoneNumber', 'contact'], fallback: 'Not available'),
      licenseNumber: readString(data, ['licenseNumber', 'license', 'cnic'], fallback: 'Not available'),
      status: readString(data, ['status', 'driverStatus'], fallback: 'Active'),
      insured: data['insured'] == true,
      policyNumber: readString(data, ['policyNumber', 'insurancePolicy'], fallback: 'N/A'),
      licenseExpiry: readString(data, ['licenseExpiry', 'expiry'], fallback: 'N/A'),
      safetyScore: readDouble(stats, ['safetyScore', 'score'], fallback: 100.0),
      lastAssignment: readString(stats, ['lastAssignment', 'assignment'], fallback: 'None'),
    );
  }
}


class Tanker {
  final String id;
  final String tankerId; // e.g. TNK001
  final String name;
  final String driverName;
  final String status;
  final double latitude;
  final double longitude;
  final double speed;
  final double fuel;
  final double rssi;
  final DateTime lastUpdated;
  final String origin;
  final String destination;
  final List<LatLng> points;

  const Tanker({
    required this.id,
    required this.tankerId,
    required this.name,
    required this.driverName,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.fuel,
    required this.rssi,
    required this.lastUpdated,
    this.origin = 'Pending',
    this.destination = 'Pending',
    this.points = const [],
  });

  factory Tanker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final points = <LatLng>[];
    final rawPoints = data['points'] ?? data['routePoints'];
    if (rawPoints is List) {
      for (final point in rawPoints) {
        if (point is GeoPoint) {
          points.add(LatLng(point.latitude, point.longitude));
        } else if (point is Map) {
          final map = Map<String, dynamic>.from(point);
          final lat = readDouble(map, ['latitude', 'lat']);
          final lng = readDouble(map, ['longitude', 'lng']);
          if (lat != 0 || lng != 0) points.add(LatLng(lat, lng));
        }
      }
    }

    return Tanker(
      id: doc.id,
      tankerId: readString(data, ['tankerId', 'vehicleId', 'id'], fallback: doc.id),
      name: readString(data, ['name', 'tankerName', 'displayName'], fallback: 'Tanker'),
      driverName: readString(data, ['driverName', 'driver'], fallback: 'Unassigned'),
      status: readString(data, ['status', 'state'], fallback: 'Active'),
      latitude: readDouble(data, ['latitude', 'lat']),
      longitude: readDouble(data, ['longitude', 'lng']),
      speed: readDouble(data, ['speed', 'currentSpeed']),
      fuel: readDouble(data, ['fuel', 'fuelLevel', 'fuelPercent'], fallback: 100.0),
      rssi: readDouble(data, ['rssi', 'signal'], fallback: -70.0),
      lastUpdated: readDate(data['lastUpdated'] ?? data['timestamp'] ?? data['updatedAt']),
      origin: readString(data, ['origin', 'start']),
      destination: readString(data, ['destination', 'end']),
      points: points,
    );
  }

  TankerStatus get tankerStatus => determineStatus(status, null);
}
