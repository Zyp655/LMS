import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/route/app_route.dart';
import '../../../../injection_container.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  int? _roleFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
    _loadAcademicData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _academicCourses = [];
  List<Map<String, dynamic>> _courseClasses = [];

  Future<void> _loadAcademicData() async {
    try {
      final apiClient = sl<ApiClient>();
      final deptRes = await apiClient.get('/academic/departments');
      final semRes = await apiClient.get('/academic/semesters');
      final courseRes = await apiClient.get('/academic/courses');
      final classRes = await apiClient.get('/academic/classes');
      setState(() {
        _departments = List<Map<String, dynamic>>.from(
          deptRes['departments'] ?? [],
        );
        _semesters = List<Map<String, dynamic>>.from(semRes['semesters'] ?? []);
        _academicCourses = List<Map<String, dynamic>>.from(
          courseRes['courses'] ?? [],
        );
        _courseClasses = List<Map<String, dynamic>>.from(
          classRes['classes'] ?? [],
        );
      });
    } catch (e) {
      _snack('Lỗi tải dữ liệu học thuật: $e', isError: true);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = sl<ApiClient>();
      var path = '/admin/users';
      final params = <String>[];
      if (_roleFilter != null) params.add('role=$_roleFilter');
      if (_searchQuery.isNotEmpty) params.add('search=$_searchQuery');
      if (params.isNotEmpty) path += '?${params.join('&')}';

      final response = await apiClient.get(path);
      setState(() {
        _users = List<Map<String, dynamic>>.from(response['users'] ?? []);
      });
    } catch (e) {
      _snack('Lỗi tải danh sách: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBan(int userId) async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.post('/admin/users/$userId/ban', {});
      _snack(response['message'] ?? 'Thành công');
      _loadUsers();
    } catch (e) {
      _snack('Lỗi: $e', isError: true);
    }
  }

  Future<void> _deleteUser(int userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 36),
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc muốn xoá tài khoản\n$email?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.delete('/admin/users/$userId');
      _snack(response['message'] ?? 'Đã xoá');
      _loadUsers();
    } catch (e) {
      _snack('Lỗi: $e', isError: true);
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['fullName'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    int selectedRole = user['role'] ?? 0;

    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: Icon(Icons.edit_rounded, color: cs.primary, size: 32),
          title: const Text('Chỉnh sửa thông tin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Họ tên',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Vai trò',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Student')),
                  DropdownMenuItem(value: 1, child: Text('Teacher')),
                  DropdownMenuItem(value: 2, child: Text('Admin')),
                ],
                onChanged: (v) => setDialogState(() => selectedRole = v ?? 0),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, {
                'fullName': nameCtrl.text,
                'email': emailCtrl.text,
                'role': selectedRole,
              }),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    try {
      final apiClient = sl<ApiClient>();
      await apiClient.put('/admin/users/${user['id']}', result);
      _snack('Cập nhật thành công');
      _loadUsers();
    } catch (e) {
      _snack('Lỗi: $e', isError: true);
    }
  }

  Future<void> _seedUsers() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.post('/admin/seed-users', {});
      _snack(response['message'] ?? 'Seed xong!');
      _loadUsers();
    } catch (e) {
      _snack('L\u1ed7i: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seedAchievements() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.post('/admin/seed-achievements', {});
      _snack(response['message'] ?? 'Seed achievements xong!');
    } catch (e) {
      _snack('L\u1ed7i: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seedRoadmap() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.post('/admin/seed_roadmap_courses', {});
      _snack(response['message'] ?? 'Seed roadmap xong!');
    } catch (e) {
      _snack('L\u1ed7i: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignRoadmapTeacher() async {
    final emailCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Gán Roadmap cho Giảng viên'),
          content: TextField(
            controller: emailCtrl,
            decoration: InputDecoration(
              labelText: 'Email giảng viên',
              hintText: 'teacher@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: cs.primary),
              child: const Text('Gán'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || emailCtrl.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.post('/admin/assign_roadmap_teacher', {
        'teacherEmail': emailCtrl.text.trim(),
      });
      final count = response['updatedCoursesCount'] ?? 0;
      final name = response['teacherName'] ?? '';
      _snack('Đã gán $count khóa học cho $name');
    } catch (e) {
      _snack('Lỗi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        _snack('Không đọc được file', isError: true);
        return;
      }

      final apiClient = sl<ApiClient>();
      final ext = file.extension?.toLowerCase() ?? '';
      final body = ext == 'xlsx'
          ? {'xlsxBase64': base64Encode(bytes)}
          : {'csvContent': utf8.decode(bytes)};

      final response = await apiClient.post('/admin/import-students', body);
      final created = response['created'] ?? 0;
      final skipped = response['skipped'] ?? 0;
      _snack('Import: $created tạo mới, $skipped bỏ qua');
      _loadUsers();
    } catch (e) {
      _snack('Lỗi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Trị Hệ Thống',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'User'),
            Tab(icon: Icon(Icons.school_rounded), text: 'Học thuật'),
            Tab(icon: Icon(Icons.build_circle_rounded), text: 'Công cụ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserManagementTab(cs),
          _buildAcademicTab(cs),
          _buildToolsTab(cs),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab(ColorScheme cs) {
    return Column(
      children: [
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchBar(
            hintText: 'Tìm theo tên hoặc email...',
            leading: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.search_rounded),
            ),
            trailing: [
              PopupMenuButton<int?>(
                icon: Badge(
                  isLabelVisible: _roleFilter != null,
                  child: const Icon(Icons.filter_list_rounded),
                ),
                tooltip: 'Lọc vai trò',
                onSelected: (v) {
                  _roleFilter = v;
                  _loadUsers();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: null, child: Text('Tất cả')),
                  PopupMenuItem(value: 0, child: Text('🎓 Student')),
                  PopupMenuItem(value: 1, child: Text('👨‍🏫 Teacher')),
                  PopupMenuItem(value: 2, child: Text('🛡️ Admin')),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Làm mới',
                onPressed: _loadUsers,
              ),
            ],
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 4),
            ),
            elevation: const WidgetStatePropertyAll(1),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            onChanged: (v) {
              _searchQuery = v;
              _loadUsers();
            },
          ),
        ),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _m3StatChip(
                'Tổng ${_users.length}',
                Icons.people_alt_rounded,
                cs.primary,
                cs.primaryContainer,
              ),
              _m3StatChip(
                'Admin ${_users.where((u) => u['role'] == 2).length}',
                Icons.shield_rounded,
                cs.tertiary,
                cs.tertiaryContainer,
              ),
              _m3StatChip(
                'GV ${_users.where((u) => u['role'] == 1).length}',
                Icons.school_rounded,
                Colors.teal,
                Colors.teal.shade50,
              ),
              _m3StatChip(
                'SV ${_users.where((u) => u['role'] == 0).length}',
                Icons.person_rounded,
                cs.secondary,
                cs.secondaryContainer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 64,
                        color: cs.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có user nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _users.length,
                    itemBuilder: (_, i) => _buildUserCard(_users[i], cs),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _m3StatChip(
    String label,
    IconData icon,
    Color fgColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, ColorScheme cs) {
    final isBanned = user['isBanned'] == true;
    final role = user['role'] as int? ?? 0;
    final fullName = user['fullName'] as String? ?? '(Chưa đặt tên)';

    final roleConfig = {
      0: (
        label: 'Student',
        icon: Icons.school_rounded,
        fg: cs.primary,
        bg: cs.primaryContainer,
        onBg: cs.onPrimaryContainer,
      ),
      1: (
        label: 'Teacher',
        icon: Icons.cast_for_education_rounded,
        fg: Colors.teal,
        bg: Colors.teal.shade50,
        onBg: Colors.teal.shade800,
      ),
      2: (
        label: 'Admin',
        icon: Icons.shield_rounded,
        fg: cs.tertiary,
        bg: cs.tertiaryContainer,
        onBg: cs.onTertiaryContainer,
      ),
    };
    final cfg = roleConfig[role] ?? roleConfig[0]!;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isBanned
              ? cs.error.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: isBanned
          ? cs.errorContainer.withValues(alpha: 0.15)
          : cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: isBanned ? cs.errorContainer : cfg.bg,
            child: Icon(
              isBanned ? Icons.block_rounded : cfg.icon,
              color: isBanned ? cs.error : cfg.fg,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isBanned ? TextDecoration.lineThrough : null,
                    decorationColor: cs.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: cfg.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cfg.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cfg.onBg,
                  ),
                ),
              ),
              if (isBanned) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Khoá',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              user['email'] ?? '',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showUserActions(user, isBanned, role, cs),
          ),
        ),
      ),
    );
  }

  void _showUserActions(
    Map<String, dynamic> user,
    bool isBanned,
    int role,
    ColorScheme cs,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                user['fullName'] ?? user['email'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                user['email'] ?? '',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.primary),
                title: const Text('Sửa thông tin'),
                shape: _sheetTileShape,
                onTap: () {
                  Navigator.pop(ctx);
                  _editUser(user);
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Icon(
                  isBanned ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: Colors.orange.shade700,
                ),
                title: Text(isBanned ? 'Mở khoá tài khoản' : 'Khoá tài khoản'),
                shape: _sheetTileShape,
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleBan(user['id']);
                },
              ),
              if (role != 2) ...[
                const SizedBox(height: 4),
                ListTile(
                  leading: Icon(Icons.delete_forever_rounded, color: cs.error),
                  title: Text(
                    'Xoá tài khoản',
                    style: TextStyle(color: cs.error),
                  ),
                  shape: _sheetTileShape,
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteUser(user['id'], user['email']);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ShapeBorder get _sheetTileShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  Widget _buildAcademicTab(ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: _loadAcademicData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statCard(
                  cs,
                  'Khoa',
                  _departments.length,
                  Icons.business_rounded,
                  cs.primary,
                ),
                const SizedBox(width: 10),
                _statCard(
                  cs,
                  'Học kỳ',
                  _semesters.length,
                  Icons.calendar_month_rounded,
                  Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statCard(
                  cs,
                  'Học phần',
                  _academicCourses.length,
                  Icons.menu_book_rounded,
                  cs.secondary,
                ),
                const SizedBox(width: 10),
                _statCard(
                  cs,
                  'Lớp HP',
                  _courseClasses.length,
                  Icons.groups_rounded,
                  cs.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.academicStructure,
              ).then((_) => _loadAcademicData()),
              icon: const Icon(Icons.school_rounded),
              label: const Text('Quản lý cấu trúc học thuật'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Thêm, sửa, xóa Khoa · Học kỳ · Học phần · Lớp HP',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    ColorScheme cs,
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsTab(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _m3ToolCard(
            cs: cs,
            icon: Icons.group_add_rounded,
            iconColor: cs.onPrimaryContainer,
            iconBg: cs.primaryContainer,
            title: 'Tạo Dữ Liệu Mẫu',
            subtitle: '1 Admin · 2 Giảng viên · 2 Sinh viên',
            buttonLabel: 'Seed Users',
            buttonColor: cs.primaryContainer,
            buttonTextColor: cs.onPrimaryContainer,
            onPressed: _isLoading ? null : _seedUsers,
          ),
          const SizedBox(height: 16),

          _m3ToolCard(
            cs: cs,
            icon: Icons.upload_file_rounded,
            iconColor: Colors.teal.shade800,
            iconBg: Colors.teal.shade50,
            title: 'Import Sinh Viên',
            subtitle: 'CSV hoặc Excel · Mã SV, Họ Tên, Lớp, Khoa',
            buttonLabel: 'Chọn File',
            buttonColor: Colors.teal.shade50,
            buttonTextColor: Colors.teal.shade800,
            onPressed: _isLoading ? null : _importFile,
          ),
          const SizedBox(height: 16),

          _m3ToolCard(
            cs: cs,
            icon: Icons.emoji_events_rounded,
            iconColor: Colors.amber.shade800,
            iconBg: Colors.amber.shade50,
            title: 'Seed Achievements',
            subtitle: 'T\u1ea1o danh hi\u1ec7u, huy ch\u01b0\u01a1ng m\u1eabu',
            buttonLabel: 'Seed',
            buttonColor: Colors.amber.shade50,
            buttonTextColor: Colors.amber.shade800,
            onPressed: _isLoading ? null : _seedAchievements,
          ),
          const SizedBox(height: 16),

          _m3ToolCard(
            cs: cs,
            icon: Icons.map_rounded,
            iconColor: Colors.indigo.shade800,
            iconBg: Colors.indigo.shade50,
            title: 'Seed Roadmap & Kho\u0301a h\u1ecdc',
            subtitle:
                'T\u1ea1o l\u1ed9 tr\u00ecnh v\u00e0 kho\u0301a h\u1ecdc m\u1eabu',
            buttonLabel: 'Seed',
            buttonColor: Colors.indigo.shade50,
            buttonTextColor: Colors.indigo.shade800,
            onPressed: _isLoading ? null : _seedRoadmap,
          ),
          const SizedBox(height: 16),

          _m3ToolCard(
            cs: cs,
            icon: Icons.how_to_reg_rounded,
            iconColor: Colors.green.shade800,
            iconBg: Colors.green.shade50,
            title: 'Duyệt đơn Giảng viên',
            subtitle: 'Xem & duyệt đơn đăng ký làm giảng viên',
            buttonLabel: 'Duyệt',
            buttonColor: Colors.green.shade50,
            buttonTextColor: Colors.green.shade800,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.teacherApplications);
            },
          ),
          const SizedBox(height: 16),

          _m3ToolCard(
            cs: cs,
            icon: Icons.person_pin_rounded,
            iconColor: Colors.deepPurple.shade800,
            iconBg: Colors.deepPurple.shade50,
            title: 'Gán Roadmap cho GV',
            subtitle: 'Assign tất cả khóa roadmap cho 1 giảng viên',
            buttonLabel: 'Gán',
            buttonColor: Colors.deepPurple.shade50,
            buttonTextColor: Colors.deepPurple.shade800,
            onPressed: _isLoading ? null : _assignRoadmapTeacher,
          ),

          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _m3ToolCard({
    required ColorScheme cs,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required Color buttonTextColor,
    required VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 1,
      shadowColor: cs.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
