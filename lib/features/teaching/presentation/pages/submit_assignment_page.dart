import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../domain/entities/assignment_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/student_bloc.dart';
import '../bloc/student_event.dart';
import '../bloc/student_state.dart';
import '../../../../injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';

class SubmitAssignmentPage extends StatelessWidget {
  final AssignmentEntity assignment;

  const SubmitAssignmentPage({Key? key, required this.assignment})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<StudentBloc>(),
      child: SubmitAssignmentView(assignment: assignment),
    );
  }
}

class SubmitAssignmentView extends StatefulWidget {
  final AssignmentEntity assignment;

  const SubmitAssignmentView({Key? key, required this.assignment})
    : super(key: key);

  @override
  State<SubmitAssignmentView> createState() => _SubmitAssignmentViewState();
}

class _SubmitAssignmentViewState extends State<SubmitAssignmentView> {
  String _submissionType = 'link';
  File? _selectedFile;
  final _linkController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _linkController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'rar', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi chọn file: $e')));
    }
  }

  void _submit() {
    if (_submissionType == 'file' && _selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
                    content: Text('Vui lòng chọn file')));
      return;
    }

    if (_submissionType == 'link' && _linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
                    content: Text('Vui lòng nhập link')));
      return;
    }

    if (_submissionType == 'text' && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
                    content: Text('Vui lòng nhập nội dung')));
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
                    content: Text('Chưa đăng nhập')));
      return;
    }

    context.read<StudentBloc>().add(
      SubmitAssignmentEvent(
        assignmentId: widget.assignment.id!,
        studentId: authState.user!.id,
        file: _submissionType == 'file' ? _selectedFile : null,
        link: _submissionType == 'link' ? _linkController.text.trim() : null,
        text: _submissionType == 'text' ? _textController.text.trim() : null,
      ),
    );
  }

  bool _isLate() {
    return DateTime.now().isAfter(widget.assignment.dueDate);
  }

  @override
  Widget build(BuildContext context) {
    final isLate = _isLate();

    return Scaffold(
      appBar: AppBar(title: const Text('Nộp Bài')),
      body: BlocConsumer<StudentBloc, StudentState>(
        listener: (context, state) {
          if (state is SubmissionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is StudentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is StudentLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assignment.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (widget.assignment.description != null)
                          Text(
                            widget.assignment.description!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 20,
                              color: isLate ? Colors.red : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hạn nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.assignment.dueDate)}',
                              style: TextStyle(
                                color: isLate ? Colors.red : null,
                                fontWeight: isLate ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                        if (isLate)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đã quá hạn nộp bài',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Chọn hình thức nộp bài',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'link',
                      label: Text('Link'),
                      icon: Icon(Icons.link),
                    ),
                    ButtonSegment(
                      value: 'file',
                      label: Text('File'),
                      icon: Icon(Icons.upload_file),
                    ),
                    ButtonSegment(
                      value: 'text',
                      label: Text('Text'),
                      icon: Icon(Icons.text_fields),
                    ),
                  ],
                  selected: {_submissionType},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() {
                      _submissionType = selected.first;
                      if (_submissionType != 'file') _selectedFile = null;
                      if (_submissionType != 'link') _linkController.clear();
                      if (_submissionType != 'text') _textController.clear();
                    });
                  },
                ),
                const SizedBox(height: 24),

                if (_submissionType == 'file') ...[
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(Icons.folder_open),
                    label: const Text('Chọn File'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.insert_drive_file),
                        title: Text(_selectedFile!.path.split('/').last),
                        subtitle: Text(
                          '${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => setState(() => _selectedFile = null),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Định dạng hỗ trợ: PDF, DOC, DOCX, ZIP, RAR, TXT',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ] else if (_submissionType == 'link') ...[
                  TextField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      labelText: 'Link bài làm',
                      hintText: 'https://drive.google.com/...',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                      helperText:
                          'Ví dụ: Google Drive, GitHub, OneDrive, Dropbox',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ] else if (_submissionType == 'text') ...[
                  TextField(
                    controller: _textController,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: 'Nội dung bài làm',
                      hintText: 'Nhập nội dung bài làm của bạn...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isLate ? Colors.orange : null,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isLate ? 'Nộp Bài (Trễ hạn)' : 'Nộp Bài',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
