import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/firestore_models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background_wrapper.dart';

class RouteManagementScreen extends StatelessWidget {
  const RouteManagementScreen({super.key});

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
          'Route Management',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 18,
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
          stream: dataService.getRoutesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: theme.primaryColor));
            }

            final routes = (snapshot.data?.docs ?? [])
                .map((doc) => RouteAssignment.fromFirestore(doc))
                .toList();

            if (routes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.route_outlined, size: 64, color: theme.hintColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No routes assigned.',
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: routes.length,
              itemBuilder: (context, index) => _RouteCard(route: routes[index]),
            );
          },
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteAssignment route;

  const _RouteCard({required this.route});

  Color _statusColor(BuildContext context) {
    final status = route.status.toLowerCase();
    if (status.contains('complete') || status.contains('delivered')) return Colors.green;
    if (status.contains('pending') || status.contains('idle')) return Colors.orange;
    if (status.contains('alert') || status.contains('critical')) return Theme.of(context).colorScheme.error;
    return Theme.of(context).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color?.withValues(alpha: 0.92) ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  route.vehicleId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.titleMedium?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  route.status,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Driver: ${route.driverName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _locationRow(context, Icons.location_on_outlined, 'Start', route.origin),
          const SizedBox(height: 8),
          _locationRow(context, Icons.flag_outlined, 'Destination', route.destination),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: route.progress,
              minHeight: 7,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.primaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
