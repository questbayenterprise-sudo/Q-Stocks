import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, ReceiptText, Search, Plus, Calendar, ChevronRight } from 'lucide-react';
import { fetchSalesHistory } from '../../api/dashboardApi';

const SalesHistoryPage = () => {
  const navigate = useNavigate();
  const [sales, setSales] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user) return;
    fetchSalesHistory(user.id, user.userType_id).then(data => {
      setSales(data);
      setLoading(false);
    });
  }, []);

  const filteredSales = sales.filter(s => 
    s.booking_ref?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.user_name?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-[#F8F9FA] pb-20 relative">
      {/* Top Header */}
      <div className="bg-white border-b border-slate-100 sticky top-0 z-30">
        <div className="max-w-5xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button onClick={() => navigate(-1)} className="p-2 hover:bg-slate-50 rounded-full transition-colors">
              <ArrowLeft size={20} className="text-slate-600" />
            </button>
            <div>
              <h1 className="text-xl font-black text-slate-800 tracking-tight">Sales History</h1>
              <p className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em]">Transaction Logs</p>
            </div>
          </div>

          {/* DESKTOP ADD BUTTON */}
          <button 
            onClick={() => navigate('/sales/new')}
            className="hidden sm:flex items-center gap-2 bg-q-green hover:bg-q-green-dark text-white px-5 py-2.5 rounded-xl font-bold shadow-lg shadow-green-200 transition-all active:scale-95"
          >
            <Plus size={18} />
            <span>NEW SALE</span>
          </button>
        </div>
      </div>

      <div className="max-w-5xl mx-auto p-6">
        {/* Search & Filter Bar */}
        <div className="flex gap-3 mb-8">
          <div className="flex-1 relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-5 h-5" />
            <input 
              type="text"
              placeholder="Search Invoice or Customer..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-4 bg-white border border-slate-200 rounded-2xl outline-none focus:border-q-green shadow-sm font-medium"
            />
          </div>
          <button className="p-4 bg-white border border-slate-200 rounded-2xl text-slate-600 shadow-sm hover:bg-slate-50">
            <Calendar size={20} />
          </button>
        </div>

        {/* Sales List */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <div className="h-10 w-10 animate-spin rounded-full border-4 border-q-green border-t-transparent mb-4"></div>
            <p className="font-bold text-slate-400 uppercase tracking-widest text-xs">Loading logs...</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredSales.map((sale) => (
              <div key={sale.id} className="bg-white p-5 rounded-[1.5rem] border border-slate-100 shadow-sm flex items-center gap-4 group hover:shadow-md transition-all">
                <div className="w-12 h-12 rounded-2xl bg-slate-50 flex items-center justify-center text-slate-300 group-hover:bg-q-green/10 group-hover:text-q-green transition-colors">
                  <ReceiptText size={24} />
                </div>
                
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-black text-slate-800">INV #{sale.booking_ref}</span>
                    <span className={`text-[9px] font-black px-2 py-0.5 rounded-md uppercase ${
                      sale.status === 'CONFIRMED' || sale.status === 'COMPLETED' 
                        ? 'bg-emerald-50 text-emerald-600' 
                        : 'bg-orange-50 text-orange-600'
                    }`}>
                      {sale.status}
                    </span>
                  </div>
                  <p className="text-xs font-bold text-slate-500 mt-0.5">{sale.user_name || "Walk-in Customer"}</p>
                  <p className="text-[10px] text-slate-400 mt-1 font-medium">{sale.start_time}</p>
                </div>

                <div className="text-right">
                  <p className="text-lg font-black text-slate-900">₹{sale.price}</p>
                  <ChevronRight size={16} className="ml-auto text-slate-200 group-hover:text-q-green transition-colors" />
                </div>
              </div>
            ))}

            {filteredSales.length === 0 && (
              <div className="text-center py-20 bg-white rounded-[2rem] border-2 border-dashed border-slate-100">
                <p className="font-bold text-slate-300 uppercase tracking-widest">No matching records</p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* MOBILE FLOATING ACTION BUTTON (Visible only on small screens) */}
      <button 
        onClick={() => navigate('/sales/new')}
        className="fixed bottom-24 right-6 sm:hidden w-14 h-14 bg-q-green text-white rounded-full shadow-2xl flex items-center justify-center active:scale-90 transition-transform z-50"
      >
        <Plus size={28} />
      </button>
    </div>
  );
};

export default SalesHistoryPage;