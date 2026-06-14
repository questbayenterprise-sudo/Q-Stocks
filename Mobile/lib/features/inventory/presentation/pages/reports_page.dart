import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/excel_service.dart'; // Ensure this utility is created
import '../../data/repositories/reports_repository.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _repo = ReportsRepository();
  bool _isExporting = false;

  // Default range: Last 7 days
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  String get _formattedRange =>
      "${DateFormat('dd MMM').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Business Reports", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _selectDateRange,
            tooltip: "Filter by Date",
          )
        ],
      ),
      body: Column(
        children: [
          // Date Range Display Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Reporting Period: $_formattedRange",
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _repo.getSummaryReport(start: _dateRange.start, end: _dateRange.end),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error calculating reports: ${snapshot.error}"));
                }

                final data = snapshot.data ?? {};
                final totalSales = data['total_sales'] ?? 0.0;
                final totalReceived = data['total_received'] ?? 0.0;
                final totalDues = data['total_dues'] ?? 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildReportCard("TOTAL SALES", "₹$totalSales", Icons.trending_up, Colors.blue),
                      const SizedBox(height: 16),
                      _buildReportCard("CASH COLLECTED", "₹$totalReceived", Icons.payments_outlined, Colors.green),
                      const SizedBox(height: 16),
                      _buildReportCard("PENDING DUES", "₹$totalDues", Icons.assignment_late_outlined, Colors.red),
                      
                      const SizedBox(height: 40),
                      
                      // Action Buttons
                      const Text(
                        "Download Detail Statement",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildExportButton(
                        label: "EXPORT TO EXCEL",
                        icon: Icons.table_view,
                        color: const Color(0xFF1D6F42), // Excel Green
                        onPressed: _exportToExcel,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildExportButton(
                        label: "EXPORT TO PDF",
                        icon: Icons.picture_as_pdf,
                        color: const Color(0xFFE91E63), // PDF Red
                        onPressed: () {
                          // Placeholder for PDF logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("PDF Export coming in next update!")),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 24,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : onPressed,
        icon: _isExporting 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // --- Logic Methods ---

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00A36C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      // 1. Fetch the raw rows from DB
      final detailedData = await _repo.getDetailedSalesReport(
        start: _dateRange.start,
        end: _dateRange.end,
      );

      // 2. Call Excel Service
      await ExcelService.exportSalesReport(
        salesData: detailedData,
        fileName: "Sales_Report_${DateFormat('ddMMyy').format(_dateRange.start)}_to_${DateFormat('ddMMyy').format(_dateRange.end)}",
      );

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Excel Exported Successfully")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export Error: $e")));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}