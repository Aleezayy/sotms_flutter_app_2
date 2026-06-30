import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlertSummaryCard extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const AlertSummaryCard({
    super.key,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color?.withValues(alpha: 0.9) ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

enum AlertType { critical, warning, medium, info }

class AlertTile extends StatelessWidget {
  final AlertType type;
  final String title;
  final String vehicleId;
  final String? driverName;
  final String description;
  final String status;
  final String timestamp;
  final VoidCallback? onTap;

  const AlertTile({
    super.key,
    required this.type,
    required this.title,
    required this.vehicleId,
    this.driverName,
    required this.description,
    required this.status,
    required this.timestamp,
    this.onTap,
  });

  Color _getColor(BuildContext context) {
    switch (type) {
      case AlertType.critical:
        return const Color(0xFFEF4444); // Bright Red
      case AlertType.warning:
        return const Color(0xFFF97316); // Orange
      case AlertType.medium:
        return const Color(0xFFEAB308); // Yellow
      case AlertType.info:
        return const Color(0xFF0EA5E9); // Blue
    }
  }

  IconData _getIcon() {
    switch (type) {
      case AlertType.critical:
        return Icons.dangerous_rounded;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.medium:
        return Icons.info_outline_rounded;
      case AlertType.info:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(context);
    final isResolved = status.toLowerCase().contains('resolved') || status.toLowerCase().contains('closed');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? const Color(0xFF1E293B).withValues(alpha: 0.8) // Slate-800
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.1), width: 0.5),
                ),
                child: Icon(
                  _getIcon(),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: theme.textTheme.titleMedium?.color,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    vehicleId,
                                    style: const TextStyle(
                                      color: Color(0xFF22D3EE), // Cyan
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (driverName != null && driverName != 'Unassigned') ...[
                                    Text(
                                      ' • ',
                                      style: TextStyle(color: theme.hintColor.withValues(alpha: 0.4)),
                                    ),
                                    Text(
                                      driverName!,
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isResolved ? Colors.green.withValues(alpha: 0.1) : theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isResolved ? Colors.green.withValues(alpha: 0.5) : theme.primaryColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: isResolved ? Colors.green : theme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: theme.hintColor.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              timestamp,
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: color.withValues(alpha: 0.4),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
