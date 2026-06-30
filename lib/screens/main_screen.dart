import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background_wrapper.dart';
import 'dashboard_screen.dart';
import 'vehicles_screen.dart';
import 'map_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';
import 'route_management_screen.dart';
import 'help_service_screen.dart';
import 'driver_behaviour_alerts_screen.dart';
import 'drivers_screen.dart';
import 'reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static void switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainScreenState>()?.onItemTapped(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  
  final List<Widget> _mainScreens = [
    const DashboardScreen(),
    const VehiclesScreen(),
    const MapScreen(),
    const AlertsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onItemTapped(int index) {
    if (index >= 0 && index < _mainScreens.length) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToSecondaryScreen(Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
        settings: const RouteSettings(name: 'SecondaryScreen'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(color: theme.primaryColor.withValues(alpha: 0.1), width: 1),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  'app_title'.tr(),
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'app_subtitle'.tr(),
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color ?? AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu_rounded, color: theme.iconTheme.color),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.98),
        elevation: 16,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_shipping_rounded, size: 42, color: theme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SOTMS Fleet',
                      style: TextStyle(
                        color: theme.textTheme.titleLarge?.color,
                        fontSize: 20, 
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildDrawerItem(icon: Icons.dashboard_rounded, title: 'Dashboard', index: 0),
                  _buildDrawerItem(icon: Icons.local_shipping_rounded, title: 'Vehicles', index: 1),
                  _buildDrawerItem(icon: Icons.map_rounded, title: 'Map / Live Tracking', index: 2),
                  _buildDrawerItem(icon: Icons.warning_amber_rounded, title: 'Alerts', index: 3),
                  _buildDrawerItem(icon: Icons.settings_rounded, title: 'Settings', index: 4),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  
                  _buildDrawerActionItem(
                    icon: Icons.route_rounded, 
                    title: 'Route Management', 
                    screen: const RouteManagementScreen(),
                  ),
                  _buildDrawerActionItem(
                    icon: Icons.warning_rounded, 
                    title: 'Driver Behaviour', 
                    screen: const DriverBehaviourAlertsScreen(),
                  ),
                  _buildDrawerActionItem(
                    icon: Icons.person_search_rounded, 
                    title: 'Drivers List', 
                    screen: const DriversScreen(),
                  ),
                  _buildDrawerActionItem(
                    icon: Icons.summarize_rounded, 
                    title: 'Fleet Reports', 
                    screen: const ReportsScreen(),
                  ),
                  _buildDrawerActionItem(
                    icon: Icons.help_outline_rounded, 
                    title: 'Help & Support', 
                    screen: const HelpServiceScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: AppBackgroundWrapper(
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _mainScreens,
        ),
      ),
      bottomNavigationBar: _selectedIndex < 5
          ? Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color?.withValues(alpha: 0.85) ?? 
                       theme.colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NavigationBar(
                  height: 72,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: onItemTapped,
                  backgroundColor: Colors.transparent,
                  indicatorColor: theme.primaryColor.withValues(alpha: 0.15),
                  animationDuration: const Duration(milliseconds: 400),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded, color: theme.primaryColor),
                      label: 'nav_dashboard'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.local_shipping_outlined),
                      selectedIcon: Icon(Icons.local_shipping_rounded, color: theme.primaryColor),
                      label: 'nav_vehicles'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded, color: theme.primaryColor),
                      label: 'nav_map'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.notifications_outlined),
                      selectedIcon: Icon(Icons.notifications_active_rounded, color: theme.primaryColor),
                      label: 'nav_alerts'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded, color: theme.primaryColor),
                      label: 'settings'.tr(),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon, 
          color: isSelected ? theme.primaryColor : theme.hintColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          onItemTapped(index);
        },
      ),
    );
  }

  Widget _buildDrawerActionItem({required IconData icon, required String title, required Widget screen}) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: theme.hintColor),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _navigateToSecondaryScreen(screen),
      ),
    );
  }
}

