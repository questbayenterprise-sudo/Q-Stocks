import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../../core/utils/excel_service.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../data/repositories/reports_repository.dart';
import 'package:go_router/go_router.dart';
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

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Customer Reports", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _repo.getCustomerWiseSummary(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final summary = snapshot.data!;

          return ListView.builder(
            itemCount: summary.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = summary[index];
              double pending = double.tryParse(data['pending_balance'].toString()) ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  onTap: () => context.push('/customers/${data['id']}'), // Navigate to Ledger
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
                      const Text("PENDING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                        "₹${pending.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 20, 
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
    );
  }

  Widget _smallStat(String label, String val, Color col) {
    return Text("$label: $val", style: TextStyle(color: col, fontSize: 13, fontWeight: FontWeight.w600));
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
        // FIXED: Added items with loadProps for v6 compatibility
        items: (filter, loadProps) => _customerRepo.fetchCustomers(),
        
        // FIXED: compareFn is REQUIRED for custom objects to avoid AssertionError
        compareFn: (CustomerModel item, CustomerModel selectedItem) => item.id == selectedItem.id,
        
        itemAsString: (CustomerModel? c) => c?.name ?? "",
        onChanged: (val) => setState(() => _selectedCustomer = val),
        
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Filter by Customer",
            hintText: "All Customers (General View)",
            prefixIcon: const Icon(Icons.person_search, color: Color(0xFF00A36C)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search customer name...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          emptyBuilder: (context, search) => const Center(child: Text("No customers found")),
        ),
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text("Financial Summary", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          
          _buildReportCard(
            "SALES AMOUNT", 
            "₹${NumberFormat('#,##,###.##').format(data['total_sales'] ?? 0)}", 
            Icons.trending_up, 
            Colors.blue
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            "COLLECTED CASH", 
            "₹${NumberFormat('#,##,###.##').format(data['total_received'] ?? 0)}", 
            Icons.payments_outlined, 
            Colors.green
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            "OUTSTANDING DUES", 
            "₹${NumberFormat('#,##,###.##').format(data['total_dues'] ?? 0)}", 
            Icons.assignment_late_outlined, 
            Colors.red
          ),
          
          const SizedBox(height: 40),
          
          const Center(
            child: Text(
              "Generate Statement",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildExportButton(
            label: "EXPORT TO EXCEL (.XLSX)",
            icon: Icons.table_view,
            color: const Color(0xFF1D6F42), // Excel Green
            onPressed: _exportToExcel,
          ),
          
          const SizedBox(height: 12),
          
          _buildExportButton(
            label: "EXPORT TO PDF (.PDF)",
            icon: Icons.picture_as_pdf,
            color: const Color(0xFFE91E63), // PDF Red
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("PDF statement generation feature coming soon!")),
              );
            },
          ),
          const SizedBox(height: 30),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : onPressed,
        icon: _isExporting 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon, color: Colors.white, size: 20),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A36C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final detailedData = await _repo.getDetailedSalesReport(
        customerId: _selectedCustomer?.id,
        start: _dateRange.start,
        end: _dateRange.end,
      );

      if (detailedData.isEmpty) {
        throw Exception("No data found for the selected period.");
      }

      String fileNameSuffix = _selectedCustomer?.name.replaceAll(" ", "_") ?? "General_Sales";
      String dateStr = DateFormat('ddMMyy').format(DateTime.now());
      
      await ExcelService.exportSalesReport(
        salesData: detailedData,
        fileName: "Report_${fileNameSuffix}_$dateStr",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Statement generated and ready to share!"), backgroundColor: Color(0xFF00A36C)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}