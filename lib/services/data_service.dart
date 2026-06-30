import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/sensor_data.dart';
import '../models/firestore_models.dart';
import '../models/vehicle_info.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';


class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Caching subjects for "Instant" data loading
  final _vehiclesSubject = BehaviorSubject<List<VehicleInfo>>();
  final _alertsSubject = BehaviorSubject<List<AppAlert>>();
  
  Stream<List<VehicleInfo>> get vehiclesStream => _vehiclesSubject.stream;
  Stream<List<AppAlert>> get alertsStream => _alertsSubject.stream;

  void initialize() {
    _initVehiclesStream();
    _initAlertsStream();
  }

  void _initVehiclesStream() {
    final devicesStream = _db.collection('devices').snapshots();
    final assignmentsStream = _db.collection('assignments').snapshots();
    final driversStream = _db.collection('drivers').snapshots();
    final sensorsStream = _db.collection('sensors')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();

    Rx.combineLatest4(
      devicesStream,
      assignmentsStream,
      driversStream,
      sensorsStream,
      (QuerySnapshot devicesSnap, QuerySnapshot assignmentsSnap, QuerySnapshot driversSnap, QuerySnapshot sensorsSnap) {
        final assignments = assignmentsSnap.docs.map((d) => RouteAssignment.fromFirestore(d)).toList();
        final sensors = sensorsSnap.docs.map((d) => SensorData.fromFirestore(d)).toList();
        
        final vehicleInfos = <VehicleInfo>[];

        // Single Tanker Logic: Prioritize TNK-001 or take the first sensor
        String targetId = 'TNK-001';
        final sensorIds = sensors.map((s) => s.vehicleId).toList();
        if (!sensorIds.contains(targetId) && sensorIds.isNotEmpty) {
          targetId = sensorIds.first;
        }

        if (targetId.isNotEmpty) {
          final latestSensor = sensors.firstWhere((s) => s.vehicleId == targetId, orElse: () => _emptySensor(targetId));
          final activeAssignment = assignments.firstWhere(
            (a) => a.vehicleId == targetId && a.status.toLowerCase() != 'completed',
            orElse: () => _emptyAssignment(targetId)
          );
          
          final status = determineStatus(activeAssignment.status, latestSensor);
          final speed = latestSensor.speed ?? 0.0;
          final fuel = latestSensor.fuelLevel ?? 100.0;

          vehicleInfos.add(VehicleInfo(
            id: targetId,
            displayName: 'Tanker 1',
            vehicleId: targetId,
            driverName: activeAssignment.driverName,
            statusLabel: status.name.toUpperCase(),
            status: status,
            position: LatLng(latestSensor.latitude, latestSensor.longitude),
            locationText: 'Lat: ${latestSensor.latitude.toStringAsFixed(4)}, Lng: ${latestSensor.longitude.toStringAsFixed(4)}',
            speedText: '${speed.toStringAsFixed(1)} km/h',
            coPilotName: activeAssignment.coPilotName,
            progress: activeAssignment.progress,
            fuelLevel: fuel,
            lastUpdated: DateFormat('HH:mm:ss').format(latestSensor.timestamp),
            origin: activeAssignment.origin,
            destination: activeAssignment.destination,
            cargo: activeAssignment.cargo,
            routePoints: activeAssignment.points,
          ));
        }
        return vehicleInfos;
      }
    ).listen((data) {
      if (!_vehiclesSubject.isClosed) {
        _vehiclesSubject.add(data);
      }
    });
  }

  void _initAlertsStream() {
    // Fetch full history as requested (removing .limit(1000))
    final alertsStream = _db.collection('alerts').orderBy('timestamp', descending: true).snapshots();
    final incidentStream = _db.collection('incidents').orderBy('timestamp', descending: true).snapshots();
    final behaviorStream = _db.collection('driverBehaviourAlerts').orderBy('timestamp', descending: true).snapshots();

    Rx.combineLatest3<QuerySnapshot, QuerySnapshot, QuerySnapshot, List<AppAlert>>(
      alertsStream, incidentStream, behaviorStream, (s1, s2, s3) {
        final allDocs = [...s1.docs, ...s2.docs, ...s3.docs];
        final alerts = allDocs.map((doc) => AppAlert.fromFirestore(doc)).toList();
        
        final seen = <String>{};
        final filteredAlerts = alerts.where((a) {
          // Robust deduplication: vehicle + title + timestamp
          final key = '${a.vehicleId}_${a.title}_${a.timestamp.millisecondsSinceEpoch}';
          // Filter for TNK-001 as per current logic requirement (including common variations)
          return seen.add(key) && (a.vehicleId == 'TNK-001' || a.vehicleId == 'Tanker 1' || a.vehicleId == 'tanker_001' || a.vehicleId == 'tanker-001');
        }).toList();
        
        filteredAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return filteredAlerts;
      }
    ).listen((data) {
      if (!_alertsSubject.isClosed) _alertsSubject.add(data);
    });
  }

  // Helper methods
  SensorData _emptySensor(String id) => SensorData(id: '0', vehicleId: id, distanceCm: 0, latitude: 0, longitude: 0, satellites: 0, status: 'Unknown', rssi: 0, timestamp: DateTime.now(), uptimeMs: 0);
  RouteAssignment _emptyAssignment(String id) => RouteAssignment(id: '0', vehicleId: id, driverName: 'Unassigned', driverId: '', origin: 'Pending', destination: 'Pending', status: 'idle', progress: 0, eta: '', cargo: '', points: []);

  // Backwards compatibility or specialized streams
  Stream<List<VehicleInfo>> getVehiclesStream() => vehiclesStream;
  Stream<QuerySnapshot> getAlertsStream() => _db.collection('alerts').snapshots();

  Stream<List<SensorData>> getSensorStream() {
    return _db.collection('sensors')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SensorData.fromFirestore(doc)).toList());
  }

  Stream<QuerySnapshot> getRoutesStream() => _db.collection('assignments').snapshots();
  Stream<QuerySnapshot> getIncidentsStream() => _db.collection('incidents').snapshots();
  Stream<QuerySnapshot> getDriversStream() => _db.collection('drivers').snapshots();
  Stream<QuerySnapshot> getReportsStream() => _db.collection('reports').snapshots();

  Stream<List<DriverBehaviorAlert>> getDriverBehaviorAlertsStream() {
    final dedicated = _db.collection('driverBehaviourAlerts').orderBy('createdAt', descending: true).snapshots();
    final fallback = _db.collection('alerts').orderBy('timestamp', descending: true).snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<DriverBehaviorAlert>>(
      dedicated, fallback, (dedicatedSnap, fallbackSnap) {
        final List<DriverBehaviorAlert> results = [];
        
        // 1. Process dedicated behavior alerts
        results.addAll(dedicatedSnap.docs
            .map((d) => DriverBehaviorAlert.fromFirestore(d))
            .where((a) => a.tankerId == 'TNK-001' || a.tankerId == 'Tanker 1' || a.tankerId == 'tanker_001' || a.tankerId == 'tanker-001'));

        // 2. Extract behavior-related alerts from the main collection
        final behaviorKeywords = ['speed', 'overspeed', 'brak', 'acceleration', 'turn', 'fatigue', 'drowsy', 'idle', 'unsafe', 'driver', 'harsh'];
        final fromFallback = fallbackSnap.docs
            .map((d) => AppAlert.fromFirestore(d))
            .where((a) {
              final text = '${a.title} ${a.description}'.toLowerCase();
              return (a.vehicleId == 'TNK-001' || a.vehicleId == 'Tanker 1' || a.vehicleId == 'tanker_001' || a.vehicleId == 'tanker-001') && 
                     behaviorKeywords.any((kw) => text.contains(kw));
            })
            .map((a) => DriverBehaviorAlert.fromAppAlert(a));
        
        results.addAll(fromFallback);

        // 3. Deduplicate and sort
        final seen = <String>{};
        final unique = results.where((a) => seen.add(a.dedupeKey)).toList();
        unique.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        return unique;
      }
    );
  }

  List<DriverBehaviorAlert> _deduplicateAlerts(List<DriverBehaviorAlert> alerts) {
    final seen = <String>{};
    return alerts.where((a) => seen.add(a.dedupeKey)).toList();
  }

  Future<void> upsertTanker(Tanker tanker) async {
    await _db.collection('devices').doc(tanker.id).set({
      'tankerId': tanker.tankerId,
      'name': tanker.name,
      'driverName': tanker.driverName,
      'status': tanker.status,
      'latitude': tanker.latitude,
      'longitude': tanker.longitude,
      'speed': tanker.speed,
      'fuelLevel': tanker.fuel,
      'lastUpdated': FieldValue.serverTimestamp(),
      'origin': tanker.origin,
      'destination': tanker.destination,
      'points': tanker.points.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
    }, SetOptions(merge: true));
  }

  void dispose() {
    _vehiclesSubject.close();
    _alertsSubject.close();
  }
}
