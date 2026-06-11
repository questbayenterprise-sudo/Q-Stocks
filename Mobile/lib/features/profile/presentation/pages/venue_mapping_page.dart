import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

class VenueMappingPage extends StatefulWidget {
  const VenueMappingPage({super.key});

  @override
  State<VenueMappingPage> createState() => _VenueMappingPageState();
}

class _VenueMappingPageState extends State<VenueMappingPage> {
  final String baseUrl = AppConfig.baseUrl;
  List<Map<String, dynamic>> _mappings = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadMappings(), _loadUsers(), _loadVenues()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMappings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/GetVenueMappings'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          _mappings = List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/GetUserListForMapping'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          _users = List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadVenues() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/GetVenueListForMapping'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          _venues = List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
    } catch (_) {}
  }

  Future<void> _addMapping(int userId, int venueId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/AddVenueMapping'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "venue_id": venueId}),
      );
      final data = jsonDecode(res.body);
      _showSnackBar(data['message'] ?? 'Done', isError: data['success'] != true);
      if (data['success'] == true) _loadAll();
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    }
  }

  Future<void> _removeMapping(int id) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/RemoveVenueMapping'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );
      final data = jsonDecode(res.body);
      _showSnackBar(data['message'] ?? 'Removed', isError: data['success'] != true);
      if (data['success'] == true) _loadAll();
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF00A36C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin': return Colors.red.shade600;
      case 'owner': return Colors.blue.shade600;
      case 'vendor': return Colors.purple.shade500;
      case 'manager': return Colors.teal.shade600;
      default: return const Color(0xFF00A36C);
    }
  }

  List<Map<String, dynamic>> get _filteredMappings {
    if (_searchQuery.isEmpty) return _mappings;
    final q = _searchQuery.toLowerCase();
    return _mappings.where((m) =>
        (m['username'] ?? '').toLowerCase().contains(q) ||
        (m['email'] ?? '').toLowerCase().contains(q) ||
        (m['venue_name'] ?? '').toLowerCase().contains(q)).toList();
  }

  void _showAddMappingDialog() {
    int? selectedUserId;
    int? selectedVenueId;
    String userSearch = '';
    String venueSearch = '';

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (ctx, a1, a2, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        ),
        pageBuilder: (ctx, a1, a2) {
          return StatefulBuilder(builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final filteredUsers = userSearch.isEmpty
                ? _users
                : _users.where((u) =>
                    (u['username'] ?? '').toLowerCase().contains(userSearch.toLowerCase()) ||
                    (u['email'] ?? '').toLowerCase().contains(userSearch.toLowerCase())).toList();
            final filteredVenues = venueSearch.isEmpty
                ? _venues
                : _venues.where((v) =>
                    (v['name'] ?? '').toLowerCase().contains(venueSearch.toLowerCase()) ||
                    (v['location'] ?? '').toLowerCase().contains(venueSearch.toLowerCase())).toList();

            final selectedUser = selectedUserId != null
                ? _users.firstWhere((u) => u['id'] == selectedUserId, orElse: () => {})
                : null;
            final selectedVenue = selectedVenueId != null
                ? _venues.firstWhere((v) => v['id'] == selectedVenueId, orElse: () => {})
                : null;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {},
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 8),
                              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  const Text("Map Venue to User", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Content
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Selected summary
                                    if (selectedUser != null || selectedVenue != null)
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00A36C).withAlpha(10),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFF00A36C).withAlpha(40)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("User", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                                  Text(selectedUser?['username'] ?? 'Not selected',
                                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: selectedUser != null ? null : Colors.grey)),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.link, color: Color(0xFF00A36C)),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text("Venue", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                                  Text(selectedVenue?['name'] ?? 'Not selected',
                                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: selectedVenue != null ? null : Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // User section
                                    const Text("Select User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      onChanged: (v) => setDialogState(() => userSearch = v),
                                      decoration: InputDecoration(
                                        hintText: "Search users...",
                                        prefixIcon: const Icon(Icons.search, size: 20),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 140,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                      ),
                                      child: ListView.builder(
                                        itemCount: filteredUsers.length,
                                        itemBuilder: (ctx, i) {
                                          final u = filteredUsers[i];
                                          final isSelected = selectedUserId == u['id'];
                                          return ListTile(
                                            dense: true,
                                            selected: isSelected,
                                            selectedTileColor: const Color(0xFF00A36C).withAlpha(15),
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setDialogState(() => selectedUserId = u['id']);
                                            },
                                            leading: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: _roleColor(u['role']).withAlpha(25),
                                              child: Text((u['username'] ?? 'U')[0].toUpperCase(),
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _roleColor(u['role']))),
                                            ),
                                            title: Text(u['username'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                            subtitle: Text(u['email'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                            trailing: isSelected
                                                ? const Icon(Icons.check_circle, color: Color(0xFF00A36C), size: 20)
                                                : Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: _roleColor(u['role']).withAlpha(15), borderRadius: BorderRadius.circular(6)),
                                                    child: Text((u['role'] ?? 'user').toUpperCase(), style: TextStyle(fontSize: 9, color: _roleColor(u['role']), fontWeight: FontWeight.bold)),
                                                  ),
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Venue section
                                    const Text("Select Venue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      onChanged: (v) => setDialogState(() => venueSearch = v),
                                      decoration: InputDecoration(
                                        hintText: "Search venues...",
                                        prefixIcon: const Icon(Icons.search, size: 20),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 140,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                      ),
                                      child: ListView.builder(
                                        itemCount: filteredVenues.length,
                                        itemBuilder: (ctx, i) {
                                          final v = filteredVenues[i];
                                          final isSelected = selectedVenueId == v['id'];
                                          return ListTile(
                                            dense: true,
                                            selected: isSelected,
                                            selectedTileColor: const Color(0xFF00A36C).withAlpha(15),
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setDialogState(() => selectedVenueId = v['id']);
                                            },
                                            leading: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.blue.withAlpha(20),
                                              child: const Icon(Icons.sports_soccer, size: 16, color: Colors.blue),
                                            ),
                                            title: Text(v['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                            subtitle: Text(v['location'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                            trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00A36C), size: 20) : null,
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Submit
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: selectedUserId != null && selectedVenueId != null
                                            ? () {
                                                Navigator.pop(context);
                                                _addMapping(selectedUserId!, selectedVenueId!);
                                              }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00A36C),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: const Text("Map Venue to User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredMappings;

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
                        const Text("Venue Mapping", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text("${_mappings.length} active mappings", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh_rounded)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search by user or venue...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                            onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
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
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                child: Icon(Icons.link_off, size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text("No mappings found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text("Tap + to map a venue to a user", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAll,
                          color: const Color(0xFF00A36C),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildMappingCard(isDark, filtered[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMappingDialog,
        backgroundColor: const Color(0xFF00A36C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMappingCard(bool isDark, Map<String, dynamic> mapping) {
    final roleColor = _roleColor(mapping['role']);
    return Dismissible(
      key: Key(mapping['id'].toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Remove Mapping"),
            content: Text("Remove ${mapping['username']} from ${mapping['venue_name']}?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Remove", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _removeMapping(mapping['id']),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.delete_outline, color: Colors.red.shade400),
      ),
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
            // User avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: roleColor.withAlpha(20),
              child: Text(
                (mapping['username'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(mapping['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: roleColor.withAlpha(15), borderRadius: BorderRadius.circular(6)),
                        child: Text((mapping['role'] ?? 'user').toUpperCase(), style: TextStyle(fontSize: 8, color: roleColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.link, size: 13, color: Color(0xFF00A36C)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mapping['venue_name'] ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF00A36C)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(mapping['email'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),

            // Swipe hint
            Icon(Icons.chevron_left, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}
