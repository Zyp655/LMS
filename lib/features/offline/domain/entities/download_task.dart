import 'package:equatable/equatable.dart';

enum DownloadStatus { pending, downloading, paused, completed, failed }

class DownloadTask extends Equatable {
  final int lessonId;
  final int courseId;
  final String title;
  final String fileType;
  final String originalUrl;
  final String? localPath;
  final int fileSizeBytes;
  final double progressPercent;
  final DownloadStatus status;
  final String? error;

  const DownloadTask({
    required this.lessonId,
    required this.courseId,
    required this.title,
    required this.fileType,
    required this.originalUrl,
    this.localPath,
    required this.fileSizeBytes,
    this.progressPercent = 0.0,
    this.status = DownloadStatus.pending,
    this.error,
  });

  DownloadTask copyWith({
    String? localPath,
    double? progressPercent,
    DownloadStatus? status,
    String? error,
  }) {
    return DownloadTask(
      lessonId: lessonId,
      courseId: courseId,
      title: title,
      fileType: fileType,
      originalUrl: originalUrl,
      localPath: localPath ?? this.localPath,
      fileSizeBytes: fileSizeBytes,
      progressPercent: progressPercent ?? this.progressPercent,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  List<Object?> get props => [
    lessonId,
    courseId,
    title,
    fileType,
    originalUrl,
    localPath,
    fileSizeBytes,
    progressPercent,
    status,
    error,
  ];
}
