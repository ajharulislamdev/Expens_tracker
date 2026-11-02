import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/auth_view.dart';
import '../../reports/views/report_view.dart';
import '../../transactions/views/transaction_list_view.dart';
import '../controllers/home_controller.dart';
import 'home_view.dart';
import 'plans_view.dart';
import 'settings_view.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  late final HomeController _controller = Get.find<HomeController>();

  static const _pages = [
    HomeView(key: PageStorageKey('home-tab')),
    ReportView(key: PageStorageKey('reports-tab')),
    PlansView(key: PageStorageKey('plans-tab')),
    SettingsView(key: PageStorageKey('settings-tab')),
    TransactionListView(key: PageStorageKey('transactions-tab')),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      if (!authController.isAuthenticated) return const AuthView();
      final index =
          _controller.tabIndex.value.clamp(0, _pages.length - 1).toInt();
      return Scaffold(
        body: IndexedStack(
          index: index,
          children: _pages,
        ),
        bottomNavigationBar: _FloatingBottomBar(
          selectedIndex: index < 4 ? index : null,
          onDestinationSelected: (i) => _controller.tabIndex.value = i,
          onAddPressed: () => Get.toNamed(AppRoutes.form),
        ),
      );
    });
  }
}

class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
  });

  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  static const _destinations = [
    _NavDestinationData(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDestinationData(
      label: 'Reports',
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
    ),
    _NavDestinationData(
      label: 'Plan',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
    ),
    _NavDestinationData(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalMargin = constraints.maxWidth < 360 ? 8.0 : 14.0;

          return SizedBox(
            height: 92,
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 8),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    top: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: theme.brightness == Brightness.light
                                  ? 0.09
                                  : 0.22,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            for (var index = 0; index < 2; index++)
                              Expanded(
                                child: _NavigationDestination(
                                  data: _destinations[index],
                                  selected: selectedIndex == index,
                                  onTap: () => onDestinationSelected(index),
                                ),
                              ),
                            const SizedBox(width: 58),
                            for (var index = 2;
                                index < _destinations.length;
                                index++)
                              Expanded(
                                child: _NavigationDestination(
                                  data: _destinations[index],
                                  selected: selectedIndex == index,
                                  onTap: () => onDestinationSelected(index),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _AddTransactionButton(onPressed: onAddPressed),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavDestinationData {
  const _NavDestinationData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavDestinationData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: Tooltip(
        message: data.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      selected ? data.selectedIcon : data.icon,
                      size: 21,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 10.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTransactionButton extends StatelessWidget {
  const _AddTransactionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add transaction',
      child: Tooltip(
        message: 'Add transaction',
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF8270F4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.36),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(21),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
