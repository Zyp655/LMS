import 'package:equatable/equatable.dart';

class StorageInfo extends Equatable {
  final int totalBytes;
  final int usedBytes;
  final List<CourseStorageInfo> courses;

  const StorageInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.courses,
  });

  int get freeBytes => totalBytes - usedBytes;
  double get usagePercent =>
      totalBytes > 0 ? usedBytes / totalBytes * 100 : 0.0;

  String get usedFormatted => _formatBytes(usedBytes);
  String get totalFormatted => _formatBytes(totalBytes);
  String get freeFormatted => _formatBytes(freeBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  List<Object?> get props => [totalBytes, usedBytes, courses];
}

class CourseStorageInfo extends Equatable {
  final int courseId;
  final String courseTitle;
  final int sizeBytes;
  final int downloadedLessons;
  final int totalLessons;

  const CourseStorageInfo({
    required this.courseId,
    required this.courseTitle,
    required this.sizeBytes,
    required this.downloadedLessons,
    required this.totalLessons,
  });

  String get sizeFormatted => StorageInfo._formatBytes(sizeBytes);

  @override
  List<Object?> get props => [
    courseId,
    courseTitle,
    sizeBytes,
    downloadedLessons,
    totalLessons,
  ];
}
