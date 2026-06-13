import 'package:flutter/material.dart';

import 'history_view.dart';
import 'home_view.dart';
import 'profile_view.dart';
import 'scan_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeView(
        onStartScan: () => setState(() => _selectedIndex = 1),
        onViewHistory: () => setState(() => _selectedIndex = 2),
      ),
      const ScanView(),
      const HistoryView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FruityCheck'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileView()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_strong),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
