import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'password_recovery_screen.dart';
import 'login_page.dart';

class ProfileScreen extends StatefulWidget {
  final dynamic userId;
  
  const ProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _logger = Logger();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final url = '${dotenv.env['API_URL']}${dotenv.env['GET_USER_PROFILE']}?userListId=${widget.userId}';
      _logger.d("Fetching user profile from URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );

      _logger.d("Response status: ${response.statusCode}");
      _logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _userProfile = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      _logger.e("Error fetching profile: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final url = '${dotenv.env['API_URL']}${dotenv.env['LOGOUT']}';
      _logger.d("Logging out. URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );

      _logger.d("Logout response status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        throw Exception('Failed to logout');
      }
    } catch (e) {
      _logger.e("Error during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error occurred during logout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileItem(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not specified',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontFamily: 'Inter'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Avatar section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: _userProfile?['Avatar'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        '${dotenv.env['API_URL']}${_userProfile!['Avatar']}',
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Profile info
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildProfileItem('First Name', _userProfile?['FirstName']),
                            _buildProfileItem('Last Name', _userProfile?['LastName']),
                            _buildProfileItem('Email', _userProfile?['Email']),
                            _buildProfileItem('Phone', _userProfile?['Phone']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Buttons
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(50),
    backgroundColor: Colors.indigo,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: const Text('Change Password'),
),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _showLogoutDialog,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}