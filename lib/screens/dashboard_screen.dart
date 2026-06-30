import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/firestore_models.dart';
import '../models/vehicle_info.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alerts_widgets.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/app_background_wrapper.dart';
import '../widgets/shimmer_widgets.dart';
import 'alerts_screen.dart';
import 'map_screen.dart';
import 'main_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedStatusIndex = -1;
  final DataService _dataService = DataService();

  Widget _buildStatusCard(int index, String label, String value, IconData icon, Color color) {
    return StatusCard(
      label: label,
      value: value,
      icon: icon,
      color: color,
      isSelected: _selectedStatusIndex == index,
      onTap: () {
        setState(() => _selectedStatusIndex = index);
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AlertsScreen()),
          );
        }
      },
    );
  }

  bool _isActive(RouteAssignment route) {
    final status = route.status.toLowerCase();
    return status.contains('active') ||
        status.contains('assigned') ||
        status.contains('enroute') ||
        status.contains('progress');
  }

  bool _isIdle(RouteAssignment route) {
    final status = route.status.toLowerCase();
    return status.contains('idle') || status.contains('pending');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackgroundWrapper(
        child: StreamBuilder<List<VehicleInfo>>(
          stream: _dataService.vehiclesStream,
          builder: (context, vehicleSnapshot) {
            return StreamBuilder<List<AppAlert>>(
              stream: _dataService.alertsStream,
              builder: (context, alertSnapshot) {
                // Show shimmer only when initial data is loading and no cache exists
                if (!vehicleSnapshot.hasData && vehicleSnapshot.connectionState == ConnectionState.waiting) {
                  return const SafeArea(child: Padding(padding: EdgeInsets.all(16), child: DashboardShimmer()));
                }

                final vehicles = vehicleSnapshot.data ?? [];
                final alerts = alertSnapshot.data ?? [];
                
                int activeCount = vehicles.where((v) => v.status == TankerStatus.active).length;
                int idleCount = vehicles.where((v) => v.status == TankerStatus.idle).length;
                int alertCount = alerts.length;
                int totalFleet = vehicles.length;

                final cargoValues = vehicles
                    .map((v) => v.cargo)
                    .where((cargo) => cargo.isNotEmpty && cargo != 'Not available')
                    .toList();

                final deliveredCount = vehicles
                    .where((v) => v.statusLabel.toLowerCase().contains('delivered'))
                    .length
                    .toString();

                return SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      // Statistics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: MediaQuery.sizeOf(context).width < 360 ? 1.1 : 1.4,
                        children: [
                          _buildStatusCard(0, 'status_active'.tr(), activeCount.toString(), Icons.check_circle_outline, AppTheme.success),
                          _buildStatusCard(1, 'status_idle'.tr(), idleCount.toString(), Icons.local_shipping_outlined, AppTheme.warning),
                          _buildStatusCard(2, 'status_alerts'.tr(), alertCount.toString(), Icons.warning_amber_rounded, AppTheme.error),
                          _buildStatusCard(3, 'status_total_fleet'.tr(), totalFleet.toString(), Icons.trending_up, theme.primaryColor),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _SystemAlertsPanel(
                        alertCount: alertCount,
                        alerts: alerts,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen())),
                      ),
                      const SizedBox(height: 28),
                      
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 4, height: 20,
                              decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'active_transports'.tr(),
                              style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      
                      if (vehicles.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color?.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: theme.hintColor),
                              const SizedBox(height: 16),
                              Text(
                                'No active transports assigned.',
                                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      else
                        ...vehicles.map((v) => TransportCard(
                          id: v.displayName,
                          vehicleId: v.vehicleId,
                          driver: v.driverName,
                          route: '${v.origin} -> ${v.destination}',
                          progress: v.progress,
                          eta: v.lastUpdated,
                          isActive: v.status == TankerStatus.active,
                          onTrack: () {
                            MainScreen.switchTab(context, 2);
                          },
                        )),
                      
                      const SizedBox(height: 24),
                      
                      FleetOverviewCard(
                        totalCargo: cargoValues.isEmpty ? 'No cargo assigned' : cargoValues.join(', '),
                        inProgress: '$activeCount Deliveries',
                        delivered: deliveredCount,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SystemAlertsPanel extends StatelessWidget {
  final int alertCount;
  final List<AppAlert> alerts;
  final VoidCallback onTap;

  const _SystemAlertsPanel({
    required this.alertCount,
    required this.alerts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final recentAlerts = alerts.take(3).map((alert) {
      final type = alert.severity.contains('CRITICAL')
          ? AlertType.critical
          : alert.severity.contains('WARNING')
              ? AlertType.warning
              : AlertType.info;
      return AlertTile(
        type: type,
        title: alert.title,
        vehicleId: alert.vehicleId,
        description: alert.description,
        status: alert.status,
        timestamp: DateFormat('HH:mm').format(alert.timestamp),
        onTap: onTap,
      );
    }).toList();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color?.withValues(alpha: 0.9) ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.error.withValues(alpha: isDark ? 0.2 : 0.1)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.error.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppTheme.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'System Alerts',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.titleMedium?.color,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$alertCount Open',
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentAlerts.isEmpty)
                Text(
                  'No recent system alerts.',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                ...recentAlerts,
            ],
          ),
        ),
      ),
    );
  }
}
