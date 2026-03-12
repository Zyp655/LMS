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
import 'add_lesson_dialog.dart';
import '../../../../../core/theme/app_colors.dart';

class EditLessonDialog {
  static void show(BuildContext mainContext, LessonEntity lesson) {
    final titleController = TextEditingController(text: lesson.title);
    final urlController = TextEditingController(text: lesson.contentUrl ?? '');
    String type = lesson.type == LessonType.video ? 'video' : 'document';
    String videoSource = 'url';
    if (lesson.contentUrl != null && !lesson.contentUrl!.startsWith('http')) {
      videoSource = 'upload';
    }

    String? selectedFileName;
    String? selectedFilePath;
    bool isUploading = false;

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
                    onChanged: (value) => setState(() {
                      type = value!;
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (type == 'video') ...[
                    AddLessonDialog.buildVideoSourceToggle(
                      videoSource: videoSource,
                      onSelectUrl: () => setState(() {
                        videoSource = 'url';
                        selectedFileName = null;
                        selectedFilePath = null;
                      }),
                      onSelectUpload: () => setState(() {
                        videoSource = 'upload';
                        urlController.clear();
                      }),
                    ),
                    const SizedBox(height: 16),
                    if (videoSource == 'url')
                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: 'URL Video',
                          hintText: 'https://youtube.com/watch?v=...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                    if (videoSource == 'upload')
                      FileUploadBox(
                        selectedFileName: selectedFileName,
                        fileType: 'video',
                        onClear: () => setState(() {
                          selectedFileName = null;
                          selectedFilePath = null;
                        }),
                        onPick: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'mp4',
                                  'mov',
                                  'avi',
                                  'webm',
                                ],
                              );
                          if (result != null) {
                            setState(() {
                              selectedFileName = result.files.single.name;
                              selectedFilePath = result.files.single.path;
                            });
                          }
                        },
                      ),
                  ],
                  if (type == 'document')
                    FileUploadBox(
                      selectedFileName: selectedFileName,
                      fileType: 'document',
                      onClear: () => setState(() {
                        selectedFileName = null;
                        selectedFilePath = null;
                      }),
                      onPick: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'doc', 'docx'],
                            );
                        if (result != null) {
                          setState(() {
                            selectedFileName = result.files.single.name;
                            selectedFilePath = result.files.single.path;
                          });
                        }
                      },
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
                    : () async {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                    content: Text('Vui lòng nhập tên bài học'),
                            ),
                          );
                          return;
                        }

                        String? contentUrl = lesson.contentUrl;

                        if (type == 'video' && videoSource == 'url') {
                          contentUrl = urlController.text;
                        } else if ((type == 'video' &&
                                videoSource == 'upload') ||
                            type == 'document') {
                          if (selectedFilePath != null) {
                            setState(() => isUploading = true);
                            final file = File(selectedFilePath!);
                            final uploadService = FileUploadService();
                            final result = await uploadService.uploadFile(
                              file: file,
                              fileType: type == 'video' ? 'video' : 'document',
                            );

                            if (!result.isSuccess) {
                              setState(() => isUploading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result.errorMessage ?? 'Lỗi upload',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                              return;
                            }
                            contentUrl = result.uploadUrl;
                            setState(() => isUploading = false);
                          }
                        }

                        if (mainContext.mounted) {
                          BlocProvider.of<CourseDetailBloc>(mainContext).add(
                            UpdateLessonEvent(
                              courseId:
                                  (BlocProvider.of<CourseDetailBloc>(
                                            mainContext,
                                          ).state
                                          as CourseDetailLoaded)
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
