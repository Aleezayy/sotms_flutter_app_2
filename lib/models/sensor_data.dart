import 'package:cloud_firestore/cloud_firestore.dart';

class SensorData {
  final String id;
  final String vehicleId;
  final double distanceCm;
  final double latitude;
  final double longitude;
  final double satellites;
  final String status;
  final int rssi; // Signal strength
  final DateTime timestamp;
  final int uptimeMs;
  final double? speed;
  final double? fuelLevel;

  SensorData({
    required this.id,
    required this.vehicleId,
    required this.distanceCm,
    required this.latitude,
    required this.longitude,
    required this.satellites,
    required this.status,
    required this.rssi,
    required this.timestamp,
    required this.uptimeMs,
    this.speed,
    this.fuelLevel,
  });

  factory SensorData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final gps = data['gps'] as Map<String, dynamic>? ?? {};
    
    // Parse timestamp safely
    DateTime parsedTimestamp;
    try {
      final ts = data['timestamp'];
      if (ts is Timestamp) {
        parsedTimestamp = ts.toDate();
      } else if (ts is String) {
        parsedTimestamp = DateTime.tryParse(ts) ?? DateTime.now();
      } else {
        parsedTimestamp = DateTime.now();
      }
    } catch (e) {
      parsedTimestamp = DateTime.now();
    }

    return SensorData(
      id: doc.id,
      vehicleId: (data['vehicleId'] ?? data['tankerId'] ?? data['vehicleName'] ?? data['tankerName'] ?? doc.id).toString(),
      distanceCm: (data['distance_cm'] as num?)?.toDouble() ?? 0.0,
      latitude: (gps['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (gps['longitude'] as num?)?.toDouble() ?? 0.0,
      satellites: (gps['satellites'] as num?)?.toDouble() ?? 0.0,
      status: gps['status'] as String? ?? 'Unknown',
      rssi: (data['rssi'] as num?)?.toInt() ?? 0,
      timestamp: parsedTimestamp,
      uptimeMs: (data['uptime_ms'] as num?)?.toInt() ?? 0,
      speed: (data['speed'] as num?)?.toDouble(),
      fuelLevel: (data['fuelLevel'] as num? ?? data['fuel'] as num?)?.toDouble(),
    );
  }
}
