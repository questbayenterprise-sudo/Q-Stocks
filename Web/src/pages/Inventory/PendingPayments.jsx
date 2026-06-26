import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { IndianRupee, User, Search, ArrowRight, Loader2, AlertCircle } from 'lucide-react';
import { getPendingPayments } from '../../api/inventoryApi';

const PendingPayments = () => {
  const [list, setList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    getPendingPayments().then(data => {
      setList(data);
      setLoading(false);
    });
  }, []);

  const totalOutstanding = list.reduce((sum, item) => sum + item.current_balance, 0);
  const filtered = list.filter(c => c.name.toLowerCase().includes(search.toLowerCase()));

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg p-4 md:p-8 lg:p-10 transition-colors duration-300">
      <div className="max-w-5xl mx-auto">
        
        {/* Header Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-10">
          <div>
            <h1 className="text-3xl font-black text-text-h tracking-tight leading-tight">
              Pending Collections
            </h1>
            <p className="text-text-m font-medium mt-1">Track and recover outstanding customer dues.</p>
          </div>
          
          {/* Summary Box - UNIFIED: bg-red-500/10 (Opacity based for theme compatibility) */}
          <div className="w-full md:w-auto bg-red-500/10 px-8 py-4 rounded-[2rem] border border-red-500/20 shadow-sm text-center md:text-right">
            <p className="text-[10px] font-black text-red-500 uppercase tracking-[0.2em]">Total Outstanding</p>
            <p className="text-3xl font-black text-red-500 mt-1">₹{totalOutstanding.toLocaleString()}</p>
          </div>
        </div>

        {/* Search Bar - UNIFIED: bg-card-bg, border-border-v */}
        <div className="relative mb-8 group">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m group-focus-within:text-q-green transition-colors" size={20} />
          <input 
            type="text"
            className="w-full pl-12 pr-4 py-4 bg-card-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green transition-all shadow-sm text-text-h font-medium placeholder:text-text-m/40"
            placeholder="Search customer name or phone..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        {/* Content Area */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="animate-spin text-red-500 w-10 h-10 mb-4" />
            <p className="text-text-m font-bold uppercase tracking-widest text-[10px]">Scanning Ledger...</p>
          </div>
        ) : filtered.length > 0 ? (
          <div className="space-y-4">
            {filtered.map(item => (
              <div 
                key={item.id} 
                // UNIFIED: bg-card-bg, border-border-v
                className="bg-card-bg p-5 rounded-[2rem] border border-border-v shadow-sm flex flex-wrap md:flex-nowrap items-center gap-4 hover:border-red-500/30 transition-all group"
              >
                {/* Avatar with dynamic red tint */}
                <div className="w-14 h-14 rounded-2xl bg-red-500/10 flex items-center justify-center text-red-500 font-black text-xl shadow-inner">
                  {item.name[0].toUpperCase()}
                </div>
                
                <div className="flex-1 min-w-[150px]">
                  <h3 className="font-black text-text-h text-lg leading-tight group-hover:text-red-500 transition-colors">
                    {item.name}
                  </h3>
                  <p className="text-xs font-bold text-text-m mt-1 uppercase tracking-tighter">
                    {item.phone || 'No phone recorded'}
                  </p>
                </div>

                <div className="text-right md:mr-6">
                  <p className="text-[10px] font-black text-text-m uppercase tracking-widest mb-1">Balance Due</p>
                  <p className="text-2xl font-black text-red-500">₹{item.current_balance.toLocaleString()}</p>
                </div>

                <button 
                  onClick={() => navigate('/income-entry', { state: { customer: item } })}
                  className="w-full md:w-auto bg-q-green hover:bg-q-green-dark text-white px-8 py-3 rounded-xl text-xs font-black tracking-widest shadow-lg shadow-q-green/20 active:scale-95 transition-all flex items-center justify-center gap-2"
                >
                  <ArrowRight size={16} />
                  COLLECT
                </button>
              </div>
            ))}
          </div>
        ) : (
          /* Empty State - UNIFIED: text-text-m */
          <div className="text-center py-20 bg-card-bg rounded-[3rem] border-2 border-dashed border-border-v">
            <AlertCircle size={48} className="mx-auto text-text-m/20 mb-4" />
            <h3 className="text-xl font-bold text-text-m opacity-50 uppercase tracking-widest">
              Zero Outstanding Dues
            </h3>
            <p className="text-text-m/40 text-sm mt-2 font-medium">Your accounts are currently settled.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default PendingPayments;