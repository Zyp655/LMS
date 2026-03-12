import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import '../../../../core/theme/app_colors.dart';

class CreateClassDialog extends StatelessWidget {
  final String subjectName;
  final int Function() getCurrentUserId;

  const CreateClassDialog({
    super.key,
    required this.subjectName,
    required this.getCurrentUserId,
  });

  static void show(
    BuildContext context, {
    required String subjectName,
    required int Function() getCurrentUserId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<TeacherBloc>(),
          child: CreateClassDialog(
            subjectName: subjectName,
            getCurrentUserId: getCurrentUserId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classNameCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final repeatWeeksCtrl = TextEditingController(text: "1");
    final creditsCtrl = TextEditingController(text: "2");
    final notifMinutesCtrl = TextEditingController(text: "15");

    TimeOfDay? startTime;
    TimeOfDay? endTime;
    DateTime? startDate;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return BlocListener<TeacherBloc, TeacherState>(
          listener: (context, state) {
            if (state is ClassCreatedSuccess) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("Tạo lớp thành công!"),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state is TeacherError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Lỗi: ${state.message}"),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Tạo Lớp Học Mới",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: classNameCtrl,
                          decoration: InputDecoration(
                            labelText: "Tên lớp học",
                            hintText: "VD: Lớp A",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: roomCtrl,
                          decoration: InputDecoration(
                            labelText: "Phòng học",
                            hintText: "VD: A101",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.room),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null)
                              setDialogState(() => startDate = picked);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Ngày bắt đầu",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                              isDense: true,
                            ),
                            child: Text(
                              startDate != null
                                  ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                                  : 'Chọn ngày',
                              style: TextStyle(
                                color: startDate != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null)
                                    setDialogState(() => startTime = picked);
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: "Bắt đầu",
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Text(
                                    startTime != null
                                        ? startTime!.format(context)
                                        : '--:--',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: startTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null)
                                    setDialogState(() => endTime = picked);
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: "Kết thúc",
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Text(
                                    endTime != null
                                        ? endTime!.format(context)
                                        : '--:--',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: repeatWeeksCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: "Tuần",
                                  hintText: "1",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: notifMinutesCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: "Phút báo",
                                  hintText: "15",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: creditsCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: "Tín chỉ",
                                  hintText: "2",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            final className = classNameCtrl.text.trim();
                            final room = roomCtrl.text.trim();
                            final repeatWeeks =
                                int.tryParse(repeatWeeksCtrl.text.trim()) ?? 1;
                            final notifMinutes =
                                int.tryParse(notifMinutesCtrl.text.trim()) ??
                                15;
                            final credits =
                                int.tryParse(creditsCtrl.text.trim()) ?? 2;

                            if (className.isEmpty ||
                                room.isEmpty ||
                                startDate == null ||
                                startTime == null ||
                                endTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                    content: Text(
                                    "Vui lòng điền đầy đủ thông tin!",
                                  ),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }

                            final now = DateTime.now();
                            final startDT = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              startTime!.hour,
                              startTime!.minute,
                            );
                            final endDT = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              endTime!.hour,
                              endTime!.minute,
                            );

                            if (!endDT.isAfter(startDT)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                    content: Text(
                                    "Giờ kết thúc phải sau giờ bắt đầu",
                                  ),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }

                            context.read<TeacherBloc>().add(
                              CreateClassRequested(
                                className: className,
                                teacherId: getCurrentUserId(),
                                subjectName: subjectName,
                                room: room,
                                startTime: startDT,
                                endTime: endDT,
                                startDate: startDate!,
                                repeatWeeks: repeatWeeks,
                                notificationMinutes: notifMinutes,
                                credits: credits,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "TẠO LỚP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
