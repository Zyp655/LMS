import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../course/domain/entities/module_entity.dart';
import '../../../../course/presentation/bloc/course_detail_bloc.dart';
import '../../../../course/presentation/bloc/course_detail_event.dart';
import '../../../../course/presentation/bloc/course_detail_state.dart';

class ModuleDialogs {
  static void showAddModule(BuildContext mainContext) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: mainContext,
      builder: (context) => AlertDialog(
        title: const Text('Thêm chương mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Tên chương'),
              autofocus: true,
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Mô tả (tùy chọn)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                BlocProvider.of<CourseDetailBloc>(mainContext).add(
                  CreateModuleEvent(
                    courseId:
                        (BlocProvider.of<CourseDetailBloc>(mainContext).state
                                as CourseDetailLoaded)
                            .course
                            .id,
                    title: titleController.text,
                    description: descriptionController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  static void showUpdateModule(BuildContext mainContext, ModuleEntity module) {
    final titleController = TextEditingController(text: module.title);
    final descriptionController = TextEditingController(
      text: module.description,
    );

    showDialog(
      context: mainContext,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa chương'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Tên chương'),
              autofocus: true,
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Mô tả (tùy chọn)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ScaffoldMessenger.of(mainContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Tính năng cập nhật đang được hoàn thiện backend',
                    ),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
