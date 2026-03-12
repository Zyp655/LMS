import 'package:equatable/equatable.dart';

abstract class OfflineEvent extends Equatable {
  const OfflineEvent();
  @override
  List<Object?> get props => [];
}

class LoadOfflineStatus extends OfflineEvent {}

class DownloadLesson extends OfflineEvent {
  final int lessonId;
  final int courseId;
  final String title;
  final String contentUrl;
  const DownloadLesson({
    required this.lessonId,
    required this.courseId,
    required this.title,
    required this.contentUrl,
  });
  @override
  List<Object?> get props => [lessonId, courseId, title, contentUrl];
}

class PauseDownload extends OfflineEvent {
  final int lessonId;
  const PauseDownload(this.lessonId);
  @override
  List<Object?> get props => [lessonId];
}

class ResumeDownload extends OfflineEvent {
  final int lessonId;
  const ResumeDownload(this.lessonId);
  @override
  List<Object?> get props => [lessonId];
}

class CancelDownload extends OfflineEvent {
  final int lessonId;
  const CancelDownload(this.lessonId);
  @override
  List<Object?> get props => [lessonId];
}

class DeleteOfflineCourse extends OfflineEvent {
  final int courseId;
  const DeleteOfflineCourse(this.courseId);
  @override
  List<Object?> get props => [courseId];
}

class SyncPending extends OfflineEvent {}

class CheckConnectivity extends OfflineEvent {}

class ConnectivityChanged extends OfflineEvent {
  final bool isOnline;
  const ConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}
