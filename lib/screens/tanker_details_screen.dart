import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/firestore_models.dart';
import '../models/sensor_data.dart';
import '../models/vehicle_info.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background_wrapper.dart';

class TankerDetailsScreen extends StatelessWidget {
  final String id; // This is the Display Name (e.g. Tanker 1)
  final String vehicleId; // This is the real DB ID
  final String driver;
  final String contact;

  const TankerDetailsScreen({
    super.key,
    required this.id,
    required this.vehicleId,
    required this.driver,
    this.contact = '',
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
  @override
  Widget build(BuildContext context) {
    final dataService = DataService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackgroundWrapper(
        child: SafeArea(
          child: StreamBuilder<List<VehicleInfo>>(
          stream: dataService.getVehiclesStream(),
          builder: (context, snapshot) {
            final vehicles = snapshot.data ?? [];
            final vehicle = vehicles.cast<VehicleInfo?>().firstWhere(
                  (v) => v?.vehicleId == vehicleId || v?.id == id,
                  orElse: () => null,
                );

            if (vehicle == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Vehicle $id not found', style: TextStyle(color: Theme.of(context).hintColor)),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Live Vehicle Status',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _driverCard(vehicle.driverName, contact, vehicle.coPilotName),
                  const SizedBox(height: 16),
                  _infoCard('Route', '${vehicle.origin} -> ${vehicle.destination}'),
                  const SizedBox(height: 16),
                  _infoCard('Status', vehicle.statusLabel),
                  const SizedBox(height: 16),
                  _metricCard(Icons.local_gas_station_outlined, 'Fuel Level', '${vehicle.fuelLevel.round()}%'),
                  const SizedBox(height: 12),
                  _metricCard(Icons.speed_rounded, 'Speed / Signal', vehicle.speedText),
                  const SizedBox(height: 12),
                  _infoCard('Coordinates', vehicle.locationText),
                  const SizedBox(height: 12),
                  _infoCard('Last Updated', vehicle.lastUpdated),
                ],
              ),
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _driverCard(String driverName, String phone, String coPilotName) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Driver Information', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (coPilotName != 'None' && coPilotName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Co-Pilot: $coPilotName', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14)),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(phone, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14)),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            InkWell(
              onTap: () => _makePhoneCall(phone),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone, color: Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
    );
   });
  }

  Widget _infoCard(String title, String value) {
    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _metricCard(IconData icon, String title, String value) {
    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(color: Theme.of(context).hintColor)),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
