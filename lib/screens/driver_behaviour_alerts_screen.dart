import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/firestore_models.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background_wrapper.dart';
import '../widgets/shimmer_widgets.dart';

// ─── Filter Options ──────────────────────────────────────────────────────────
enum DriverAlertFilter { all, today, thisWeek, criticalOnly }

extension DriverAlertFilterLabel on DriverAlertFilter {
  String get label {
    switch (this) {
      case DriverAlertFilter.all:
        return 'All Alerts';
      case DriverAlertFilter.today:
        return 'Today';
      case DriverAlertFilter.thisWeek:
        return 'This Week';
      case DriverAlertFilter.criticalOnly:
        return 'Critical Only';
    }
  }

  IconData get icon {
    switch (this) {
      case DriverAlertFilter.all:
        return Icons.list_alt_rounded;
      case DriverAlertFilter.today:
        return Icons.today_rounded;
      case DriverAlertFilter.thisWeek:
        return Icons.date_range_rounded;
      case DriverAlertFilter.criticalOnly:
        return Icons.warning_amber_rounded;
    }
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class DriverBehaviourAlertsScreen extends StatefulWidget {
  const DriverBehaviourAlertsScreen({super.key});

  @override
  State<DriverBehaviourAlertsScreen> createState() =>
      _DriverBehaviourAlertsScreenState();
}

class _DriverBehaviourAlertsScreenState
    extends State<DriverBehaviourAlertsScreen>
    with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  final NotificationService _notif = NotificationService();

  DriverAlertFilter _filter = DriverAlertFilter.all;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _notif.init();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Filter logic ─────────────────────────────────────────────────────────
  List<DriverBehaviorAlert> _applyFilter(List<DriverBehaviorAlert> raw) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    switch (_filter) {
      case DriverAlertFilter.all:
        return raw;
      case DriverAlertFilter.today:
        return raw.where((a) => a.timestamp.isAfter(todayStart)).toList();
      case DriverAlertFilter.thisWeek:
        return raw.where((a) => a.timestamp.isAfter(weekStart)).toList();
      case DriverAlertFilter.criticalOnly:
        return raw
            .where((a) => a.severity == DriverAlertSeverity.critical)
            .toList();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(theme),
      body: AppBackgroundWrapper(
        child: StreamBuilder<List<DriverBehaviorAlert>>(
          stream: _dataService.getDriverBehaviorAlertsStream(),
          builder: (context, snapshot) {
            // Trigger notifications for critical alerts
            if (snapshot.hasData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _notif.notifyBatch(context, snapshot.data!);
              });
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.all(16), child: AlertShimmer());
            }

            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString(), theme);
            }

            final all = snapshot.data ?? [];
            final filtered = _applyFilter(all);

            // Count by severity for summary bar
            final criticalCount =
                all.where((a) => a.severity == DriverAlertSeverity.critical).length;
            final warningCount =
                all.where((a) => a.severity == DriverAlertSeverity.warning).length;
            final mediumCount = all
                .where((a) =>
                    a.severity == DriverAlertSeverity.medium ||
                    a.severity == DriverAlertSeverity.info)
                .length;

            return Column(
              children: [
                // Summary bar
                _buildSummaryBar(criticalCount, warningCount, mediumCount, theme),
                // Filter chips
                _buildFilterBar(theme),
                // Alert list
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(theme, isDark)
                      : _buildAlertList(filtered, theme),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: theme.textTheme.titleLarge?.color),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            'Driver Behaviour',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Real-time monitoring',
            style: TextStyle(
              color: theme.hintColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        // Live pulse indicator
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Summary Bar ──────────────────────────────────────────────────────────
  Widget _buildSummaryBar(
      int critical, int warning, int medium, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _SummaryChip(
            count: critical,
            label: 'Critical',
            color: AppTheme.error,
            icon: Icons.dangerous_rounded,
          ),
          const SizedBox(width: 10),
          _SummaryChip(
            count: warning,
            label: 'Warning',
            color: const Color(0xFFF97316), // orange-500
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(width: 10),
          _SummaryChip(
            count: medium,
            label: 'Medium',
            color: const Color(0xFFEAB308), // Yellow
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  // ─── Filter Bar ───────────────────────────────────────────────────────────
  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: DriverAlertFilter.values.map((f) {
            final isSelected = _filter == f;
            final color = f == DriverAlertFilter.criticalOnly
                ? AppTheme.error
                : theme.primaryColor;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.icon,
                          size: 14,
                          color: isSelected ? Colors.white : theme.hintColor),
                      const SizedBox(width: 5),
                      Text(
                        f.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : theme.hintColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  selectedColor: color,
                  backgroundColor: theme.cardTheme.color?.withValues(alpha: 0.8) ??
                      theme.colorScheme.surface,
                  checkmarkColor: Colors.transparent,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : theme.dividerColor.withValues(alpha: 0.4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => setState(() => _filter = f),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Alert List ───────────────────────────────────────────────────────────
  Widget _buildAlertList(List<DriverBehaviorAlert> alerts, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: alerts.length,
      itemBuilder: (context, i) {
        return _DriverAlertCard(alert: alerts[i]);
      },
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(
                Icons.verified_user_rounded,
                size: 48,
                color: AppTheme.success.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _filter == DriverAlertFilter.all
                  ? 'No Alerts Detected'
                  : 'No Alerts for This Filter',
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _filter == DriverAlertFilter.all
                  ? 'All drivers are currently operating\nwithin safe behaviour limits.'
                  : 'Try changing the filter to see more alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.hintColor,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            if (_filter != DriverAlertFilter.all) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() => _filter = DriverAlertFilter.all),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('View All Alerts'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Loading ──────────────────────────────────────────────────────────────
  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading driver alerts…',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────
  Widget _buildError(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: AppTheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('Failed to load alerts',
                style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Chip ─────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Driver Alert Card ────────────────────────────────────────────────────────
class _DriverAlertCard extends StatelessWidget {
  final DriverBehaviorAlert alert;
  const _DriverAlertCard({required this.alert});

  Color get _color {
    switch (alert.severity) {
      case DriverAlertSeverity.critical:
        return const Color(0xFFEF4444); // Red
      case DriverAlertSeverity.warning:
        return const Color(0xFFF97316); // Orange
      case DriverAlertSeverity.medium:
      case DriverAlertSeverity.info:
        return const Color(0xFFEAB308); // Yellow
    }
  }

  IconData _getIcon() {
    final type = alert.alertTypeLabel.toLowerCase();
    if (type.contains('drowsy') || type.contains('fatigue')) return Icons.visibility_rounded;
    if (type.contains('reach') || type.contains('phone')) return Icons.camera_alt_rounded;
    if (type.contains('speed')) return Icons.speed_rounded;
    return Icons.warning_amber_rounded;
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;
    final timeAgo = _getTimeAgo(alert.timestamp);

    return Container(
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
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Column
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getIcon(), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          
          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      alert.alertTypeLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: theme.hintColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: alert.driverName,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      ),
                      TextSpan(
                        text: ' • ',
                        style: TextStyle(color: theme.hintColor.withValues(alpha: 0.5)),
                      ),
                      TextSpan(
                        text: alert.tankerId,
                        style: const TextStyle(color: Color(0xFF22D3EE)), // Cyan ID
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.description,
                  style: TextStyle(
                    color: theme.hintColor.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Action Column (Right Side)
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 32),
              Material(
                color: alert.status == 'Acknowledged' 
                    ? Colors.green.withValues(alpha: 0.1)
                    : const Color(0xFF0E7490).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: alert.status == 'Acknowledged' ? null : () {},
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: alert.status == 'Acknowledged'
                            ? Colors.green.withValues(alpha: 0.4)
                            : const Color(0xFF22D3EE).withValues(alpha: 0.4), 
                        width: 0.5
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alert.status == 'Acknowledged' ? Icons.check_circle_rounded : Icons.check, 
                          size: 12, 
                          color: alert.status == 'Acknowledged' ? Colors.green : const Color(0xFF22D3EE)
                        ),
                        const SizedBox(width: 4),
                        Text(
                          alert.status == 'Acknowledged' ? 'Acknowledged' : 'Ack',
                          style: TextStyle(
                            color: alert.status == 'Acknowledged' ? Colors.green : const Color(0xFF22D3EE),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: theme.hintColor),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: theme.hintColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
