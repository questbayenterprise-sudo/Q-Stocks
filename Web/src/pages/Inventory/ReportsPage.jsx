import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  BarChart3, TrendingUp, Wallet, AlertCircle, 
  Search, FileSpreadsheet, FileText, 
  ChevronRight, Loader2, Calendar 
} from 'lucide-react';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import api from '../../api/axiosInstance';

const ReportsPage = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  // UPDATED: Initial state to match new Backend keys
  const [summary, setSummary] = useState({ 
    today_sales: 0, 
    weekly_sales: 0, 
    monthly_sales: 0, 
    total_stock: 0, 
    total_pending: 0 
  });
  const [customerSummary, setCustomerSummary] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');

  const user = JSON.parse(localStorage.getItem('user'));

  useEffect(() => {
    fetchReports();
  }, []);

  const fetchReports = async () => {
    setLoading(true);
    try {
      const analyticsRes = await api.post('/GetShopAnalytics', {
        user_id: user.id.toString(),
        user_type: user.userType_id
      });
      const customerRes = await api.get('/GetAllCustomers');
      setSummary(analyticsRes.data.data);
      setCustomerSummary(customerRes.data.data || []);
    } catch (err) {
      console.error("Report Sync Error:", err);
    } finally {
      setLoading(false);
    }
  };

  const exportToExcel = () => {
    // UPDATED: Include new sales data in Excel
    const dataToExport = customerSummary.map(c => ({
      "Customer Name": c.name,
      "Phone": c.phone,
      "Pending Balance": c.current_balance,
      "Status": c.current_balance > 0 ? "Owed" : "Settled"
    }));
    const worksheet = XLSX.utils.json_to_sheet(dataToExport);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Customer Dues");
    XLSX.writeFile(workbook, `Shop_Report_${new Date().toLocaleDateString()}.xlsx`);
  };

  const exportToPdf = () => {
    const doc = new jsPDF();
    doc.setFontSize(18);
    doc.text("Q-Stocks Business Report", 14, 22);
    doc.setFontSize(11);
    doc.setTextColor(100);
    doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 30);
    
    // UPDATED: PDF Financial Summary
    doc.text(`Today's Sales: Rs. ${summary.today_sales}`, 14, 38);
    doc.text(`Weekly Sales: Rs. ${summary.weekly_sales}`, 14, 46);
    doc.text(`Monthly Sales: Rs. ${summary.monthly_sales}`, 14, 54);
    doc.text(`Pending Dues: Rs. ${summary.total_pending}`, 14, 62);

    const tableColumn = ["Customer Name", "Phone", "Balance (Rs.)", "Status"];
    const tableRows = customerSummary.map(c => [
      c.name,
      c.phone || '---',
      c.current_balance.toFixed(2),
      c.current_balance > 0 ? "Owed" : "Settled"
    ]);

    autoTable(doc, {
      head: [tableColumn],
      body: tableRows,
      startY: 70, // Moved down to accommodate extra text
      theme: 'grid',
      headStyles: { fillColor: [0, 163, 108] },
      styles: { fontSize: 9 }
    });

    doc.save(`Shop_Report_${new Date().getTime()}.pdf`);
  };

  const filteredCustomers = customerSummary.filter(c => 
    c.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-app-bg p-4 md:p-8 lg:p-10 transition-colors duration-300">
      <div className="max-w-7xl mx-auto">
        
        {/* Header Section */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
          <div>
            <h1 className="text-3xl font-black text-text-h tracking-tight flex items-center gap-3">
              <BarChart3 className="text-q-green" size={32} /> Business Reports
            </h1>
            <p className="text-text-m font-medium">Financial insights and customer dues tracking.</p>
          </div>

          <div className="flex items-center gap-3">
            <button onClick={exportToExcel} className="flex items-center gap-2 bg-card-bg border border-border-v px-5 py-3 rounded-2xl font-bold text-text-h hover:bg-app-bg transition-all shadow-sm active:scale-95">
              <FileSpreadsheet size={18} className="text-green-600" />
              <span className="text-xs uppercase tracking-widest">Excel</span>
            </button>
            <button onClick={exportToPdf} className="flex items-center gap-2 bg-card-bg border border-border-v px-5 py-3 rounded-2xl font-bold text-text-h hover:bg-app-bg transition-all shadow-sm active:scale-95">
              <FileText size={18} className="text-red-500" />
              <span className="text-xs uppercase tracking-widest">PDF</span>
            </button>
          </div>
        </div>

        {/* UPDATED: Analytics Grid (5 Columns on Desktop) */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-10">
          <StatCard label="Today Sales" value={`₹${summary.today_sales}`} icon={<TrendingUp />} color="bg-emerald-500" />
          <StatCard label="Weekly Sales" value={`₹${summary.weekly_sales}`} icon={<Calendar />} color="bg-cyan-500" />
          <StatCard label="Monthly Sales" value={`₹${summary.monthly_sales}`} icon={<BarChart3 />} color="bg-indigo-500" />
          <StatCard label="Stock (kg)" value={`${summary.total_stock}`} icon={<Wallet />} color="bg-blue-500" />
          <StatCard label="Pending Dues" value={`₹${summary.total_pending}`} icon={<AlertCircle />} color="bg-red-500" />
        </div>

        {/* Customer Breakdown Section */}
        <div className="bg-card-bg rounded-[2.5rem] shadow-sm border border-border-v overflow-hidden transition-colors duration-300">
          <div className="p-8 border-b border-border-v flex flex-col md:flex-row md:items-center justify-between gap-4">
            <h3 className="text-lg font-black text-text-h uppercase tracking-tight">Customer Breakdown</h3>
            <div className="relative w-full md:w-80">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m w-4 h-4" />
              <input 
                type="text"
                placeholder="Search customer..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-3 bg-app-bg border-none rounded-xl outline-none focus:ring-2 focus:ring-q-green/20 font-medium text-sm text-text-h"
              />
            </div>
          </div>

          <div className="overflow-x-auto">
            {loading ? (
              <div className="py-20 flex justify-center"><Loader2 className="animate-spin text-q-green" /></div>
            ) : (
              <table className="w-full text-left">
                <thead className="bg-app-bg text-[10px] font-black text-text-m uppercase tracking-[0.2em]">
                  <tr>
                    <th className="px-8 py-4">Customer Name</th>
                    <th className="px-8 py-4">Phone</th>
                    <th className="px-8 py-4 text-right">Balance</th>
                    <th className="px-8 py-4"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-v">
                  {filteredCustomers.map(customer => (
                    <tr 
                      key={customer.id} 
                      onClick={() => navigate(`/customers/${customer.id}`)}
                      className="hover:bg-app-bg/50 transition-colors cursor-pointer group"
                    >
                      <td className="px-8 py-5 font-bold text-text-h">{customer.name}</td>
                      <td className="px-8 py-5 text-text-m text-sm">{customer.phone || '---'}</td>
                      <td className={`px-8 py-5 text-right font-black ${customer.current_balance > 0 ? 'text-red-500' : 'text-emerald-500'}`}>
                        ₹{customer.current_balance.toLocaleString()}
                      </td>
                      <td className="px-8 py-5 text-right">
                        <ChevronRight size={18} className="ml-auto text-border-v group-hover:text-q-green transition-colors" />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

const StatCard = ({ label, value, icon, color }) => (
  <div className="bg-card-bg p-6 rounded-[2rem] shadow-sm border border-border-v flex items-center gap-4 transition-colors duration-300">
    <div className={`w-12 h-12 rounded-2xl ${color} text-white flex items-center justify-center shadow-lg`}>
      {React.cloneElement(icon, { size: 22 })}
    </div>
    <div>
      <p className="text-[9px] font-black text-text-m uppercase tracking-widest mb-1">{label}</p>
      <p className="text-xl font-black text-text-h">{value}</p>
    </div>
  </div>
);

export default ReportsPage;