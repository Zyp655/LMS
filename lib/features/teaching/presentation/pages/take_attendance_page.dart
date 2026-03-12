import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/student_entity.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import '../../../../core/theme/app_colors.dart';

class TakeAttendancePage extends StatefulWidget {
  final int classId;
  final String subjectName;
  final List<StudentEntity> students;
  final int teacherId;

  const TakeAttendancePage({
    super.key,
    required this.classId,
    required this.subjectName,
    required this.students,
    required this.teacherId,
  });

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  final Map<int, int> _periodsMissed = {};

  @override
  void initState() {
    super.initState();
    for (var student in widget.students) {
      _periodsMissed[student.userId] = 0;
    }
  }

  void _submit() {
    final attendances = widget.students.map((student) {
      final sId = student.userId;
      return {
        'studentId': sId,
        'status': (_periodsMissed[sId] ?? 0).toString(),
      };
    }).toList();

    context.read<TeacherBloc>().add(
      MarkAttendanceRequested(
        classId: widget.classId,
        date: _selectedDate,
        teacherId: widget.teacherId,
        attendances: attendances,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Điểm danh: ${widget.subjectName}"),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _submit)],
      ),
      body: BlocListener<TeacherBloc, TeacherState>(
        listener: (context, state) {
          if (state is AttendanceMarkedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                    content: Text("Đã lưu điểm danh thành công!"),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is TeacherError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Lỗi: ${state.message}"),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            ListTile(
              title: const Text("Ngày điểm danh"),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.students.length,
                itemBuilder: (context, index) {
                  final student = widget.students[index];
                  final sId = student.userId;
                  final periods = _periodsMissed[sId] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(student.studentName),
                      subtitle: Text("ID: ${student.studentId}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Số tiết nghỉ: "),
                          DropdownButton<int>(
                            value: periods,
                            items: List.generate(6, (i) => i).map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.toString(),
                                  style: TextStyle(
                                    color: e == 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _periodsMissed[sId] = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
