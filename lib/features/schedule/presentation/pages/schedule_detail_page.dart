import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:image_picker/image_picker.dart';
import '../../domain/enitities/schedule_entity.dart';
import '../../../../core/theme/app_colors.dart';

class ScheduleDetailPage extends StatefulWidget {
  final ScheduleEntity schedule;

  const ScheduleDetailPage({super.key, required this.schedule});

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late TextEditingController _noteController;
  String? _imagePath;
  late int _currentAbsences;
  final int _maxAbsences = 3; 

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.schedule.note ?? '');
    _imagePath = widget.schedule.imagePath;
    _currentAbsences = widget.schedule.currentAbsences;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    ); 
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  Widget _buildStatusHeader() {
    Color statusColor = AppColors.success;
    String statusText = "An toàn";
    IconData statusIcon = Icons.check_circle;

    if (_currentAbsences >= _maxAbsences) {
      statusColor = AppColors.error;
      statusText = "CẤM THI (Đã nghỉ quá mức)";
      statusIcon = Icons.warning;
    } else if (_currentAbsences == _maxAbsences - 1) {
      statusColor = AppColors.warning;
      statusText = "NGUY HIỂM (Chỉ còn 1 buổi)";
      statusIcon = Icons.warning_amber;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceChart() {
    int remaining = _maxAbsences - _currentAbsences;
    if (remaining < 0) remaining = 0;

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.redAccent,
              value: _currentAbsences.toDouble(),
              title: 'Nghỉ: $_currentAbsences',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: AppColors.success,
              value: remaining.toDouble(),
              title: 'Còn: $remaining',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
      appBar: AppBar(
        title: Text(widget.schedule.subject),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 20),

            const Text(
              "Thống kê điểm danh",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildAbsenceChart(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() {
                    if (_currentAbsences > 0) _currentAbsences--;
                  }),
                ),
                Text(
                  "$_currentAbsences / $_maxAbsences",
                  style: const TextStyle(fontSize: 20),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _currentAbsences++),
                ),
              ],
            ),
            const Divider(height: 30),

            const Text(
              "Ghi chú & Tài liệu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Nhập ghi chú môn học...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _imagePath == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40),
                          Text("Chụp bảng / Đính kèm ảnh"),
                        ],
                      )
                    : Image.file(File(_imagePath!), fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
