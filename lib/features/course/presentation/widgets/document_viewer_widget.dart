import 'package:flutter/material.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:http/http.dart' as http;

class DocumentViewerWidget extends StatefulWidget {
  final String? contentUrl;
  final String title;

  const DocumentViewerWidget({
    super.key,
    required this.contentUrl,
    required this.title,
  });

  @override
  State<DocumentViewerWidget> createState() => _DocumentViewerWidgetState();
}

class _DocumentViewerWidgetState extends State<DocumentViewerWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String _resolvedUrl = '';

  @override
  void initState() {
    super.initState();
    _resolveUrl();
  }

  void _resolveUrl() {
    var url = widget.contentUrl ?? '';
    if (url.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final base = ApiConstants.baseUrl;
      url = url.startsWith('/') ? '$base$url' : '$base/$url';
    }
    setState(() {
      _resolvedUrl = url;
      _isLoading = false;
    });
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_resolvedUrl);
    try {
      await http.head(uri);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.open_in_browser, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Đang mở tài liệu: ${widget.title}')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở tài liệu'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _resolvedUrl.isEmpty) {
      return _buildEmptyState(cs);
    }

    return Container(
      color: cs.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 56,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Tài liệu PDF',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Mở tài liệu'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy tài liệu',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
