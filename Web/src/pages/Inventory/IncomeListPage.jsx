import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  ArrowLeft, Wallet, Search, Plus, 
  Calendar, User, Trash2, Loader2, 
  ArrowDownCircle 
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
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const filteredIncomes = incomes.filter(inc => 
    inc.customer_name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalCollected = filteredIncomes.reduce((sum, item) => sum + item.amount, 0);

  return (
    <div className="min-h-screen bg-[#F8F9FA] pb-20">
      {/* Header */}
      <div className="bg-white border-b border-slate-100 sticky top-0 z-30">
        <div className="max-w-5xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button onClick={() => navigate('/home')} className="p-2 hover:bg-slate-50 rounded-full transition-colors">
              <ArrowLeft size={20} className="text-slate-600" />
            </button>
            <div>
              <h1 className="text-xl font-black text-slate-800 tracking-tight">Income Entries</h1>
              <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Collection History</p>
            </div>
          </div>

          <button 
            onClick={() => navigate('/income-entry/new')}
            className="flex items-center gap-2 bg-q-green hover:bg-q-green-dark text-white px-5 py-2.5 rounded-xl font-bold shadow-lg shadow-green-200 transition-all active:scale-95"
          >
            <Plus size={18} />
            <span className="hidden sm:inline">RECEIVE PAYMENT</span>
          </button>
        </div>
      </div>

      <div className="max-w-5xl mx-auto p-6">
        {/* Collection Summary Card */}
        <div className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-sm mb-8 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-emerald-50 rounded-2xl text-q-green">
              <ArrowDownCircle size={28} />
            </div>
            <div>
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Total Collected (Filtered)</p>
              <p className="text-2xl font-black text-slate-800">₹{totalCollected.toLocaleString()}</p>
            </div>
          </div>
          <div className="text-right hidden sm:block">
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Records</p>
            <p className="text-lg font-bold text-slate-600">{filteredIncomes.length}</p>
          </div>
        </div>

        {/* Search Bar */}
        <div className="relative mb-8">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-5 h-5" />
          <input 
            type="text"
            placeholder="Search customer name..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-12 pr-4 py-4 bg-white border border-slate-200 rounded-2xl outline-none focus:border-q-green shadow-sm font-medium"
          />
        </div>

        {/* List of Incomes */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="animate-spin text-q-green w-10 h-10 mb-4" />
            <p className="font-bold text-slate-400 uppercase text-xs tracking-widest">Fetching Collections...</p>
          </div>
        ) : filteredIncomes.length > 0 ? (
          <div className="space-y-4">
            {filteredIncomes.map((item) => (
              <div key={item.id} className="bg-white p-5 rounded-[1.5rem] border border-slate-100 shadow-sm flex items-center gap-4 group hover:border-q-green/30 transition-all">
                <div className="w-12 h-12 rounded-2xl bg-slate-50 flex items-center justify-center text-slate-300 group-hover:bg-q-green/10 group-hover:text-q-green transition-colors">
                  <Wallet size={24} />
                </div>
                
                <div className="flex-1">
                  <h3 className="text-sm font-black text-slate-800 uppercase tracking-tight">{item.customer_name}</h3>
                  <div className="flex items-center gap-3 mt-1">
                    <p className="text-[10px] font-bold text-slate-400 flex items-center gap-1">
                      <Calendar size={12} /> {new Date(item.transaction_date).toLocaleDateString()}
                    </p>
                    <p className="text-[10px] font-bold text-slate-400 italic">"{item.remarks}"</p>
                  </div>
                </div>

                <div className="text-right">
                  <p className="text-lg font-black text-emerald-600">₹{item.amount}</p>
                  <button className="p-2 text-slate-300 hover:text-red-500 transition-colors">
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-20 bg-white rounded-[2.5rem] border-2 border-dashed border-slate-100">
            <p className="font-bold text-slate-300 uppercase tracking-widest">No payment records found</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default IncomeListPage;