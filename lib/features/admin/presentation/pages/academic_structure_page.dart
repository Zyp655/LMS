import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart';

class AcademicStructurePage extends StatefulWidget {
  const AcademicStructurePage({super.key});

  @override
  State<AcademicStructurePage> createState() => _AcademicStructurePageState();
}

class _AcademicStructurePageState extends State<AcademicStructurePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = sl<ApiClient>();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _users = [];

  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get('/academic/departments'),
        _api.get('/academic/semesters'),
        _api.get('/academic/courses'),
        _api.get('/academic/classes'),
        _api.get('/admin/users'),
      ]);
      setState(() {
        _departments = List<Map<String, dynamic>>.from(
          results[0]['departments'] ?? [],
        );
        _semesters = List<Map<String, dynamic>>.from(
          results[1]['semesters'] ?? [],
        );
        _courses = List<Map<String, dynamic>>.from(results[2]['courses'] ?? []);
        _classes = List<Map<String, dynamic>>.from(results[3]['classes'] ?? []);
        _users = List<Map<String, dynamic>>.from(results[4]['users'] ?? []);
      });
    } catch (e) {
      _snack('Lỗi tải dữ liệu: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Cấu trúc học thuật'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            _tab('Khoa', Icons.business_rounded, _departments.length),
            _tab('Học kỳ', Icons.calendar_month_rounded, _semesters.length),
            _tab('Học phần', Icons.menu_book_rounded, _courses.length),
            _tab('Lớp HP', Icons.groups_rounded, _classes.length),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildDepartmentsTab(cs),
                      _buildSemestersTab(cs),
                      _buildCoursesTab(cs),
                      _buildClassesTab(cs),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabTap,
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
      ),
    );
  }

  Tab _tab(String label, IconData icon, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onFabTap() {
    final cs = Theme.of(context).colorScheme;
    switch (_tabCtrl.index) {
      case 0:
        _showDepartmentSheet(cs);
        break;
      case 1:
        _showSemesterSheet(cs);
        break;
      case 2:
        _showCourseSheet(cs);
        break;
      case 3:
        _showClassSheet(cs);
        break;
    }
  }

  Widget _buildDepartmentsTab(ColorScheme cs) {
    final filtered = _departments
        .where(
          (d) =>
              _search.isEmpty ||
              (d['name'] ?? '').toString().toLowerCase().contains(_search) ||
              (d['code'] ?? '').toString().toLowerCase().contains(_search),
        )
        .toList();

    return _listOrEmpty(
      cs: cs,
      items: filtered,
      emptyLabel: 'Chưa có khoa nào',
      emptyIcon: Icons.business_outlined,
      builder: (item) => _itemCard(
        cs: cs,
        title: item['name'] ?? '',
        subtitle: 'Mã: ${item['code'] ?? ''}',
        description: item['description'],
        icon: Icons.apartment_rounded,
        color: cs.primary,
        onEdit: () => _showDepartmentSheet(cs, existing: item),
        onDelete: () => _confirmDelete(
          cs: cs,
          label: item['name'] ?? '',
          endpoint: '/academic/departments',
          id: item['id'],
        ),
      ),
    );
  }

  Widget _buildSemestersTab(ColorScheme cs) {
    final filtered = _semesters
        .where(
          (s) =>
              _search.isEmpty ||
              (s['name'] ?? '').toString().toLowerCase().contains(_search),
        )
        .toList();

    return _listOrEmpty(
      cs: cs,
      items: filtered,
      emptyLabel: 'Chưa có học kỳ nào',
      emptyIcon: Icons.calendar_month_outlined,
      builder: (item) {
        final isActive = item['isActive'] == true;
        return _itemCard(
          cs: cs,
          title: item['name'] ?? '',
          subtitle: 'Năm ${item['year']} · HK${item['term']}',
          badge: isActive ? 'Active' : null,
          badgeColor: isActive ? Colors.green : null,
          icon: Icons.date_range_rounded,
          color: Colors.teal,
          onEdit: () => _showSemesterSheet(cs, existing: item),
          onDelete: () => _confirmDelete(
            cs: cs,
            label: item['name'] ?? '',
            endpoint: '/academic/semesters',
            id: item['id'],
          ),
        );
      },
    );
  }

  Widget _buildCoursesTab(ColorScheme cs) {
    final filtered = _courses
        .where(
          (c) =>
              _search.isEmpty ||
              (c['name'] ?? '').toString().toLowerCase().contains(_search) ||
              (c['code'] ?? '').toString().toLowerCase().contains(_search),
        )
        .toList();

    return _listOrEmpty(
      cs: cs,
      items: filtered,
      emptyLabel: 'Chưa có học phần nào',
      emptyIcon: Icons.menu_book_outlined,
      builder: (item) => _itemCard(
        cs: cs,
        title: '${item['code']} · ${item['name']}',
        subtitle: '${item['credits']} TC · ${item['departmentName'] ?? ''}',
        description: item['description'],
        icon: Icons.class_rounded,
        color: cs.secondary,
        onEdit: () => _showCourseSheet(cs, existing: item),
        onDelete: () => _confirmDelete(
          cs: cs,
          label: '${item['code']} - ${item['name']}',
          endpoint: '/academic/courses',
          id: item['id'],
        ),
      ),
    );
  }

  Widget _buildClassesTab(ColorScheme cs) {
    final filtered = _classes
        .where(
          (c) =>
              _search.isEmpty ||
              (c['classCode'] ?? '').toString().toLowerCase().contains(
                _search,
              ) ||
              (c['courseName'] ?? '').toString().toLowerCase().contains(
                _search,
              ) ||
              (c['teacherName'] ?? '').toString().toLowerCase().contains(
                _search,
              ),
        )
        .toList();

    return _listOrEmpty(
      cs: cs,
      items: filtered,
      emptyLabel: 'Chưa có lớp học phần nào',
      emptyIcon: Icons.groups_outlined,
      builder: (item) => _itemCard(
        cs: cs,
        title: item['classCode'] ?? '',
        subtitle: '${item['courseName']} · GV: ${item['teacherName']}',
        description: [
          if (item['semesterName'] != null) 'HK: ${item['semesterName']}',
          if (item['room'] != null) 'Phòng: ${item['room']}',
          if (item['schedule'] != null) 'TKB: ${item['schedule']}',
          'SV tối đa: ${item['maxStudents'] ?? 50}',
        ].join(' · '),
        icon: Icons.meeting_room_rounded,
        color: cs.tertiary,
        onEdit: () => _showClassSheet(cs, existing: item),
        onDelete: () => _confirmDelete(
          cs: cs,
          label: item['classCode'] ?? '',
          endpoint: '/academic/classes',
          id: item['id'],
        ),
      ),
    );
  }

  Widget _listOrEmpty({
    required ColorScheme cs,
    required List<Map<String, dynamic>> items,
    required String emptyLabel,
    required IconData emptyIcon,
    required Widget Function(Map<String, dynamic>) builder,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              emptyLabel,
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => builder(items[i]),
      ),
    );
  }

  Widget _itemCard({
    required ColorScheme cs,
    required String title,
    required String subtitle,
    String? description,
    String? badge,
    Color? badgeColor,
    required IconData icon,
    required Color color,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? cs.primary).withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: badgeColor ?? cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Chỉnh sửa'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Xóa', style: TextStyle(color: Colors.red)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete({
    required ColorScheme cs,
    required String label,
    required String endpoint,
    required int id,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa "$label"?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.delete('$endpoint?id=$id');
      _snack('Đã xóa thành công');
      _loadAll();
    } catch (e) {
      _snack('Lỗi xóa: $e', isError: true);
    }
  }

  Widget _sheetField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _showSheet({
    required ColorScheme cs,
    required String title,
    required List<Widget> fields,
    Widget? extra,
    required Future<void> Function() onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ...fields,
              if (extra != null) ...[
                const SizedBox(height: 4),
                extra,
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await onSave();
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Lưu'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
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

  void _showDepartmentSheet(ColorScheme cs, {Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final codeCtrl = TextEditingController(text: existing?['code'] ?? '');
    final descCtrl = TextEditingController(
      text: existing?['description'] ?? '',
    );
    final isEdit = existing != null;

    _showSheet(
      cs: cs,
      title: isEdit ? 'Sửa Khoa' : 'Thêm Khoa',
      fields: [
        _sheetField(nameCtrl, 'Tên Khoa', Icons.business),
        _sheetField(codeCtrl, 'Mã Khoa', Icons.tag),
        _sheetField(descCtrl, 'Mô tả (tuỳ chọn)', Icons.description),
      ],
      onSave: () async {
        final data = {
          'name': nameCtrl.text,
          'code': codeCtrl.text,
          'description': descCtrl.text.isEmpty ? null : descCtrl.text,
        };
        if (isEdit) {
          data['id'] = existing['id'];
          await _api.put('/academic/departments', data);
          _snack('Cập nhật khoa thành công');
        } else {
          await _api.post('/academic/departments', data);
          _snack('Tạo khoa thành công');
        }
        _loadAll();
      },
    );
  }

  void _showSemesterSheet(ColorScheme cs, {Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final yearCtrl = TextEditingController(
      text: (existing?['year'] ?? DateTime.now().year).toString(),
    );
    final termCtrl = TextEditingController(
      text: (existing?['term'] ?? 1).toString(),
    );
    final isEdit = existing != null;

    _showSheet(
      cs: cs,
      title: isEdit ? 'Sửa Học kỳ' : 'Thêm Học kỳ',
      fields: [
        _sheetField(nameCtrl, 'Tên (VD: HK1 2025-2026)', Icons.label),
        _sheetField(yearCtrl, 'Năm', Icons.calendar_today),
        _sheetField(termCtrl, 'Kỳ (1/2/3)', Icons.format_list_numbered),
      ],
      onSave: () async {
        final now = DateTime.now();
        final data = <String, dynamic>{
          'name': nameCtrl.text,
          'year': int.tryParse(yearCtrl.text) ?? now.year,
          'term': int.tryParse(termCtrl.text) ?? 1,
          'startDate': now.toIso8601String(),
          'endDate': now.add(const Duration(days: 120)).toIso8601String(),
          'isActive': true,
        };
        if (isEdit) {
          data['id'] = existing['id'];
          await _api.put('/academic/semesters', data);
          _snack('Cập nhật học kỳ thành công');
        } else {
          await _api.post('/academic/semesters', data);
          _snack('Tạo học kỳ thành công');
        }
        _loadAll();
      },
    );
  }

  void _showCourseSheet(ColorScheme cs, {Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final codeCtrl = TextEditingController(text: existing?['code'] ?? '');
    final creditsCtrl = TextEditingController(
      text: (existing?['credits'] ?? 3).toString(),
    );
    int? selectedDeptId =
        existing?['departmentId'] ??
        (_departments.isNotEmpty ? _departments.first['id'] : null);
    final isEdit = existing != null;

    _showSheet(
      cs: cs,
      title: isEdit ? 'Sửa Học phần' : 'Thêm Học phần',
      fields: [
        _sheetField(nameCtrl, 'Tên học phần', Icons.menu_book),
        _sheetField(codeCtrl, 'Mã (VD: INT1234)', Icons.tag),
        _sheetField(creditsCtrl, 'Số tín chỉ', Icons.numbers),
      ],
      extra: _departments.isNotEmpty
          ? StatefulBuilder(
              builder: (ctx, setSt) => DropdownButtonFormField<int>(
                initialValue: selectedDeptId,
                decoration: InputDecoration(
                  labelText: 'Khoa',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _departments
                    .map(
                      (d) => DropdownMenuItem<int>(
                        value: d['id'],
                        child: Text(d['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSt(() => selectedDeptId = v),
              ),
            )
          : null,
      onSave: () async {
        final data = <String, dynamic>{
          'name': nameCtrl.text,
          'code': codeCtrl.text,
          'credits': int.tryParse(creditsCtrl.text) ?? 3,
          'departmentId': selectedDeptId,
        };
        if (isEdit) {
          data['id'] = existing['id'];
          await _api.put('/academic/courses', data);
          _snack('Cập nhật học phần thành công');
        } else {
          await _api.post('/academic/courses', data);
          _snack('Tạo học phần thành công');
        }
        _loadAll();
      },
    );
  }

  void _showClassSheet(ColorScheme cs, {Map<String, dynamic>? existing}) {
    final codeCtrl = TextEditingController(text: existing?['classCode'] ?? '');
    final roomCtrl = TextEditingController(text: existing?['room'] ?? '');
    final schedCtrl = TextEditingController(text: existing?['schedule'] ?? '');
    final maxCtrl = TextEditingController(
      text: (existing?['maxStudents'] ?? 50).toString(),
    );

    int? selectedCourseId =
        existing?['academicCourseId'] ??
        (_courses.isNotEmpty ? _courses.first['id'] : null);
    int? selectedSemId =
        existing?['semesterId'] ??
        (_semesters.isNotEmpty ? _semesters.first['id'] : null);

    final teachers = _users
        .where((u) => u['role'] == 1 || u['role'] == 2)
        .toList();
    int? selectedTeacherId =
        existing?['teacherId'] ??
        (teachers.isNotEmpty ? teachers.first['id'] : null);

    final isEdit = existing != null;

    _showSheet(
      cs: cs,
      title: isEdit ? 'Sửa Lớp HP' : 'Thêm Lớp học phần',
      fields: [
        _sheetField(codeCtrl, 'Mã lớp (VD: INT1234.01)', Icons.tag),
        _sheetField(roomCtrl, 'Phòng', Icons.meeting_room),
        _sheetField(schedCtrl, 'TKB (VD: T2(1-3), T5(4-6))', Icons.schedule),
        _sheetField(maxCtrl, 'SV tối đa', Icons.people),
      ],
      extra: Column(
        children: [
          if (_courses.isNotEmpty)
            StatefulBuilder(
              builder: (ctx, setSt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int>(
                  initialValue: selectedCourseId,
                  decoration: InputDecoration(
                    labelText: 'Học phần',
                    prefixIcon: const Icon(Icons.menu_book),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _courses
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text('${c['code']} - ${c['name']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSt(() => selectedCourseId = v),
                ),
              ),
            ),
          if (_semesters.isNotEmpty)
            StatefulBuilder(
              builder: (ctx, setSt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int>(
                  initialValue: selectedSemId,
                  decoration: InputDecoration(
                    labelText: 'Học kỳ',
                    prefixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _semesters
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text(s['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSt(() => selectedSemId = v),
                ),
              ),
            ),
          if (teachers.isNotEmpty)
            StatefulBuilder(
              builder: (ctx, setSt) => DropdownButtonFormField<int>(
                initialValue: selectedTeacherId,
                decoration: InputDecoration(
                  labelText: 'Giảng viên',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: teachers
                    .map(
                      (t) => DropdownMenuItem<int>(
                        value: t['id'],
                        child: Text(t['fullName'] ?? t['email']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSt(() => selectedTeacherId = v),
              ),
            ),
        ],
      ),
      onSave: () async {
        final data = <String, dynamic>{
          'classCode': codeCtrl.text,
          'academicCourseId': selectedCourseId,
          'semesterId': selectedSemId,
          'teacherId': selectedTeacherId,
          'room': roomCtrl.text.isEmpty ? null : roomCtrl.text,
          'schedule': schedCtrl.text.isEmpty ? null : schedCtrl.text,
          'maxStudents': int.tryParse(maxCtrl.text) ?? 50,
        };
        if (isEdit) {
          data['id'] = existing['id'];
          await _api.put('/academic/classes', data);
          _snack('Cập nhật lớp HP thành công');
        } else {
          await _api.post('/academic/classes', data);
          _snack('Tạo lớp HP thành công');
        }
        _loadAll();
      },
    );
  }
}
