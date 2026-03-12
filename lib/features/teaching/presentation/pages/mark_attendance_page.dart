import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_constants.dart';

class MarkAttendancePage extends StatefulWidget {
  final int classId;
  final String className;
  final DateTime? initialDate;

  const MarkAttendancePage({
    Key? key,
    required this.classId,
    required this.className,
    this.initialDate,
  }) : super(key: key);

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  Map<int, String> _attendance = {};
  Map<int, String> _notes = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/teacher/classes/${widget.classId}/students',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _students = data.cast<Map<String, dynamic>>();
          for (var student in _students) {
            _attendance[student['id']] = 'present';
          }
          _isLoading = false;
        });

        await _loadExistingAttendance();
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadExistingAttendance() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/teacher/attendance/records?classId=${widget.classId}&date=$dateStr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          for (var record in data) {
            _attendance[record['studentId']] = record['status'];
            if (record['note'] != null) {
              _notes[record['studentId']] = record['note'];
            }
          }
          setState(() {});
        }
      }
    } catch (e) {}
  }

  Future<void> _saveAttendance() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess || authState.user == null) return;

    setState(() => _isSaving = true);

    try {
      final attendances = _attendance.entries.map((entry) {
        return {
          'studentId': entry.key,
          'status': entry.value,
          if (_notes[entry.key] != null) 'note': _notes[entry.key],
        };
      }).toList();

      final url = Uri.parse('${ApiConstants.baseUrl}/teacher/attendance/mark');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'classId': widget.classId,
          'date': _selectedDate.toIso8601String(),
          'teacherId': authState.user!.id,
          'attendances': attendances,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                    content: Text('Lưu điểm danh thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to save attendance');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        for (var student in _students) {
          _attendance[student['id']] = 'present';
        }
        _notes.clear();
      });
      await _loadExistingAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Danh'),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveAttendance,
              tooltip: 'Lưu điểm danh',
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.info.withValues(alpha: 0.1),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(Icons.calendar_today, size: 16),
                      label: const Text('Đổi ngày'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction('Tất cả có mặt', Icons.check_circle, () {
                  setState(() {
                    for (var student in _students) {
                      _attendance[student['id']] = 'present';
                    }
                  });
                }),
                _buildQuickAction('Tất cả vắng', Icons.cancel, () {
                  setState(() {
                    for (var student in _students) {
                      _attendance[student['id']] = 'absent';
                    }
                  });
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                ? const Center(child: Text('Không có sinh viên'))
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return _buildStudentCard(student);
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Có mặt',
                  _attendance.values
                      .where((s) => s == 'present')
                      .length
                      .toString(),
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Vắng',
                  _attendance.values
                      .where((s) => s == 'absent')
                      .length
                      .toString(),
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Muộn',
                  _attendance.values
                      .where((s) => s == 'late')
                      .length
                      .toString(),
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Có phép',
                  _attendance.values
                      .where((s) => s == 'excused')
                      .length
                      .toString(),
                  Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final studentId = student['id'] as int;
    final status = _attendance[studentId] ?? 'present';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    (student['fullName'] ?? student['email'] ?? '?')[0]
                        .toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['fullName'] ?? student['email'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (student['email'] != null)
                        Text(
                          student['email'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildStatusChip(
                  'present',
                  'Có mặt',
                  Icons.check_circle,
                  Colors.green,
                  studentId,
                ),
                _buildStatusChip(
                  'absent',
                  'Vắng',
                  Icons.cancel,
                  Colors.red,
                  studentId,
                ),
                _buildStatusChip(
                  'late',
                  'Muộn',
                  Icons.access_time,
                  Colors.orange,
                  studentId,
                ),
                _buildStatusChip(
                  'excused',
                  'Có phép',
                  Icons.event_available,
                  Colors.blue,
                  studentId,
                ),
              ],
            ),
            if (status == 'absent' || status == 'late' || status == 'excused')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _notes[studentId] = value;
                  },
                  controller: TextEditingController(text: _notes[studentId]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String value,
    String label,
    IconData icon,
    Color color,
    int studentId,
  ) {
    final isSelected = _attendance[studentId] == value;

    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _attendance[studentId] = value;
          });
        }
      },
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
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
}
