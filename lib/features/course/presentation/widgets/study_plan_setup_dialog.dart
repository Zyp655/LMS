import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';

class StudyPlanSetupDialog extends StatefulWidget {
  final int courseId;
  final VoidCallback onSaved;

  const StudyPlanSetupDialog({
    super.key,
    required this.courseId,
    required this.onSaved,
  });

  @override
  State<StudyPlanSetupDialog> createState() => _StudyPlanSetupDialogState();
}

class _StudyPlanSetupDialogState extends State<StudyPlanSetupDialog> {
  DateTime? _targetDate;
  int _dailyMinutes = 30;
  final List<String> _preferredDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _isLoading = false;

  final Map<String, String> _dayLabels = {
    'Mon': 'T2',
    'Tue': 'T3',
    'Wed': 'T4',
    'Thu': 'T5',
    'Fri': 'T6',
    'Sat': 'T7',
    'Sun': 'CN',
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lên kế hoạch học tập 📅',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thiết lập mục tiêu để AI giúp bạn hoàn thành khóa học đúng hạn!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Mục tiêu hoàn thành'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _targetDate == null
                          ? 'Chọn ngày hoàn thành'
                          : DateFormat('dd/MM/yyyy').format(_targetDate!),
                      style: TextStyle(
                        color: _targetDate == null
                            ? Colors.grey[500]
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Thời gian học mỗi ngày: $_dailyMinutes phút'),
            Slider(
              value: _dailyMinutes.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              activeColor: AppColors.accent,
              label: '$_dailyMinutes phút',
              onChanged: (val) => setState(() => _dailyMinutes = val.round()),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('Ngày học trong tuần'),
            Wrap(
              spacing: 8,
              children: _dayLabels.keys.map((day) {
                final isSelected = _preferredDays.contains(day);
                return FilterChip(
                  label: Text(_dayLabels[day]!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _preferredDays.add(day);
                      } else if (_preferredDays.length > 1) {
                        _preferredDays.remove(day);
                      }
                    });
                  },
                  selectedColor: AppColors.accent.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.accent
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Giờ nhắc nhở'),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _reminderTime.format(context),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Tạo kế hoạch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Bỏ qua',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkBackground,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _targetDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => _reminderTime = time);
  }

  Future<void> _savePlan() async {
    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
                    content: Text('Vui lòng chọn ngày hoàn thành')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hour = _reminderTime.hour.toString().padLeft(2, '0');
      final minute = _reminderTime.minute.toString().padLeft(2, '0');

      final api = GetIt.instance<ApiClient>();
      await api.post('/courses/${widget.courseId}/study_plan', {
        'targetCompletionDate': _targetDate!.toIso8601String(),
        'dailyStudyMinutes': _dailyMinutes,
        'preferredDays': _preferredDays,
        'reminderTime': '$hour:$minute',
      });

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                    content: Text('Đã tạo kế hoạch học tập thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
