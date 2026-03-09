import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';

class LessonResourcesTab extends StatefulWidget {
  final int moduleId;
  final int lessonId;

  const LessonResourcesTab({
    super.key,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  State<LessonResourcesTab> createState() => _LessonResourcesTabState();
}

class _LessonResourcesTabState extends State<LessonResourcesTab> {
  List<Map<String, dynamic>>? _lessonFiles;
  bool _filesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLessonFiles();
  }

  Future<void> _loadLessonFiles() async {
    if (_filesLoading || _lessonFiles != null) return;
    setState(() => _filesLoading = true);
    try {
      final api = sl<ApiClient>();
      final res = await api.get(
        '/courses/${widget.moduleId}/lesson_files?lessonId=${widget.lessonId}',
      );
      if (mounted) {
        setState(() {
          _lessonFiles = List<Map<String, dynamic>>.from(res['files'] ?? []);
          _filesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lessonFiles = [];
          _filesLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_filesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final files = _lessonFiles ?? [];
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có tài liệu đính kèm',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = file['fileName'] as String? ?? 'Untitled';
        final fileType = file['fileType'] as String? ?? '';
        final sizeBytes = file['fileSizeBytes'] as int? ?? 0;
        final downloadUrl = file['downloadUrl'] as String? ?? '';

        return Material(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang tải: $fileName'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              sl<ApiClient>().get(downloadUrl).catchError((_) {});
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _fileIconColor(fileType).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _fileIcon(fileType),
                      color: _fileIconColor(fileType),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${fileType.toUpperCase()} • ${_formatFileSize(sizeBytes)}',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.download_rounded, color: cs.primary, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _fileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'video':
        return Icons.videocam_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'image':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileIconColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'video':
        return AppColors.primary;
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'image':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
