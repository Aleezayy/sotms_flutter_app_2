import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../models/firestore_models.dart';
import '../screens/vehicle_analytics_screen.dart';

class VehicleSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const VehicleSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'search_hint'.tr(),
        hintStyle: TextStyle(color: theme.hintColor),
        prefixIcon: Icon(Icons.search, color: theme.hintColor),
        filled: true,
        fillColor: theme.cardTheme.color?.withValues(alpha: 0.7) ?? theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class FilterTabs extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onSelect;

  const FilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ['All', 'Active', 'Idle', 'Alert', 'Maintenance'];
    // ... rest same ...
    final filterTrKeys = {
      'All': 'filter_all',
      'Active': 'filter_active',
      'Idle': 'filter_idle',
      'Alert': 'filter_alert',
      'Maintenance': 'filter_maintenance',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          final displayLabel = filterTrKeys[filter]?.tr() ?? filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelect(filter),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 78),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : (theme.cardTheme.color ?? theme.colorScheme.surface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


// Mapping VehicleStatus to TankerStatus internally or just using it directly
typedef VehicleStatus = TankerStatus;

class VehicleCard extends StatelessWidget {
  final String id; // Display Name
  final String realVehicleId; // DB ID
  final String driver;
  final String location;
  final String cargo;
  final String speed;
  final TankerStatus status;
  final String? routeStart;
  final String? routeEnd;
  final double? progress;

  const VehicleCard({
    super.key,
    required this.id,
    required this.realVehicleId,
    required this.driver,
    required this.location,
    required this.cargo,
    required this.speed,
    required this.status,
    this.routeStart,
    this.routeEnd,
    this.progress,
  });

  Color _getStatusColor() {
    switch (status) {
      case TankerStatus.active:
        return Colors.green;
      case TankerStatus.idle:
        return Colors.orange;
      case TankerStatus.stop:
      case TankerStatus.maintenance:
      case TankerStatus.alert:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (status) {
      case TankerStatus.active:
        return 'status_active'.tr();
      case TankerStatus.idle:
        return 'status_idle'.tr();
      case TankerStatus.stop:
        return 'Stop';
      case TankerStatus.alert:
        return 'Alert';
      case TankerStatus.maintenance:
        return 'filter_maintenance'.tr();
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleAnalyticsScreen(
              vehicleId: realVehicleId,
              title: id,
              driverName: driver,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color?.withValues(alpha: 0.9) ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.14),
          ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textTheme.titleMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              driver,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.hintColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'location'.tr() + ':', location),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'cargo'.tr() + ':', cargo),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'speed'.tr() + ':', speed),
            
            if (status == VehicleStatus.active && routeStart != null && routeEnd != null) ...[
              const SizedBox(height: 16),
              Divider(color: theme.dividerColor.withValues(alpha: 0.10), height: 1),
              const SizedBox(height: 12),
              Text(
                '$routeStart → $routeEnd',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress ?? 0,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.hintColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 3,
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
