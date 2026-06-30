import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/firestore_models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alerts_widgets.dart';
import '../widgets/app_background_wrapper.dart';
import '../widgets/shimmer_widgets.dart';
import 'vehicle_analytics_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final DataService _dataService = DataService();

  void _navigateToDetail(AppAlert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleAnalyticsScreen(
          vehicleId: alert.vehicleId,
          title: alert.vehicleId,
          driverName: alert.driverName,
          alertDetails: {
            'severity': alert.severity,
            'title': alert.title,
            'description': alert.description,
            'timestamp': DateFormat('dd/MM/yyyy, HH:mm:ss').format(alert.timestamp),
            'type': alert.severity.toLowerCase(),
          },
        ),
      ),
    );
  }

  AlertType _typeFor(AppAlert alert) {
    final s = alert.severity.toUpperCase();
    if (s.contains('CRITICAL') || s.contains('HIGH') || s.contains('DANGER') || s.contains('EMERGENCY')) return AlertType.critical;
    if (s.contains('WARNING') || s.contains('WARN')) return AlertType.warning;
    if (s.contains('MEDIUM') || s.contains('MODERATE') || s.contains('LOW')) return AlertType.medium;
    return AlertType.info;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackgroundWrapper(
        child: SafeArea(
          child: StreamBuilder<List<AppAlert>>(
            stream: _dataService.alertsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(16), child: AlertShimmer());
              }

              final theme = Theme.of(context);
              final alerts = snapshot.data ?? [];
              
              final critical = alerts.where((a) => _typeFor(a) == AlertType.critical).toList();
              final warnings = alerts.where((a) => _typeFor(a) == AlertType.warning).toList();
              final medium = alerts.where((a) => _typeFor(a) == AlertType.medium).toList();
              final info = alerts.where((a) => _typeFor(a) == AlertType.info).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).textTheme.titleLarge?.color),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alerts',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Theme.of(context).textTheme.titleLarge?.color,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitor critical, warning, and information alerts',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          AlertSummaryCard(count: critical.length.toString(), label: 'alert_critical'.tr(), color: const Color(0xFFEF4444)),
                          AlertSummaryCard(count: warnings.length.toString(), label: 'alert_warning'.tr(), color: const Color(0xFFF97316)),
                          AlertSummaryCard(count: medium.length.toString(), label: 'alert_medium'.tr(), color: const Color(0xFFEAB308)),
                        ];

                        if (constraints.maxWidth < 340) {
                          return Column(children: [for (final card in cards) ...[SizedBox(width: double.infinity, child: card), if (card != cards.last) const SizedBox(height: 10)]]);
                        }

                        return Row(children: [for (final card in cards) ...[Expanded(child: card), if (card != cards.last) const SizedBox(width: 10)]]);
                      },
                    ),
                    const SizedBox(height: 32),
                    if (alerts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Icon(Icons.notifications_off_outlined, size: 64, color: theme.hintColor.withValues(alpha: 0.5)),
                              ),
                              const SizedBox(height: 24),
                              Text('no_alerts_found'.tr(), style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 20, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text('no_alerts_subtitle'.tr(), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      _section('sec_critical_alerts'.tr(), const Color(0xFFEF4444), critical),
                      _section('sec_warnings'.tr(), const Color(0xFFF97316), warnings),
                      _section('sec_medium_alerts'.tr(), const Color(0xFFEAB308), medium),
                      _section('sec_information'.tr(), const Color(0xFF0EA5E9), info),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Color color, List<AppAlert> alerts) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.map(
          (alert) => AlertTile(
            type: _typeFor(alert),
            title: alert.title,
            vehicleId: alert.vehicleId,
            driverName: alert.driverName,
            description: alert.description,
            status: alert.status,
            timestamp: DateFormat('dd MMM, HH:mm').format(alert.timestamp),
            onTap: () => _navigateToDetail(alert),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
