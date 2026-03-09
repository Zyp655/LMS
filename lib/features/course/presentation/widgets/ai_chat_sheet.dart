import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';
import '../bloc/ai_assistant_state.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

class AiChatSheet extends StatefulWidget {
  final String lessonTitle;
  final String textContent;
  final String? contentUrl;

  const AiChatSheet({
    super.key,
    required this.lessonTitle,
    required this.textContent,
    this.contentUrl,
  });

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isTranscribingVideo = false;
  String _videoTranscript = '';

  static const _suggestedQuestions = [
    'Tóm tắt nội dung chính',
    'Giải thích khái niệm quan trọng',
    'Cho ví dụ thực tế',
  ];

  String get _effectiveTextContent {
    if (widget.textContent.isNotEmpty) return widget.textContent;
    if (_videoTranscript.isNotEmpty) return _videoTranscript;
    return '';
  }

  @override
  void initState() {
    super.initState();
    if (widget.textContent.isEmpty && widget.contentUrl != null) {
      _extractContent();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  bool _isDocumentUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.md') ||
        lower.contains('/documents/') ||
        lower.contains('/uploads/docs/');
  }

  Future<void> _extractContent() async {
    if (widget.contentUrl == null || widget.contentUrl!.isEmpty) return;

    setState(() => _isTranscribingVideo = true);

    try {
      var url = widget.contentUrl!;
      if (!url.startsWith('http')) {
        url = '${ApiConstants.baseUrl}/$url';
      }

      if (_isDocumentUrl(url)) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/ai/extract-document'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'documentUrl': url}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _videoTranscript = data['text'] as String? ?? '';
            _isTranscribingVideo = false;
          });
          return;
        }
      } else {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/ai/transcribe-video'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'videoUrl': url}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _videoTranscript = data['transcript'] as String? ?? '';
            _isTranscribingVideo = false;
          });
          return;
        }
      }

      setState(() => _isTranscribingVideo = false);
    } catch (_) {
      setState(() => _isTranscribingVideo = false);
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<AiAssistantBloc>().add(
      AskAiQuestion(
        lessonTitle: widget.lessonTitle,
        textContent: _effectiveTextContent,
        question: text.trim(),
      ),
    );
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/ai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    if (path == null) {
      setState(() => _isTranscribing = false);
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/ai/speech-to-text'),
      );
      request.files.add(await http.MultipartFile.fromPath('audio', path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'] as String;
        if (text.isNotEmpty) {
          setState(() => _isTranscribing = false);
          _sendMessage(text);
          return;
        }
      }
    } catch (_) {}

    setState(() => _isTranscribing = false);

    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(cs),
              const Divider(height: 1),
              if (_isTranscribingVideo) _buildVideoTranscribeBanner(cs),
              if (_isRecording) _buildRecordingBanner(cs),
              if (_isTranscribing) _buildTranscribingBanner(cs),
              Expanded(
                child: BlocConsumer<AiAssistantBloc, AiAssistantState>(
                  listener: (context, state) {
                    if (state is AiChatLoaded) _scrollToBottom();
                  },
                  builder: (context, state) {
                    final messages = _getMessages(state);
                    final isLoading = state is AiChatLoading;

                    if (messages.isEmpty && !isLoading) {
                      return _buildEmptyState(cs);
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == messages.length && isLoading) {
                          return _buildTypingIndicator(cs);
                        }
                        return _buildMessageBubble(messages[i], cs);
                      },
                    );
                  },
                ),
              ),
              _buildInput(cs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoTranscribeBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.primary.withAlpha(15),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đang phân tích nội dung video bài học...',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.red.withAlpha(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Đang ghi âm... Nhấn mic để dừng',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscribingBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.orange.withAlpha(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Đang nhận diện giọng nói...',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trợ lý AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      _isTranscribingVideo
                          ? 'Đang phân tích video...'
                          : _videoTranscript.isNotEmpty
                          ? 'Đã phân tích video ✓'
                          : 'Hỏi đáp theo nội dung bài học',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isTranscribingVideo
                            ? AppColors.primary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: cs.onSurfaceVariant),
                onPressed: () {
                  context.read<AiAssistantBloc>().add(ClearChat());
                },
                tooltip: 'Xóa hội thoại',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.psychology_rounded,
            size: 64,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _isTranscribingVideo
                ? 'Đang phân tích nội dung video...'
                : _videoTranscript.isNotEmpty
                ? 'Video đã được phân tích! Hãy hỏi bất kỳ điều gì'
                : 'Hỏi bất kỳ điều gì về bài học',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI sẽ trả lời dựa trên nội dung bài: "${widget.lessonTitle}"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ..._suggestedQuestions.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _sendMessage(q),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          q,
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message, ColorScheme cs) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.accent : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : cs.onSurface,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.accent.withValues(alpha: 0.1),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đang trả lời...',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _isTranscribing ? null : _toggleRecording,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? Colors.red
                      : (_isTranscribing
                            ? Colors.orange
                            : AppColors.primary.withAlpha(20)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording
                      ? Icons.stop_rounded
                      : (_isTranscribing
                            ? Icons.hourglass_top_rounded
                            : Icons.mic_rounded),
                  color: _isRecording || _isTranscribing
                      ? Colors.white
                      : AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: cs.onSurface, fontSize: 14),
                  enabled: !_isTranscribing,
                  decoration: InputDecoration(
                    hintText: _isTranscribing
                        ? 'Đang nhận diện...'
                        : 'Nhập câu hỏi hoặc nhấn 🎤',
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _isTranscribing
                    ? null
                    : () => _sendMessage(_controller.text),
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AiChatMessage> _getMessages(AiAssistantState state) {
    if (state is AiChatLoaded) return state.messages;
    if (state is AiChatLoading) return state.messages;
    if (state is AiError && state.previousMessages != null) {
      return state.previousMessages!;
    }
    return [];
  }
}
