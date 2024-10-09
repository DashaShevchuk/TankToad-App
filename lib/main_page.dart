import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart'; // New import

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(color: Color(0xFF1D1B20));
            }
            return const TextStyle(color: Color(0xFF49454F));
          }),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const MapScreen(), // Using the imported MapScreen
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

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
        onDestinationSelected: (int index) {
          _onItemTapped(index);
        },
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

// Other screens remain unchanged
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Notifications Screen'));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile Screen'));
  }
}