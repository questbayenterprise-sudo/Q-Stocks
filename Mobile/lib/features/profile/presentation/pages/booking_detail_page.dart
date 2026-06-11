import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';

class BookingDetailPage extends StatefulWidget {
  final int bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBookingDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookingDetail() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/GetBookingDetail'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "booking_id": widget.bookingId,
          "user_id": UserSession().userId,
        }),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && mounted) {
          setState(() {
            _data = result['data'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("BookingDetail fetch error: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _safe(String key) => (_data?[key] ?? '').toString();
  double _safeNum(String key) => (_data?[key] as num?)?.toDouble() ?? 0.0;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return const Color(0xFF00A36C);
      case 'PENDING':
        return Colors.orange;
      case 'CHECKED-IN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.teal;
      case 'COMPLETED':
        return const Color(0xFF00A36C);
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Booking Details",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_data != null)
            IconButton(
              onPressed: _shareBooking,
              icon: const Icon(Icons.share_outlined),
            ),
        ],
        bottom: _data != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00A36C),
                labelColor: const Color(0xFF00A36C),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Details"),
                  Tab(text: "QR Code"),
                  Tab(text: "Invoice"),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)))
          : _data == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text("Booking not found",
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildQRTab(),
                    _buildInvoiceTab(),
                  ],
                ),
    );
  }

  // ═══════════════════════════════════════
  //  TAB 1: DETAILS
  // ═══════════════════════════════════════

  Widget _buildDetailsTab() {
    final status = _safe('status');
    final sColor = _statusColor(status);
    final venueImage = _resolveImageUrl(_safe('venue_image'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [sColor, sColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  status == 'COMPLETED'
                      ? Icons.check_circle
                      : status == 'CANCELLED'
                          ? Icons.cancel
                          : Icons.confirmation_num,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  status.replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _safe('booking_ref'),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Venue card
          _sectionCard([
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: venueImage.isNotEmpty
                        ? Image.network(venueImage, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(Icons.sports_soccer))
                        : _placeholder(Icons.sports_soccer),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_safe('venue_name'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_safe('venue_location').isNotEmpty)
                        Text(_safe('venue_location'),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      if (_safe('sport_name').isNotEmpty)
                        Text(_safe('sport_name'),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 14),

          // Booking info
          _sectionCard([
            _infoRow(Icons.calendar_today, "Date", _safe('booking_date')),
            _infoRow(Icons.schedule, "Time",
                "${_safe('start_time')} - ${_safe('end_time')}"),
            _infoRow(Icons.person_outline, "Customer", _safe('user_name')),
            if (_safe('user_phone').isNotEmpty)
              _infoRow(Icons.phone_outlined, "Phone", _safe('user_phone')),
            if (_safe('user_email').isNotEmpty)
              _infoRow(Icons.email_outlined, "Email", _safe('user_email')),
          ]),

          const SizedBox(height: 14),

          // Payment info
          _sectionCard([
            _infoRow(Icons.currency_rupee, "Amount",
                "₹${_safeNum('amount').toStringAsFixed(0)}"),
            _infoRow(Icons.payment, "Payment", _safe('payment_status')),
            _infoRow(Icons.access_time, "Booked At", _safe('booked_at')),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  TAB 2: QR CODE
  // ═══════════════════════════════════════

  Widget _buildQRTab() {
    final qrData = jsonEncode({
      "booking_ref": _safe('booking_ref'),
      "booking_id": _data?['id'],
      "venue": _safe('venue_name'),
      "date": _safe('booking_date'),
      "time": "${_safe('start_time')} - ${_safe('end_time')}",
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // QR Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _safe('booking_ref'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  embeddedImage:
                      const AssetImage('assets/images/logo.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(40, 40),
                  ),
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
                const SizedBox(height: 20),
                Text(
                  "Show this QR at the venue",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  _safe('venue_name'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${_safe('booking_date')}  |  ${_safe('start_time')} - ${_safe('end_time')}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Share QR button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _shareBooking,
              icon: const Icon(Icons.share_outlined),
              label: const Text("Share Booking",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00A36C),
                side: const BorderSide(color: Color(0xFF00A36C)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  TAB 3: INVOICE
  // ═══════════════════════════════════════

  Widget _buildInvoiceTab() {
    final amount = _safeNum('amount');
    final tax = amount * 0.18; // 18% GST
    final total = amount + tax;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Invoice card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("INVOICE",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 2)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_safe('booking_ref'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_safe('booking_date'),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ],
                ),

                const Divider(height: 30),

                // Bill to
                Text("BILL TO",
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(_safe('user_name'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (_safe('user_email').isNotEmpty)
                  Text(_safe('user_email'),
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (_safe('user_phone').isNotEmpty)
                  Text(_safe('user_phone'),
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12)),

                const SizedBox(height: 20),

                // Service details table
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text("Service",
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text("Qty",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text("Amount",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const Divider(height: 16),
                      // Service row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_safe('venue_name'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(
                                    "${_safe('start_time')} - ${_safe('end_time')}",
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11)),
                                if (_safe('sport_name').isNotEmpty)
                                  Text(_safe('sport_name'),
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11)),
                              ],
                            ),
                          ),
                          const Expanded(
                              child: Text("1",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13))),
                          Expanded(
                              child: Text(
                                  "₹${amount.toStringAsFixed(0)}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Totals
                _invoiceRow("Subtotal", "₹${amount.toStringAsFixed(0)}"),
                _invoiceRow("GST (18%)", "₹${tax.toStringAsFixed(0)}"),
                const Divider(height: 16),
                _invoiceRow(
                  "Total",
                  "₹${total.toStringAsFixed(0)}",
                  bold: true,
                  large: true,
                ),

                const SizedBox(height: 16),

                // Payment status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _safe('payment_status') == 'Success'
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _safe('payment_status') == 'Success'
                            ? Icons.check_circle
                            : Icons.pending,
                        size: 16,
                        color: _safe('payment_status') == 'Success'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Payment: ${_safe('payment_status')}",
                        style: TextStyle(
                          color: _safe('payment_status') == 'Success'
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Export buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text("Export PDF",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _printInvoice,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text("Print",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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

  Widget _invoiceRow(String label, String value,
      {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: bold ? Colors.black : Colors.grey[600],
                fontSize: large ? 16 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: large ? 18 : 13,
                color: bold ? const Color(0xFF00A36C) : null,
              )),
        ],
      ),
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      color: Colors.grey[200],
      child: Icon(icon, size: 28, color: Colors.grey[400]),
    );
  }

  void _shareBooking() {
    final text = "Booking: ${_safe('booking_ref')}\n"
        "Venue: ${_safe('venue_name')}\n"
        "Date: ${_safe('booking_date')}\n"
        "Time: ${_safe('start_time')} - ${_safe('end_time')}\n"
        "Status: ${_safe('status')}";
    Share.share(text);
  }

  // ── PDF Generation ──

  Future<pw.Document> _buildPdfDocument() async {
    final pdf = pw.Document();
    final amount = _safeNum('amount');
    final tax = amount * 0.18;
    final total = amount + tax;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Q-SPORTS",
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("INVOICE",
                          style: pw.TextStyle(
                              fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_safe('booking_ref'),
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text(_safe('booking_date'),
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Bill to
              pw.Text("BILL TO",
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(_safe('user_name'),
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(_safe('user_email')),
              pw.Text(_safe('user_phone')),
              pw.SizedBox(height: 20),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Service",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Qty",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Amount",
                            textAlign: pw.TextAlign.right,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_safe('venue_name')),
                          pw.Text(
                              "${_safe('start_time')} - ${_safe('end_time')}",
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("1"),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                          "Rs.${amount.toStringAsFixed(0)}",
                          textAlign: pw.TextAlign.right),
                    ),
                  ]),
                ],
              ),

              pw.SizedBox(height: 16),

              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        "Subtotal: Rs.${amount.toStringAsFixed(0)}"),
                    pw.Text("GST (18%): Rs.${tax.toStringAsFixed(0)}"),
                    pw.Divider(),
                    pw.Text("Total: Rs.${total.toStringAsFixed(0)}",
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),
              pw.Text("Payment Status: ${_safe('payment_status')}"),
              pw.Text("Booking Status: ${_safe('status')}"),

              pw.Spacer(),
              pw.Divider(),
              pw.Text("Thank you for booking with Q-Sports!",
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _exportPdf() async {
    final pdf = await _buildPdfDocument();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_${_safe('booking_ref')}.pdf',
    );
  }

  Future<void> _printInvoice() async {
    final pdf = await _buildPdfDocument();
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Invoice_${_safe('booking_ref')}',
    );
  }
}
