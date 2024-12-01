import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'device_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final dynamic userId;
  
  const HomeScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DeviceSettings> _deviceSettings = [];
  List<DeviceSettings> _filteredDeviceSettings = [];
  bool _isLoading = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    _fetchDeviceSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeviceSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
       final url = '${dotenv.env['API_URL']}${dotenv.env['DEVICES_LIST']}?userListId=${widget.userId}';
      logger.d("Fetching devices from URL: $url");
    
      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );
      logger.d("Request completed with status: ${response.statusCode}");
      logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          _deviceSettings = decodedData.map((item) => DeviceSettings.fromJson(item)).toList();
          _filteredDeviceSettings = _deviceSettings;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load device settings');
      }
    } catch (e) {
      logger.e("Error fetching devices: $e");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterDevices(String query) {
    setState(() {
      _filteredDeviceSettings = _deviceSettings
          .where((device) => device.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _navigateToDeviceDetails(DeviceSettings device) {
    logger.d("Navigating to device details. Device ID: ${device.id}, Name: ${device.name}");
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailsScreen(
          deviceId: device.id,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        title: _isSearching
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF757575),
                      fontFamily: 'Inter',
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF757575)),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _isSearching = false;
                          _filteredDeviceSettings = _deviceSettings;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Inter'),
                  onChanged: _filterDevices,
                  autofocus: true,
                ),
              )
            : const Text('Devices', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF757575)),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredDeviceSettings = _deviceSettings;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchDeviceSettings,
                    child: ListView.builder(
                      itemCount: _filteredDeviceSettings.length,
                      itemBuilder: (context, index) {
                        final device = _filteredDeviceSettings[index];
                        return _buildDeviceCard(device);
                      },
                    ),
                  ),
                ),
                _buildAddSensorsButton(),
              ],
            ),
    );
  }

  Widget _buildAddSensorsButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // TODO: Implement add sensors functionality
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.indigo[400], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add sensor',
                  style: TextStyle(
                    color: Colors.indigo[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

   Widget _buildDeviceCard(DeviceSettings device) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (device.type) {
      case DeviceType.waterSensor:
        iconData = Icons.water_drop;
        iconColor = Colors.blue;
        backgroundColor = Colors.blue.withOpacity(0.1);
        break;
      case DeviceType.electromotor:
        iconData = Icons.electric_bolt;
        iconColor = Colors.yellow;
        backgroundColor = Colors.yellow.withOpacity(0.1);
        break;
      case DeviceType.camera:
        iconData = Icons.camera_alt;
        iconColor = Colors.deepPurple;
        backgroundColor = Colors.deepPurple.withOpacity(0.1);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Card(
        color: Colors.white,
        elevation: 0,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor),
          ),
          title: Text(device.name),
          subtitle: Text(
            device.getStatusText(),
            style: TextStyle(
              color: device.status == DeviceStatus.normal
                  ? Colors.black54
                  : Colors.red,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF757575)),
          onTap: () => _navigateToDeviceDetails(device),
        ),
      ),
    );
  }
}

class DeviceIcon extends StatelessWidget {
  final DeviceSettings device;
  final double size;

  const DeviceIcon({
    Key? key,
    required this.device,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (device.type) {
      case DeviceType.waterSensor:
        iconData = Icons.water_drop;
        iconColor = Colors.blue;
        backgroundColor = Colors.blue.withOpacity(0.1);
        break;
      case DeviceType.electromotor:
        iconData = Icons.electric_bolt;
        iconColor = Colors.orange;
        backgroundColor = Colors.orange.withOpacity(0.1);
        break;
      case DeviceType.camera:
        iconData = Icons.camera_alt;
        iconColor = Colors.purple;
        backgroundColor = Colors.purple.withOpacity(0.1);
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: size * 0.6,
      ),
    );
  }
}

enum DeviceType { waterSensor, electromotor, camera }

enum DeviceStatus { normal, warning, offline }

class DeviceSettings {
  final dynamic id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final String? additionalInfo;

  DeviceSettings({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.additionalInfo,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    final logger = Logger();
    logger.d("Processing device JSON: $json");
    
    DeviceType type;
    DeviceStatus status;

    if (json['DeviceNickname'].toString().toLowerCase().contains('sw')) {
      type = DeviceType.waterSensor;
      status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.warning;
    } else if (json['DeviceNickname'].toString().toLowerCase().contains('mailbox')) {
      type = DeviceType.camera;
      status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.offline;
    } else {
      type = DeviceType.electromotor;
      status = DeviceStatus.normal;
    }

      switch (json['DeviceType']) {
      case 'Water sensor':
        type = DeviceType.waterSensor;
        status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.warning;
        break;
      case 'Camera':
        type = DeviceType.camera;
        status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.offline;
        break;
      case 'Electro motor':
        type = DeviceType.electromotor;
        status = DeviceStatus.normal;
        break;
      default:
        logger.w("Unknown device type: ${json['DeviceType']}");
        type = DeviceType.waterSensor;
        status = DeviceStatus.normal;
    }

    final deviceId = json['Id'];
    logger.d("Parsed device ID: $deviceId");

    if (deviceId == null) {
      logger.e("Device ID is null in JSON: $json");
    }

    return DeviceSettings(
      id: deviceId,
      name: json['DeviceNickname'] ?? 'Unknown Device',
      type: type,
      status: status,
      additionalInfo: type == DeviceType.electromotor ? '4.75 kWh' : null,
    );
  }

  String getStatusText() {
    switch (type) {
      case DeviceType.waterSensor:
        return status == DeviceStatus.normal
            ? 'Рівень води в нормі'
            : 'Рівень води перевищує норму';
      case DeviceType.electromotor:
        return 'Працює • ${additionalInfo ?? "0.00 kWh"}';
      case DeviceType.camera:
        return status == DeviceStatus.normal ? 'Працює' : 'Offline';
    }
  }
}