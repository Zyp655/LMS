import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/services/file_upload_service.dart';
import '../../../../course/presentation/bloc/course_detail_bloc.dart';
import '../../../../course/presentation/bloc/course_detail_event.dart';
import '../../../../course/presentation/bloc/course_detail_state.dart';
import '../file_upload_box.dart';
import '../../../../../core/theme/app_colors.dart';

class AddLessonDialog {
  static void show(BuildContext mainContext, int moduleId) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String type = 'video';
    String videoSource = 'url';
    String? selectedFileName;
    String? selectedFilePath;
    bool isUploading = false;

    showDialog(
      context: mainContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Thêm bài học mới'),
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
                      urlController.clear();
                      selectedFileName = null;
                      selectedFilePath = null;
                    }),
                  ),
                  const SizedBox(height: 16),

                  if (type == 'video') ...[
                    buildVideoSourceToggle(
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
                          labelText: 'URL Video (YouTube, Vimeo...)',
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

                        String? contentUrl;

                        if (type == 'video' && videoSource == 'url') {
                          if (urlController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                    content: Text('Vui lòng nhập URL Video'),
                              ),
                            );
                            return;
                          }
                          contentUrl = urlController.text;
                        }

                        if ((type == 'video' && videoSource == 'upload') ||
                            type == 'document') {
                          if (selectedFilePath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  type == 'video'
                                      ? 'Vui lòng chọn file video'
                                      : 'Vui lòng chọn tệp tài liệu',
                                ),
                              ),
                            );
                            return;
                          }

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

                        final courseId =
                            (BlocProvider.of<CourseDetailBloc>(
                                      mainContext,
                                    ).state
                                    as CourseDetailLoaded)
                                .course
                                .id;
                        BlocProvider.of<CourseDetailBloc>(mainContext).add(
                          CreateLessonEvent(
                            courseId: courseId,
                            moduleId: moduleId,
                            title: titleController.text,
                            type: type,
                            contentUrl: contentUrl,
                          ),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget buildVideoSourceToggle({
    required String videoSource,
    required VoidCallback onSelectUrl,
    required VoidCallback onSelectUpload,
  }) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onSelectUrl,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: videoSource == 'url'
                    ? AppColors.accent
                    : Colors.grey[200],
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.link,
                    size: 18,
                    color: videoSource == 'url'
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Nhập URL',
                    style: TextStyle(
                      color: videoSource == 'url'
                          ? Colors.white
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onSelectUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: videoSource == 'upload'
                    ? AppColors.accent
                    : Colors.grey[200],
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 18,
                    color: videoSource == 'upload'
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Upload từ máy',
                    style: TextStyle(
                      color: videoSource == 'upload'
                          ? Colors.white
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
