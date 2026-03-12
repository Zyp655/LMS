import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_constants.dart';

class MyAttendancePage extends StatefulWidget {
  final int? classId;
  final String? className;

  const MyAttendancePage({Key? key, this.classId, this.className})
    : super(key: key);

  @override
  State<MyAttendancePage> createState() => _MyAttendancePageState();
}

class _MyAttendancePageState extends State<MyAttendancePage> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess || authState.user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String url =
          '${ApiConstants.baseUrl}/student/attendance?userId=${authState.user!.id}';
      if (widget.classId != null) {
        url += '&classId=${widget.classId}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _records = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load attendance');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, int> get _summary {
    final present = _records.where((r) => r['status'] == 'present').length;
    final absent = _records.where((r) => r['status'] == 'absent').length;
    final late = _records.where((r) => r['status'] == 'late').length;
    final excused = _records.where((r) => r['status'] == 'excused').length;

    return {
      'total': _records.length,
      'present': present,
      'absent': absent,
      'late': late,
      'excused': excused,
    };
  }

  double get _attendanceRate {
    final summary = _summary;
    final total = summary['total']!;
    if (total == 0) return 0;

    final present = summary['present']!;
    final excused = summary['excused']!;
    return ((present + excused) / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className ?? 'Điểm Danh Của Tôi'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: _buildContent(),
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
              onPressed: _loadAttendance,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCard(),

        Expanded(
          child: _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text('Chưa có dữ liệu điểm danh'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _records.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return _buildRecordCard(record);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final summary = _summary;
    final rate = _attendanceRate;

    Color getRateColor() {
      if (rate >= 90) return Colors.green;
      if (rate >= 75) return Colors.orange;
      return Colors.red;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: getRateColor(),
              ),
            ),
            const Text(
              'Tỷ lệ tham gia',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(getRateColor()),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Tổng', summary['total']!, Colors.grey),
                _buildSummaryItem('Có mặt', summary['present']!, Colors.green),
                _buildSummaryItem('Vắng', summary['absent']!, Colors.red),
                _buildSummaryItem('Muộn', summary['late']!, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final date = DateTime.parse(record['date']);

    IconData getIcon() {
      switch (status) {
        case 'present':
          return Icons.check_circle;
        case 'absent':
          return Icons.cancel;
        case 'late':
          return Icons.access_time;
        case 'excused':
          return Icons.event_available;
        default:
          return Icons.help;
      }
    }

    Color getColor() {
      switch (status) {
        case 'present':
          return Colors.green;
        case 'absent':
          return Colors.red;
        case 'late':
          return Colors.orange;
        case 'excused':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    String getStatusText() {
      switch (status) {
        case 'present':
          return 'Có mặt';
        case 'absent':
          return 'Vắng';
        case 'late':
          return 'Muộn';
        case 'excused':
          return 'Có phép';
        default:
          return status;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getColor(),
          child: Icon(getIcon(), color: Colors.white),
        ),
        title: Text(
          record['className'] ?? 'Unknown Class',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
        trailing: Chip(
          label: Text(
            getStatusText(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: getColor(),
        ),
      ),
    );
  }
}
