import 'package:flutter/material.dart';
import 'package:first_flutter_proj/home_screen.dart';  // Оновлений імпорт
import 'package:first_flutter_proj/map_screen.dart';   // Оновлений імпорт
import 'package:first_flutter_proj/profile_screen.dart'; // Оновлений імпорт

class MainPage extends StatefulWidget {
  final dynamic userId;
  
  const MainPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(userId: widget.userId),
      MapScreen(userId: widget.userId),
      const NotificationsScreen(),
      ProfileScreen(userId: widget.userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: Colors.indigo,
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <Widget>[
          _buildNavigationDestination(Icons.home_outlined, Icons.home, 'Home', 0),
          _buildNavigationDestination(Icons.map_outlined, Icons.map, 'Map', 1),
          _buildNavigationDestination(Icons.notifications_active_outlined, Icons.notifications_active, 'Notifications', 2),
          _buildNavigationDestination(Icons.account_circle_outlined, Icons.account_circle, 'Profile', 3),
        ],
      ),
    );
  }

  NavigationDestination _buildNavigationDestination(IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return NavigationDestination(
      icon: Icon(outlinedIcon, color: isSelected ? Colors.white : const Color(0xFF49454F)),
      selectedIcon: Icon(filledIcon, color: Colors.white),
      label: label,
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Notifications Screen')),
    );
  }
}