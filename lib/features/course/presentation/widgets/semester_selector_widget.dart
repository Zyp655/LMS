import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

class SemesterSelectorWidget extends StatefulWidget {
  final int? selectedSemesterId;
  final ValueChanged<int?> onSemesterChanged;

  const SemesterSelectorWidget({
    super.key,
    this.selectedSemesterId,
    required this.onSemesterChanged,
  });

  @override
  State<SemesterSelectorWidget> createState() => _SemesterSelectorWidgetState();
}

class _SemesterSelectorWidgetState extends State<SemesterSelectorWidget> {
  List<Map<String, dynamic>> _semesters = [];
  bool _isLoading = true;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedSemesterId;
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/semesters'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['semesters'] as List? ?? [];
        setState(() {
          _semesters = List<Map<String, dynamic>>.from(list);
          if (_selectedId == null && _semesters.isNotEmpty) {
            final current = _semesters.firstWhere(
              (s) => s['isCurrent'] == true,
              orElse: () => _semesters.first,
            );
            _selectedId = current['id'];
            widget.onSemesterChanged(_selectedId);
          }
        });
      } else {
        setState(() {
          _semesters = [
            {'id': 1, 'name': 'HK1 2024-2025', 'isCurrent': false},
            {'id': 2, 'name': 'HK2 2024-2025', 'isCurrent': true},
            {'id': 3, 'name': 'HK1 2025-2026', 'isCurrent': false},
          ];
          if (_selectedId == null) {
            _selectedId = 2;
            widget.onSemesterChanged(_selectedId);
          }
        });
      }
    } catch (e) {
      setState(() {
        _semesters = [
          {'id': 1, 'name': 'HK1 2024-2025', 'isCurrent': false},
          {'id': 2, 'name': 'HK2 2024-2025', 'isCurrent': true},
          {'id': 3, 'name': 'HK1 2025-2026', 'isCurrent': false},
        ];
        if (_selectedId == null) {
          _selectedId = 2;
          widget.onSemesterChanged(_selectedId);
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _semesters.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedId == null;
            return _buildChip(
              label: 'Tất cả',
              isSelected: isSelected,
              isDark: isDark,
              onTap: () {
                setState(() => _selectedId = null);
                widget.onSemesterChanged(null);
              },
            );
          }

          final semester = _semesters[index - 1];
          final id = semester['id'] as int;
          final isSelected = _selectedId == id;
          final isCurrent = semester['isCurrent'] == true;

          return _buildChip(
            label: semester['name'] ?? 'HK $id',
            isSelected: isSelected,
            isDark: isDark,
            isCurrent: isCurrent,
            onTap: () {
              setState(() => _selectedId = id);
              widget.onSemesterChanged(id);
            },
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    bool isCurrent = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isDark
              ? AppColors.darkSurface
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                ? AppColors.darkSurfaceVariant
                : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isDark
                    ? Colors.white70
                    : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
