import React, { useState, useEffect } from 'react';
import { 
  BarChart3, TrendingUp, Wallet, AlertCircle, 
  Search, Calendar, FileSpreadsheet, FileText, 
  ChevronRight, Loader2 
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import * as XLSX from 'xlsx'; // Import Excel Library
import api from '../../api/axiosInstance';

const ReportsPage = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [summary, setSummary] = useState({ total_revenue: 0, total_bookings: 0, occupancy: 0 });
  const [customerSummary, setCustomerSummary] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');

  const user = JSON.parse(localStorage.getItem('user'));

  useEffect(() => {
    fetchReports();
  }, []);

  const fetchReports = async () => {
    setLoading(true);
    try {
      // 1. Fetch Global Analytics (Matches bal.GetShopAnalytics)
      const analyticsRes = await api.post('/GetShopAnalytics', {
        user_id: user.id.toString(),
        user_type: user.userType_id
      });

      // 2. Fetch Customer-wise Summary (We can reuse the GetAllCustomers logic)
      const customerRes = await api.get('/GetAllCustomers');

      setSummary(analyticsRes.data.data);
      setCustomerSummary(customerRes.data.data || []);
    } catch (err) {
      console.error("Report Sync Error:", err);
    } finally {
      setLoading(false);
    }
  };

  // --- EXCEL EXPORT LOGIC ---
  const exportToExcel = () => {
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

  const filteredCustomers = customerSummary.filter(c => 
    c.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-[#F8F9FA] p-6 lg:p-10">
      <div className="max-w-7xl mx-auto">
        
        {/* Header & Export Actions */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
          <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
              <BarChart3 className="text-q-green" size={32} /> Business Reports
            </h1>
            <p className="text-slate-500 font-medium">Financial insights and customer dues tracking.</p>
          </div>

          <div className="flex items-center gap-3">
            <button 
              onClick={exportToExcel}
              className="flex items-center gap-2 bg-white border border-slate-200 px-5 py-3 rounded-2xl font-bold text-slate-700 hover:bg-slate-50 transition-all shadow-sm"
            >
              <FileSpreadsheet size={18} className="text-green-600" />
              <span>EXCEL</span>
            </button>
            <button className="flex items-center gap-2 bg-white border border-slate-200 px-5 py-3 rounded-2xl font-bold text-slate-700 hover:bg-slate-50 transition-all shadow-sm">
              <FileText size={18} className="text-red-500" />
              <span>PDF</span>
            </button>
          </div>
        </div>

        {/* Analytics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
          <StatCard 
            label="Total Sales" 
            value={`₹${summary.total_revenue}`} 
            icon={<TrendingUp />} 
            color="bg-emerald-500" 
          />
          <StatCard 
            label="Stock Weight" 
            value={`${summary.total_bookings} kg`} 
            icon={<Wallet />} 
            color="bg-blue-500" 
          />
          <StatCard 
            label="Pending Dues" 
            value={`₹${summary.occupancy}`} 
            icon={<AlertCircle />} 
            color="bg-red-500" 
          />
        </div>

        {/* Customer Breakdown Section */}
        <div className="bg-white rounded-[2.5rem] shadow-sm border border-slate-100 overflow-hidden">
          <div className="p-8 border-b border-slate-50 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <h3 className="text-lg font-black text-slate-800 uppercase tracking-tight">Customer Breakdown</h3>
            <div className="relative w-full md:w-80">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 w-4 h-4" />
              <input 
                type="text"
                placeholder="Search customer..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-3 bg-slate-50 border-none rounded-xl outline-none focus:ring-2 focus:ring-q-green/20 font-medium text-sm"
              />
            </div>
          </div>

          <div className="overflow-x-auto">
            {loading ? (
              <div className="py-20 flex justify-center"><Loader2 className="animate-spin text-q-green" /></div>
            ) : (
              <table className="w-full text-left">
                <thead className="bg-slate-50 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">
                  <tr>
                    <th className="px-8 py-4">Customer Name</th>
                    <th className="px-8 py-4">Phone</th>
                    <th className="px-8 py-4 text-right">Balance</th>
                    <th className="px-8 py-4"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-50">
                  {filteredCustomers.map(customer => (
                    <tr 
                      key={customer.id} 
                      onClick={() => navigate(`/customers/${customer.id}`)}
                      className="hover:bg-slate-50/80 transition-colors cursor-pointer group"
                    >
                      <td className="px-8 py-5 font-bold text-slate-700">{customer.name}</td>
                      <td className="px-8 py-5 text-slate-400 text-sm">{customer.phone || '---'}</td>
                      <td className={`px-8 py-5 text-right font-black ${customer.current_balance > 0 ? 'text-red-500' : 'text-emerald-500'}`}>
                        ₹{customer.current_balance}
                      </td>
                      <td className="px-8 py-5 text-right">
                        <ChevronRight size={18} className="ml-auto text-slate-200 group-hover:text-q-green transition-colors" />
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

// Internal Sub-component for Stats
const StatCard = ({ label, value, icon, color }) => (
  <div className="bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100 flex items-center gap-6">
    <div className={`w-14 h-14 rounded-2xl ${color} text-white flex items-center justify-center shadow-lg shadow-slate-100`}>
      {React.cloneElement(icon, { size: 28 })}
    </div>
    <div>
      <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{label}</p>
      <p className="text-2xl font-black text-slate-800 mt-1">{value}</p>
    </div>
  </div>
);

export default ReportsPage;