import '../../../../core/utils/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/excel_service.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../data/repositories/reports_repository.dart';
import '../../../../core/utils/pdf_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _repo = ReportsRepository();
  final _customerRepo = CustomerRepository();

  bool _isExporting = false;
  CustomerModel? _selectedCustomer;

  // Default range: Last 7 days
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  String get _formattedRange =>
      "${DateFormat('dd MMM').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}";
Future<void> _exportToPdf() async {
    setState(() => _isExporting = true);
    try {
      final detailedData = await _repo.getDetailedSalesReport(
        customerId: _selectedCustomer?.id,
        start: _dateRange.start,
        end: _dateRange.end,
      );

      if (detailedData.isEmpty) throw Exception("No sales found for this period");

      await PdfService.exportSalesReport(
        salesData: detailedData,
        fileName: "Report_${DateFormat('ddMMyy').format(DateTime.now())}",
        period: _formattedRange,
        customerName: _selectedCustomer?.name,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Business Reports", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF00A36C)),
            onPressed: _selectDateRange,
            tooltip: "Filter by Date",
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Date Range Display Bar
          _buildDateRangeBar(),

          // 2. Searchable Customer Filter
          _buildCustomerFilter(),

          // 3. Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- Part A: Global Summary & Export Buttons ---
                  FutureBuilder<Map<String, dynamic>>(
                    future: _repo.getSummaryReport(
                      customerId: _selectedCustomer?.id,
                      start: _dateRange.start,
                      end: _dateRange.end,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final data = snapshot.data ?? {};
                      // This method builds the Cards and the Excel/PDF Buttons
                      return _buildReportContent(data); 
                    },
                  ),

                  const Divider(thickness: 1, height: 40),

                  // --- Part B: Customer-wise Breakdown List ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Customer-wise Breakdown",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _repo.getCustomerWiseSummary(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      
                      final summary = snapshot.data!;
                      if (summary.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No data found"));

                      return ListView.builder(
                        shrinkWrap: true, // Crucial for using inside SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: summary.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final data = summary[index];
                          double pending = double.tryParse(data['pending_balance'].toString()) ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              onTap: () => context.push('/customers/${data['id']}'),
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _smallStat("Sales", "₹${data['total_sales']}", Colors.blue),
                                      _smallStat("Paid", "₹${data['total_paid']}", Colors.green),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("PENDING", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  Text(
                                    "₹${pending.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.w900, 
                                      color: pending > 0 ? Colors.red : Colors.green
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HELPER WIDGETS =====================

  Widget _smallStat(String label, String val, Color col) {
    return Text("$label: $val", style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w600));
  }

  Widget _buildDateRangeBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            "Reporting Period: $_formattedRange",
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: DropdownSearch<CustomerModel>(
        items: (filter, loadProps) => _customerRepo.fetchCustomers(),
        compareFn: (CustomerModel item, CustomerModel selectedItem) => item.id == selectedItem.id,
        itemAsString: (CustomerModel? c) => c?.name ?? "",
        onChanged: (val) => setState(() => _selectedCustomer = val),
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Quick Search Customer",
            hintText: "Search for customer-specific summary...",
            prefixIcon: const Icon(Icons.person_search, color: Color(0xFF00A36C)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Type customer name...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReportCard("TOTAL SALES", "₹${data['total_sales']}", Icons.trending_up, Colors.blue),
          const SizedBox(height: 12),
          _buildReportCard("TOTAL RECEIVED", "₹${data['total_received']}", Icons.payments_outlined, Colors.green),
          const SizedBox(height: 12),
          _buildReportCard("TOTAL DUES", "₹${data['total_dues']}", Icons.assignment_late_outlined, Colors.red),
          
          const SizedBox(height: 30),
          
          _buildExportButton(
            label: "EXPORT TO EXCEL (.XLSX)",
            icon: Icons.table_view,
            color: const Color(0xFF1D6F42), 
            onPressed: _exportToExcel,
          ),
          
          const SizedBox(height: 12),
          
          _buildExportButton(
            label: "EXPORT TO PDF (.PDF)",
            icon: Icons.picture_as_pdf,
            color: const Color(0xFFE91E63),
           onPressed: _exportToPdf, 
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 24, child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : onPressed,
        icon: _isExporting 
          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon, color: Colors.white, size: 20),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  // ===================== LOGIC METHODS =====================

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF00A36C))),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final detailedData = await _repo.getDetailedSalesReport(
        customerId: _selectedCustomer?.id,
        start: _dateRange.start,
        end: _dateRange.end,
      );

      if (detailedData.isEmpty) throw Exception("No sales found for this period");

      String fileNameSuffix = _selectedCustomer?.name.replaceAll(" ", "_") ?? "General";
      await ExcelService.exportSalesReport(
        salesData: detailedData,
        fileName: "Report_${fileNameSuffix}_${DateFormat('ddMMyy').format(DateTime.now())}",
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
