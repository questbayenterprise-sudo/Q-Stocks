import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, ReceiptText, Search, Plus, Calendar, ChevronRight, Loader2 } from 'lucide-react';
import { fetchSalesHistory } from '../../api/dashboardApi';

const SalesHistoryPage = () => {
  const navigate = useNavigate();
  const [sales, setSales] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    const userStr = localStorage.getItem('user');
    if (!userStr) {
      navigate('/');
      return;
    }
    const user = JSON.parse(userStr);
    
    fetchSalesHistory(user.id, user.userType_id).then(data => {
      setSales(data || []);
      setLoading(false);
    }).catch(err => {
      console.error("Sales History Sync Error:", err);
      setLoading(false);
    });
  }, [navigate]);

  const filteredSales = sales.filter(s => 
    s.booking_ref?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.user_name?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg pb-20 relative transition-colors duration-300">
      
      {/* Top Header - UNIFIED: bg-card-bg, border-border-v */}
      <div className="bg-card-bg border-b border-border-v sticky top-0 z-30 transition-colors duration-300">
        <div className="max-w-5xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => navigate(-1)} 
              className="p-2 bg-app-bg text-text-m hover:text-q-green rounded-full transition-all"
            >
              <ArrowLeft size={20} />
            </button>
            <div>
              <h1 className="text-xl font-black text-text-h tracking-tight leading-tight">Sales History</h1>
              <p className="text-[10px] font-bold text-text-m uppercase tracking-[0.2em]">Transaction Logs</p>
            </div>
          </div>

          {/* DESKTOP ADD BUTTON */}
          <button 
            onClick={() => navigate('/sales/new')}
            className="hidden sm:flex items-center gap-2 bg-q-green hover:bg-q-green-dark text-white px-5 py-2.5 rounded-xl font-black shadow-lg shadow-q-green/20 transition-all active:scale-95"
          >
            <Plus size={18} />
            <span>NEW SALE</span>
          </button>
        </div>
      </div>

      <div className="max-w-5xl mx-auto p-6">
        {/* Search & Filter Bar - UNIFIED: bg-card-bg, border-border-v */}
        <div className="flex gap-3 mb-8 group">
          <div className="flex-1 relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m group-focus-within:text-q-green transition-colors" size={18} />
            <input 
              type="text"
              placeholder="Search Invoice or Customer..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-4 bg-card-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green shadow-sm text-text-h font-medium transition-all placeholder:text-text-m/40"
            />
          </div>
          <button className="p-4 bg-card-bg border border-border-v rounded-2xl text-text-m shadow-sm hover:bg-app-bg transition-colors active:scale-95">
            <Calendar size={20} />
          </button>
        </div>

        {/* Content Area */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="animate-spin text-q-green w-10 h-10 mb-4" />
            <p className="font-black text-text-m uppercase tracking-[0.2em] text-[10px]">Fetching records...</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredSales.map((sale) => (
              <div 
                key={sale.id} 
                className="bg-card-bg p-5 rounded-[1.8rem] border border-border-v shadow-sm flex items-center gap-4 group hover:border-q-green/30 transition-all duration-300"
              >
                {/* Icon Box - UNIFIED: bg-app-bg */}
                <div className="w-12 h-12 rounded-2xl bg-app-bg flex items-center justify-center text-text-m group-hover:bg-q-green/10 group-hover:text-q-green transition-colors">
                  <ReceiptText size={24} strokeWidth={2.5} />
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-sm font-black text-text-h uppercase tracking-tight">INV #{sale.booking_ref}</span>
                    
                    {/* Status Badges - Opacity based for Dark Mode compatibility */}
                    <span className={`text-[9px] font-black px-2 py-0.5 rounded-md uppercase tracking-tighter ${
                      sale.status === 'CONFIRMED' || sale.status === 'COMPLETED' 
                        ? 'bg-emerald-500/10 text-emerald-500' 
                        : 'bg-orange-500/10 text-orange-500'
                    }`}>
                      {sale.status}
                    </span>
                  </div>
                  <p className="text-xs font-bold text-text-m mt-1 truncate">
                    {sale.user_name || "Walk-in Customer"}
                  </p>
                  <p className="text-[9px] text-text-m/60 mt-1 font-bold uppercase tracking-widest">{sale.start_time}</p>
                </div>

                <div className="text-right">
                  <p className="text-lg font-black text-text-h tracking-tighter">₹{sale.price}</p>
                  <div className="flex items-center justify-end gap-1 text-q-green font-bold text-[10px] mt-1 group-hover:translate-x-1 transition-transform">
                    DETAILS <ChevronRight size={12} />
                  </div>
                </div>
              </div>
            ))}

            {filteredSales.length === 0 && (
              <div className="text-center py-20 bg-card-bg rounded-[2.5rem] border-2 border-dashed border-border-v">
                <ReceiptText size={48} className="mx-auto text-text-m/20 mb-4" />
                <p className="font-bold text-text-m uppercase tracking-widest text-xs italic">No matching records</p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* MOBILE FLOATING ACTION BUTTON */}
      <button 
        onClick={() => navigate('/sales/new')}
        className="fixed bottom-24 right-6 sm:hidden w-14 h-14 bg-q-green text-white rounded-full shadow-2xl flex items-center justify-center active:scale-90 transition-all z-40 shadow-q-green/40 border-4 border-card-bg"
      >
        <Plus size={28} strokeWidth={3} />
      </button>
    </div>
  );
};

export default SalesHistoryPage;