import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../../../schedule/presentation/widgets/schedule_data_source.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import 'teacher_student_list_page.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherCalendarTab extends StatelessWidget {
  final String subjectName;
  final int teacherId;
  final List<ScheduleEntity> schedules;

  const TeacherCalendarTab({
    super.key,
    required this.subjectName,
    required this.teacherId,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    final subjectSchedules = schedules
        .where((s) => s.subject == subjectName)
        .toList();

    if (subjectSchedules.isEmpty) {
      return const Center(child: Text("Chưa có lịch dạy nào cho môn này."));
    }

    return SfCalendar(
      view: CalendarView.week,
      firstDayOfWeek: 1,
      dataSource: ScheduleDataSource(subjectSchedules),
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 6,
        endHour: 23,
        timeFormat: 'H:mm',
      ),
      onTap: (CalendarTapDetails details) {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          final schedule = details.appointments!.first as ScheduleEntity;
          _showScheduleOptions(
            context,
            schedule,
            schedules, 
          );
        }
      },
    );
  }

  void _showScheduleOptions(
    BuildContext context,
    ScheduleEntity schedule,
    List<ScheduleEntity> allSchedules,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.people, color: AppColors.info),
            title: const Text('Quản lý Sinh viên / Điểm danh'),
            subtitle: Text('${schedule.subject} - ${schedule.room}'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<TeacherBloc>(),
                    child: TeacherStudentListPage(
                      subjectName: subjectName,
                      allSchedules: allSchedules,
                      selectedDate: schedule.start,
                      weekIndex: null,
                    ),
                  ),
                ),
              ).then((_) {
                context.read<TeacherBloc>().add(LoadTeacherClasses(teacherId));
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.edit, color: AppColors.warning),
            title: const Text('Sửa thông tin lớp (Phòng, Giờ)'),
            onTap: () {
              Navigator.pop(ctx);
              _showEditClassDialog(context, schedule);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: AppColors.error),
            title: const Text('Xóa lịch học này'),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteSchedule(context, schedule);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSchedule(BuildContext context, ScheduleEntity schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc chắn muốn xóa lịch học môn ${schedule.subject} tại phòng ${schedule.room} không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<TeacherBloc>().add(
                DeleteClassRequested(schedule.id!, teacherId),
              );
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(BuildContext context, ScheduleEntity schedule) {
    final roomController = TextEditingController(text: schedule.room);
    TimeOfDay startTime = TimeOfDay.fromDateTime(schedule.start);
    TimeOfDay endTime = TimeOfDay.fromDateTime(schedule.end);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickTime(bool isStart) async {
            final picked = await showTimePicker(
              context: context,
              initialTime: isStart ? startTime : endTime,
            );
            if (picked != null) {
              setState(() {
                if (isStart) {
                  startTime = picked;
                } else {
                  endTime = picked;
                }
              });
            }
          }

          return AlertDialog(
            title: const Text("Sửa thông tin lớp"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomController,
                  decoration: InputDecoration(labelText: "Phòng học"),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => pickTime(true),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "Giờ bắt đầu",
                      ),
                      controller: TextEditingController(
                        text:
                            "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => pickTime(false),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "Giờ kết thúc",
                      ),
                      controller: TextEditingController(
                        text:
                            "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () {
                  final newStart = DateTime(
                    schedule.start.year,
                    schedule.start.month,
                    schedule.start.day,
                    startTime.hour,
                    startTime.minute,
                  );
                  final newEnd = DateTime(
                    schedule.end.year,
                    schedule.end.month,
                    schedule.end.day,
                    endTime.hour,
                    endTime.minute,
                  );

                  final updatedSchedule = ScheduleEntity(
                    id: schedule.id,
                    subject: schedule.subject,
                    room: roomController.text,
                    start: newStart,
                    end: newEnd,
                    note: schedule.note,
                    imagePath: schedule.imagePath,
                    currentAbsences: schedule.currentAbsences,
                    maxAbsences: schedule.maxAbsences,
                    currentScore: schedule.currentScore,
                    targetScore: schedule.targetScore,
                    midtermScore: schedule.midtermScore,
                    finalScore: schedule.finalScore,
                    userId: schedule.userId,
                    classId: schedule.classId,
                    classCode: schedule.classCode,
                    credits: schedule.credits,
                    createdAt: schedule.createdAt,
                  );

                  context.read<TeacherBloc>().add(
                    UpdateClassRequested(updatedSchedule, teacherId),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text("Lưu"),
              ),
            ],
          );
        },
      ),
    );
  }
}
