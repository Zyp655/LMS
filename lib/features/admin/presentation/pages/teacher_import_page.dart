import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/admin_bloc.dart';


enum ImportRowStatus { valid, error }

class _ImportRow {
  final int rowIndex;
  final String teacherId;
  final String fullName;
  final String email;
  final String department;
  final ImportRowStatus status;
  final String? errorReason;
  String? generatedPassword;

  _ImportRow({
    required this.rowIndex,
    required this.teacherId,
    required this.fullName,
    required this.email,
    required this.department,
    required this.status,
    this.errorReason,
    this.generatedPassword,
  });
}

enum _FilterMode { all, valid, error }


class TeacherImportPage extends StatefulWidget {
  const TeacherImportPage({super.key});

  @override
  State<TeacherImportPage> createState() => _TeacherImportPageState();
}

class _TeacherImportPageState extends State<TeacherImportPage> {
  int _currentStep = 0;
  bool _isProcessing = false;
  String? _selectedFileName;
  List<_ImportRow> _rows = [];
  _FilterMode _filterMode = _FilterMode.all;
  String? _resultMessage;
  String? _exportedFilePath;

  int get _validCount =>
      _rows.where((r) => r.status == ImportRowStatus.valid).length;
  int get _errorCount =>
      _rows.where((r) => r.status == ImportRowStatus.error).length;

  List<_ImportRow> get _filteredRows {
    switch (_filterMode) {
      case _FilterMode.valid:
        return _rows.where((r) => r.status == ImportRowStatus.valid).toList();
      case _FilterMode.error:
        return _rows.where((r) => r.status == ImportRowStatus.error).toList();
      case _FilterMode.all:
        return _rows;
    }
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String _generatePassword([int length = 8]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(
      length,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isProcessing = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['DanhSachGiangVien'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#6366F1'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers = ['MÃ£ GV (*)', 'Há» tÃªn (*)', 'Email (*)', 'Khoa'];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      final samples = [
        [
          'GV001',
          'Nguyá»…n VÄƒn A',
          'nguyenvana@lms.edu.vn',
          'CÃ´ng nghá»‡ thÃ´ng tin',
        ],
        ['GV002', 'Tráº§n Thá»‹ B', 'tranthib@lms.edu.vn', 'Kinh táº¿'],
      ];
      for (var r = 0; r < samples.length; r++) {
        for (var c = 0; c < samples[r].length; c++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
              .value = TextCellValue(
            samples[r][c],
          );
        }
      }

      sheet.setColumnWidth(0, 15);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 30);
      sheet.setColumnWidth(3, 25);

      final bytes = excel.save();
      if (bytes == null) throw Exception('KhÃ´ng thá»ƒ táº¡o tá»‡p');

      final dir = Directory('/storage/emulated/0/Download');
      final savePath = dir.existsSync()
          ? dir.path
          : (await getApplicationDocumentsDirectory()).path;
      final filePath = '$savePath/MauImportGiangVien.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      _snack('ÄÃ£ táº¡o tá»‡p máº«u thÃ nh cÃ´ng!');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          title: 'Tá»‡p máº«u Import Giáº£ng ViÃªn',
        ),
      );
    } catch (e) {
      _snack('Lá»—i táº¡o tá»‡p máº«u: $e', isError: true);
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
      if (bytes == null) throw Exception('KhÃ´ng Ä‘á»c Ä‘Æ°á»£c tá»‡p');

      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.maxRows < 2) {
        throw Exception('Tá»‡p khÃ´ng cÃ³ dá»¯ liá»‡u (chá»‰ cÃ³ header hoáº·c trá»‘ng)');
      }

      final rows = <_ImportRow>[];
      final seenEmails = <String>{};

      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        final teacherId = _cellToString(row.isNotEmpty ? row[0] : null).trim();
        final fullName = _cellToString(row.length > 1 ? row[1] : null).trim();
        final email = _cellToString(
          row.length > 2 ? row[2] : null,
        ).trim().toLowerCase();
        final department = _cellToString(row.length > 3 ? row[3] : null).trim();

        if (teacherId.isEmpty && fullName.isEmpty && email.isEmpty) continue;

        final errors = <String>[];
        if (teacherId.isEmpty) errors.add('Thiáº¿u mÃ£ GV');
        if (fullName.isEmpty) errors.add('Thiáº¿u há» tÃªn');
        if (email.isEmpty) {
          errors.add('Thiáº¿u email');
        } else if (!_emailRegex.hasMatch(email)) {
          errors.add('Email khÃ´ng há»£p lá»‡');
        } else if (seenEmails.contains(email)) {
          errors.add('Email trÃ¹ng láº·p trong file');
        }

        if (email.isNotEmpty) seenEmails.add(email);

        rows.add(
          _ImportRow(
            rowIndex: r + 1,
            teacherId: teacherId,
            fullName: fullName,
            email: email,
            department: department,
            status: errors.isEmpty
                ? ImportRowStatus.valid
                : ImportRowStatus.error,
            errorReason: errors.isEmpty ? null : errors.join('; '),
          ),
        );
      }

      if (rows.isEmpty) throw Exception('KhÃ´ng tÃ¬m tháº¥y dá»¯ liá»‡u há»£p lá»‡');

      setState(() {
        _rows = rows;
        _currentStep = 2;
        _filterMode = _FilterMode.all;
      });
    } catch (e) {
      _snack('Lá»—i Ä‘á»c tá»‡p: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final v = cell.value;
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    return v.toString();
  }

  Future<void> _confirmAndCreate() async {
    final validRows = _rows
        .where((r) => r.status == ImportRowStatus.valid)
        .toList();
    if (validRows.isEmpty) {
      _snack('KhÃ´ng cÃ³ báº£n ghi há»£p lá»‡ Ä‘á»ƒ táº¡o tÃ i khoáº£n', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    for (final row in validRows) {
      row.generatedPassword = _generatePassword();
    }

    final teachers = validRows
        .map(
          (r) => {
            'teacherId': r.teacherId,
            'fullName': r.fullName,
            'email': r.email,
            'department': r.department,
            'password': r.generatedPassword,
          },
        )
        .toList();

    context.read<AdminBloc>().add(ImportTeachers({'teachers': teachers}));
  }

  Future<void> _exportResults() async {
    setState(() => _isProcessing = true);
    try {
      final validRows = _rows
          .where((r) => r.status == ImportRowStatus.valid)
          .toList();

      final excel = Excel.createExcel();
      final sheet = excel['KetQuaImport'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#6366F1'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers = [
        'MÃ£ GV',
        'Há» tÃªn',
        'Email',
        'Máº­t kháº©u',
        'Khoa',
        'Tráº¡ng thÃ¡i',
      ];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      for (var r = 0; r < validRows.length; r++) {
        final row = validRows[r];
        final values = [
          row.teacherId,
          row.fullName,
          row.email,
          row.generatedPassword ?? '',
          row.department,
          'ÄÃ£ táº¡o',
        ];
        for (var c = 0; c < values.length; c++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
              .value = TextCellValue(
            values[c],
          );
        }
      }

      sheet.setColumnWidth(0, 15);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 30);
      sheet.setColumnWidth(3, 15);
      sheet.setColumnWidth(4, 25);
      sheet.setColumnWidth(5, 12);

      final bytes = excel.save();
      if (bytes == null) throw Exception('KhÃ´ng thá»ƒ táº¡o tá»‡p');

      final dir = Directory('/storage/emulated/0/Download');
      final savePath = dir.existsSync()
          ? dir.path
          : (await getApplicationDocumentsDirectory()).path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$savePath/KetQuaImportGV_$timestamp.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      setState(() {
        _exportedFilePath = filePath;
      });

      _snack('ÄÃ£ xuáº¥t tá»‡p káº¿t quáº£ thÃ nh cÃ´ng!');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          title: 'Káº¿t quáº£ Import Giáº£ng ViÃªn',
        ),
      );
    } catch (e) {
      _snack('Lá»—i xuáº¥t tá»‡p: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _resetFlow() {
    setState(() {
      _currentStep = 0;
      _rows = [];
      _selectedFileName = null;
      _resultMessage = null;
      _exportedFilePath = null;
      _filterMode = _FilterMode.all;
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

    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          setState(() {
            _isProcessing = false;
            _resultMessage = state.message;
            _currentStep = 3;
          });
        } else if (state is AdminError) {
          setState(() => _isProcessing = false);
          _snack(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Import Giáº£ng ViÃªn'),
          centerTitle: true,
          elevation: 0,
        ),
        body: _isProcessing
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _currentStep == 2
                          ? 'Äang táº¡o tÃ i khoáº£n...'
                          : 'Äang xá»­ lÃ½...',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepIndicator(isDark),
                    const SizedBox(height: 20),
                    if (_currentStep == 0 || _currentStep == 1)
                      _buildUploadSection(isDark),
                    if (_currentStep == 2) _buildPreviewSection(isDark),
                    if (_currentStep == 3) _buildResultSection(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    const labels = ['Tá»‡p máº«u', 'Táº£i lÃªn', 'Kiá»ƒm tra', 'Káº¿t quáº£'];
    const icons = [
      Icons.description_outlined,
      Icons.upload_file_rounded,
      Icons.fact_check_outlined,
      Icons.download_done_rounded,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          final color = isActive
              ? const Color(0xFF6366F1)
              : isDone
              ? AppColors.success
              : (isDark ? Colors.white24 : Colors.grey.shade300);

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: isActive ? 0.15 : 0.08),
                    border: Border.all(color: color, width: isActive ? 2 : 1),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : icons[i],
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? const Color(0xFF6366F1)
                        : (isDark ? Colors.white54 : Colors.grey),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUploadSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          isDark: isDark,
          icon: Icons.description_outlined,
          iconColor: AppColors.info,
          title: '1. Táº£i Tá»‡p Máº«u Chuáº©n',
          subtitle:
              'Tá»‡p Excel vá»›i cÃ¡c cá»™t: MÃ£ GV, Há» tÃªn, Email, Khoa.\n'
              'Äiá»n Ä‘áº§y Ä‘á»§ thÃ´ng tin rá»“i táº£i lÃªn á»Ÿ bÆ°á»›c 2.',
          action: FilledButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Táº£i Tá»‡p Máº«u'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          isDark: isDark,
          icon: Icons.upload_file_rounded,
          iconColor: const Color(0xFF6366F1),
          title: '2. Táº£i Tá»‡p Dá»¯ Liá»‡u',
          subtitle: _selectedFileName != null
              ? 'ÄÃ£ chá»n: $_selectedFileName'
              : 'Chá»n tá»‡p Excel (.xlsx) chá»©a danh sÃ¡ch giáº£ng viÃªn.',
          action: FilledButton.icon(
            onPressed: _pickAndParseFile,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(
              _selectedFileName != null ? 'Chá»n Tá»‡p KhÃ¡c' : 'Chá»n Tá»‡p',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        Row(
          children: [
            _summaryCard(
              isDark,
              'Tá»•ng',
              _rows.length,
              AppColors.info,
              Icons.list_alt_rounded,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              isDark,
              'Há»£p lá»‡',
              _validCount,
              AppColors.success,
              Icons.check_circle_rounded,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              isDark,
              'Lá»—i',
              _errorCount,
              AppColors.error,
              Icons.error_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _filterTab('Táº¥t cáº£ (${_rows.length})', _FilterMode.all, isDark),
              _filterTab('Há»£p lá»‡ ($_validCount)', _FilterMode.valid, isDark),
              _filterTab('Lá»—i ($_errorCount)', _FilterMode.error, isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF6366F1).withValues(alpha: 0.08),
                  ),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 64,
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(
                      label: Text(
                        '#',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'MÃ£ GV',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Há» tÃªn',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Khoa',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tráº¡ng thÃ¡i',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: _filteredRows.map((row) {
                    final isError = row.status == ImportRowStatus.error;
                    return DataRow(
                      color: WidgetStateProperty.all(
                        isError
                            ? AppColors.error.withValues(alpha: 0.06)
                            : Colors.transparent,
                      ),
                      cells: [
                        DataCell(Text('${row.rowIndex}')),
                        DataCell(
                          Text(
                            row.teacherId.isEmpty ? 'â€”' : row.teacherId,
                            style: TextStyle(
                              color: row.teacherId.isEmpty
                                  ? AppColors.error
                                  : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            row.fullName.isEmpty ? 'â€”' : row.fullName,
                            style: TextStyle(
                              color: row.fullName.isEmpty
                                  ? AppColors.error
                                  : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            row.email.isEmpty ? 'â€”' : row.email,
                            style: TextStyle(
                              color:
                                  row.email.isEmpty ||
                                      (row.errorReason?.contains('email') ??
                                          false) ||
                                      (row.errorReason?.contains('Email') ??
                                          false)
                                  ? AppColors.error
                                  : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(row.department.isEmpty ? 'â€”' : row.department),
                        ),
                        DataCell(
                          isError
                              ? Tooltip(
                                  message: row.errorReason ?? '',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      row.errorReason ?? 'Lá»—i',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Há»£p lá»‡',
                                    style: TextStyle(
                                      color: AppColors.successDark,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _rows = [];
                    _selectedFileName = null;
                    _filterMode = _FilterMode.all;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Quay láº¡i'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _validCount > 0 ? _confirmAndCreate : null,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text('Táº¡o TÃ i Khoáº£n ($_validCount GV)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Import ThÃ nh CÃ´ng!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _resultMessage ?? 'ÄÃ£ táº¡o tÃ i khoáº£n thÃ nh cÃ´ng',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _exportResults,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Xuáº¥t Káº¿t Quáº£ (Excel)'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_exportedFilePath != null) ...[
          const SizedBox(height: 8),
          Text(
            'ÄÃ£ lÆ°u: $_exportedFilePath',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _resetFlow,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Import Má»›i'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
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
                width: 40,
                height: 40,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: action),
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
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTab(String label, _FilterMode mode, bool isDark) {
    final isActive = _filterMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
