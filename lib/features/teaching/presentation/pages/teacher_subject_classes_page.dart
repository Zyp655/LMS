import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../injection_container.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import 'teacher_student_list_page.dart';
import '../widgets/class_code_manager_dialog.dart';
import '../widgets/create_class_dialog.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherSubjectClassesPage extends StatefulWidget {
  final String subjectName;
  final List<ScheduleEntity> allSchedules;

  const TeacherSubjectClassesPage({
    super.key,
    required this.subjectName,
    required this.allSchedules,
  });

  @override
  State<TeacherSubjectClassesPage> createState() =>
      _TeacherSubjectClassesPageState();
}

class _TeacherSubjectClassesPageState extends State<TeacherSubjectClassesPage> {
  int _getCurrentUserId() {
    return sl<SharedPreferences>().getInt('current_user_id') ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final subjectSchedules = List<ScheduleEntity>.from(
      widget.allSchedules.where((s) => s.subject == widget.subjectName),
    );

    if (subjectSchedules.isEmpty) {
      return Scaffold(
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Chưa có lớp học nào được tạo.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                "Nhấn nút + bên dưới để tạo lớp mới",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => CreateClassDialog.show(
            context,
            subjectName: widget.subjectName,
            getCurrentUserId: _getCurrentUserId,
          ),
          backgroundColor: AppColors.info,
          child: Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subjectSchedules.length,
        itemBuilder: (context, index) {
          final item = subjectSchedules[index];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.info.withValues(alpha: 0.15),
                child: Icon(Icons.class_, color: AppColors.info),
              ),
              title: Text(
                'Môn học: ${item.subject}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.room.isNotEmpty) Text("Phòng: ${item.room}"),
                  const Text("Giảng viên: Tôi"),
                  if (item.createdAt != null)
                    Text(
                      "Tạo lúc: ${item.createdAt!.day.toString().padLeft(2, '0')}/${item.createdAt!.month.toString().padLeft(2, '0')}/${item.createdAt!.year} ${item.createdAt!.hour.toString().padLeft(2, '0')}:${item.createdAt!.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.vpn_key, color: AppColors.warning),
                tooltip: "Xem/Lấy Mã Lớp",
                onPressed: () => ClassCodeManagerDialog.show(
                  context,
                  classItem: item,
                  getCurrentUserId: _getCurrentUserId,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<TeacherBloc>(),
                      child: TeacherStudentListPage(
                        subjectName: widget.subjectName,
                        allSchedules: widget.allSchedules,
                        selectedDate: item.start,
                        weekIndex: null,
                      ),
                    ),
                  ),
                ).then((_) {
                  context.read<TeacherBloc>().add(
                    LoadTeacherClasses(_getCurrentUserId()),
                  );
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => CreateClassDialog.show(
          context,
          subjectName: widget.subjectName,
          getCurrentUserId: _getCurrentUserId,
        ),
        backgroundColor: AppColors.info,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
