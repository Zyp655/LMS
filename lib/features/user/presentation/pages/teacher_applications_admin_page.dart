import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart' as di;
import '../../data/models/teacher_application_model.dart';
import '../bloc/teacher_app_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherApplicationsAdminPage extends StatelessWidget {
  const TeacherApplicationsAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<TeacherAppBloc>()..add(LoadAllApplicationsEvent()),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatefulWidget {
  const _AdminView();

  @override
  State<_AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<_AdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _activeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        _activeFilter = 0;
        break;
      case 1:
        _activeFilter = 1;
        break;
      case 2:
        _activeFilter = 2;
        break;
    }
    context.read<TeacherAppBloc>().add(
      LoadAllApplicationsEvent(statusFilter: _activeFilter),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.grey[100];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Quản lý đơn đăng ký Giảng viên'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã duyệt'),
            Tab(text: 'Từ chối'),
          ],
        ),
      ),
      body: BlocConsumer<TeacherAppBloc, TeacherAppState>(
        listener: (context, state) {
          if (state is ApplicationReviewed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<TeacherAppBloc>().add(
              LoadAllApplicationsEvent(statusFilter: _activeFilter),
            );
          } else if (state is TeacherAppError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TeacherAppLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AllApplicationsLoaded) {
            if (state.applications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không có đơn nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.applications.length,
              itemBuilder: (context, index) {
                final app = state.applications[index];
                return GestureDetector(
                  onTap: () => _showDetailSheet(context, app),
                  child: _ApplicationCard(
                    application: app,
                    isDark: isDark,
                    onApprove: app.status == 0
                        ? () => _showConfirmStep(context, app, true)
                        : null,
                    onReject: app.status == 0
                        ? () => _showConfirmStep(context, app, false)
                        : null,
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showConfirmStep(
    BuildContext ctx,
    TeacherApplicationEntity app,
    bool isApprove,
  ) {
    final color = isApprove ? Colors.green : Colors.red;
    final icon = isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = isApprove ? 'Duyệt đơn' : 'Từ chối đơn';
    final body = isApprove
        ? 'Bạn có chắc muốn DUYỆT đơn của\n"${app.fullName}"?\n\nNgười này sẽ được nâng cấp thành Giảng viên.'
        : 'Bạn có chắc muốn TỪ CHỐI đơn của\n"${app.fullName}"?\n\nHành động này không thể hoàn tác.';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          icon: Icon(icon, color: color, size: 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          content: Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Huỷ'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _showNoteStep(ctx, app, isApprove);
              },
              child: Text(isApprove ? 'Tiếp tục duyệt' : 'Tiếp tục từ chối'),
            ),
          ],
        );
      },
    );
  }

  void _showNoteStep(
    BuildContext ctx,
    TeacherApplicationEntity app,
    bool isApprove,
  ) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isApprove ? 'Ghi chú duyệt' : 'Ghi chú từ chối',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thêm ghi chú cho ${app.fullName} (tuỳ chọn):',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập ghi chú...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Quay lại'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: Icon(isApprove ? Icons.check : Icons.close, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ctx.read<TeacherAppBloc>().add(
                  ReviewApplicationEvent(
                    applicationId: app.id!,
                    status: isApprove ? 1 : 2,
                    adminNote: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                  ),
                );
                Navigator.pop(dialogCtx);
              },
              label: Text(isApprove ? 'Xác nhận duyệt' : 'Xác nhận từ chối'),
            ),
          ],
        );
      },
    );
  }

  void _showDetailSheet(BuildContext ctx, TeacherApplicationEntity app) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      builder: (_) {
        final textColor = isDark ? Colors.white : Colors.black87;
        final subColor = isDark ? Colors.grey[400] : Colors.grey[600];

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(
                          0xFF667eea,
                        ).withValues(alpha: 0.15),
                        child: Text(
                          app.fullName.isNotEmpty
                              ? app.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.fullName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (app.createdAt != null)
                              Text(
                                'Ngày nộp: ${_formatDate(app.createdAt!)}',
                                style: TextStyle(fontSize: 13, color: subColor),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.lightbulb,
                    'Chuyên môn',
                    app.expertise,
                    textColor,
                  ),
                  if (app.experience.isNotEmpty)
                    _detailRow(
                      Icons.work,
                      'Kinh nghiệm',
                      app.experience,
                      textColor,
                    ),
                  if (app.qualifications.isNotEmpty)
                    _detailRow(
                      Icons.card_membership,
                      'Bằng cấp',
                      app.qualifications,
                      textColor,
                    ),
                  _detailRow(Icons.edit_note, 'Lý do', app.reason, textColor),
                  if (app.adminNote != null && app.adminNote!.isNotEmpty)
                    _detailRow(
                      Icons.comment,
                      'Ghi chú Admin',
                      app.adminNote!,
                      textColor,
                    ),
                  const SizedBox(height: 16),
                  if (app.status == 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showConfirmStep(ctx, app, false);
                            },
                            icon: Icon(Icons.close, size: 18),
                            label: const Text('Từ chối'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showConfirmStep(ctx, app, true);
                            },
                            icon: Icon(Icons.check, size: 18),
                            label: const Text('Duyệt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  final TeacherApplicationEntity application;
  final bool isDark;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ApplicationCard({
    required this.application,
    required this.isDark,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  application.fullName.isNotEmpty
                      ? application.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (application.createdAt != null)
                      Text(
                        _formatDate(application.createdAt!),
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                  ],
                ),
              ),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.lightbulb,
            'Chuyên môn',
            application.expertise,
            textColor,
            subColor,
          ),
          if (application.experience.isNotEmpty)
            _infoRow(
              Icons.work,
              'Kinh nghiệm',
              application.experience,
              textColor,
              subColor,
            ),
          if (application.qualifications.isNotEmpty)
            _infoRow(
              Icons.card_membership,
              'Bằng cấp',
              application.qualifications,
              textColor,
              subColor,
            ),
          _infoRow(
            Icons.edit_note,
            'Lý do',
            application.reason,
            textColor,
            subColor,
          ),

          if (application.adminNote != null &&
              application.adminNote!.isNotEmpty)
            _infoRow(
              Icons.comment,
              'Ghi chú admin',
              application.adminNote!,
              textColor,
              subColor,
            ),

          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onReject != null)
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: Icon(Icons.close, size: 18),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (onApprove != null)
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: Icon(Icons.check, size: 18),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge() {
    Color color;
    String text;
    switch (application.status) {
      case 0:
        color = AppColors.warning;
        text = 'Chờ duyệt';
        break;
      case 1:
        color = AppColors.success;
        text = 'Đã duyệt';
        break;
      case 2:
        color = AppColors.error;
        text = 'Từ chối';
        break;
      default:
        color = Colors.grey;
        text = '?';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color? subColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: subColor),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 13, color: subColor)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
