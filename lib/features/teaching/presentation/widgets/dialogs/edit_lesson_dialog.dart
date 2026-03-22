import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/services/file_upload_service.dart';
import '../../../../course/domain/entities/lesson_entity.dart';
import '../../../../course/presentation/bloc/course_detail_bloc.dart';
import '../../../../course/presentation/bloc/course_detail_event.dart';
import '../../../../course/presentation/bloc/course_detail_state.dart';
import '../file_upload_box.dart';
import '../../../../../core/theme/app_colors.dart';

class EditLessonDialog {
  static void show(BuildContext mainContext, LessonEntity lesson) {
    final titleController = TextEditingController(text: lesson.title);
    String type = lesson.type == LessonType.video ? 'video' : 'document';
    String? selectedFileName;
    String? uploadedUrl;
    bool isUploading = false;
    bool isPicking = false;

    Future<void> pickAndUpload(
      StateSetter setState,
      BuildContext context,
      String fileType,
      List<String> extensions,
    ) async {
      if (isPicking || isUploading) return;
      isPicking = true;
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: extensions,
        );
        if (result == null) {
          isPicking = false;
          return;
        }

        final file = File(result.files.single.path!);
        setState(() {
          selectedFileName = result.files.single.name;
          isUploading = true;
          uploadedUrl = null;
        });

        final uploadService = FileUploadService();
        final uploadResult = await uploadService.uploadFile(
          file: file,
          fileType: fileType,
        );

        if (uploadResult.isSuccess) {
          setState(() {
            uploadedUrl = uploadResult.uploadUrl;
            isUploading = false;
          });
        } else {
          setState(() {
            isUploading = false;
            selectedFileName = null;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uploadResult.errorMessage ?? 'Lỗi upload'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (_) {
        setState(() {
          isUploading = false;
          selectedFileName = null;
        });
      }
      isPicking = false;
    }

    showDialog(
      context: mainContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Chỉnh sửa bài học'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Tên bài học'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: 'Loại bài học',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'video', child: Text('Video')),
                      DropdownMenuItem(
                        value: 'document',
                        child: Text('Tài liệu (.pdf, .doc)'),
                      ),
                    ],
                    onChanged: isUploading
                        ? null
                        : (value) => setState(() {
                              type = value!;
                              selectedFileName = null;
                              uploadedUrl = null;
                            }),
                  ),
                  const SizedBox(height: 16),

                  if (type == 'video')
                    FileUploadBox(
                      selectedFileName: selectedFileName,
                      fileType: 'video',
                      onClear: isUploading
                          ? () {}
                          : () => setState(() {
                                selectedFileName = null;
                                uploadedUrl = null;
                              }),
                      onPick: () => pickAndUpload(
                        setState,
                        context,
                        'video',
                        ['mp4', 'mov', 'avi', 'webm'],
                      ),
                    ),

                  if (type == 'document')
                    FileUploadBox(
                      selectedFileName: selectedFileName,
                      fileType: 'document',
                      onClear: isUploading
                          ? () {}
                          : () => setState(() {
                                selectedFileName = null;
                                uploadedUrl = null;
                              }),
                      onPick: () => pickAndUpload(
                        setState,
                        context,
                        'document',
                        ['pdf', 'doc', 'docx'],
                      ),
                    ),

                  if (isUploading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text(
                      'Đang upload...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],

                  if (uploadedUrl != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Upload thành công!',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Vui lòng nhập tên bài học')),
                          );
                          return;
                        }

                        final contentUrl = uploadedUrl ?? lesson.contentUrl;

                        if (mainContext.mounted) {
                          BlocProvider.of<CourseDetailBloc>(mainContext).add(
                            UpdateLessonEvent(
                              courseId: (BlocProvider.of<CourseDetailBloc>(
                                        mainContext,
                                      ).state as CourseDetailLoaded)
                                  .course
                                  .id,
                              moduleId: lesson.moduleId,
                              lessonId: lesson.id,
                              title: titleController.text,
                              type: type,
                              contentUrl: contentUrl,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                child: const Text('Lưu thay đổi'),
              ),
            ],
          );
        },
      ),
    );
  }
}
