import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final String baseUrl = AppConfig.baseUrl;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/GetNotifications'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": UserSession().userId ?? ""}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(data['data'] ?? []);
            _unreadCount = data['unread_count'] ?? 0;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(int id) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/MarkNotificationRead'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/MarkNotificationRead'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": UserSession().userId ?? "", "all": true}),
      );
      _loadNotifications();
    } catch (_) {}
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'booking_confirmed':
        return Icons.check_circle_outline;
      case 'booking_cancelled':
        return Icons.cancel_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'reminder':
        return Icons.alarm_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'booking_confirmed':
        return const Color(0xFF00A36C);
      case 'booking_cancelled':
        return Colors.red;
      case 'payment':
        return Colors.orange;
      case 'reminder':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
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
                        const Text("Notifications", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        if (_unreadCount > 0)
                          Text("$_unreadCount unread", style: TextStyle(color: const Color(0xFF00A36C), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text("Read all", style: TextStyle(color: Color(0xFF00A36C), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)))
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: const Color(0xFF00A36C),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              return _buildNotificationCard(isDark, _notifications[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text("No notifications yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text("You'll see booking updates here", style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A36C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Refresh", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(bool isDark, Map<String, dynamic> notification) {
    final type = notification['type'] ?? '';
    final isRead = notification['is_read'] == true;
    final color = _typeColor(type);
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(notification['id']);
          setState(() {
            notification['is_read'] = true;
            _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? (isRead ? Colors.grey.shade900 : const Color(0xFF2A2A2A))
              : (isRead ? Colors.white : const Color(0xFFF0FDF4)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                : color.withAlpha(40),
          ),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(type), color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['body'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Booking details chips
                  if (data.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (data['booking_ref'] != null)
                          _buildChip(Icons.confirmation_number_outlined, data['booking_ref'], color, isDark),
                        if (data['venue_name'] != null)
                          _buildChip(Icons.location_on_outlined, data['venue_name'], Colors.blue, isDark),
                        if (data['amount'] != null && data['amount'] != '0')
                          _buildChip(Icons.currency_rupee, '${data['amount']}', Colors.orange, isDark),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notification['created_at'] ?? ''),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? color.withAlpha(20) : color.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
