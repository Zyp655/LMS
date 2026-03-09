import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/submission_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class AssignmentSubmissionWidget extends StatefulWidget {
  final int assignmentId;
  final int studentId;

  const AssignmentSubmissionWidget({
    super.key,
    required this.assignmentId,
    required this.studentId,
  });

  @override
  State<AssignmentSubmissionWidget> createState() =>
      _AssignmentSubmissionWidgetState();
}

class _AssignmentSubmissionWidgetState extends State<AssignmentSubmissionWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _linkController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<SubmissionBloc>().add(
      LoadMySubmissionEvent(
        assignmentId: widget.assignmentId,
        studentId: widget.studentId,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _linkController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubmissionBloc, SubmissionState>(
      listener: (context, state) {
        if (state is SubmissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is SubmissionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        if (state is MySubmissionLoaded) {
          return _buildSubmissionStatus(state);
        }

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.link), text: 'Link Project'),
                Tab(icon: Icon(Icons.text_fields), text: 'Trả lời'),
                Tab(icon: Icon(Icons.image), text: 'Chụp ảnh'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildLinkTab(), _buildTextTab(), _buildImageTab()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: state is SubmissionLoading
                      ? null
                      : () => _submitAssignment(),
                  child: state is SubmissionLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Nộp bài'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmissionStatus(MySubmissionLoaded state) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            const Text(
              'Đã nộp bài thành công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (state.submission.grade != null) ...[
              const SizedBox(height: 16),
              Text(
                'Điểm: ${state.submission.grade}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
              },
              child: const Text('Nộp lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nộp link GitHub, Google Drive hoặc Figma',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              hintText: 'https://github.com/username/project',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập câu trả lời trực tiếp',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung bài làm ở đây...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Tính năng đang phát triển')),
              );
            },
            icon: Icon(Icons.add_a_photo),
            label: const Text('Chọn ảnh / Chụp ảnh'),
          ),
        ],
      ),
    );
  }

  void _submitAssignment() {
    String? link = _linkController.text.trim();
    String? text = _textController.text.trim();

    if (_tabController.index == 0) {
      if (link.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
                    content: Text('Vui lòng nhập link')));
        return;
      }
      text = null;
    } else if (_tabController.index == 1) {
      if (text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
                    content: Text('Vui lòng nhập nội dung')));
        return;
      }
      link = null;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
                    content: Text('Vui lòng chọn ảnh (Mock)')));
      return;
    }

    context.read<SubmissionBloc>().add(
      CreateSubmissionEvent(
        assignmentId: widget.assignmentId,
        studentId: widget.studentId,
        linkUrl: link,
        textContent: text,
      ),
    );
  }
}
