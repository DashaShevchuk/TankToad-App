import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<DeviceSettings> devices = [];
  bool isLoading = true;
  int currentDeviceIndex = 0;
  PageController _pageController = PageController(viewportFraction: 0.9);
  MapController mapController = MapController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}${dotenv.env['DEVICES_LIST']}102'),
        headers: {"accept": "text/plain"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          devices = decodedData.map((item) => DeviceSettings.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load devices');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

 void _onMarkerTapped(int index) {
    setState(() {
      currentDeviceIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    _animateToLocation(devices[index]);
  }

  void _animateToLocation(DeviceSettings device) {
    final latTween = Tween<double>(
      begin: mapController.center.latitude,
      end: device.latitude,
    );
    final lngTween = Tween<double>(
      begin: mapController.center.longitude,
      end: device.longitude,
    );

    _animationController.forward(from: 0);

    _animation.addListener(() {
      mapController.move(
        LatLng(latTween.evaluate(_animation), lngTween.evaluate(_animation)),
        mapController.zoom,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Map', style: TextStyle(color: Colors.black, fontFamily: 'Inter')),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: devices.isNotEmpty
                        ? LatLng(devices.first.latitude, devices.first.longitude)
                        : LatLng(50.4501, 30.5234),
                    zoom: 10.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: devices.asMap().entries.map((entry) {
                        int idx = entry.key;
                        DeviceSettings device = entry.value;
                        return Marker(
                          width: 40.0,
                          height: 40.0,
                          point: LatLng(device.latitude, device.longitude),
                          builder: (ctx) => GestureDetector(
                            onTap: () => _onMarkerTapped(idx),
                            child: MapMarker(device: device),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  height: 60,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: devices.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentDeviceIndex = index;
                      });
                      _animateToLocation(devices[index]);
                    },
                    itemBuilder: (context, index) {
                      return _buildDeviceCard(devices[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDeviceCard(DeviceSettings device) {
  return Card(
    margin: EdgeInsets.symmetric(horizontal: 8),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), 
      child: Row(
        children: [
          DeviceIcon(device: device, size: 40),
          SizedBox(width: 8), // Зменшено відстань між іконкою та текстом
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  device.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2), // Зменшено висоту між текстами
                Text(
                  device.getStatusText(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class MapMarker extends StatelessWidget {
  final DeviceSettings device;

  const MapMarker({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: DeviceIcon(device: device, size: 30.0), // Використання DeviceIcon
      ),
    );
  }
}

class DeviceIcon extends StatelessWidget {
  final DeviceSettings device;
  final double size;

  const DeviceIcon({Key? key, required this.device, this.size = 40}) : super(key: key);

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
      child: Icon(iconData, color: iconColor, size: size * 0.6),
    );
  }
}


class DeviceSettings {
  final int id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final double latitude;
  final double longitude;

  DeviceSettings({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    DeviceType type;
    DeviceStatus status;

    if (json['DeviceNickname'].toLowerCase().contains('sw')) {
      type = DeviceType.waterSensor;
    } else if (json['DeviceNickname'].toLowerCase().contains('mailbox')) {
      type = DeviceType.camera;
    } else {
      type = DeviceType.electromotor;
    }

    status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.warning;

    return DeviceSettings(
      id: json['Id'],
      name: json['DeviceNickname'] ?? 'Unknown Device',
      type: type,
      status: status,
      latitude: json['Latitude'],
      longitude: json['Longitude'],
    );
  }

  String getStatusText() {
    switch (type) {
      case DeviceType.waterSensor:
        return status == DeviceStatus.normal ? 'Рівень води в нормі' : 'Рівень води перевищує норму';
      case DeviceType.electromotor:
        return 'Працює';
      case DeviceType.camera:
        return status == DeviceStatus.normal ? 'Працює' : 'Offline';
    }
  }
}

enum DeviceType { waterSensor, electromotor, camera }
enum DeviceStatus { normal, warning, offline }