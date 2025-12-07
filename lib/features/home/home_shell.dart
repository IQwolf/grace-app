import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/theme.dart';

class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({
    super.key,
    required this.child,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      label: AppStrings.home,
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: AppRoutes.home,
    ),
    NavigationItem(
      label: AppStrings.search,
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      route: AppRoutes.search,
    ),
    NavigationItem(
      label: AppStrings.library,
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books,
      route: AppRoutes.library,
    ),
    NavigationItem(
      label: AppStrings.account,
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: AppRoutes.account,
    ),
  ];

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      context.go(_navigationItems[index].route);
    }
  }

  int _calculateSelectedIndex(String location) {
    for (int i = 0; i < _navigationItems.length; i++) {
      if (location == _navigationItems[i].route) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: EduPulseColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(GoRouterState.of(context).matchedLocation),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: EduPulseColors.surface,
          selectedItemColor: EduPulseColors.primary,
          unselectedItemColor: EduPulseColors.textMain.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          items: _navigationItems.map((item) {
            final isSelected = _calculateSelectedIndex(
              GoRouterState.of(context).matchedLocation
            ) == _navigationItems.indexOf(item);
            
            return BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 24,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}