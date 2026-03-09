import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/module_entity.dart';
import '../bloc/learning_player_bloc.dart';
import '../bloc/learning_player_event.dart';
import '../../../../injection_container.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/route/app_route.dart';

import '../widgets/assignment_submission_widget.dart';
import '../widgets/lesson_overview_tab.dart';

import '../widgets/lesson_notes_tab.dart';
import '../widgets/lesson_list_sheet.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../../../../core/api/api_client.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../analytics/presentation/bloc/analytics_event.dart';
import '../../../offline/presentation/bloc/offline_bloc.dart';
import '../../../offline/presentation/widgets/download_lesson_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/segment_quiz_overlay.dart';
import '../widgets/verify_quiz_overlay.dart';

class LessonPlayerPage extends StatelessWidget {
  final LessonEntity lesson;
  final int userId;
  final int? startPosition;
  final LessonEntity? previousLesson;
  final LessonEntity? nextLesson;
  final List<ModuleEntity>? allModules;

  const LessonPlayerPage({
    super.key,
    required this.lesson,
    required this.userId,
    this.startPosition,
    this.previousLesson,
    this.nextLesson,
    this.allModules,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<LearningPlayerBloc>()),
        BlocProvider(
          create: (_) => AiAssistantBloc(apiClient: sl<ApiClient>()),
        ),
        BlocProvider(create: (_) => sl<AnalyticsBloc>()),
        BlocProvider(create: (_) => sl<OfflineBloc>()),
      ],
      child: LessonPlayerView(
        lesson: lesson,
        userId: userId,
        startPosition: startPosition,
        previousLesson: previousLesson,
        nextLesson: nextLesson,
        allModules: allModules,
      ),
    );
  }
}

class LessonPlayerView extends StatefulWidget {
  final LessonEntity lesson;
  final int userId;
  final int? startPosition;
  final LessonEntity? previousLesson;
  final LessonEntity? nextLesson;
  final List<ModuleEntity>? allModules;

  const LessonPlayerView({
    super.key,
    required this.lesson,
    required this.userId,
    this.startPosition,
    this.previousLesson,
    this.nextLesson,
    this.allModules,
  });

  @override
  State<LessonPlayerView> createState() => _LessonPlayerViewState();
}

class _LessonPlayerViewState extends State<LessonPlayerView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressTimer;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _canRetry = false;
  late TabController _tabController;

  Duration _maxWatchedPosition = Duration.zero;
  bool _isSeeking = false;
  bool _hasMarkedComplete = false;
  late final DateTime _sessionStart;

  late final AnalyticsBloc _analyticsBloc;
  late final LearningPlayerBloc _learningPlayerBloc;
  int _accumulatedWatchSeconds = 0;
  Timer? _watchTimeReportTimer;
  bool _isReviewMode = false;
  bool _wasPausedByFocusLoss = false;
  List<Map<String, dynamic>> _segments = [];
  final Set<int> _completedSegments = {};
  bool _showQuizOverlay = false;
  Map<String, dynamic>? _currentQuiz;
  int _currentQuizSegmentIndex = -1;
  int _currentSegmentId = 0;

  int _verifyWatchSeconds = 0;
  Timer? _verifyTimer;
  bool _showVerifyOverlay = false;
  Map<String, dynamic>? _verifyQuizData;
  bool _isLoadingVerify = false;
  static const _verifyIntervalSeconds = 600;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStart = DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
    _analyticsBloc = context.read<AnalyticsBloc>();
    _learningPlayerBloc = context.read<LearningPlayerBloc>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lessonDate = DateTime(
      widget.lesson.createdAt.year,
      widget.lesson.createdAt.month,
      widget.lesson.createdAt.day,
    );
    _isReviewMode = lessonDate.isBefore(today);

    _initializePlayer();
    _loadSegments();

    _analyticsBloc.add(
      TrackActivity(
        userId: widget.userId,
        activityType: 'start_lesson',
        lessonId: widget.lesson.id,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_videoController != null && _videoController!.value.isPlaying) {
        _videoController!.pause();
        _wasPausedByFocusLoss = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPausedByFocusLoss && _videoController != null) {
        _wasPausedByFocusLoss = false;
      }
    }
  }

  void _setError(String message, {bool canRetry = false}) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _canRetry = canRetry;
      });
    }
  }

  Future<void> _retryPlayer() async {
    _chewieController?.dispose();
    _videoController?.removeListener(_onVideoPositionChanged);
    _videoController?.dispose();
    _progressTimer?.cancel();
    setState(() {
      _videoController = null;
      _chewieController = null;
      _isInitialized = false;
      _errorMessage = null;
      _canRetry = false;
    });
    await _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.lesson.type == LessonType.assignment) {
      setState(() => _isInitialized = true);
      return;
    }

    if (widget.lesson.contentUrl == null || widget.lesson.contentUrl!.isEmpty) {
      _setError('Không tìm thấy URL video');
      return;
    }

    var finalUrl = widget.lesson.contentUrl!;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      final baseUrl = ApiConstants.baseUrl;
      finalUrl = finalUrl.startsWith('/')
          ? '$baseUrl$finalUrl'
          : '$baseUrl/$finalUrl';
    }

    try {
      if (!kIsWeb && Platform.isAndroid && finalUrl.contains('localhost')) {
        finalUrl = finalUrl.replaceFirst('localhost', '10.0.2.2');
      }

      _videoController = VideoPlayerController.networkUrl(Uri.parse(finalUrl));
      await _videoController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Video tải quá chậm');
        },
      );

      if (widget.startPosition != null && widget.startPosition! > 0) {
        final start = Duration(seconds: widget.startPosition!);
        _maxWatchedPosition = start;
        await _videoController!.seekTo(start);
      }

      _videoController!.addListener(_onVideoPositionChanged);

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.accent,
          handleColor: AppColors.accent,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.white30,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
      );

      _startProgressTracking();
      setState(() => _isInitialized = true);
    } on SocketException {
      _setError(
        'Không có kết nối mạng.\nVui lòng kiểm tra WiFi hoặc dữ liệu di động.',
        canRetry: true,
      );
    } on TimeoutException {
      _setError(
        'Video tải quá chậm.\nVui lòng kiểm tra kết nối mạng và thử lại.',
        canRetry: true,
      );
    } on HttpException {
      _setError(
        'Không thể tải video từ máy chủ.\nVideo có thể đã bị xóa hoặc di chuyển.',
        canRetry: true,
      );
    } on FormatException {
      _setError('Định dạng URL video không hợp lệ.');
    } catch (e) {
      _setError('Lỗi phát video: ${e.toString()}', canRetry: true);
    }
  }

  void _onVideoPositionChanged() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    if (_videoController!.value.hasError) {
      _setError(
        'Lỗi phát video. Video có thể bị hỏng hoặc định dạng không được hỗ trợ.',
        canRetry: true,
      );
      return;
    }

    final currentPos = _videoController!.value.position;
    final totalDuration = _videoController!.value.duration;

    if (currentPos > _maxWatchedPosition) {
      if (currentPos - _maxWatchedPosition < const Duration(seconds: 2)) {
        _maxWatchedPosition = currentPos;
      }
    }

    if (currentPos > _maxWatchedPosition + const Duration(seconds: 5)) {
      if (!_isSeeking) {
        _isSeeking = true;
        _videoController!.seekTo(_maxWatchedPosition);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Bạn chưa thể tua qua phần này! Hãy học tuần tự.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(
          const Duration(milliseconds: 500),
          () => _isSeeking = false,
        );
      }
    }

    if (!_hasMarkedComplete && totalDuration.inSeconds > 0) {
      final percentWatched = currentPos.inSeconds / totalDuration.inSeconds;
      final isNearEnd = totalDuration.inSeconds - currentPos.inSeconds <= 3;
      if (percentWatched >= 0.95 || isNearEnd) {
        _hasMarkedComplete = true;
        _onVideoComplete();
        _autoNavigateToNextLesson();
      }
    }

    if (_segments.isNotEmpty && !_showQuizOverlay) {
      final posSec = currentPos.inSeconds.toDouble();
      for (final seg in _segments) {
        final segIdx = seg['segmentIndex'] as int;
        final endTs = (seg['endTimestamp'] as num).toDouble();
        if (_completedSegments.contains(segIdx)) continue;
        final attempt = seg['attempt'] as Map<String, dynamic>?;
        if (attempt != null && attempt['passed'] == true) {
          _completedSegments.add(segIdx);
          continue;
        }
        if (posSec >= endTs - 1 && posSec <= endTs + 2) {
          _videoController?.pause();
          final quizStr = seg['quizQuestion'] as String? ?? '{}';
          setState(() {
            _showQuizOverlay = true;
            _currentQuiz = jsonDecode(quizStr) as Map<String, dynamic>;
            _currentQuizSegmentIndex = segIdx;
            _currentSegmentId = seg['id'] as int;
          });
          break;
        }
      }
    }
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_videoController != null && _videoController!.value.isPlaying) {
        _learningPlayerBloc.add(
          UpdateProgressEvent(
            userId: widget.userId,
            lessonId: widget.lesson.id,
            currentPosition: _videoController!.value.position.inSeconds,
          ),
        );
        _accumulatedWatchSeconds += 10;
      }
    });

    _watchTimeReportTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _reportWatchTime();
    });

    _verifyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_videoController != null &&
          _videoController!.value.isPlaying &&
          !_showVerifyOverlay &&
          !_showQuizOverlay &&
          !_isReviewMode) {
        _verifyWatchSeconds += 5;
        if (_verifyWatchSeconds >= _verifyIntervalSeconds) {
          _triggerVerifyQuiz();
        }
      }
    });
  }

  Future<void> _triggerVerifyQuiz() async {
    if (_isLoadingVerify || _showVerifyOverlay) return;
    _videoController?.pause();
    setState(() => _isLoadingVerify = true);

    try {
      final totalDuration = _videoController?.value.duration ?? Duration.zero;
      final currentPos = _videoController?.value.position ?? Duration.zero;
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/ai/verify-watching'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lessonTitle': widget.lesson.title,
          'currentMinute': currentPos.inMinutes,
          'totalMinutes': totalDuration.inMinutes.clamp(1, 999),
          'textContent': widget.lesson.textContent ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final quiz = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _verifyQuizData = quiz;
          _showVerifyOverlay = true;
          _isLoadingVerify = false;
        });
      } else {
        setState(() => _isLoadingVerify = false);
        _verifyWatchSeconds = 0;
        _videoController?.play();
      }
    } catch (_) {
      setState(() => _isLoadingVerify = false);
      _verifyWatchSeconds = 0;
      _videoController?.play();
    }
  }

  void _onVerifyResult(bool correct) {
    if (correct) {
      setState(() {
        _showVerifyOverlay = false;
        _verifyQuizData = null;
        _verifyWatchSeconds = 0;
      });
      _videoController?.play();
    }
  }

  Future<void> _loadSegments() async {
    try {
      final api = sl<ApiClient>();
      final response = await api.get(
        '/lesson/segments?lessonId=${widget.lesson.id}&userId=${widget.userId}',
      );
      if (response != null && response['segments'] != null) {
        final list = (response['segments'] as List)
            .cast<Map<String, dynamic>>();
        setState(() => _segments = list);
        for (final seg in list) {
          final attempt = seg['attempt'] as Map<String, dynamic>?;
          if (attempt != null && attempt['passed'] == true) {
            _completedSegments.add(seg['segmentIndex'] as int);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _onQuizAnswer(int answerIndex) async {
    try {
      final api = sl<ApiClient>();
      final response = await api.post('/lesson/segment-quiz-attempt', {
        'studentId': widget.userId,
        'segmentId': _currentSegmentId,
        'answerIndex': answerIndex,
      });
      if (response == null) return;

      final correct = response['correct'] as bool? ?? false;
      final shouldRewind = response['shouldRewind'] as bool? ?? false;

      if (correct) {
        _completedSegments.add(_currentQuizSegmentIndex);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() => _showQuizOverlay = false);
            _videoController?.play();
          }
        });
      } else if (shouldRewind) {
        final rewindTo = (response['rewindTo'] as num?)?.toDouble() ?? 0;
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() => _showQuizOverlay = false);
            _videoController?.seekTo(Duration(seconds: rewindTo.toInt()));
            _videoController?.play();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _reportWatchTime() async {
    if (_accumulatedWatchSeconds <= 0 || _isReviewMode) return;
    final seconds = _accumulatedWatchSeconds;
    _accumulatedWatchSeconds = 0;
    try {
      final api = sl<ApiClient>();
      await api.post('/student/daily-learning-log', {
        'scheduleId': widget.lesson.moduleId,
        'watchSeconds': seconds,
      });
    } catch (_) {}
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  void _onVideoComplete() {
    _learningPlayerBloc.add(
      MarkLessonCompleteEvent(
        userId: widget.userId,
        lessonId: widget.lesson.id,
      ),
    );

    final duration = DateTime.now().difference(_sessionStart).inMinutes;
    _analyticsBloc.add(
      TrackActivity(
        userId: widget.userId,
        activityType: 'complete_lesson',
        lessonId: widget.lesson.id,
        durationMinutes: duration,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Đã hoàn thành bài học!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _autoNavigateToNextLesson() {
    if (widget.nextLesson != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.arrow_forward, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đang chuyển đến: ${widget.nextLesson!.title}'),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go(
            AppRoutes.lessonPlayer,
            extra: {
              'lesson': widget.nextLesson,
              'userId': widget.userId,
              'previousLesson': widget.lesson,
              'nextLesson': null,
            },
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final duration = DateTime.now().difference(_sessionStart).inMinutes;
    _analyticsBloc.add(
      TrackActivity(
        userId: widget.userId,
        activityType: 'leave',
        lessonId: widget.lesson.id,
        durationMinutes: duration,
      ),
    );

    _reportWatchTime();

    if (_videoController != null) {
      _videoController!.removeListener(_onVideoPositionChanged);
      _learningPlayerBloc.add(
        UpdateProgressEvent(
          userId: widget.userId,
          lessonId: widget.lesson.id,
          currentPosition: _videoController!.value.position.inSeconds,
        ),
      );
    }
    _progressTimer?.cancel();
    _watchTimeReportTimer?.cancel();
    _verifyTimer?.cancel();
    _chewieController?.dispose();
    _videoController?.dispose();
    _tabController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  List<LessonEntity> get _allLessons {
    final list = <LessonEntity>[];
    if (widget.allModules != null) {
      for (final m in widget.allModules!) {
        if (m.lessons != null) list.addAll(m.lessons!);
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceDim,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildVideoSection(),

            _buildProgressStrip(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    _buildTabBar(cs),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          LessonOverviewTab(
                            lesson: widget.lesson,
                            videoController: _videoController,
                            isVideoInitialized: _isInitialized,
                          ),
                          const LessonNotesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomControls(cs),
    );
  }

  Widget _buildVideoSection() {
    final cs = Theme.of(context).colorScheme;
    if (widget.lesson.type == LessonType.assignment) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        color: cs.surface,
        child: AssignmentSubmissionWidget(
          assignmentId: widget.lesson.id,
          studentId: widget.userId,
        ),
      );
    }

    return Stack(
      children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
            minHeight: 180,
          ),
          color: Colors.black,
          child: _isInitialized
              ? Chewie(controller: _chewieController!)
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.accent,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (_canRetry) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _retryPlayer,
                            icon: Icon(Icons.refresh_rounded),
                            label: const Text('Thử lại'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
        ),
        if (_showQuizOverlay && _currentQuiz != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: SingleChildScrollView(
                  child: SegmentQuizOverlay(
                    quizData: _currentQuiz!,
                    segmentIndex: _currentQuizSegmentIndex,
                    attemptCount: 0,
                    segmentTimeRange: _getSegmentTimeRange(),
                    onAnswer: _onQuizAnswer,
                    onDismiss: () {
                      setState(() => _showQuizOverlay = false);
                      _videoController?.play();
                    },
                  ),
                ),
              ),
            ),
          ),
        if (_showVerifyOverlay && _verifyQuizData != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: SingleChildScrollView(
                  child: VerifyQuizOverlay(
                    quizData: _verifyQuizData!,
                    watchedMinutes: (_verifyWatchSeconds / 60).round(),
                    onResult: _onVerifyResult,
                  ),
                ),
              ),
            ),
          ),
        if (_isLoadingVerify)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.warning),
                    const SizedBox(height: 16),
                    Text(
                      'Đang tạo câu hỏi xác minh...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getSegmentTimeRange() {
    if (_segments.isEmpty || _currentQuizSegmentIndex < 0) return '';
    for (final seg in _segments) {
      if (seg['segmentIndex'] == _currentQuizSegmentIndex) {
        final start = (seg['startTimestamp'] as num).toDouble();
        final end = (seg['endTimestamp'] as num).toDouble();
        final startMin = (start / 60).floor().toString().padLeft(2, '0');
        final startSec = (start % 60).floor().toString().padLeft(2, '0');
        final endMin = (end / 60).floor().toString().padLeft(2, '0');
        final endSec = (end % 60).floor().toString().padLeft(2, '0');
        return '$startMin:$startSec - $endMin:$endSec';
      }
    }
    return '';
  }

  Widget _buildProgressStrip() {
    if (!_isInitialized ||
        _videoController == null ||
        !_videoController!.value.isInitialized ||
        widget.lesson.type == LessonType.assignment) {
      return const SizedBox.shrink();
    }

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.darkBackground,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),

              Text(
                _formatDuration(duration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.accent,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: AppColors.accent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Ghi chú'),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ColorScheme cs) {
    final allLessons = _allLessons;
    final currentIndex = allLessons.indexWhere((l) => l.id == widget.lesson.id);
    final bool hasPrev = currentIndex > 0;
    final bool hasNext =
        currentIndex >= 0 && currentIndex < allLessons.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () {
                if (hasPrev) {
                  context.go(
                    AppRoutes.lessonPlayer,
                    extra: {
                      'lesson': allLessons[currentIndex - 1],
                      'userId': widget.userId,
                      'allModules': widget.allModules,
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đây là bài học đầu tiên')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Icon(Icons.skip_previous, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => LessonListSheet.show(
                  context,
                  allLessons: allLessons,
                  currentIndex: currentIndex,
                  allModules: widget.allModules,
                  userId: widget.userId,
                ),
                icon: Icon(Icons.menu_book, size: 20),
                label: Text(
                  allLessons.isNotEmpty
                      ? 'Bài ${currentIndex + 1}/${allLessons.length}'
                      : 'Đang học',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DownloadLessonButton(
              lessonId: widget.lesson.id,
              courseId: widget.lesson.moduleId,
              title: widget.lesson.title,
              contentUrl: widget.lesson.contentUrl ?? '',
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                if (hasNext) {
                  context.read<LearningPlayerBloc>().add(
                    MarkLessonCompleteEvent(
                      userId: widget.userId,
                      lessonId: widget.lesson.id,
                    ),
                  );
                  context.go(
                    AppRoutes.lessonPlayer,
                    extra: {
                      'lesson': allLessons[currentIndex + 1],
                      'userId': widget.userId,
                      'allModules': widget.allModules,
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đây là bài học cuối cùng')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Icon(Icons.skip_next, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
