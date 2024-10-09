import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DeviceSettings> _deviceSettings = [];
  List<DeviceSettings> _filteredDeviceSettings = [];
  bool _isLoading = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  var logger = Logger();

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
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}${dotenv.env['DEVICES_LIST']}102'),
        headers: {"accept": "text/plain"},
      );
      logger.d("Request completed");
      logger.d(response.body);

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
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _filterDevices(String query) {
    setState(() {
      _filteredDeviceSettings = _deviceSettings
          .where((device) => device.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
                  hintStyle: TextStyle(
                    color: Color(0xFF757575),
                    fontFamily: 'Inter',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                style: TextStyle(fontFamily: 'Inter'),
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
          trailing: const Icon(Icons.more_vert),
        ),
      ),
    );
  }
}

enum DeviceType { waterSensor, electromotor, camera }

enum DeviceStatus { normal, warning, offline }

class DeviceSettings {
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final String? additionalInfo;

  DeviceSettings({
    required this.name,
    required this.type,
    required this.status,
    this.additionalInfo,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    DeviceType type;
    DeviceStatus status;

    if (json['DeviceNickname'].toLowerCase().contains('sw')) {
      type = DeviceType.waterSensor;
      status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.warning;
    } else if (json['DeviceNickname'].toLowerCase().contains('mailbox')) {
      type = DeviceType.camera;
      status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.offline;
    } else {
      type = DeviceType.electromotor;
      status = DeviceStatus.normal;
    }

    return DeviceSettings(
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
