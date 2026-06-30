import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/firestore_models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alerts_widgets.dart';
import '../widgets/app_background_wrapper.dart';

class CriticalAlertsScreen extends StatelessWidget {
  const CriticalAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'critical_alerts'.tr(),
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.titleLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackgroundWrapper(
        child: StreamBuilder<QuerySnapshot>(
          stream: dataService.getAlertsStream(),
          builder: (context, snapshot) {
            final alerts = (snapshot.data?.docs ?? [])
                .map((doc) => AppAlert.fromFirestore(doc))
                .where((alert) => alert.severity.contains('CRITICAL'))
                .toList();
            alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            if (alerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 64, color: AppTheme.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'no_critical_alerts'.tr(),
                      style: TextStyle(
                        color: theme.textTheme.titleLarge?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'system_secure_msg'.tr(),
                      style: TextStyle(color: theme.hintColor, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Text(
                  'sec_critical_alerts'.tr(),
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...alerts.map(
                  (alert) => AlertTile(
                    type: AlertType.critical,
                    title: alert.title,
                    vehicleId: alert.vehicleId,
                    description: alert.description,
                    status: alert.status,
                    timestamp: DateFormat('dd MMM, HH:mm').format(alert.timestamp),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
