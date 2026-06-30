import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../models/firestore_models.dart';

import '../widgets/app_background_wrapper.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final DataService _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'FLEET DRIVERS', 
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color, 
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          )
        ),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: AppBackgroundWrapper(
        child: StreamBuilder<QuerySnapshot>(
          stream: _dataService.getDriversStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final drivers = (snapshot.data?.docs ?? [])
                .map((doc) => AppDriver.fromFirestore(doc))
                .toList();

            if (drivers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined, size: 64, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'No drivers found in Firestore.',
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return _buildDriverCard(driver, theme);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverCard(AppDriver driver, ThemeData theme) {
    final statusColor = driver.status.toLowerCase() == 'active' ? AppTheme.success : AppTheme.warning;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color?.withValues(alpha: 0.9) ?? theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, color: theme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: TextStyle(
                          color: theme.textTheme.titleMedium?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${driver.id}',
                        style: TextStyle(color: theme.hintColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    driver.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.05)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.phone_outlined, 'Phone', driver.phone, theme),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.badge_outlined, 'License', driver.licenseNumber, theme),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.event_available_outlined, 'License Expiry', driver.licenseExpiry, theme),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.verified_user_outlined, 'Insurance', driver.insured ? 'Active (Policy: ${driver.policyNumber})' : 'Not Insured', theme, 
                  valueColor: driver.insured ? AppTheme.success : AppTheme.error),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Safety Score', style: TextStyle(color: theme.hintColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: AppTheme.accent),
                              const SizedBox(width: 6),
                              Text('${driver.safetyScore.toInt()}/100', style: TextStyle(color: theme.textTheme.titleSmall?.color, fontSize: 15, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Last Assignment', style: TextStyle(color: theme.hintColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(driver.lastAssignment, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.primaryColor.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Text('$label:', style: TextStyle(color: theme.hintColor, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? theme.textTheme.bodyLarge?.color, 
              fontSize: 13, 
              fontWeight: FontWeight.w700
            )
          ),
        ),
      ],
    );
  }
}

