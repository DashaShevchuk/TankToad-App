// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:logger/logger.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:convert';

// class DeviceDetailsScreen extends StatefulWidget {
//   final dynamic deviceId;
//   final dynamic userId;

//   const DeviceDetailsScreen({
//     Key? key,
//     required this.deviceId,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   _DeviceDetailsScreenState createState() => _DeviceDetailsScreenState();
// }

// class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
//   bool _isLoading = true;
//   Map<String, dynamic>? _deviceInfo;
//   final _logger = Logger();
//   String? _error;

//   final List<String> _dateRanges = [
//     '24 HOURS',
//     '48 HOURS',
//     '7 DAYS',
//     '30 DAYS'
//   ];
//   String _selectedRange = '48 HOURS';
//   DateTime _startDate = DateTime.now().subtract(const Duration(hours: 48));
//   DateTime _endDate = DateTime.now();

//   final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss.000');

//   @override
//   void initState() {
//     super.initState();
//     _fetchDeviceInfo();
//   }

//   Future<void> _fetchDeviceInfo() async {
//     try {
//       final formattedStartDate = _dateFormatter.format(_startDate);
//       final formattedEndDate = _dateFormatter.format(_endDate);

//       final url =
//           '${dotenv.env['API_URL']}${dotenv.env['DEVICE_INFO']}?id=${widget.deviceId}&userListId=${widget.userId}';
//       _logger.d("Fetching device data from URL: $url");

//       final response = await http.get(
//         Uri.parse(url),
//         headers: {"accept": "application/json"},
//       );

//       _logger.d("Device info request completed");
//       _logger.d("Response status: ${response.statusCode}");
//       _logger.d("Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final deviceInfo = data is List ? data.first : data;

//         setState(() {
//           _deviceInfo = deviceInfo;
//           _isLoading = false;
//           _error = null;
//         });
//       } else {
//         throw Exception('Failed to load device info');
//       }
//     } catch (e) {
//       _logger.e("Error fetching device info: $e");
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   void _updateDateRange(String range) {
//     setState(() {
//       _selectedRange = range;
//       _endDate = DateTime.now();

//       switch (range) {
//         case '24 HOURS':
//           _startDate = _endDate.subtract(const Duration(hours: 24));
//           break;
//         case '48 HOURS':
//           _startDate = _endDate.subtract(const Duration(hours: 48));
//           break;
//         case '7 DAYS':
//           _startDate = _endDate.subtract(const Duration(days: 7));
//           break;
//         case '30 DAYS':
//           _startDate = _endDate.subtract(const Duration(days: 30));
//           break;
//       }
//     });

//     _logger.d(
//         'Date range updated: ${_startDate.toIso8601String()} - ${_endDate.toIso8601String()}');
//     // TODO: Тут можна додати запит на оновлення даних графіка
//   }

//   double calculateWaterPercentage() {
//     if (_deviceInfo == null) return 0;

//     try {
//       // Отримуємо значення і перевіряємо на null
//       final currentLevel = _deviceInfo!['WatherConverted'];
//       final maxLevel = _deviceInfo!['WaterHighLevel'];
//       final minLevel = _deviceInfo!['WaterLowLevel'];

//       // Якщо якесь значення відсутнє, повертаємо 0
//       if (currentLevel == null || maxLevel == null || minLevel == null) {
//         return 0.0;
//       }

//       // Конвертуємо всі значення в double
//       final currentLevelDouble = currentLevel is int
//           ? currentLevel.toDouble()
//           : (currentLevel as double);
//       final maxLevelDouble =
//           maxLevel is int ? maxLevel.toDouble() : (maxLevel as double);
//       final minLevelDouble =
//           minLevel is int ? minLevel.toDouble() : (minLevel as double);

//       // Перевіряємо, щоб не було ділення на нуль
//       if (maxLevelDouble == minLevelDouble) return 0.0;

//       return ((currentLevelDouble - minLevelDouble) /
//               (maxLevelDouble - minLevelDouble) *
//               100)
//           .clamp(0.0, 100.0);
//     } catch (e) {
//       _logger.e("Error calculating water percentage: $e");
//       return 0.0;
//     }
//   }

//   double calculateBatteryPercentage() {
//     if (_deviceInfo == null) return 0;

//     try {
//       // Отримуємо значення і перевіряємо на null
//       final voltage = _deviceInfo!['BatteryVoltage'];
//       final maxVoltage = _deviceInfo!['BatteryHighLevel'];
//       final minVoltage = _deviceInfo!['BatteryLowLevel'];

//       // Якщо якесь значення відсутнє, повертаємо 0
//       if (voltage == null || maxVoltage == null || minVoltage == null) {
//         return 0.0;
//       }

//       // Конвертуємо всі значення в double
//       final voltageDouble =
//           voltage is int ? voltage.toDouble() : (voltage as double);
//       final maxVoltageDouble =
//           maxVoltage is int ? maxVoltage.toDouble() : (maxVoltage as double);
//       final minVoltageDouble =
//           minVoltage is int ? minVoltage.toDouble() : (minVoltage as double);

//       // Перевіряємо, щоб не було ділення на нуль
//       if (maxVoltageDouble == minVoltageDouble) return 0.0;

//       return ((voltageDouble - minVoltageDouble) /
//               (maxVoltageDouble - minVoltageDouble) *
//               100)
//           .clamp(0.0, 100.0);
//     } catch (e) {
//       _logger.e("Error calculating battery percentage: $e");
//       return 0.0;
//     }
//   }

//   Widget _buildMetricsGrid() {
//     try {
//       // Безпечне отримання значень
//       final waterLevel = _deviceInfo?['WatherConverted'];
//       final waterLevelDouble = waterLevel != null
//           ? (waterLevel is int ? waterLevel.toDouble() : waterLevel as double)
//           : 0.0;

//       final batteryLevel = calculateBatteryPercentage();
//       final waterPercentage = calculateWaterPercentage();

//       return Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildMetricCard(
//                     'Level',
//                     '${waterLevelDouble.toStringAsFixed(1)} cm',
//                     Icons.water_drop,
//                     Colors.blue,
//                     '${waterPercentage.toStringAsFixed(0)}%',
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildMetricCard(
//                     'Battery',
//                     '${_deviceInfo?['BatteryVoltage'] ?? 0} mV',
//                     Icons.battery_full,
//                     Colors.green,
//                     '${batteryLevel.toStringAsFixed(0)}%',
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildMetricCard(
//                     'High level',
//                     '${(_deviceInfo?['WaterHighLevel'] ?? 0)} cm',
//                     Icons.trending_up,
//                     Colors.orange,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildMetricCard(
//                     'Low level',
//                     '${(_deviceInfo?['WaterLowLevel'] ?? 0)} cm',
//                     Icons.trending_down,
//                     Colors.purple,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     } catch (e) {
//       _logger.e("Error building metrics grid: $e");
//       return const Center(child: Text('Error loading metrics'));
//     }
//   }

//   Widget _buildDateRangeSelector() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '${DateFormat('E dd MMM').format(_startDate)} - ${DateFormat('E dd MMM').format(_endDate)}',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Row(
//                 children: [
//                   Icon(Icons.access_time, size: 16, color: Colors.white),
//                   const SizedBox(width: 4),
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: _selectedRange,
//                         isDense: true,
//                         items: _dateRanges.map((String range) {
//                           return DropdownMenuItem<String>(
//                             value: range,
//                             child: Text(
//                               range,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[800],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (String? newValue) {
//                           if (newValue != null) {
//                             _updateDateRange(newValue);
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricCard(
//       String title, String value, IconData icon, Color color,
//       [String? percentage]) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   color: Colors.grey,
//                   fontSize: 14,
//                 ),
//               ),
//               Icon(icon, color: color, size: 20),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           if (percentage != null) ...[
//             const SizedBox(height: 4),
//             Container(
//               width: double.infinity,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//               child: FractionallySizedBox(
//                 alignment: Alignment.centerLeft,
//                 widthFactor: double.parse(percentage.replaceAll('%', '')) / 100,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: color,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               percentage,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildChart() {
//     return Container(
//       height: 300,
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: LineChart(
//         LineChartData(
//           gridData: FlGridData(
//             show: true,
//             drawVerticalLine: true,
//             horizontalInterval: 50,
//             verticalInterval: 1,
//           ),
//           titlesData: FlTitlesData(
//             show: true,
//             topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 getTitlesWidget: (value, meta) {
//                   return Text(
//                     value.toInt().toString(),
//                     style: const TextStyle(
//                       color: Colors.grey,
//                       fontSize: 10,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           borderData: FlBorderData(show: false),
//           lineBarsData: [
//             LineChartBarData(
//               spots: [
//                 const FlSpot(0, 150),
//                 const FlSpot(1, 140),
//                 const FlSpot(2, 120),
//                 const FlSpot(3, 80),
//                 const FlSpot(4, 50),
//               ],
//               isCurved: true,
//               color: Colors.blue,
//               barWidth: 2,
//               dotData: FlDotData(show: false),
//               belowBarData: BarAreaData(
//                 show: true,
//                 color: Colors.blue.withOpacity(0.1),
//               ),
//             ),
//           ],
//           lineTouchData: LineTouchData(
//             touchTooltipData: LineTouchTooltipData(
//               tooltipBgColor: Colors.blueAccent,
//               getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
//                 return touchedBarSpots.map((barSpot) {
//                   final flSpot = barSpot;
//                   return LineTooltipItem(
//                     '${flSpot.y.toStringAsFixed(1)} cm',
//                     const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   );
//                 }).toList();
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: Text(
//           _deviceInfo?['DeviceNickname'] ?? 'Device Details',
//           style: const TextStyle(color: Colors.black, fontSize: 20),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.black),
//             onPressed: _fetchDeviceInfo,
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert, color: Colors.black),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.error_outline,
//                           color: Colors.red, size: 48),
//                       const SizedBox(height: 16),
//                       Text(_error!, style: const TextStyle(color: Colors.red)),
//                       const SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: _fetchDeviceInfo,
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 )
//               : SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildMetricsGrid(),
//                       const SizedBox(height: 16),
//                       _buildDateRangeSelector(), // Додаємо селектор дат
//                       const SizedBox(height: 8),
//                       _buildChart(),
//                       const SizedBox(height: 16),
//                     ],
//                   ),
//                 ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';

class DeviceDetailsScreen extends StatefulWidget {
  final dynamic deviceId;
  final dynamic userId;
  
  const DeviceDetailsScreen({
    Key? key,
    required this.deviceId,
    required this.userId,
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

  final List<String> _dateRanges = ['24 HOURS', '48 HOURS', '7 DAYS', '30 DAYS'];
  String _selectedRange = '48 HOURS';
  DateTime _startDate = DateTime.now().subtract(const Duration(hours: 48));
  DateTime _endDate = DateTime.now();
  
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss.000');

  // Constants for API endpoints
  static const String _DEVICE_INFO_ENDPOINT = 'DEVICE_INFO';
  static const String _CHART_DATA_ENDPOINT = 'GET_WHATER_SENSOR_LEVEL_DATA';

  @override
  void initState() {
    super.initState();
    _fetchDeviceInfo();
    _fetchChartData();
  }

  Future<void> _fetchDeviceInfo() async {
    try {
      final url = '${dotenv.env['API_URL']}${dotenv.env[_DEVICE_INFO_ENDPOINT]}?id=${widget.deviceId}&userListId=${widget.userId}';
      _logger.d("Fetching device data from URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );

      _logger.d("Device info request completed");
      _logger.d("Response status: ${response.statusCode}");
      _logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final deviceInfo = data is List ? data.first : data;

        setState(() {
          _deviceInfo = deviceInfo;
          _isLoading = false;
          _error = null;
        });
      } else {
        throw Exception('Failed to load device info');
      }
    } catch (e) {
      _logger.e("Error fetching device info: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchChartData() async {
    try {
      final formattedStartDate = _dateFormatter.format(_startDate);
      final formattedEndDate = _dateFormatter.format(_endDate);

      final url = '${dotenv.env['API_URL']}$_CHART_DATA_ENDPOINT'
          '?wm6_DeviceSettingId=${widget.deviceId}'
          '&dateTimeFrom=$formattedStartDate'
          '&dateTimeTo=$formattedEndDate';

      _logger.d("Fetching chart data from URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"accept": "application/json"},
      );

      _logger.d("Chart data request completed");
      _logger.d("Response status: ${response.statusCode}");
      _logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _chartData = data.map((item) => {
            'waterLevel': item['WaterLevel'] ?? 0,
            'batteryVoltage': item['BatteryVoltage'] ?? 0,
            'timestamp': DateTime.parse(item['Timestamp']),
          }).toList();
        });
      } else {
        throw Exception('Failed to load chart data');
      }
    } catch (e) {
      _logger.e("Error fetching chart data: $e");
    }
  }

 void _updateDateRange(String range) {
    setState(() {
      _selectedRange = range;
      _endDate = DateTime.now();
      
      if (range.isEmpty) {
        // Якщо вибрано "Custom", не змінюємо дати
        return;
      }
      
      switch (range) {
        case '24 HOURS':
          _startDate = _endDate.subtract(const Duration(hours: 24));
          break;
        case '48 HOURS':
          _startDate = _endDate.subtract(const Duration(hours: 48));
          break;
        case '7 DAYS':
          _startDate = _endDate.subtract(const Duration(days: 7));
          break;
        case '30 DAYS':
          _startDate = _endDate.subtract(const Duration(days: 30));
          break;
      }
    });
    
    _logger.d('Date range updated: ${_dateFormatter.format(_startDate)} - ${_dateFormatter.format(_endDate)}');
    // Оновлюємо обидва набори даних
    _fetchDeviceInfo();
    _fetchChartData();
  }

  double calculateWaterPercentage() {
    if (_deviceInfo == null) return 0;

    try {
      final currentLevel = _deviceInfo!['WatherConverted'];
      final maxLevel = _deviceInfo!['WaterHighLevel'];
      final minLevel = _deviceInfo!['WaterLowLevel'];
      
      if (currentLevel == null || maxLevel == null || minLevel == null) {
        return 0.0;
      }

      final currentLevelDouble = currentLevel is int ? currentLevel.toDouble() : (currentLevel as double);
      final maxLevelDouble = maxLevel is int ? maxLevel.toDouble() : (maxLevel as double);
      final minLevelDouble = minLevel is int ? minLevel.toDouble() : (minLevel as double);
      
      if (maxLevelDouble == minLevelDouble) return 0.0;
      
      return ((currentLevelDouble - minLevelDouble) / (maxLevelDouble - minLevelDouble) * 100)
          .clamp(0.0, 100.0);
    } catch (e) {
      _logger.e("Error calculating water percentage: $e");
      return 0.0;
    }
  }

  double calculateBatteryPercentage() {
    if (_deviceInfo == null) return 0;

    try {
      final voltage = _deviceInfo!['BatteryVoltage'];
      final maxVoltage = _deviceInfo!['BatteryHighLevel'];
      final minVoltage = _deviceInfo!['BatteryLowLevel'];
      
      if (voltage == null || maxVoltage == null || minVoltage == null) {
        return 0.0;
      }

      final voltageDouble = voltage is int ? voltage.toDouble() : (voltage as double);
      final maxVoltageDouble = maxVoltage is int ? maxVoltage.toDouble() : (maxVoltage as double);
      final minVoltageDouble = minVoltage is int ? minVoltage.toDouble() : (minVoltage as double);
      
      if (maxVoltageDouble == minVoltageDouble) return 0.0;
      
      return ((voltageDouble - minVoltageDouble) / (maxVoltageDouble - minVoltageDouble) * 100)
          .clamp(0.0, 100.0);
    } catch (e) {
      _logger.e("Error calculating battery percentage: $e");
      return 0.0;
    }
  }

  Widget _buildMetricsGrid() {
    try {
      final waterLevel = _deviceInfo?['WatherConverted'];
      final waterLevelDouble = waterLevel != null 
          ? (waterLevel is int ? waterLevel.toDouble() : waterLevel as double)
          : 0.0;

      final batteryLevel = calculateBatteryPercentage();
      final waterPercentage = calculateWaterPercentage();

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Level',
                    '${waterLevelDouble.toStringAsFixed(1)} cm',
                    Icons.water_drop,
                    Colors.blue,
                    '${waterPercentage.toStringAsFixed(0)}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Battery',
                    '${_deviceInfo?['BatteryVoltage'] ?? 0} mV',
                    Icons.battery_full,
                    Colors.green,
                    '${batteryLevel.toStringAsFixed(0)}%',
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
                    '${(_deviceInfo?['WaterHighLevel'] ?? 0)} cm',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Low level',
                    '${(_deviceInfo?['WaterLowLevel'] ?? 0)} cm',
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
              Expanded(
                child: Row(
                  children: [
                    // Поле для початкової дати
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: DateFormat('dd.MM.yyyy').format(_startDate),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                  border: InputBorder.none,
                                  hintText: 'DD.MM.YYYY',
                                ),
                                keyboardType: TextInputType.datetime,
                                onChanged: (value) {
                                  try {
                                    if (value.length == 10) { // DD.MM.YYYY
                                      final parts = value.split('.');
                                      if (parts.length == 3) {
                                        final newDate = DateTime(
                                          int.parse(parts[2]), // year
                                          int.parse(parts[1]), // month
                                          int.parse(parts[0]), // day
                                          _startDate.hour,
                                          _startDate.minute,
                                        );
                                        if (newDate.isBefore(_endDate)) {
                                          setState(() {
                                            _startDate = newDate;
                                            _selectedRange = '';
                                          });
                                          _fetchDeviceInfo();
                                          _fetchChartData();
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    // Ігноруємо неправильний формат
                                  }
                                },
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
                                if (picked != null) {
                                  setState(() {
                                    _startDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      _startDate.hour,
                                      _startDate.minute,
                                    );
                                    _selectedRange = '';
                                  });
                                  _fetchDeviceInfo();
                                  _fetchChartData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('—', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    // Поле для кінцевої дати
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: DateFormat('dd.MM.yyyy').format(_endDate),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                  border: InputBorder.none,
                                  hintText: 'DD.MM.YYYY',
                                ),
                                keyboardType: TextInputType.datetime,
                                onChanged: (value) {
                                  try {
                                    if (value.length == 10) { // DD.MM.YYYY
                                      final parts = value.split('.');
                                      if (parts.length == 3) {
                                        final newDate = DateTime(
                                          int.parse(parts[2]), // year
                                          int.parse(parts[1]), // month
                                          int.parse(parts[0]), // day
                                          _endDate.hour,
                                          _endDate.minute,
                                        );
                                        if (newDate.isAfter(_startDate) && 
                                            newDate.isBefore(DateTime.now())) {
                                          setState(() {
                                            _endDate = newDate;
                                            _selectedRange = '';
                                          });
                                          _fetchDeviceInfo();
                                          _fetchChartData();
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    // Ігноруємо неправильний формат
                                  }
                                },
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
                                if (picked != null) {
                                  setState(() {
                                    _endDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      _endDate.hour,
                                      _endDate.minute,
                                    );
                                    _selectedRange = '';
                                  });
                                  _fetchDeviceInfo();
                                  _fetchChartData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Дропдаун для швидкого вибору періоду
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
                        _updateDateRange(newValue);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, [String? percentage]) {
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (percentage != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: double.parse(percentage.replaceAll('%', '')) / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              percentage,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChart() {
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
          child: Text('No data available'),
        ),
      );
    }

    final spots = _chartData.asMap().entries.map((entry) {
      return FlSpot(
      entry.key.toDouble(),
        entry.value['waterLevel'].toDouble(),
      );
    }).toList();

    final minY = _chartData.map((data) => data['waterLevel'] as num).reduce(min).toDouble();
    final maxY = _chartData.map((data) => data['waterLevel'] as num).reduce(max).toDouble();
    final padding = (maxY - minY) * 0.1;

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
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 5,
            verticalInterval: max(1, (_chartData.length / 6).floor().toDouble()),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: max(1, (_chartData.length / 6).floor().toDouble()),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _chartData.length) return const Text('');
                  final date = _chartData[value.toInt()]['timestamp'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(date),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
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
              dotData: FlDotData(show: false),
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
                  final date = _chartData[flSpot.x.toInt()]['timestamp'] as DateTime;
                  return LineTooltipItem(
                    '${DateFormat('HH:mm').format(date)}\n${flSpot.y.toStringAsFixed(1)} cm',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _deviceInfo?['DeviceNickname'] ?? 'Device Details',
          style: const TextStyle(color: Colors.black, fontSize: 20),
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
              _fetchChartData();
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
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _fetchDeviceInfo();
                          _fetchChartData();
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
                      _buildMetricsGrid(),
                      const SizedBox(height: 16),
                      _buildDateRangeSelector(),
                      const SizedBox(height: 8),
                      _buildChart(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}