import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'emergency_screen.dart';
import 'profile_screen.dart';
import 'medical_history_screen.dart';
import 'health_features_screen.dart';

class HomeScreen extends StatefulWidget {
  final String gender;
  const HomeScreen({super.key, required this.gender});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(gender: widget.gender),
      const HealthFeaturesScreen(),
      const MedicalHistoryScreen(),
      const EmergencyScreen(),
      ProfileScreen(gender: widget.gender),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_outlined, Icons.dashboard, "Home"),
                _navItem(1, Icons.medical_services_outlined, Icons.medical_services, "Health"),
                _navItem(2, Icons.history_outlined, Icons.history, "History"),
                _navItem(3, Icons.emergency_outlined, Icons.emergency, "SOS", isEmergency: true),
                _navItem(4, Icons.person_outline, Icons.person, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label,
      {bool isEmergency = false}) {
    final isActive = _index == index;

    if (isEmergency) {
      return GestureDetector(
        onTap: () => setState(() => _index = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(isActive ? activeIcon : icon,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? const Color(0xFFE53935) : Colors.grey.shade400,
                )),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _index = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A6B9A).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF1A6B9A) : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF1A6B9A) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}