import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';

enum DeviceStatus { safe, warning, danger }

class DeviceDetailsScreen extends StatefulWidget {
  final dynamic deviceId;
  final dynamic userId;
  final dynamic deviceType;

  const DeviceDetailsScreen({
    Key? key,
    required this.deviceId,
    required this.userId,
    this.deviceType,
  }) : super(key: key);

  @override
  _DeviceDetailsScreenState createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _deviceInfo;
  List<Map<String, dynamic>> _chartData = [];
  final _logger = Logger();
  String? _error;
  List<String> _galleryImages = [];
  final int _imagesPerRow = 3;
  bool _autoMode = true;
final _minutesController = TextEditingController(text: '10');
  final List<String> _dateRanges = [
    '24 HOURS',
    '48 HOURS',
    '7 DAYS',
    '30 DAYS'
  ];
  String _selectedRange = '48 HOURS';
  DateTime _startDate = DateTime.now().subtract(const Duration(hours: 48));
  DateTime _endDate = DateTime.now();
  static const String _PLACEHOLDER_IMAGE = 'assets/images/no_image.png';
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _fetchDeviceInfo();
    _fetchTypeSpecificData();
  }

@override
void dispose() {
  _minutesController.dispose();
  super.dispose();
}

  IconData _getDeviceIcon(String? type) {
    switch (type) {
      case 'Water sensor':
        return Icons.water_drop;
      case 'Camera':
        return Icons.camera_alt;
      case 'Pump':
        return Icons.electric_bolt;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getDeviceColor(String? type) {
    switch (type) {
      case 'Water sensor':
        return Colors.blue;
      case 'Camera':
        return Colors.deepPurple;
      case 'Pump':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  DeviceStatus _getStatusFromValue(dynamic value) {
    if (value == 0) return DeviceStatus.danger;
    if (value == 1) return DeviceStatus.warning;
    return DeviceStatus.safe;
  }

  Color _getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.danger:
        return Colors.red;
      case DeviceStatus.warning:
        return Colors.orange;
      default:
        return Colors.black54;
    }
  }

  Future<void> _fetchTypeSpecificData() async {
    if (_deviceInfo == null) return;

    _logger.d("Device Type for specific data: ${_deviceInfo!['DeviceType']}");

    switch (_deviceInfo!['DeviceType']) {
      case 'Water sensor':
        await _fetchChartData();
        break;
      case 'Camera':
        await _fetchGalleryData();
        break;
      case 'Pump':
        break;
      default:
        _logger.w("Unsupported device type: ${_deviceInfo!['DeviceType']}");
        break;
    }
  }

  Future<void> _fetchGalleryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _galleryImages = [];
      });

      final formattedStartDate = _dateFormatter.format(_startDate);
      final formattedEndDate = _dateFormatter.format(_endDate);

      final url = '${dotenv.env['API_URL']}${dotenv.env['GET_IMAGES']}'
          '?deviceSettingId=${widget.deviceId}'
          '&dateFrom=$formattedStartDate'
          '&dateTo=$formattedEndDate';

      _logger.d("Fetching gallery data from URL: $url");
      _logger.d("dateTimeFrom: $formattedStartDate");
      _logger.d("dateTimeTo: $formattedEndDate");

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );

      if (!mounted) return;

      _logger.d("Gallery data request completed");
      _logger.d("Response status: ${response.statusCode}");
      _logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _galleryImages =
              data.map((item) => item['ImageUrl'] as String).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load gallery data');
      }
    } catch (e) {
      _logger.e("Error fetching gallery data: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDeviceInfo() async {
    try {
      final url =
          '${dotenv.env['API_URL']}${dotenv.env['DEVICE_INFO']}?id=${widget.deviceId}&userListId=${widget.userId}';
      _logger.d("Fetching device data from URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );

      _logger.d("Device info request completed");
      _logger.d("Response status: ${response.statusCode}");
      _logger.d("Raw response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.d("Decoded data: $data");

        final deviceInfo = data is List ? data.first : data;
        _logger.d("Device info: $deviceInfo");

        setState(() {
          _deviceInfo = deviceInfo;
          _isLoading = false;
          _error = null;
        });

        // Визначаємо тип пристрою та завантажуємо специфічні дані
        final deviceType = deviceInfo['DeviceType']?.toString();
        _logger.d("Device type: $deviceType");

        if (deviceType == 'Water sensor') {
          await _fetchChartData();
        } else if (deviceType == 'Camera') {
          await _fetchGalleryData();
        }
      } else {
        throw Exception(
            'Failed to load device info. Status: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e("Error fetching device info: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchChartData() async {
    try {
      if (!mounted) return;

      final formattedStartDate = _dateFormatter.format(_startDate);
      final formattedEndDate = _dateFormatter.format(_endDate);

      final url =
          '${dotenv.env['API_URL']}${dotenv.env['GET_WHATER_SENSOR_LEVEL_DATA']}'
          '?wm6_DeviceSettingId=${widget.deviceId}'
          '&dateTimeFrom=$formattedStartDate'
          '&dateTimeTo=$formattedEndDate';

      _logger.d("dateTimeFrom ", formattedStartDate);
      _logger.d("dateTimeTo ", formattedEndDate);

      _logger.d("Fetching chart data from URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );

      if (!mounted) return;
      _logger.d("Chart data request completed");
      _logger.d("Response status: ${response.statusCode}");
      _logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _chartData = data
              .map((item) => {
                    'waterLevel': item['WaterLevel'] ?? 0,
                    'batteryVoltage': item['BatteryVoltage'] ?? 0,
                    'timestamp': DateTime.parse(item['Timestamp']),
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to load chart data');
      }
    } catch (e) {
      _logger.e("Error fetching chart data: $e");
    }
  }

  Future<void> _updateDatesAndFetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_deviceInfo?['DeviceType'] == 'Water sensor') {
        _chartData = []; // Очищаємо дані графіка тільки для водного сенсора
        await _fetchChartData();
      } else if (_deviceInfo?['DeviceType'] == 'Camera') {
        _galleryImages = []; // Очищаємо дані галереї тільки для камери
        await _fetchGalleryData();
      }

      _logger.d(
          'Data refresh completed for date range: ${_dateFormatter.format(_startDate)} - ${_dateFormatter.format(_endDate)}');
    } catch (e) {
      _logger.e('Error updating data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          if (_deviceInfo?['DeviceType'] == 'Water sensor') {
            _chartData = [];
          } else if (_deviceInfo?['DeviceType'] == 'Camera') {
            _galleryImages = [];
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateCustomDateRange(DateTime? newStartDate, DateTime? newEndDate) {
    bool datesChanged = false;

    if (newStartDate != null) {
      setState(() {
        _startDate = DateTime(
          newStartDate.year,
          newStartDate.month,
          newStartDate.day,
          _startDate.hour,
          _startDate.minute,
        );
        _selectedRange = '';
      });
      datesChanged = true;
    }

    if (newEndDate != null) {
      setState(() {
        _endDate = DateTime(
          newEndDate.year,
          newEndDate.month,
          newEndDate.day,
          _endDate.hour,
          _endDate.minute,
        );
        _selectedRange = '';
      });
      datesChanged = true;
    }

    if (datesChanged) {
      _logger.d(
          'Custom date range updated: ${_dateFormatter.format(_startDate)} - ${_dateFormatter.format(_endDate)}');
      _updateDatesAndFetchData();
    }
  }

  void _updateDateRange(String range) async {
    if (range.isEmpty) {
      setState(() {
        _selectedRange = range;
      });
      return;
    }

    DateTime newEndDate = DateTime.now();
    late DateTime newStartDate;

    switch (range) {
      case '24 HOURS':
        newStartDate = newEndDate.subtract(const Duration(hours: 24));
        break;
      case '48 HOURS':
        newStartDate = newEndDate.subtract(const Duration(hours: 48));
        break;
      case '7 DAYS':
        newStartDate = newEndDate.subtract(const Duration(days: 7));
        break;
      case '30 DAYS':
        newStartDate = newEndDate.subtract(const Duration(days: 30));
        break;
      default:
        return;
    }

    setState(() {
      _selectedRange = range;
      _startDate = newStartDate;
      _endDate = newEndDate;
    });

    _logger.d('Date range updated:');
    _logger.d('Start date: ${_dateFormatter.format(_startDate)}');
    _logger.d('End date: ${_dateFormatter.format(_endDate)}');

    await _updateDatesAndFetchData();
  }

  Widget _buildStatusCard() {
    if (_deviceInfo == null || !(_deviceInfo?['Status'] is Map))
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              (_deviceInfo!['Status'] as Map).entries.map<Widget>((entry) {
            final status = _getStatusFromValue(entry.value);
            return Row(
              children: [
                if (status == DeviceStatus.danger ||
                    status == DeviceStatus.warning) ...[
                  Icon(
                    status == DeviceStatus.danger ? Icons.error : Icons.warning,
                    color: status == DeviceStatus.danger
                        ? Colors.red
                        : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  entry.key,
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 14,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRange,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ..._dateRanges.map((String range) {
                        return DropdownMenuItem<String>(
                          value: range,
                          child: Text(
                            range,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _updateDateRange(
                            newValue); // This will now properly trigger data refresh
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Start date field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'From:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(_startDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: _endDate,
                        );
                        if (picked != null && picked != _startDate) {
                          _updateCustomDateRange(picked, null);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // End date field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(_endDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != _endDate) {
                          _updateCustomDateRange(null, picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double calculateBatteryPercentage() {
    if (_deviceInfo == null) return 0.0;

    final voltage = _deviceInfo!['BatteryVoltage']?.toDouble() ?? 0.0;
    final maxVoltage = _deviceInfo!['BatteryHighLevel']?.toDouble() ?? 0.0;
    final minVoltage = _deviceInfo!['BatteryLowLevel']?.toDouble() ?? 0.0;

    if (maxVoltage <= minVoltage) return 0.0;
    return ((voltage - minVoltage) / (maxVoltage - minVoltage));
  }

  double calculateWaterPercentage() {
    if (_deviceInfo == null) return 0.0;

    final level = _deviceInfo!['WaterConverted']?.toDouble() ?? 0.0;
    final maxLevel = _deviceInfo!['WaterHighLevel']?.toDouble() ?? 0.0;
    final minLevel = _deviceInfo!['WaterLowLevel']?.toDouble() ?? 0.0;

    if (maxLevel <= minLevel) return 0.0;
    return ((level - minLevel) / (maxLevel - minLevel));
  }

Widget _buildMetricCard(String title, String value, IconData icon, Color color, [String? range]) {
  String? minValue;
  String? maxValue;
  double? current;
  double? min;
  double? max;

  if (title == 'Level') {
    current = _deviceInfo?['WaterConverted']?.toDouble();
    min = _deviceInfo?['WaterLowLevel']?.toDouble();
    max = _deviceInfo?['WaterHighLevel']?.toDouble();
    minValue = '${min?.toStringAsFixed(2)} ${_deviceInfo?['SensorUnits']}';
    maxValue = '${max?.toStringAsFixed(2)} ${_deviceInfo?['SensorUnits']}';
  } else if (title == 'Battery') {
    current = _deviceInfo?['BatteryVoltage']?.toDouble();
    min = _deviceInfo?['BatteryLowLevel']?.toDouble();
    max = _deviceInfo?['BatteryHighLevel']?.toDouble();
    minValue = '${min?.toStringAsFixed(2)} V';
    maxValue = '${max?.toStringAsFixed(2)} V';
  }

  // Calculate progress
  double? progress;
  if (current != null && min != null && max != null) {
    // if (title == 'Level') {
    //   // Normalize values between 0 and 1
    //   progress = (max - current) / (max - min);
    // } else {
    //   // For battery, normalize between min and max
    //   progress = (current - min) / (max - min);
    // }
    progress = (max - current) / (max - min);
    progress = progress.clamp(0.0, 1.0);
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Icon(icon, color: color, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (progress != null && minValue != null && maxValue != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minValue, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(maxValue, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
  Widget _buildMetricsGrid() {
    try {
      final waterLevel = (_deviceInfo?['WaterConverted'] ?? 0.0).toDouble();
      final batteryVoltage = (_deviceInfo?['BatteryVoltage'] ?? 0.0).toDouble();

      final waterPercentage =
          (calculateWaterPercentage() * 100).clamp(0.0, 100.0);
      final batteryPercentage =
          (calculateBatteryPercentage() * 100).clamp(0.0, 100.0);

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Level',
                    '${waterLevel.toStringAsFixed(2)} ${_deviceInfo!['SensorUnits']}',
                    Icons.water_drop,
                    Colors.blue,
                    '${waterPercentage.toStringAsFixed(0)}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Battery',
                    '${batteryVoltage.toStringAsFixed(2)} V',
                    Icons.battery_full,
                    Colors.green,
                    '${batteryPercentage.toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'High level',
                    '${(_deviceInfo?['WaterHighLevel'] ?? 0.0).toStringAsFixed(2)} ${_deviceInfo!['SensorUnits']}',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Low level',
                    '${(_deviceInfo?['WaterLowLevel'] ?? 0.0).toStringAsFixed(2)} ${_deviceInfo!['SensorUnits']}',
                    Icons.trending_down,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.e("Error building metrics grid: $e");
      return const Center(child: Text('Error loading metrics'));
    }
  }

  Widget _buildChart() {
    if (_isLoading) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_chartData.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No data available for selected period',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Розрахунок відстані між точками залежно від періоду
    final periodInDays = _endDate.difference(_startDate).inDays;
    final dataLength = _chartData.length;
    int skipPoints;

    if (periodInDays > 30) {
      skipPoints = (dataLength / 40).ceil(); // ~40 точок для довгих періодів
    } else if (periodInDays > 7) {
      skipPoints = (dataLength / 25).ceil(); // ~25 точок для середніх періодів
    } else if (periodInDays > 2) {
      skipPoints = (dataLength / 15).ceil(); // ~15 точок для тижня
    } else {
      skipPoints = (dataLength / 10).ceil(); // ~10 точок для коротких періодів
    }

    // Створюємо відфільтровані точки для графіка
    final spots = <FlSpot>[];
    for (int i = 0; i < _chartData.length; i += skipPoints) {
      spots.add(FlSpot(
        i.toDouble(),
        _chartData[i]['waterLevel'].toDouble(),
      ));
    }

    // Завжди додаємо останню точку, якщо вона ще не додана
    if (_chartData.isNotEmpty &&
        spots.last.x != (_chartData.length - 1).toDouble()) {
      spots.add(FlSpot(
        (_chartData.length - 1).toDouble(),
        _chartData.last['waterLevel'].toDouble(),
      ));
    }

    // Оптимізація діапазону значень для осі Y
    double minY = _chartData
        .map((data) => data['waterLevel'] as num)
        .reduce(min)
        .toDouble();
    double maxY = _chartData
        .map((data) => data['waterLevel'] as num)
        .reduce(max)
        .toDouble();

    final valueRange = maxY - minY;
    final padding = valueRange * 0.1; // 10% відступ

    minY = (minY - padding).floorToDouble();
    maxY = (maxY + padding).ceilToDouble();

    final range = maxY - minY;
    double interval;

    if (range <= 10) {
      interval = 1;
    } else if (range <= 50) {
      interval = 5;
    } else if (range <= 100) {
      interval = 10;
    } else if (range <= 500) {
      interval = 50;
    } else if (range <= 1000) {
      interval = 100;
    } else {
      interval = (range / 5).roundToDouble(); // 5 інтервалів
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  // Не показуємо мітку, якщо вона виходить за межі діапазону
                  if (value < minY || value > maxY) {
                    return const SizedBox.shrink();
                  }
                  // Округляємо значення до цілого числа
                  return Text(
                    value.round().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: Colors.blue,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueAccent,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final date =
                      _chartData[flSpot.x.toInt()]['timestamp'] as DateTime;
                  return LineTooltipItem(
                    '${DateFormat('dd.MM HH:mm').format(date)}\n${flSpot.y.toStringAsFixed(1)} cm',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Row _buildWellButtons() {
  return Row(
    children: [
      Expanded(
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.play_arrow, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'WELL ON',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.stop, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'WELL OFF',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildPumpControls() {
 return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Manual mode',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            TextFormField(
              initialValue: 'AC-118',
              enabled: true,
              decoration: const InputDecoration(
                labelText: 'Master device',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '112',
                    enabled: true,
                    decoration: const InputDecoration(
                      labelText: 'Well ON',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: '110',
                    enabled: true,
                    decoration: const InputDecoration(
                      labelText: 'Well OFF',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto mode'),
              value: _autoMode,
              onChanged: (value) => setState(() => _autoMode = value),
            ),
            // const SizedBox(height: 16),
            // Row(
            //   children: [
            //     // Expanded(
            //     //   child: ElevatedButton.icon(
            //     //     onPressed: () {},
            //     //     icon: const Icon(Icons.play_arrow),
            //     //     label: const Text('WELL ON'),
            //     //     style: ElevatedButton.styleFrom(
            //     //       backgroundColor: Colors.green,
            //     //       foregroundColor: Colors.white,
            //     //       padding: const EdgeInsets.all(16),
            //     //     ),
            //     //   ),
            //     // ),
            //     // const SizedBox(width: 16),
            //     // SizedBox(
            //     //   width: 100,
            //     //   child: TextFormField(
            //     //     controller: _minutesController,
            //     //     decoration: const InputDecoration(
            //     //       labelText: 'Minutes',
            //     //       border: OutlineInputBorder(),
            //     //     ),
            //     //     keyboardType: TextInputType.number,
            //     //   ),
            //     // ),
            //   ],
            // ),
            // const SizedBox(height: 16),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     onPressed: () {},
            //     icon: const Icon(Icons.stop),
            //     label: const Text('WELL OFF'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.red,
            //       foregroundColor: Colors.white,
            //       padding: const EdgeInsets.all(16),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),
_buildWellButtons(),
const SizedBox(height: 16),
SizedBox(
  width: 100,
  child: TextFormField(
    controller: _minutesController,
    decoration: const InputDecoration(
      labelText: 'Minutes',
      border: OutlineInputBorder(),
    ),
    keyboardType: TextInputType.number,
    textAlign: TextAlign.center,
  ),
),
          ],
        ),
      ),
    ],
  );
}
  Widget _buildDeviceSpecificContent() {
    if (_deviceInfo == null) {
      _logger.w("Device info is null");
      return const SizedBox.shrink();
    }

    final deviceType = _deviceInfo!['DeviceType']?.toString();
    _logger.d("Building content for device type: $deviceType");

    switch (deviceType) {
      case 'Water sensor':
        return Column(
          children: [
            _buildMetricsGrid(),
            const SizedBox(height: 16),
            _buildDateRangeSelector(),
            const SizedBox(height: 8),
            _buildChart(),
          ],
        );
      case 'Camera':
        return Column(
          children: [
            _buildDateRangeSelector(),
            const SizedBox(height: 16),
            _buildGallery(),
          ],
        );

         case 'Pump':
        return Column(
          children: [
            _buildPumpControls(),
          ],
        );
      default:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Device type "$deviceType" is not supported for detailed view',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildGallery() {
    if (_isLoading) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_galleryImages.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No images available for selected period',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Збільшуємо кількість колонок назад до 3
          crossAxisSpacing: 4, // Зменшуємо відступи
          mainAxisSpacing: 4,
          childAspectRatio: 1, // Квадратні зображення
        ),
        itemCount: _galleryImages.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => _showImageDialog(index),
            child: Hero(
              tag: 'gallery_image_$index',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    _galleryImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        // Прибираємо відступи діалогу
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Затемнений фон
            Container(color: Colors.black.withOpacity(0.9)),

            // Зображення з можливістю взаємодії
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Hero(
                  tag: 'gallery_image_$index',
                  child: Center(
                    child: Container(
                      // Встановлюємо максимальні розміри для фото
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      // Додаємо відступи тільки зверху і знизу для кнопки і дати
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Image.network(
                        _galleryImages[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Кнопка закриття
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Дата знизу
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(
                      DateTime.now(), // TODO: Додати реальну дату з API
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        title: Row(
          children: [
            if (_deviceInfo != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getDeviceColor(_deviceInfo!['DeviceType'])
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getDeviceIcon(_deviceInfo!['DeviceType']),
                  color: _getDeviceColor(_deviceInfo!['DeviceType']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _deviceInfo?['DeviceNickname'] ?? 'Device Details',
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _fetchDeviceInfo();
              _fetchTypeSpecificData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _fetchDeviceInfo();
                          _fetchTypeSpecificData();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      _buildDeviceSpecificContent(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}
