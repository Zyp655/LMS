import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../../domain/entities/subject_entity.dart';
import '../../../../core/theme/app_colors.dart';

class EditTaskDialog extends StatefulWidget {
  final AssignmentEntity assignment;
  final TeacherBloc assignmentBloc;

  const EditTaskDialog({
    super.key,
    required this.assignment,
    required this.assignmentBloc,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pointsController;
  late DateTime _selectedDate;
  int? _selectedClassId;
  int? _selectedSubjectId;
  List<ScheduleEntity> _classes = [];
  List<SubjectEntity> _subjects = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment.title);
    _descriptionController = TextEditingController(
      text: widget.assignment.description ?? '',
    );
    _pointsController = TextEditingController(
      text: widget.assignment.rewardPoints.toString(),
    );
    _selectedDate = widget.assignment.dueDate;
    _selectedClassId = widget.assignment.classId;
    _loadSubjectsAndClasses();
  }

  void _loadSubjectsAndClasses() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess && authState.user != null) {
      context.read<TeacherBloc>().add(LoadSubjects(authState.user!.id));
      context.read<TeacherBloc>().add(LoadTeacherClasses(authState.user!.id));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeacherBloc, TeacherState>(
      listener: (context, state) {
        if (state is SubjectsLoaded) {
          setState(() {
            _subjects = state.subjects;
            if (_selectedSubjectId == null && _subjects.isNotEmpty) {
              final matchingClass = _classes.firstWhere(
                (c) => c.id == widget.assignment.classId,
                orElse: () => ScheduleEntity(
                  subject: '',
                  room: '',
                  start: DateTime.now(),
                  end: DateTime.now(),
                ),
              );
              if (matchingClass.subject.isNotEmpty) {
                final matchingSubject = _subjects.firstWhere(
                  (s) => s.name == matchingClass.subject,
                  orElse: () => _subjects.first,
                );
                _selectedSubjectId = matchingSubject.id;
              } else {
                _selectedSubjectId = _subjects.first.id;
              }
            }
          });
        } else if (state is TeacherLoaded) {
          setState(() {
            _classes = state.schedules;
          });
        }
      },
      builder: (context, state) {
        final filteredClasses = _selectedSubjectId != null
            ? _classes
                  .where(
                    (c) => c.subject == _getSubjectName(_selectedSubjectId!),
                  )
                  .toList()
            : [];

        final uniqueClasses = <int, ScheduleEntity>{};
        for (var c in filteredClasses) {
          if (c.id != null) {
            uniqueClasses[c.id!] = c;
          }
        }
        final displayClasses = uniqueClasses.values.toList();

        if (displayClasses.isNotEmpty) {
          final exists = displayClasses.any((c) => c.id == _selectedClassId);
          if (!exists) {
            _selectedClassId = displayClasses.first.id;
          }
        } else {
          _selectedClassId = null;
        }

        return AlertDialog(
          title: const Text("Chỉnh Sửa Bài Tập"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_subjects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        "Chưa có môn học nào. Vui lòng tạo môn học trước.",
                        style: TextStyle(color: AppColors.error),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: _selectedSubjectId,
                      items: _subjects
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSubjectId = val;
                          _selectedClassId = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Chọn Môn Học",
                      ),
                      validator: (val) =>
                          val == null ? "Vui lòng chọn môn học" : null,
                    ),

                  const SizedBox(height: 8),

                  if (displayClasses.isEmpty && _selectedSubjectId != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Chưa có lớp học nào cho môn này.",
                        style: TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    )
                  else if (displayClasses.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: _selectedClassId,
                      items: displayClasses
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text("${c.subject} - ${c.room}"),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val;
                        });
                      },
                      decoration: InputDecoration(labelText: "Chọn Lớp"),
                      validator: (val) =>
                          val == null ? "Vui lòng chọn lớp" : null,
                    ),

                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: "Tiêu đề"),
                    validator: (val) => val!.isEmpty ? "Nhập tiêu đề" : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: "Mô tả"),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: _pointsController,
                    decoration: InputDecoration(labelText: "Điểm thưởng"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("Hạn nộp: "),
                      TextButton.icon(
                        icon: Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                _selectedDate.hour,
                                _selectedDate.minute,
                              );
                            });
                          }
                        },
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.access_time, size: 18),
                        label: Text(DateFormat('HH:mm').format(_selectedDate)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthSuccess && authState.user != null) {
                    final updatedAssignment = AssignmentEntity(
                      id: widget.assignment.id,
                      classId: _selectedClassId!,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      dueDate: _selectedDate,
                      rewardPoints: int.tryParse(_pointsController.text) ?? 0,
                      createdAt: widget.assignment.createdAt,
                    );
                    widget.assignmentBloc.add(
                      UpdateAssignmentRequested(
                        updatedAssignment,
                        authState.user!.id,
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text("Cập Nhật"),
            ),
          ],
        );
      },
    );
  }

  String _getSubjectName(int subjectId) {
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => SubjectEntity(id: 0, name: '', credits: 0),
    );
    return subject.name;
  }
}
