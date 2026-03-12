import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../injection_container.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../../domain/entities/student_entity.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import '../widgets/student_card.dart';
import '../widgets/teacher_update_dialog.dart';
import 'take_attendance_page.dart';
import 'teacher_enrollment_import_page.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherStudentListPage extends StatefulWidget {
  final String subjectName;
  final List<ScheduleEntity> allSchedules;
  final DateTime? selectedDate;
  final int? weekIndex;

  const TeacherStudentListPage({
    super.key,
    required this.subjectName,
    required this.allSchedules,
    this.selectedDate,
    this.weekIndex,
  });

  @override
  State<TeacherStudentListPage> createState() => _TeacherStudentListPageState();
}

class _TeacherStudentListPageState extends State<TeacherStudentListPage> {
  int? _currentTeacherId;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
  }

  void _loadTeacherId() {
    final prefs = sl<SharedPreferences>();
    setState(() {
      _currentTeacherId = prefs.getInt('current_user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTeacherId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocConsumer<TeacherBloc, TeacherState>(
      listener: (context, state) {
        if (state is TeacherError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi: ${state.message}"),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        List<ScheduleEntity> currentSourceData = widget.allSchedules;
        if (state is TeacherLoaded) {
          currentSourceData = state.schedules;
        }

        final classItem = currentSourceData.firstWhere(
          (s) => s.subject == widget.subjectName,
          orElse: () => currentSourceData.first,
        );

        return _StudentListContent(
          subjectName: widget.subjectName,
          classItem: classItem,
          studentListState: state,
          teacherId: _currentTeacherId,
        );
      },
    );
  }
}

class _StudentListContent extends StatefulWidget {
  final String subjectName;
  final ScheduleEntity classItem;
  final TeacherState studentListState;
  final int? teacherId;

  const _StudentListContent({
    required this.subjectName,
    required this.classItem,
    required this.studentListState,
    required this.teacherId,
  });

  @override
  State<_StudentListContent> createState() => _StudentListContentState();
}

class _StudentListContentState extends State<_StudentListContent> {
  List<StudentEntity> _students = [];

  @override
  void initState() {
    super.initState();
    final idToUse = widget.classItem.id ?? widget.classItem.classId;

    if (idToUse != null) {
      context.read<TeacherBloc>().add(GetStudentsInClass(idToUse));
    }
  }

  void _showClassCodeManager(BuildContext context) {
    String currentCode = widget.classItem.classCode ?? "Chưa có";

    showDialog(
      context: context,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<TeacherBloc>(),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return BlocListener<TeacherBloc, TeacherState>(
                listener: (context, state) {
                  if (state is CodeRegeneratedSuccess) {
                    setStateDialog(() {
                      currentCode = state.newCode;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.vpn_key, color: AppColors.info),
                      SizedBox(width: 10),
                      Text("Mã Lớp Học"),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Lớp: ${widget.classItem.subject}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Phòng: ${widget.classItem.room}"),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Mã tham gia:",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              currentCode,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: currentCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Đã sao chép mã!")),
                              );
                            },
                            icon: Icon(Icons.copy, size: 20),
                            label: const Text("Sao chép"),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.read<TeacherBloc>().add(
                                RegenerateCodeRequested(
                                  widget.teacherId ?? 1,
                                  widget.classItem.subject,
                                  true,
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.refresh,
                              color: AppColors.error,
                              size: 20,
                            ),
                            label: const Text(
                              "Làm mới",
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Đóng"),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.studentListState is StudentsLoaded) {
      _students = (widget.studentListState as StudentsLoaded).students;
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName, style: const TextStyle(fontSize: 18)),
            if (widget.classItem.room.isNotEmpty)
              Text(
                "Phòng: ${widget.classItem.room}",
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key),
            tooltip: "Quản lý Mã Lớp",
            onPressed: () {
              _showClassCodeManager(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.checklist),
            tooltip: "Điểm danh nhanh",
            onPressed: () {
              if (widget.teacherId != null && _students.isNotEmpty) {
                final teacherBloc = context.read<TeacherBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: teacherBloc,
                      child: TakeAttendancePage(
                        classId:
                            widget.classItem.id ?? widget.classItem.classId!,
                        subjectName: widget.subjectName,
                        students: _students,
                        teacherId: widget.teacherId!,
                      ),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Chưa có danh sách sinh viên")),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            tooltip: "Import ghi danh từ Excel",
            onPressed: () {
              final classId = widget.classItem.id ?? widget.classItem.classId;
              if (widget.teacherId != null && classId != null) {
                final teacherBloc = context.read<TeacherBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: teacherBloc,
                      child: TeacherEnrollmentImportPage(
                        classId: classId,
                        teacherId: widget.teacherId!,
                        className: widget.subjectName,
                      ),
                    ),
                  ),
                ).then((_) {
                  if (classId != 0) {
                    context.read<TeacherBloc>().add(
                      GetStudentsInClass(classId),
                    );
                  }
                });
              }
            },
          ),
        ],
      ),
      body: BlocListener<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is StudentsLoaded) {
            setState(() {
              _students = state.students;
            });
          } else if (state is ScoreUpdatedSuccess ||
              state is AttendanceMarkedSuccess) {
            final idToUse = widget.classItem.id ?? widget.classItem.classId;
            if (idToUse != null) {
              context.read<TeacherBloc>().add(GetStudentsInClass(idToUse));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Cập nhật thành công!"),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        },
        child: _students.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return StudentCard(
                    student: student,
                    index: index,
                    onEdit: () {
                      if (widget.teacherId != null) {
                        TeacherUpdateDialog.showForStudent(
                          context,
                          student,
                          teacherId: widget.teacherId!,
                          credits: widget.classItem.credits,
                        );
                      }
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Chưa có sinh viên nào trong danh sách.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
