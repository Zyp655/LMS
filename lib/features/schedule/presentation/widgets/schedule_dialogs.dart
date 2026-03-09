import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/enitities/schedule_entity.dart';
import '../../../../core/theme/app_colors.dart';

class ScheduleDialogs {
  static Future<Map<String, dynamic>?> showImportConfig(
    BuildContext context,
    int count,
  ) async {
    final minutesController = TextEditingController(text: "30");
    bool isRepeating = true;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Cấu hình báo thức ($count môn)"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: minutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Báo trước (phút)",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: isRepeating,
                        onChanged: (val) =>
                            setState(() => isRepeating = val ?? true),
                      ),
                      const Text("Lặp lại hàng tuần?"),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () {
                    int minutes = int.tryParse(minutesController.text) ?? 30;
                    Navigator.pop(context, {
                      'minutes': minutes,
                      'repeat': isRepeating,
                    });
                  },
                  child: const Text("Lưu & Đặt Báo Thức"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<bool> showDeleteConfirmation(
    BuildContext context,
    String subjectName,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Xóa lịch học?"),
            content: Text("Bạn có chắc muốn xóa môn '$subjectName' không?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy"),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Xóa"),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<Map<String, dynamic>?> showScheduleForm(
    BuildContext context, {
    ScheduleEntity? schedule,
  }) async {
    final isEdit = schedule != null;
    final subjectController = TextEditingController(text: schedule?.subject);
    final roomController = TextEditingController(text: schedule?.room);
    final minutesController = TextEditingController(text: "30");
    final weeksController = TextEditingController(text: "15");
    final creditsController = TextEditingController(
      text: schedule?.credits.toString() ?? "3",
    );

    DateTime selectedDate = schedule?.start ?? DateTime.now();
    TimeOfDay startTime = schedule != null
        ? TimeOfDay.fromDateTime(schedule.start)
        : const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTime = schedule != null
        ? TimeOfDay.fromDateTime(schedule.end)
        : const TimeOfDay(hour: 9, minute: 0);
    bool isRepeating = true;

    ScheduleType selectedType = schedule?.type ?? ScheduleType.classSession;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? "Sửa Lịch" : "Thêm Lịch Mới"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ScheduleType>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: "Loại lịch",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ScheduleType.classSession,
                          child: Text("Lịch Học"),
                        ),
                        DropdownMenuItem(
                          value: ScheduleType.exam,
                          child: Text("Lịch Thi"),
                        ),
                        DropdownMenuItem(
                          value: ScheduleType.event,
                          child: Text("Sự Kiện"),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedType = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: "Tên môn / Sự kiện",
                        icon: Icon(Icons.book),
                      ),
                    ),
                    TextField(
                      controller: roomController,
                      decoration: InputDecoration(
                        labelText: "Phòng / Địa điểm",
                        icon: Icon(Icons.room),
                      ),
                    ),
                    if (selectedType == ScheduleType.classSession) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: creditsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Số tín chỉ",
                          icon: Icon(Icons.star_border),
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    _buildDateTimePicker(context, "Ngày", selectedDate, (val) {
                      setState(() => selectedDate = val);
                    }),
                    _buildTimePicker(context, "Bắt đầu", startTime, (val) {
                      setState(() => startTime = val);
                    }),
                    _buildTimePicker(context, "Kết thúc", endTime, (val) {
                      setState(() => endTime = val);
                    }),
                    const Divider(),
                    if (!isEdit) ...[
                      TextField(
                        controller: minutesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Báo trước (phút)",
                          icon: Icon(Icons.timer),
                        ),
                      ),
                      if (selectedType == ScheduleType.classSession)
                        Row(
                          children: [
                            Checkbox(
                              value: isRepeating,
                              onChanged: (v) =>
                                  setState(() => isRepeating = v ?? true),
                            ),
                            const Text("Lặp lại hàng tuần?"),
                          ],
                        ),
                      if (isRepeating &&
                          selectedType == ScheduleType.classSession)
                        TextField(
                          controller: weeksController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Số tuần lặp lại",
                            suffixText: "tuần",
                            icon: Icon(Icons.repeat),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (subjectController.text.isEmpty) return;

                    final startDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final endDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    int credits = int.tryParse(creditsController.text) ?? 3;
                    int maxAbsences =
                        (selectedType == ScheduleType.classSession)
                        ? credits * 3
                        : 0;

                    final resultEntity = ScheduleEntity(
                      id: schedule?.id,
                      subject: subjectController.text,
                      room: roomController.text,
                      start: startDateTime,
                      end: endDateTime,
                      credits: credits,
                      maxAbsences: maxAbsences,
                      type: selectedType,
                    );

                    int minutes = int.tryParse(minutesController.text) ?? 30;
                    int weeks = int.tryParse(weeksController.text) ?? 15;

                    Navigator.pop(context, {
                      'schedule': resultEntity,
                      'minutes': minutes,
                      'repeat':
                          isRepeating &&
                          selectedType == ScheduleType.classSession,
                      'weeks': weeks,
                    });
                  },
                  child: Text(isEdit ? "Cập nhật" : "Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildDateTimePicker(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onSelect,
  ) {
    return ListTile(
      leading: Icon(Icons.calendar_today),
      title: Text("$label: ${DateFormat('dd/MM/yyyy').format(date)}"),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onSelect(picked);
      },
    );
  }

  static Widget _buildTimePicker(
    BuildContext context,
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onSelect,
  ) {
    return ListTile(
      leading: Icon(Icons.access_time),
      title: Text("$label: ${time.format(context)}"),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onSelect(picked);
      },
    );
  }
}
