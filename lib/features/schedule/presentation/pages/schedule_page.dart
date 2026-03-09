import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../injection_container.dart';
import '../../domain/enitities/schedule_entity.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/schedule_event.dart';
import '../bloc/schedule_state.dart';
import '../widgets/schedule_dialogs.dart';
import '../widgets/schedule_calendar_view.dart';
import '../../../../core/theme/app_colors.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final NotificationService _notificationService = NotificationService();
  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    _notificationService.requestPermissions();
  }

  void _saveAndSchedule(
    BuildContext context,
    List<ScheduleEntity> schedules,
    int minutesBefore,
    bool repeat,
  ) async {
    for (var item in schedules) {
      context.read<ScheduleBloc>().add(AddScheduleRequested(item));

      final scheduledTime = item.start.subtract(
        Duration(minutes: minutesBefore),
      );
      if (!repeat && scheduledTime.isBefore(DateTime.now())) {
      } else {
        int notificationId = item.subject.hashCode + item.start.hashCode;

        if (item.type == ScheduleType.exam) {
          await _notificationService.scheduleExamNotification(
            id: notificationId,
            subject: item.subject,
            room: item.room,
            startTime: item.start,
            minutesBefore: minutesBefore > 60 ? minutesBefore : 60,
          );
        } else {
          await _notificationService.scheduleClassNotification(
            id: notificationId,
            subject: item.subject,
            room: item.room,
            startTime: item.start,
            minutesBefore: minutesBefore,
            isRepeating: repeat,
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã lưu lịch học")));
    }
  }

  void _onEdit(BuildContext context, ScheduleEntity item) async {
    final result = await ScheduleDialogs.showScheduleForm(
      context,
      schedule: item,
    );
    if (result != null && mounted) {
      final updatedSchedule = result['schedule'] as ScheduleEntity;
      context.read<ScheduleBloc>().add(
        UpdateScheduleRequested(updatedSchedule),
      );

      if (updatedSchedule.id != null) {
        _saveAndSchedule(
          context,
          [updatedSchedule],
          result['minutes'],
          result['repeat'],
        );
      }
    }
  }

  void _onDelete(BuildContext context, ScheduleEntity item) async {
    final confirmed = await ScheduleDialogs.showDeleteConfirmation(
      context,
      item.subject,
    );
    if (confirmed && item.id != null && mounted) {
      context.read<ScheduleBloc>().add(DeleteScheduleRequested(item.id!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã xóa lịch học")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => sl<ScheduleBloc>()..add(LoadSchedules()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            appBar: AppBar(
              title: Text(
                'Lịch học',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              elevation: 0,
              centerTitle: false,
              actions: const [],
            ),
            body: BlocConsumer<ScheduleBloc, ScheduleState>(
              listener: (context, state) {
                if (state is ScheduleError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  context.read<ScheduleBloc>().add(LoadSchedules());
                }
                if (state is JoinClassSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vào lớp thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ScheduleLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                List<ScheduleEntity> appointments = [];
                if (state is ScheduleLoaded) appointments = state.schedules;

                return ScheduleCalendarView(
                  appointments: appointments,
                  calendarController: _calendarController,
                  onEdit: (item) => _onEdit(context, item),
                  onDelete: (item) => _onDelete(context, item),
                );
              },
            ),
            floatingActionButton: null,
          );
        },
      ),
    );
  }
}
