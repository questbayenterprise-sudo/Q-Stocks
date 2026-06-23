import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { IndianRupee, User, Search, ArrowRight, Loader2 } from 'lucide-react';
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
    <div className="min-h-screen bg-[#F8F9FA] p-6 lg:p-10">
      <div className="max-w-5xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-black text-slate-900">Pending Collections</h1>
          <div className="bg-red-50 px-6 py-3 rounded-2xl border border-red-100">
            <p className="text-[10px] font-black text-red-400 uppercase tracking-widest text-center">Total Dues</p>
            <p className="text-xl font-black text-red-600">₹{totalOutstanding.toLocaleString()}</p>
          </div>
        </div>

        <div className="relative mb-6">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
          <input 
            className="w-full pl-12 pr-4 py-4 bg-white border border-slate-200 rounded-2xl outline-none focus:ring-2 focus:ring-red-500/10 transition-all"
            placeholder="Search debtor name..."
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        {loading ? <div className="flex justify-center mt-20"><Loader2 className="animate-spin text-red-500" /></div> : (
          <div className="space-y-4">
            {filtered.map(item => (
              <div key={item.id} className="bg-white p-5 rounded-3xl border border-slate-100 shadow-sm flex items-center gap-4 hover:border-red-200 transition-all">
                <div className="w-12 h-12 rounded-2xl bg-red-50 flex items-center justify-center text-red-500 font-bold">
                  {item.name[0]}
                </div>
                <div className="flex-1">
                  <h3 className="font-bold text-slate-800">{item.name}</h3>
                  <p className="text-xs text-slate-400">{item.phone}</p>
                </div>
                <div className="text-right mr-4">
                  <p className="text-lg font-black text-red-600">₹{item.current_balance}</p>
                </div>
                <button 
                  onClick={() => navigate('/income-entry', { state: { customer: item } })}
                  className="bg-q-green text-white px-4 py-2 rounded-xl text-xs font-bold hover:bg-q-green-dark transition-all"
                >
                  COLLECT
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default PendingPayments;