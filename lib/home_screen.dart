import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Set<String> _pinnedDeviceIds = {};
  DeviceType? _selectedFilter;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreDevices = true;
  int _currentPage = 1;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final logger = Logger();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadPinnedDevices().then((_) => _fetchDeviceSettings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreDevices && !_isSearching) {
        _loadMoreDevices();
      }
    }
  }

  Future<void> _loadPinnedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'pinned_devices_${widget.userId}';
      final pinnedIds = prefs.getStringList(key) ?? [];
      setState(() {
        _pinnedDeviceIds = Set.from(pinnedIds);
      });
    } catch (e) {
      logger.e("Error loading pinned devices: $e");
    }
  }

  Future<void> _savePinnedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'pinned_devices_${widget.userId}';
      await prefs.setStringList(key, _pinnedDeviceIds.toList());
    } catch (e) {
      logger.e("Error saving pinned devices: $e");
    }
  }

  // Future<void> _fetchDeviceSettings() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     final url = '${dotenv.env['API_URL']}${dotenv.env['DEVICES_LIST']}?userListId=${widget.userId}';
    
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {"accept": "application/json"},
  //     );

  //     if (response.statusCode == 200) {
  //       final List<dynamic> decodedData = json.decode(response.body);
  //       setState(() {
  //         _deviceSettings = decodedData.map((item) => DeviceSettings.fromJson(item)).toList();
  //         _updateFilteredDevices();
  //         _isLoading = false;
  //       });
  //     } else {
  //       throw Exception('Failed to load device settings');
  //     }
  //   } catch (e) {
  //     logger.e("Error fetching devices: $e");
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error: ${e.toString()}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

 Future<void> _fetchDeviceSettings() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreDevices = true;
      _deviceSettings = [];
    });

    try {
      final url = '${dotenv.env['API_URL']}${dotenv.env['DEVICES_LIST']}?userListId=${widget.userId}&pageNumber=1&pageSize=10';
      
      logger.d("Fetching devices from URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> decodedData;
        int totalPages = 1;
        
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('Data')) {
            decodedData = responseData['Data'] as List<dynamic>;
            totalPages = responseData['TotalPages'] as int;
          } else {
            logger.e("Response missing Data field: $responseData");
            throw Exception('Response missing Data field');
          }
        } else if (responseData is List) {
          decodedData = responseData;
          logger.d("+++++++++++++", decodedData);
        } else {
          logger.e("Unexpected response format: $responseData");
          throw Exception('Unexpected response format');
        }
        
        logger.d("Decoded data length: ${decodedData.length}");
        logger.d("Total pages: $totalPages");
        
        setState(() {
          _deviceSettings = decodedData.map((item) => DeviceSettings.fromJson(item)).toList();
          _updateFilteredDevices();
          _isLoading = false;
          _hasMoreDevices = _currentPage < totalPages;
        });
      } else {
        logger.e("Error response: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load device settings: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      logger.e("Error fetching devices: $e");
      logger.e("Stack trace: $stackTrace");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreDevices() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final url = '${dotenv.env['API_URL']}${dotenv.env['DEVICES_LIST']}?userListId=${widget.userId}&pageNumber=$nextPage&pageSize=10';
      
      logger.d("Loading more devices from URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> decodedData;
        int totalPages = 1;
        
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('Data')) {
            decodedData = responseData['Data'] as List<dynamic>;
            totalPages = responseData['TotalPages'] as int;
          } else {
            logger.e("Response missing Data field: $responseData");
            throw Exception('Response missing Data field');
          }
        } else if (responseData is List) {
          decodedData = responseData;
        } else {
          logger.e("Unexpected response format: $responseData");
          throw Exception('Unexpected response format');
        }
        
        logger.d("Decoded data length: ${decodedData.length}");
        logger.d("Total pages: $totalPages");
        
        if (decodedData.isEmpty) {
          setState(() {
            _hasMoreDevices = false;
            _isLoadingMore = false;
          });
          return;
        }

        final newDevices = decodedData.map((item) => DeviceSettings.fromJson(item)).toList();
        
        setState(() {
          _deviceSettings.addAll(newDevices);
          _currentPage = nextPage;
          _updateFilteredDevices();
          _isLoadingMore = false;
          _hasMoreDevices = nextPage < totalPages;
        });
      } else {
        logger.e("Error response: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load more devices: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      logger.e("Error loading more devices: $e");
      logger.e("Stack trace: $stackTrace");
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more devices: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  void _togglePinDevice(String deviceId) {
    setState(() {
      if (_pinnedDeviceIds.contains(deviceId)) {
        _pinnedDeviceIds.remove(deviceId);
      } else {
        _pinnedDeviceIds.add(deviceId);
      }
    });
    _savePinnedDevices();
    _updateFilteredDevices();
  }

  void _updateFilteredDevices() {
    final searchQuery = _searchController.text.toLowerCase();
    final List<DeviceSettings> pinnedDevices = [];
    final List<DeviceSettings> unpinnedDevices = [];

    for (var device in _deviceSettings) {
      bool matchesSearch = device.name.toLowerCase().contains(searchQuery);
      bool matchesType = _selectedFilter == null || device.type == _selectedFilter;
      
      if (matchesSearch && matchesType) {
        if (_pinnedDeviceIds.contains(device.id.toString())) {
          pinnedDevices.add(device);
        } else {
          unpinnedDevices.add(device);
        }
      }
    }

    setState(() {
      _filteredDeviceSettings = [...pinnedDevices, ...unpinnedDevices];
    });
  }

  void _filterDevices(String query) {
    _updateFilteredDevices();
  }


  void _navigateToDeviceDetails(DeviceSettings device) {
    logger.d("-------------------Navigating to device details. Device ID: ${device.id}, Name: ${device.name}, Type: ${device.type}");
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailsScreen(
           deviceId: device.id,
      userId: widget.userId,
      deviceType: device.type,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedFilter == null,
            onSelected: (bool selected) {
              setState(() {
                _selectedFilter = null;
                _updateFilteredDevices();
              });
            },
            backgroundColor: Colors.grey[100],
            selectedColor: Colors.indigo[100],
            checkmarkColor: Colors.indigo,
            labelStyle: TextStyle(
              color: _selectedFilter == null ? Colors.indigo : Colors.grey[700],
              fontWeight: _selectedFilter == null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Water Sensors'),
            selected: _selectedFilter == DeviceType.waterSensor,
            onSelected: (bool selected) {
              setState(() {
                _selectedFilter = selected ? DeviceType.waterSensor : null;
                _updateFilteredDevices();
              });
            },
            backgroundColor: Colors.grey[100],
            selectedColor: Colors.blue[100],
            showCheckmark: false, 
            labelStyle: TextStyle(
              color: _selectedFilter == DeviceType.waterSensor ? Colors.blue : Colors.grey[700],
              fontWeight: _selectedFilter == DeviceType.waterSensor ? FontWeight.bold : FontWeight.normal,
            ),
            avatar: _selectedFilter == DeviceType.waterSensor 
              ? const Icon(Icons.water_drop, size: 16, color: Colors.blue)
              : const Icon(Icons.water_drop, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Electromotors'),
            selected: _selectedFilter == DeviceType.electromotor,
            onSelected: (bool selected) {
              setState(() {
                _selectedFilter = selected ? DeviceType.electromotor : null;
                _updateFilteredDevices();
              });
            },
            backgroundColor: Colors.grey[100],
            selectedColor: Colors.yellow[100],
            showCheckmark: false, 
            labelStyle: TextStyle(
              color: _selectedFilter == DeviceType.electromotor ? Colors.orange : Colors.grey[700],
              fontWeight: _selectedFilter == DeviceType.electromotor ? FontWeight.bold : FontWeight.normal,
            ),
            avatar: _selectedFilter == DeviceType.electromotor 
              ? const Icon(Icons.electric_bolt, size: 16, color: Colors.orange)
              : const Icon(Icons.electric_bolt, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Cameras'),
            selected: _selectedFilter == DeviceType.camera,
            onSelected: (bool selected) {
              setState(() {
                _selectedFilter = selected ? DeviceType.camera : null;
                _updateFilteredDevices();
              });
            },
            backgroundColor: Colors.grey[100],
            selectedColor: Colors.deepPurple[100],
            showCheckmark: false, 
            labelStyle: TextStyle(
              color: _selectedFilter == DeviceType.camera ? Colors.deepPurple : Colors.grey[700],
              fontWeight: _selectedFilter == DeviceType.camera ? FontWeight.bold : FontWeight.normal,
            ),
            avatar: _selectedFilter == DeviceType.camera 
              ? const Icon(Icons.camera_alt, size: 16, color: Colors.deepPurple)
              : const Icon(Icons.camera_alt, size: 16, color: Colors.grey),
          ),
        ],
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
                          _updateFilteredDevices();
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
                  _updateFilteredDevices();
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
                const SizedBox(height: 8),
                _buildFilterChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchDeviceSettings,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredDeviceSettings.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredDeviceSettings.length) {
                          return _buildLoadingIndicator();
                        }
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
 Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
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

    final isPinned = _pinnedDeviceIds.contains(device.id.toString());

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
  subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: device.statusList.map((status) => Row(
    children: [
      if (status.status == DeviceStatus.danger || status.status == DeviceStatus.warning) ...[
        Icon(
          status.status == DeviceStatus.danger ? Icons.error : Icons.warning,
          color: status.getColor(),
          size: 16,
        ),
        const SizedBox(width: 4),
      ],
      Text(
        status.message,
        style: TextStyle(
          color: status.getColor(),
        ),
      ),
    ],
  )).toList(),
),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isPinned ? Icons.star : Icons.star_border,
                  color: isPinned ? Colors.amber : Colors.grey,
                ),
                onPressed: () => _togglePinDevice(device.id.toString()),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF757575)),
            ],
          ),
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

enum DeviceStatus { safe, warning, danger }

class DeviceSettings {
  final dynamic id;
  final String name;
  final DeviceType type;
  final List<StatusInfo> statusList;

  DeviceSettings({
    required this.id,
    required this.name,
    required this.type,
    required this.statusList,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    final type = switch (json['DeviceType']) {
      'Water sensor' => DeviceType.waterSensor,
      'Camera' => DeviceType.camera,
      'Pump' => DeviceType.electromotor,
      _ => DeviceType.waterSensor,
    };

    List<StatusInfo> statusList = [];
    if (json['Status'] is Map) {
      (json['Status'] as Map).forEach((message, level) {
        statusList.add(StatusInfo(
          message: message,
          status: switch (level) {
            2 => DeviceStatus.safe,
            1 => DeviceStatus.warning,
            0 => DeviceStatus.danger,
            _ => DeviceStatus.safe,
          }
        ));
      });
    }

    return DeviceSettings(
      id: json['Id'],
      name: json['DeviceNickname'] ?? 'Unknown Device',
      type: type,
      statusList: statusList,
    );
  }
}

class StatusInfo {
  final String message;
  final DeviceStatus status;

  StatusInfo({
    required this.message,
    required this.status,
  });

  Color getColor() {
    return switch (status) {
      DeviceStatus.danger => Colors.red,
      DeviceStatus.warning => Colors.orange,
      DeviceStatus.safe => Colors.black54,
    };
  }
}