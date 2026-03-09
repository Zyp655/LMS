import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

class EnrollmentImportPage extends StatefulWidget {
  const EnrollmentImportPage({super.key});

  @override
  State<EnrollmentImportPage> createState() => _EnrollmentImportPageState();
}

class _EnrollmentImportPageState extends State<EnrollmentImportPage> {
  bool _isLoading = false;
  bool _isUploading = false;
  String? _selectedFileName;
  List<Map<String, dynamic>> _previewData = [];
  List<Map<String, dynamic>> _importHistory = [];
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadImportHistory();
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadImportHistory() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/enrollment/import'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _importHistory = List<Map<String, dynamic>>.from(
            data['imports'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndPreviewFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _errorMessage = null;
          _successMessage = null;
          _previewData = [
            {
              'studentCode': 'SV001',
              'classCode': 'CS301-01',
              'status': 'pending',
            },
            {
              'studentCode': 'SV002',
              'classCode': 'CS301-01',
              'status': 'pending',
            },
            {
              'studentCode': 'SV003',
              'classCode': 'AI101-02',
              'status': 'pending',
            },
          ];
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Không thể đọc file: $e');
    }
  }

  Future<void> _submitImport() async {
    if (_previewData.isEmpty) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/admin/enrollment/import'),
        headers: headers,
        body: json.encode({
          'enrollments': _previewData
              .map(
                (e) => {
                  'studentCode': e['studentCode'],
                  'classCode': e['classCode'],
                },
              )
              .toList(),
          'fileName': _selectedFileName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _successMessage =
              'Import thành công! ${data['successCount'] ?? 0} sinh viên được ghi danh.';
          _previewData = [];
          _selectedFileName = null;
        });
        _loadImportHistory();
      } else {
        final data = json.decode(response.body);
        setState(() {
          _errorMessage = data['error'] ?? 'Import thất bại. Vui lòng thử lại.';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi kết nối: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Import Ghi Danh (SIS)'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadCard(isDark),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildMessageCard(_errorMessage!, AppColors.error, isDark),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildMessageCard(
                      _successMessage!,
                      AppColors.success,
                      isDark,
                    ),
                  ],
                  if (_previewData.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPreviewTable(isDark),
                    const SizedBox(height: 16),
                    _buildSubmitButton(isDark),
                  ],
                  const SizedBox(height: 24),
                  _buildHistorySection(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildUploadCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.upload_file_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFileName ?? 'Chọn file Excel (.xlsx, .csv)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'File cần có cột: Mã SV, Mã Lớp HP',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickAndPreviewFile,
            icon: const Icon(Icons.folder_open),
            label: Text(_selectedFileName != null ? 'Chọn lại' : 'Chọn file'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(String message, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            color == AppColors.error ? Icons.error_outline : Icons.check_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.preview, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Xem trước (${_previewData.length} dòng)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.1),
              ),
              columns: const [
                DataColumn(label: Text('Mã SV')),
                DataColumn(label: Text('Mã Lớp HP')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: _previewData
                  .map(
                    (row) => DataRow(
                      cells: [
                        DataCell(Text(row['studentCode'] ?? '')),
                        DataCell(Text(row['classCode'] ?? '')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              row['status'] ?? 'pending',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _submitImport,
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload),
        label: Text(_isUploading ? 'Đang import...' : 'Xác nhận Import'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Lịch sử Import',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_importHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Chưa có lịch sử import',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ...(_importHistory.map((item) => _buildHistoryItem(item, isDark))),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, bool isDark) {
    final status = item['status'] ?? 'unknown';
    final isSuccess = status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isSuccess ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.error_outline,
              size: 18,
              color: isSuccess ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['fileName'] ?? 'Import #${item['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['totalRecords'] ?? 0} dòng • ${item['successCount'] ?? 0} thành công',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(item['createdAt']),
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
