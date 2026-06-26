import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  ArrowLeft, Wallet, Search, Plus, 
  Calendar, Trash2, Loader2, 
  ArrowDownCircle, ChevronRight
} from 'lucide-react';
import { getIncomeHistory } from '../../api/inventoryApi';

const IncomeListPage = () => {
  const navigate = useNavigate();
  const [incomes, setIncomes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    loadIncomes();
  }, []);

  const loadIncomes = async () => {
    setLoading(true);
    try {
      const data = await getIncomeHistory();
      setIncomes(data);
    } catch (err) {
      console.error("Failed to fetch income history:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm("Delete this payment record? The customer's balance will increase accordingly.")) {
      // In production: await deleteIncome(id);
      // loadIncomes();
      alert("Delete logic triggered for ID: " + id);
    }
  };

  const filteredIncomes = incomes.filter(inc => 
    inc.customer_name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalCollected = filteredIncomes.reduce((sum, item) => sum + item.amount, 0);

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg pb-20 transition-colors duration-300">
      
      {/* Header Bar - UNIFIED: bg-card-bg, border-border-v */}
      <div className="bg-card-bg border-b border-border-v sticky top-0 z-30 transition-colors duration-300">
        <div className="max-w-5xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => navigate('/home')} 
              className="p-2 bg-app-bg text-text-m hover:text-q-green rounded-full transition-all"
            >
              <ArrowLeft size={20} />
            </button>
            <div>
              <h1 className="text-xl font-black text-text-h tracking-tight leading-tight">Income Entries</h1>
              <p className="text-[10px] font-bold text-text-m uppercase tracking-widest">Collection History</p>
            </div>
          </div>

          <button 
            onClick={() => navigate('/income-entry/new')}
            className="flex items-center gap-2 bg-q-green hover:bg-q-green-dark text-white px-5 py-2.5 rounded-xl font-bold shadow-lg shadow-q-green/20 transition-all active:scale-95"
          >
            <Plus size={18} />
            <span className="hidden sm:inline uppercase text-xs tracking-tighter">Receive Payment</span>
          </button>
        </div>
      </div>

      <div className="max-w-5xl mx-auto p-6">
        
        {/* Collection Summary Card - UNIFIED: bg-card-bg */}
        <div className="bg-card-bg p-6 rounded-[2rem] border border-border-v shadow-sm mb-8 flex items-center justify-between transition-colors duration-300">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-q-green/10 rounded-2xl text-q-green">
              <ArrowDownCircle size={28} />
            </div>
            <div>
              <p className="text-[10px] font-black text-text-m uppercase tracking-widest">Period Collections</p>
              <p className="text-2xl font-black text-text-h">₹{totalCollected.toLocaleString()}</p>
            </div>
          </div>
          <div className="text-right hidden sm:block">
            <p className="text-[10px] font-black text-text-m uppercase tracking-widest">Total Logs</p>
            <p className="text-lg font-bold text-text-h">{filteredIncomes.length}</p>
          </div>
        </div>

        {/* Search Bar - UNIFIED: bg-card-bg, border-border-v */}
        <div className="relative mb-8">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m" size={18} />
          <input 
            type="text"
            placeholder="Search customer name..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-12 pr-4 py-4 bg-card-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-medium transition-all shadow-sm placeholder:text-text-m/40"
          />
        </div>

        {/* List of Incomes */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="animate-spin text-q-green w-10 h-10 mb-4" />
            <p className="font-bold text-text-m uppercase text-[10px] tracking-[0.2em]">Syncing History...</p>
          </div>
        ) : filteredIncomes.length > 0 ? (
          <div className="space-y-4">
            {filteredIncomes.map((item) => (
              <div 
                key={item.id} 
                className="bg-card-bg p-5 rounded-[1.8rem] border border-border-v shadow-sm flex items-center gap-4 group hover:border-q-green/30 transition-all duration-300"
              >
                {/* Avatar Circle - UNIFIED: bg-app-bg */}
                <div className="w-12 h-12 rounded-2xl bg-app-bg flex items-center justify-center text-text-m group-hover:bg-q-green/10 group-hover:text-q-green transition-colors">
                  <Wallet size={22} />
                </div>
                
                <div className="flex-1">
                  <h3 className="text-sm font-black text-text-h uppercase tracking-tight">{item.customer_name}</h3>
                  <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1">
                    <p className="text-[10px] font-bold text-text-m flex items-center gap-1">
                      <Calendar size={12} /> {new Date(item.transaction_date).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' })}
                    </p>
                    {item.remarks && (
                      <p className="text-[10px] font-medium text-text-m italic border-l border-border-v pl-3">
                        {item.remarks}
                      </p>
                    )}
                  </div>
                </div>

                <div className="text-right flex items-center gap-4">
                  <div>
                    <p className="text-lg font-black text-emerald-500">₹{item.amount}</p>
                    <p className="text-[9px] font-black text-text-m uppercase tracking-tighter">Received</p>
                  </div>
                  <button 
                    onClick={() => handleDelete(item.id)}
                    className="p-2 text-text-m hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950/20 rounded-xl transition-all"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          /* Empty State - UNIFIED: border-border-v, text-text-m */
          <div className="text-center py-20 bg-card-bg rounded-[2.5rem] border-2 border-dashed border-border-v transition-colors duration-300">
            <p className="font-bold text-text-m uppercase tracking-widest text-xs italic">No collection records found</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default IncomeListPage;