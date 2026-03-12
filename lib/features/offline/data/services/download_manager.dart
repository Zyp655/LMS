import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/download_task.dart';
import 'encryption_service.dart';

class DownloadManager {
  final EncryptionService encryptionService;
  final Map<int, _ActiveDownload> _activeDownloads = {};

  DownloadManager({required this.encryptionService});

  Stream<DownloadTask> downloadFile({
    required DownloadTask task,
    required String encryptionKey,
  }) {
    final controller = StreamController<DownloadTask>();
    _startDownload(task, encryptionKey, controller);
    return controller.stream;
  }

  Future<void> _startDownload(
    DownloadTask task,
    String encryptionKey,
    StreamController<DownloadTask> controller,
  ) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final downloadDir = Directory('${appDir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final tempPath =
          '${downloadDir.path}/temp_${task.lessonId}_${task.fileType}';
      final client = http.Client();
      final tempFile = File(tempPath);
      int downloadedBytes = 0;
      if (await tempFile.exists()) {
        downloadedBytes = await tempFile.length();
      }

      final request = http.Request('GET', Uri.parse(task.originalUrl));
      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      final response = await client.send(request);
      final totalBytes = task.fileSizeBytes > 0
          ? task.fileSizeBytes
          : (response.contentLength ?? 0) + downloadedBytes;

      final sink = tempFile.openWrite(mode: FileMode.append);

      final active = _ActiveDownload(
        task: task,
        client: client,
        controller: controller,
      );
      _activeDownloads[task.lessonId] = active;

      controller.add(task.copyWith(status: DownloadStatus.downloading));

      await for (final chunk in response.stream) {
        if (active.isPaused) {
          await active.resumeCompleter.future;
        }
        if (active.isCancelled) {
          sink.close();
          await tempFile.delete();
          controller.add(task.copyWith(status: DownloadStatus.failed));
          controller.close();
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        final progress = totalBytes > 0
            ? (downloadedBytes / totalBytes * 100)
            : 0.0;

        controller.add(
          task.copyWith(
            progressPercent: progress,
            status: DownloadStatus.downloading,
          ),
        );
      }

      await sink.flush();
      await sink.close();
      final encryptedPath = await encryptionService.encryptFile(
        tempPath,
        encryptionKey,
      );
      await tempFile.delete();

      controller.add(
        task.copyWith(
          localPath: encryptedPath,
          progressPercent: 100.0,
          status: DownloadStatus.completed,
        ),
      );

      _activeDownloads.remove(task.lessonId);
      controller.close();
    } catch (e) {
      controller.add(
        task.copyWith(status: DownloadStatus.failed, error: e.toString()),
      );
      controller.close();
    }
  }

  void pauseDownload(int lessonId) {
    _activeDownloads[lessonId]?.pause();
  }

  void resumeDownload(int lessonId) {
    _activeDownloads[lessonId]?.resume();
  }

  void cancelDownload(int lessonId) {
    _activeDownloads[lessonId]?.cancel();
    _activeDownloads.remove(lessonId);
  }
}

class _ActiveDownload {
  final DownloadTask task;
  final http.Client client;
  final StreamController<DownloadTask> controller;
  bool isPaused = false;
  bool isCancelled = false;
  Completer<void> resumeCompleter = Completer<void>();

  _ActiveDownload({
    required this.task,
    required this.client,
    required this.controller,
  });

  void pause() {
    isPaused = true;
    resumeCompleter = Completer<void>();
  }

  void resume() {
    isPaused = false;
    if (!resumeCompleter.isCompleted) {
      resumeCompleter.complete();
    }
  }

  void cancel() {
    isCancelled = true;
    client.close();
    if (!resumeCompleter.isCompleted) {
      resumeCompleter.complete();
    }
  }
}
