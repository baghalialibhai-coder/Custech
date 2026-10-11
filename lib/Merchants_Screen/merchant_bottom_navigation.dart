// lib/Merchants_Screen/merchant_bottom_navigation.dart

import 'package:flutter/material.dart';
import '../languages/localization/app_localizations.dart';

class MerchantBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MerchantBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: context.tr('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.storefront_outlined),
          activeIcon: const Icon(Icons.storefront),
          label: context.tr('myStore'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.build_outlined),
          activeIcon: const Icon(Icons.build),
          label: 'Technicians',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.notifications_outlined),
          activeIcon: const Icon(Icons.notifications),
          label: context.tr('notifications'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: context.tr('profile'),
        ),
      ],
    );
  }
}
