import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';
import '../../data/qr_scan_repository.dart';

class ScanResultPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const ScanResultPage({super.key, required this.bookingData});

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  final QrScanRepository _repo = QrScanRepository();
  late Map<String, dynamic> _data;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.bookingData);
  }

  String get _status => (_data['status'] ?? '').toString();
  int get _bookingId => (_data['id'] as num?)?.toInt() ?? 0;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);

    final updatedBy = int.tryParse(UserSession().userId ?? '0') ?? 0;
    final result = await _repo.updateBookingStatus(
      bookingId: _bookingId,
      status: newStatus,
      updatedBy: updatedBy,
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (result != null && result['success'] == true) {
      setState(() => _data['status'] = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Status updated'),
          backgroundColor: const Color(0xFF00A36C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? 'Failed to update status'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'PENDING':
        return Colors.orange;
      case 'CHECKED-IN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.teal;
      case 'COMPLETED':
        return const Color(0xFF00A36C);
      case 'NO_SHOW':
        return Colors.red.shade300;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.contains('uploads')) {
      return "${AppConfig.baseUrl}/${path.replaceAll('\\', '/')}";
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final venueName = (_data['venue_name'] ?? '').toString();
    final bookingRef = (_data['booking_ref'] ?? '').toString();
    final userName = (_data['user_name'] ?? '').toString();
    final userPhone = (_data['user_phone'] ?? '').toString();
    final userEmail = (_data['user_email'] ?? '').toString();
    final startTime = (_data['start_time'] ?? '').toString();
    final endTime = (_data['end_time'] ?? '').toString();
    final bookingDate = (_data['booking_date'] ?? '').toString();
    final amount = (_data['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus = (_data['payment_status'] ?? 'NA').toString();
    final sportName = (_data['sport_name'] ?? '').toString();
    final venueImage = _resolveImageUrl((_data['venue_image'] ?? '').toString());
    final sColor = _statusColor(_status);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Booking Details",
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Status header card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [sColor, sColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: sColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _status == 'COMPLETED'
                        ? Icons.check_circle
                        : _status == 'IN_PROGRESS'
                            ? Icons.play_circle_filled
                            : _status == 'CHECKED-IN'
                                ? Icons.login_rounded
                                : Icons.confirmation_num_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bookingRef,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Venue card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: venueImage.isNotEmpty
                          ? Image.network(venueImage, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _iconPlaceholder())
                          : _iconPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venueName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (sportName.isNotEmpty)
                          Text(sportName,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Booking details ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _detailRow(Icons.person_outline, "Customer", userName),
                  if (userPhone.isNotEmpty)
                    _detailRow(Icons.phone_outlined, "Phone", userPhone),
                  if (userEmail.isNotEmpty)
                    _detailRow(Icons.email_outlined, "Email", userEmail),
                  const Divider(height: 20),
                  _detailRow(Icons.calendar_today, "Date", bookingDate),
                  _detailRow(
                      Icons.schedule, "Time", "$startTime - $endTime"),
                  const Divider(height: 20),
                  _detailRow(Icons.currency_rupee, "Amount",
                      "₹${amount.toStringAsFixed(0)}"),
                  _detailRow(Icons.payment, "Payment", paymentStatus),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ──
            if (_status != 'COMPLETED' && _status != 'CANCELLED')
              _buildActionButtons(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Start button — visible when CONFIRMED, PENDING, or CHECKED-IN
        if (_status == 'CONFIRMED' ||
            _status == 'PENDING' ||
            _status == 'CHECKED-IN')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : () => _updateStatus('IN_PROGRESS'),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text("START SESSION",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

        if (_status == 'IN_PROGRESS') ...[
          // Complete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : () => _updateStatus('COMPLETED'),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("MARK COMPLETED",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // No-show / Cancel row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUpdating ? null : () => _confirmAction(
                  "Mark No-Show?",
                  "This will mark the customer as not arrived.",
                  () => _updateStatus('NO_SHOW'),
                ),
                icon: Icon(Icons.person_off_outlined,
                    color: Colors.orange.shade700, size: 18),
                label: Text("No-Show",
                    style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUpdating ? null : () => _confirmAction(
                  "Cancel Booking?",
                  "This action cannot be undone.",
                  () => _updateStatus('CANCELLED'),
                ),
                icon: const Icon(Icons.cancel_outlined,
                    color: Colors.red, size: 18),
                label: const Text("Cancel",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmAction(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("CONFIRM",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _iconPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: Icon(Icons.sports_soccer, size: 28, color: Colors.grey[400]),
    );
  }
}
