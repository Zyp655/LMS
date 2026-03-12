import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_constants.dart';

class AttendanceStatisticsPage extends StatefulWidget {
  final int classId;
  final String className;

  const AttendanceStatisticsPage({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<AttendanceStatisticsPage> createState() =>
      _AttendanceStatisticsPageState();
}

class _AttendanceStatisticsPageState extends State<AttendanceStatisticsPage> {
  List<Map<String, dynamic>> _statistics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/teacher/attendance/statistics?classId=${widget.classId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _statistics = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load statistics');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê Điểm Danh'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.secondary.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.className,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_statistics.length} sinh viên',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_statistics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Chưa có dữ liệu điểm danh'),
          ],
        ),
      );
    }

    _statistics.sort((a, b) {
      final rateA = double.parse(a['attendanceRate'] ?? '0');
      final rateB = double.parse(b['attendanceRate'] ?? '0');
      return rateB.compareTo(rateA);
    });

    return ListView.builder(
      itemCount: _statistics.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final stat = _statistics[index];
        return _buildStatCard(stat, index + 1);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, int rank) {
    final total = stat['total'] as int;
    final present = stat['present'] as int;
    final absent = stat['absent'] as int;
    final late = stat['late'] as int;
    final excused = stat['excused'] as int;
    final attendanceRate = double.parse(stat['attendanceRate'] ?? '0');

    Color getRateColor() {
      if (attendanceRate >= 90) return Colors.green;
      if (attendanceRate >= 75) return Colors.orange;
      return Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: getRateColor(),
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          stat['studentName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat['studentEmail'] ?? ''),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: attendanceRate / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(getRateColor()),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${attendanceRate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: getRateColor(),
              ),
            ),
            Text(
              '$total buổi',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Có mặt',
                  present,
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatItem('Vắng', absent, Colors.red, Icons.cancel),
                _buildStatItem('Muộn', late, Colors.orange, Icons.access_time),
                _buildStatItem(
                  'Có phép',
                  excused,
                  Colors.blue,
                  Icons.event_available,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
