import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/organic_screen.dart';
import 'screens/iot_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/schemes_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    MarketScreen(),
    OrganicScreen(),
    IoTScreen(),
    ProfileScreen(isOnboarding: false),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'Organic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'IoT',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}