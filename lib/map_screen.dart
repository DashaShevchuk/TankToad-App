import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'device_details_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
);

class MapScreen extends StatefulWidget {
  final dynamic userId;
  
  const MapScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

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
      final url = '${dotenv.env['API_URL']}${dotenv.env['DEVICES_LIST_MAP']}?userListId=${widget.userId}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          devices = decodedData.map((item) => DeviceSettings.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load devices: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onMarkerTapped(int index) {
    final device = devices[index];
   logger.i("💡 Active device: ${device.name}"
               "\n📍 Coordinates: (${device.latitude}, ${device.longitude})"
               "\n🔧 Type: ${device.type.toString().split('.').last}");
    
    setState(() {
      currentDeviceIndex = index;
    });
    
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    _animateToLocation(device);
  }

  void _animateToLocation(DeviceSettings device) {
    if (device.latitude == 0.0 && device.longitude == 0.0) {
      return;
    }

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
      final newLat = latTween.evaluate(_animation);
      final newLng = lngTween.evaluate(_animation);
      mapController.move(
        LatLng(newLat, newLng),
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
                    // TileLayer(
                    //   urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    //   subdomains: ['a', 'b', 'c'],
                    // ),
                    TileLayer(
  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
  subdomains: ['a', 'b', 'c', 'd'],
),

                  MarkerLayer(
  markers: devices.asMap().entries.map((entry) {
    int idx = entry.key;
    DeviceSettings device = entry.value;
    final isActive = currentDeviceIndex == idx;
    
    if (isActive) {
      logger.i("Active marker: ${device.name} at (${device.latitude}, ${device.longitude})");
    }
    
    return Marker(
      width: 50.0,
      height: 50.0,
      point: LatLng(device.latitude, device.longitude),
      builder: (ctx) => MapMarker(
        device: device,
        isActive: isActive,
        onTap: () => _onMarkerTapped(idx),
      ),
    );
  }).toList()..sort((a, b) {
    // Отримуємо індекси маркерів
    final indexA = devices.indexWhere((d) => 
      d.latitude == (a.point as LatLng).latitude && 
      d.longitude == (a.point as LatLng).longitude
    );
    final indexB = devices.indexWhere((d) => 
      d.latitude == (b.point as LatLng).latitude && 
      d.longitude == (b.point as LatLng).longitude
    );
    
    // Якщо один з маркерів активний, він повинен бути зверху
    if (indexA == currentDeviceIndex) return 1;  // a йде після b
    if (indexB == currentDeviceIndex) return -1; // b йде після a
    return 0; // порядок не важливий
  }),
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
                      final device = devices[index];
                      logger.i("Selected device: ${device.name} at (${device.latitude}, ${device.longitude})");
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetailsScreen(
              deviceId: device.id,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        elevation: 8,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                DeviceIcon(device: device, size: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.getStatusText(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MapMarker extends StatelessWidget {
  final DeviceSettings device;
  final VoidCallback onTap;
  final bool isActive;

  const MapMarker({
    Key? key, 
    required this.device,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

 @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: isActive ? 50.0 : 40.0,
              height: isActive ? 50.0 : 40.0,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: isActive 
                  ? Border.all(color: _getActiveColor(), width: 3)
                  : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: DeviceIcon(
                  device: device,
                  size: isActive ? 40.0 : 30.0
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getActiveColor() {
    switch (device.type) {
      case DeviceType.waterSensor:
        return Colors.blue;
      case DeviceType.electromotor:
        return Colors.orange;
      case DeviceType.camera:
        return Colors.purple;
    }
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

    switch (json['DeviceType']) {
      case 'Water sensor':
        type = DeviceType.waterSensor;
        status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.warning;
        break;
      case 'Camera':
        type = DeviceType.camera;
        status = json['Status'] == 2 ? DeviceStatus.normal : DeviceStatus.offline;
        break;
      case 'Pump':
        type = DeviceType.electromotor;
        status = DeviceStatus.normal;
        break;
      default:
        logger.i("Unknown device type: ${json['DeviceType']}");
        type = DeviceType.waterSensor;
        status = DeviceStatus.normal;
    }

    final latitude = (json['Latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (json['Longitude'] as num?)?.toDouble() ?? 0.0;

    return DeviceSettings(
      id: json['Id'] ?? 0,
      name: json['DeviceNickname']?.toString() ?? 'Unknown Device',
      type: type,
      status: status,
      latitude: latitude,
      longitude: longitude,
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