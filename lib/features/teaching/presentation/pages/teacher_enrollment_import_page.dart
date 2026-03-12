import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';

class TeacherEnrollmentImportPage extends StatefulWidget {
  final int classId;
  final int teacherId;
  final String className;

  const TeacherEnrollmentImportPage({
    super.key,
    required this.classId,
    required this.teacherId,
    required this.className,
  });

  @override
  State<TeacherEnrollmentImportPage> createState() =>
      _TeacherEnrollmentImportPageState();
}

class _TeacherEnrollmentImportPageState
    extends State<TeacherEnrollmentImportPage> {
  int _currentStep = 0;
  bool _isProcessing = false;
  String? _selectedFileName;
  List<String> _identifiers = [];

  Future<void> _downloadTemplate() async {
    setState(() => _isProcessing = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['GhiDanh'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#14B8A6'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      );
      cell.value = TextCellValue('Email hoặc Mã SV (*)');
      cell.cellStyle = headerStyle;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'nguyenvana@example.com',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
          .value = TextCellValue(
        'SV001',
      );

      sheet.setColumnWidth(0, 35);

      final bytes = excel.save();
      if (bytes == null) throw Exception('Không thể tạo tệp');

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/MauGhiDanh_${widget.className}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      _snack('Đã lưu tệp mẫu tại:\n$filePath');
    } catch (e) {
      _snack('Lỗi tạo tệp mẫu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickAndParseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _selectedFileName = result.files.first.name;
    });

    try {
      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) throw Exception('Không đọc được tệp');

      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.maxRows < 2) {
        throw Exception('Tệp không có dữ liệu');
      }

      final ids = <String>[];
      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        if (row.isEmpty) continue;
        final val = row[0]?.value?.toString().trim() ?? '';
        if (val.isNotEmpty) ids.add(val);
      }

      if (ids.isEmpty) throw Exception('Không tìm thấy identifier hợp lệ');

      final unique = ids.toSet().toList();

      setState(() {
        _identifiers = unique;
        _currentStep = 1;
      });
    } catch (e) {
      _snack('Lỗi đọc tệp: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _submitEnrollment() {
    setState(() => _isProcessing = true);
    context.read<TeacherBloc>().add(
      EnrollStudentsByFile(
        classId: widget.classId,
        teacherId: widget.teacherId,
        identifiers: _identifiers,
      ),
    );
  }

  void _resetFlow() {
    setState(() {
      _currentStep = 0;
      _identifiers = [];
      _selectedFileName = null;
    });
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? cs.onError : cs.onInverseSurface,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError ? cs.error : null,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return BlocListener<TeacherBloc, TeacherState>(
      listener: (context, state) {
        if (state is EnrollmentImportResult) {
          setState(() {
            _isProcessing = false;
            _currentStep = 2;
          });
        } else if (state is TeacherError) {
          setState(() => _isProcessing = false);
          _snack(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          title: Text('Ghi danh: ${widget.className}'),
          centerTitle: true,
          elevation: 0,
        ),
        body: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang xử lý...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Chỉ ghi danh sinh viên đã có tài khoản. '
                              'Không tạo tài khoản mới.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_currentStep == 0) _buildUploadSection(isDark),
                    if (_currentStep == 1) _buildPreviewSection(isDark),
                    if (_currentStep == 2) _buildResultSection(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUploadSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          isDark: isDark,
          icon: Icons.description_outlined,
          iconColor: AppColors.info,
          title: '1. Tải Tệp Mẫu',
          subtitle: 'Tệp Excel chỉ có 1 cột: Email hoặc Mã SV.',
          action: FilledButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Tải Tệp Mẫu'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _card(
          isDark: isDark,
          icon: Icons.upload_file_rounded,
          iconColor: AppColors.primary,
          title: '2. Tải Tệp Dữ Liệu',
          subtitle: _selectedFileName != null
              ? 'Đã chọn: $_selectedFileName'
              : 'Chọn tệp Excel (.xlsx) chứa danh sách định danh.',
          action: FilledButton.icon(
            onPressed: _pickAndParseFile,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(
              _selectedFileName != null ? 'Chọn Tệp Khác' : 'Chọn Tệp',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.list_alt_rounded, color: AppColors.info, size: 28),
              const SizedBox(height: 8),
              Text(
                '${_identifiers.length}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              Text(
                'định danh sẽ được ghi danh',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(12),
            itemCount: _identifiers.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final id = _identifiers[index];
              final isEmail = id.contains('@');
              return ListTile(
                dense: true,
                leading: Icon(
                  isEmail ? Icons.email_outlined : Icons.badge_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                title: Text(id, style: const TextStyle(fontSize: 14)),
                trailing: Text(
                  isEmail ? 'Email' : 'Mã SV',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetFlow,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tải Tệp Mới'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _submitEnrollment,
                icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                label: Text('Ghi danh ${_identifiers.length} SV'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultSection(bool isDark) {
    final state = context.read<TeacherBloc>().state;
    final enrolled = state is EnrollmentImportResult ? state.enrolled : [];
    final notFound = state is EnrollmentImportResult ? state.notFound : [];
    final alreadyEnrolled = state is EnrollmentImportResult
        ? state.alreadyEnrolled
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _summaryCard(
              isDark,
              'Đã ghi danh',
              enrolled.length,
              AppColors.success,
              Icons.check_circle_rounded,
            ),
            const SizedBox(width: 8),
            _summaryCard(
              isDark,
              'Không tìm thấy',
              notFound.length,
              AppColors.error,
              Icons.person_off_rounded,
            ),
            const SizedBox(width: 8),
            _summaryCard(
              isDark,
              'Đã có sẵn',
              alreadyEnrolled.length,
              AppColors.warning,
              Icons.info_outline_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (notFound.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_off,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Không tìm thấy trong hệ thống (${notFound.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...notFound
                    .take(10)
                    .map(
                      (id) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $id',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                if (notFound.length > 10)
                  Text(
                    '...và ${notFound.length - 10} identifier khác',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.done_all_rounded, size: 18),
          label: const Text('Hoàn tất'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _resetFlow,
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: const Text('Import Đợt Mới'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget action,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      ),
    );
  }

  Widget _summaryCard(
    bool isDark,
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
