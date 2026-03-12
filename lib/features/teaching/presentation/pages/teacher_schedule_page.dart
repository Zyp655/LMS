import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../schedule/presentation/bloc/schedule_bloc.dart';
import '../../../schedule/presentation/bloc/schedule_event.dart';
import '../../../schedule/presentation/bloc/schedule_state.dart';
import '../../../../injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/teacher_update_dialog.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherSchedulePage extends StatefulWidget {
  const TeacherSchedulePage({super.key});

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  int _currentTeacherId = 1;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
  }

  void _loadTeacherId() async {
    final prefs = sl<SharedPreferences>();
    setState(() {
      _currentTeacherId = prefs.getInt('current_user_id') ?? 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ScheduleBloc>()..add(LoadSchedules()),
      child: Scaffold(
        appBar: AppBar(title: const Text("Quản lý Lớp Học (GV)")),
        body: BlocBuilder<ScheduleBloc, ScheduleState>(
          buildWhen: (prev, curr) =>
              prev.runtimeType != curr.runtimeType || prev != curr,
          builder: (context, state) {
            if (state is ScheduleLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ScheduleLoaded) {
              return ListView.builder(
                itemCount: state.schedules.length,
                itemBuilder: (context, index) {
                  final item = state.schedules[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        item.subject,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Vắng: ${item.currentAbsences} | Điểm: ${item.currentScore ?? '--'}",
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.edit_note,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        onPressed: () {
                          TeacherUpdateDialog.show(
                            context,
                            item,
                            teacherId: _currentTeacherId,
                            onSuccess: () {
                              context.read<ScheduleBloc>().add(LoadSchedules());
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            }
            return const Center(child: Text("Chưa có dữ liệu lớp học"));
          },
        ),
      ),
    );
  }
}
