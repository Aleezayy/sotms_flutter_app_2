import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/firestore_models.dart';
import '../models/sensor_data.dart';
import '../models/vehicle_info.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

import '../widgets/app_background_wrapper.dart';

class VehicleAnalyticsScreen extends StatefulWidget {
  final String vehicleId;
  final String title;
  final String driverName;
  final Map<String, dynamic>? alertDetails;

  const VehicleAnalyticsScreen({
    super.key,
    required this.vehicleId,
    required this.title,
    required this.driverName,
    this.alertDetails,
  });

  @override
  State<VehicleAnalyticsScreen> createState() => _VehicleAnalyticsScreenState();
}

class _VehicleAnalyticsScreenState extends State<VehicleAnalyticsScreen> {
  final DataService _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VehicleInfo>>(
      stream: _dataService.getVehiclesStream(),
      builder: (context, snapshot) {
        final vehicles = snapshot.data ?? [];
        final vehicle = vehicles.cast<VehicleInfo?>().firstWhere(
              (v) => v?.vehicleId == widget.vehicleId || v?.id == widget.title,
              orElse: () => null,
            );

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle?.displayName ?? widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Realtime Firestore Analytics',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: AppBackgroundWrapper(
            child: vehicle == null 
              ? Center(child: Text('Vehicle data not found', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (widget.alertDetails != null) ...[
                        _buildAlertBanner(widget.alertDetails!),
                        const SizedBox(height: 16),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;
                          final cards = [
                            _buildInfoCard(title: 'Driver', value: vehicle.driverName),
                            _buildInfoCard(title: 'Route Status', value: vehicle.statusLabel),
                          ];
                          if (isNarrow) {
                            return Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 12),
                                cards[1],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Route',
                        value: '${vehicle.origin} -> ${vehicle.destination}',
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 520;
                          final cards = [
                            _buildMetricCard('Fuel Level', '${vehicle.fuelLevel.round()}%', Icons.local_gas_station_outlined),
                            _buildMetricCard('Signal', vehicle.speedText, Icons.network_check),
                            _buildMetricCard('Progress', '${(vehicle.progress * 100).round()}%', Icons.trending_up),
                          ];
                          if (isNarrow) {
                            return Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 12),
                                cards[1],
                                const SizedBox(height: 12),
                                cards[2],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[2]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Current Location',
                        value: vehicle.locationText,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Last Update',
                        value: vehicle.lastUpdated,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildAlertBanner(Map<String, dynamic> alert) {
    final severity = (alert['severity'] ?? 'INFO').toString().toUpperCase();
    final color = severity == 'CRITICAL'
        ? AppTheme.error
        : severity == 'WARNING'
            ? AppTheme.warning
            : AppTheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                severity,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert['description']?.toString() ?? 'No description',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            alert['timestamp']?.toString() ?? '',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.85) ?? 
               Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.16)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      height: 128,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.85) ?? 
               Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.16)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 22),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyRealtimeCard extends StatelessWidget {
  const _EmptyRealtimeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.12)),
      ),
      child: Text(
        'No realtime sensor data found for this vehicle.',
        style: TextStyle(color: Theme.of(context).hintColor),
      ),
    );
  }
}
