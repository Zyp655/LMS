import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/admin_bloc.dart';

enum _ImportRowStatus { valid, error }

enum _FilterMode { all, valid, error }

class _ImportRow {
  final int rowIndex;
  final String code;
  final String name;
  final String department;
  final String credits;
  final _ImportRowStatus status;
  final String? errorReason;

  _ImportRow({
    required this.rowIndex,
    required this.code,
    required this.name,
    required this.department,
    required this.credits,
    required this.status,
    this.errorReason,
  });
}

class SubjectImportPage extends StatefulWidget {
  const SubjectImportPage({super.key});

  @override
  State<SubjectImportPage> createState() => _SubjectImportPageState();
}

class _SubjectImportPageState extends State<SubjectImportPage> {
  int _currentStep = 1;
  bool _isProcessing = false;
  String? _selectedFileName;
  var _rows = <_ImportRow>[];
  _FilterMode _filterMode = _FilterMode.all;

  static final _codeRegex = RegExp(r'^[A-Za-z0-9_\-]{2,20}$');

  List<_ImportRow> get _filteredRows {
    switch (_filterMode) {
      case _FilterMode.valid:
        return _rows.where((r) => r.status == _ImportRowStatus.valid).toList();
      case _FilterMode.error:
        return _rows.where((r) => r.status == _ImportRowStatus.error).toList();
      case _FilterMode.all:
        return _rows;
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isProcessing = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['MauImportMonHoc'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E65100'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers = ['MÃ£ mÃ´n (*)', 'TÃªn mÃ´n (*)', 'Khoa (*)', 'TÃ­n chá»‰'];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      final samples = [
        ['CNTT101', 'Nháº­p mÃ´n láº­p trÃ¬nh', 'CÃ´ng nghá»‡ thÃ´ng tin', '3'],
        ['KT201', 'Kinh táº¿ vi mÃ´', 'Kinh táº¿', '4'],
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
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 25);
      sheet.setColumnWidth(3, 10);

      final bytes = excel.save();
      if (bytes == null) throw Exception('KhÃ´ng thá»ƒ táº¡o tá»‡p');

      final dir = Directory('/storage/emulated/0/Download');
      final savePath = dir.existsSync()
          ? dir.path
          : (await getApplicationDocumentsDirectory()).path;
      final filePath = '$savePath/MauImportMonHoc.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      _snack('ÄÃ£ táº¡o tá»‡p máº«u thÃ nh cÃ´ng!');
      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], title: 'Tá»‡p máº«u Import MÃ´n Há»c'),
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
      allowedExtensions: ['xlsx', 'xls'],
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
        throw Exception('Tá»‡p khÃ´ng cÃ³ dá»¯ liá»‡u');
      }

      final rows = <_ImportRow>[];
      final seenCodes = <String>{};

      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        final code = _cellToString(row.isNotEmpty ? row[0] : null).trim();
        final name = _cellToString(row.length > 1 ? row[1] : null).trim();
        final department = _cellToString(row.length > 2 ? row[2] : null).trim();
        final credits = _cellToString(row.length > 3 ? row[3] : null).trim();

        if (code.isEmpty && name.isEmpty) continue;

        final errors = <String>[];
        if (code.isEmpty) {
          errors.add('Thiáº¿u mÃ£ mÃ´n');
        } else if (!_codeRegex.hasMatch(code)) {
          errors.add('MÃ£ mÃ´n khÃ´ng há»£p lá»‡');
        } else if (seenCodes.contains(code.toUpperCase())) {
          errors.add('MÃ£ mÃ´n trÃ¹ng láº·p');
        }
        if (name.isEmpty) errors.add('Thiáº¿u tÃªn mÃ´n');
        if (department.isEmpty) errors.add('Thiáº¿u khoa');

        if (code.isNotEmpty) seenCodes.add(code.toUpperCase());

        rows.add(
          _ImportRow(
            rowIndex: r + 1,
            code: code,
            name: name,
            department: department,
            credits: credits.isEmpty ? '3' : credits,
            status: errors.isEmpty
                ? _ImportRowStatus.valid
                : _ImportRowStatus.error,
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
        .where((r) => r.status == _ImportRowStatus.valid)
        .toList();
    if (validRows.isEmpty) {
      _snack('KhÃ´ng cÃ³ báº£n ghi há»£p lá»‡', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    final subjects = validRows
        .map(
          (r) => {
            'code': r.code,
            'name': r.name,
            'department': r.department,
            'credits': r.credits,
          },
        )
        .toList();

    context.read<AdminBloc>().add(ImportSubjects({'subjects': subjects}));
  }

  Future<void> _exportResults() async {
    setState(() => _isProcessing = true);
    try {
      final validRows = _rows
          .where((r) => r.status == _ImportRowStatus.valid)
          .toList();

      final excel = Excel.createExcel();
      final sheet = excel['KetQuaImport'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E65100'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers = ['MÃ£ mÃ´n', 'TÃªn mÃ´n', 'Khoa', 'TÃ­n chá»‰', 'Tráº¡ng thÃ¡i'];
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
          row.code,
          row.name,
          row.department,
          row.credits,
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
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 25);
      sheet.setColumnWidth(3, 10);
      sheet.setColumnWidth(4, 12);

      final bytes = excel.save();
      if (bytes == null) throw Exception('KhÃ´ng thá»ƒ táº¡o tá»‡p');

      final dir = Directory('/storage/emulated/0/Download');
      final savePath = dir.existsSync()
          ? dir.path
          : (await getApplicationDocumentsDirectory()).path;
      final filePath = '$savePath/KetQuaImportMonHoc.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      _snack('ÄÃ£ xuáº¥t káº¿t quáº£!');
      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], title: 'Káº¿t quáº£ Import MÃ´n Há»c'),
      );
    } catch (e) {
      _snack('Lá»—i xuáº¥t: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final validCount = _rows
        .where((r) => r.status == _ImportRowStatus.valid)
        .length;
    final errorCount = _rows
        .where((r) => r.status == _ImportRowStatus.error)
        .length;

    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          setState(() {
            _isProcessing = false;
            _currentStep = 3;
          });
          _snack(state.message);
        } else if (state is AdminError) {
          setState(() => _isProcessing = false);
          _snack(state.message, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import MÃ´n Há»c'),
          centerTitle: true,
          elevation: 0,
        ),
        body: _isProcessing
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepIndicator(cs),
                    const SizedBox(height: 24),

                    if (_currentStep == 1) ...[
                      _buildStep1(cs),
                    ] else if (_currentStep == 2) ...[
                      _buildStep2(cs, validCount, errorCount),
                    ] else if (_currentStep == 3) ...[
                      _buildStep3(cs, validCount),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme cs) {
    return Row(
      children: [
        _stepCircle(1, 'Chá»n File', cs),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 2 ? AppColors.primary : cs.outlineVariant,
          ),
        ),
        _stepCircle(2, 'Xem trÆ°á»›c', cs),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 3 ? AppColors.primary : cs.outlineVariant,
          ),
        ),
        _stepCircle(3, 'HoÃ n táº¥t', cs),
      ],
    );
  }

  Widget _stepCircle(int step, String label, ColorScheme cs) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive
              ? AppColors.primary
              : cs.surfaceContainerHighest,
          child: Text(
            '$step',
            style: TextStyle(
              color: isActive ? Colors.white : cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildStep1(ColorScheme cs) {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: Colors.deepOrange.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Import MÃ´n Há»c tá»« Excel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chá»n file Excel chá»©a danh sÃ¡ch mÃ´n há»c.\nCá»™t: MÃ£ mÃ´n, TÃªn mÃ´n, Khoa, TÃ­n chá»‰.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download),
                      label: const Text('Táº£i máº«u'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _pickAndParseFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Chá»n File'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepOrange.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(ColorScheme cs, int validCount, int errorCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.deepOrange.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFileName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _pickAndParseFile,
                  child: const Text('Äá»•i file'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            _countChip('Táº¥t cáº£', _rows.length, Colors.grey, _FilterMode.all),
            const SizedBox(width: 8),
            _countChip(
              'Há»£p lá»‡',
              validCount,
              AppColors.success,
              _FilterMode.valid,
            ),
            const SizedBox(width: 8),
            _countChip('Lá»—i', errorCount, AppColors.error, _FilterMode.error),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.primary.withValues(alpha: 0.08),
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
                      'MÃ£ mÃ´n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'TÃªn mÃ´n',
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
                      'TÃ­n chá»‰',
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
                  final isError = row.status == _ImportRowStatus.error;
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
                          row.code.isEmpty ? 'â€”' : row.code,
                          style: TextStyle(
                            color: row.code.isEmpty ? AppColors.error : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          row.name.isEmpty ? 'â€”' : row.name,
                          style: TextStyle(
                            color: row.name.isEmpty ? AppColors.error : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          row.department.isEmpty ? 'â€”' : row.department,
                          style: TextStyle(
                            color: row.department.isEmpty
                                ? AppColors.error
                                : null,
                          ),
                        ),
                      ),
                      DataCell(Text(row.credits)),
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
                                  'OK',
                                  style: TextStyle(
                                    color: AppColors.success,
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
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _currentStep = 1;
                  _rows.clear();
                }),
                child: const Text('Quay láº¡i'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: validCount > 0 ? _confirmAndCreate : null,
                icon: const Icon(Icons.check),
                label: Text('Import $validCount mÃ´n'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _countChip(String label, int count, Color color, _FilterMode mode) {
    final selected = _filterMode == mode;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => setState(() => _filterMode = mode),
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
    );
  }

  Widget _buildStep3(ColorScheme cs, int validCount) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 64,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Import thÃ nh cÃ´ng!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ÄÃ£ táº¡o $validCount mÃ´n há»c',
          style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _exportResults,
          icon: const Icon(Icons.download),
          label: const Text('Xuáº¥t káº¿t quáº£'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.deepOrange.shade600,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay vá»'),
        ),
      ],
    );
  }
}
