import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../schedule/domain/enitities/schedule_entity.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import '../../../../core/theme/app_colors.dart';

class ClassCodeManagerDialog extends StatelessWidget {
  final ScheduleEntity classItem;
  final int Function() getCurrentUserId;

  const ClassCodeManagerDialog({
    super.key,
    required this.classItem,
    required this.getCurrentUserId,
  });

  static void show(
    BuildContext context, {
    required ScheduleEntity classItem,
    required int Function() getCurrentUserId,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<TeacherBloc>(),
          child: ClassCodeManagerDialog(
            classItem: classItem,
            getCurrentUserId: getCurrentUserId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentCode = classItem.classCode ?? "Chưa có";

    return StatefulBuilder(
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
                  "Lớp: ${classItem.subject}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Phòng: ${classItem.room}"),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Mã tham gia:",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
                        Clipboard.setData(ClipboardData(text: currentCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                    content: Text("Đã sao chép mã!")),
                        );
                      },
                      icon: Icon(Icons.copy, size: 20),
                      label: const Text("Sao chép"),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.read<TeacherBloc>().add(
                          RegenerateCodeRequested(
                            getCurrentUserId(),
                            classItem.subject,
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
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng"),
              ),
            ],
          ),
        );
      },
    );
  }
}
