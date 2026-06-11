import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final String baseUrl = AppConfig.baseUrl;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterRole;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _roles = ['admin', 'owner', 'vendor', 'manager', 'user'];

  final Map<String, IconData> _roleIcons = {
    'admin': Icons.shield_outlined,
    'owner': Icons.business_outlined,
    'vendor': Icons.storefront_outlined,
    'manager': Icons.manage_accounts_outlined,
    'user': Icons.person_outline,
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/GetAllUsers'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(data['data']);
            _applyFilters();
          });
        }
      }
    } catch (e) {
      _showSnackBar("Failed to load users", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          (user['username'] ?? '').toLowerCase().contains(q) ||
          (user['email'] ?? '').toLowerCase().contains(q) ||
          (user['phoneno'] ?? '').toLowerCase().contains(q);
      final matchesRole = _filterRole == null || user['role'] == _filterRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  Future<void> _updateRole(int userId, String newRole) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/UpdateUserRole'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "role": newRole}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnackBar("Role updated to ${newRole.toUpperCase()}");
        _loadUsers();
      } else {
        _showSnackBar(data['message'] ?? "Failed", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    }
  }

  Future<void> _deleteUser(int userId, String username) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Delete",
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (ctx, a1, a2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
          child: child,
        );
      },
      pageBuilder: (ctx, a1, a2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 32),
          ),
          title: const Text("Delete User", style: TextStyle(fontWeight: FontWeight.bold)),
          content: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              children: [
                const TextSpan(text: "This will permanently remove "),
                TextSpan(text: username, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const TextSpan(text: " and all associated data."),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Delete_Cususer'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": userId.toString()}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnackBar("User deleted");
        _loadUsers();
      } else {
        _showSnackBar(data['message'] ?? "Delete failed", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF00A36C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (ctx, a1, a2, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        pageBuilder: (ctx, a1, a2) {
          return _UserDetailOverlay(
            user: user,
            roles: _roles,
            roleIcons: _roleIcons,
            baseUrl: baseUrl,
            roleColorFn: _roleColor,
            onUpdateRole: _updateRole,
            onDeleteUser: _deleteUser,
          );
        },
      ),
    );
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red.shade600;
      case 'owner':
        return Colors.blue.shade600;
      case 'vendor':
        return Colors.purple.shade500;
      case 'manager':
        return Colors.teal.shade600;
      default:
        return const Color(0xFF00A36C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Map<String, int> roleCounts = {};
    for (var u in _users) {
      final r = u['role'] ?? 'user';
      roleCounts[r] = (roleCounts[r] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: isDark ? null : Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Manage Users", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text("${_users.length} total users", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh_rounded)),
                ],
              ),
            ),

            // Role filter chips
            if (!_isLoading && roleCounts.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _buildRoleFilterChip(null, "All", _users.length, isDark),
                    ..._roles.where((r) => roleCounts.containsKey(r)).map(
                        (r) => _buildRoleFilterChip(r, r[0].toUpperCase() + r.substring(1), roleCounts[r]!, isDark)),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() { _searchQuery = val; _applyFilters(); }),
                  decoration: InputDecoration(
                    hintText: "Search by name, email, or phone...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                            onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; _applyFilters(); }); },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)))
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                child: Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(_searchQuery.isNotEmpty ? "No matching users" : "No users found",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          color: const Color(0xFF00A36C),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) => _buildUserCard(context, isDark, _filteredUsers[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilterChip(String? role, String label, int count, bool isDark) {
    final isActive = _filterRole == role;
    final color = role != null ? _roleColor(role) : const Color(0xFF00A36C);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _filterRole = role; _applyFilters(); });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withAlpha(isDark ? 50 : 15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300), width: isActive ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: isActive ? color : Colors.grey.shade600, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive ? color.withAlpha(30) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("$count", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? color : Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, bool isDark, Map<String, dynamic> user) {
    final role = user['role'] ?? 'user';
    final color = _roleColor(role);
    return GestureDetector(
      onTap: () => _showUserDetail(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withAlpha(100), width: 2)),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: color.withAlpha(20),
                backgroundImage: (user['image_url'] ?? '').isNotEmpty ? NetworkImage('$baseUrl/${user['image_url']}') : null,
                child: (user['image_url'] ?? '').isEmpty
                    ? Text((user['username'] ?? 'U')[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18))
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(user['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (user['is_active'] != true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                          child: Text("INACTIVE", style: TextStyle(color: Colors.red.shade600, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.mail_outline, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(child: Text(user['email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: color.withAlpha(isDark ? 40 : 15), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_roleIcons[role], size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate overlay widget for user detail — renders above everything
class _UserDetailOverlay extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<String> roles;
  final Map<String, IconData> roleIcons;
  final String baseUrl;
  final Color Function(String?) roleColorFn;
  final Future<void> Function(int, String) onUpdateRole;
  final Future<void> Function(int, String) onDeleteUser;

  const _UserDetailOverlay({
    required this.user,
    required this.roles,
    required this.roleIcons,
    required this.baseUrl,
    required this.roleColorFn,
    required this.onUpdateRole,
    required this.onDeleteUser,
  });

  @override
  State<_UserDetailOverlay> createState() => _UserDetailOverlayState();
}

class _UserDetailOverlayState extends State<_UserDetailOverlay> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user['role'] ?? 'user';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.user;
    final roleColor = widget.roleColorFn(_selectedRole);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // prevent dismiss on sheet tap
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).padding.bottom + 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 24),

                      // Profile card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.roleColorFn(user['role']).withAlpha(isDark ? 40 : 15), widget.roleColorFn(user['role']).withAlpha(isDark ? 20 : 5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.roleColorFn(user['role']).withAlpha(isDark ? 60 : 30)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.roleColorFn(user['role']), width: 2)),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: widget.roleColorFn(user['role']).withAlpha(30),
                                backgroundImage: (user['image_url'] ?? '').isNotEmpty ? NetworkImage('${widget.baseUrl}/${user['image_url']}') : null,
                                child: (user['image_url'] ?? '').isEmpty
                                    ? Text((user['username'] ?? 'U')[0].toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.roleColorFn(user['role'])))
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['username'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.mail_outline, size: 13, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(user['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  ]),
                                  if ((user['phoneno'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(user['phoneno'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info chips
                      Row(
                        children: [
                          _infoChip(Icons.location_on_outlined, (user['city'] ?? '').isEmpty ? 'No location' : user['city'], isDark),
                          const SizedBox(width: 8),
                          _infoChip(Icons.calendar_today_outlined, user['created_at'] ?? '', isDark),
                          const SizedBox(width: 8),
                          _infoChip(
                            user['is_active'] == true ? Icons.check_circle_outline : Icons.cancel_outlined,
                            user['is_active'] == true ? 'Active' : 'Inactive',
                            isDark,
                            color: user['is_active'] == true ? const Color(0xFF00A36C) : Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Assign Role header
                      Row(
                        children: [
                          const Text("Assign Role", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: roleColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(widget.roleIcons[_selectedRole], size: 14, color: roleColor),
                                const SizedBox(width: 4),
                                Text(_selectedRole.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Role grid
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.4,
                        children: widget.roles.map((role) {
                          final isSelected = _selectedRole == role;
                          final color = widget.roleColorFn(role);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedRole = role);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withAlpha(isDark ? 50 : 20) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300), width: isSelected ? 2 : 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(widget.roleIcons[role], size: 16, color: isSelected ? color : Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Text(role[0].toUpperCase() + role.substring(1),
                                      style: TextStyle(color: isSelected ? color : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      // Actions
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(14)),
                            child: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onDeleteUser(user['id'], user['username']);
                              },
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _selectedRole != user['role']
                                  ? () {
                                      Navigator.pop(context);
                                      widget.onUpdateRole(user['id'], _selectedRole);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00A36C),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                disabledForegroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: _selectedRole != user['role'] ? 2 : 0,
                              ),
                              child: Text(
                                _selectedRole != user['role'] ? "Update to ${_selectedRole.toUpperCase()}" : "No Changes",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, bool isDark, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey.shade500),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(fontSize: 10, color: color ?? Colors.grey.shade600, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
