import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/firestore_models.dart';

/// Lightweight in-app notification service for critical driver behavior alerts.
/// Shows a SnackBar-style overlay and tracks shown alert IDs to avoid repeats.
class NotificationService {
  static const String _prefKey = 'notified_driver_alert_ids';
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final Set<String> _notifiedIds = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey) ?? [];
    _notifiedIds.addAll(saved);
    _initialized = true;
  }

  /// Returns true if the alert hasn't been notified before (i.e. it is new).
  Future<bool> _markNotified(String id) async {
    if (_notifiedIds.contains(id)) return false;
    _notifiedIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    // Keep only last 500 IDs to avoid unbounded growth
    final list = _notifiedIds.toList();
    if (list.length > 500) list.removeRange(0, list.length - 500);
    await prefs.setStringList(_prefKey, list);
    return true;
  }

  /// Shows an in-app notification banner for a critical driver behavior alert.
  Future<void> showDriverAlertNotification(
    BuildContext context,
    DriverBehaviorAlert alert,
  ) async {
    await init();
    if (alert.severity != DriverAlertSeverity.critical) return;
    final isNew = await _markNotified(alert.id);
    if (!isNew) return;
    if (!context.mounted) return;

    // Capture the messenger before any await
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        content: _CriticalAlertBanner(alert: alert),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),
    );
  }

  /// Notify about any new critical alerts from a fresh stream event.
  Future<void> notifyBatch(
    BuildContext context,
    List<DriverBehaviorAlert> alerts,
  ) async {
    await init();
    if (!context.mounted) return;
    // Pre-capture messenger before any awaits to avoid context-across-async-gap
    final messenger = ScaffoldMessenger.of(context);
    final criticals =
        alerts.where((a) => a.severity == DriverAlertSeverity.critical).toList();
    for (final alert in criticals) {
      if (_notifiedIds.contains(alert.id)) continue;
      final isNew = await _markNotified(alert.id);
      if (!isNew) continue;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 5),
          content: _CriticalAlertBanner(alert: alert),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        ),
      );
    }
  }
}

class _CriticalAlertBanner extends StatelessWidget {
  final DriverBehaviorAlert alert;
  const _CriticalAlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF43F5E),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🚨 CRITICAL DRIVER ALERT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.alertTypeLabel} — ${alert.driverName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  alert.tankerName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
