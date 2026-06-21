import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UserPlus, Search, Phone, ChevronRight, Loader2 } from 'lucide-react';
import { getCustomers } from '../../api/customerApi';

const CustomerListPage = () => {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    getCustomers().then(data => {
      setCustomers(data);
      setLoading(false);
    });
  }, []);

  const filtered = customers.filter(c => c.name.toLowerCase().includes(search.toLowerCase()));

  return (
    <div className="min-h-screen bg-[#F8F9FA] p-6 lg:p-10">
      <div className="max-w-5xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-black text-slate-900">Customer Ledger</h1>
          <button 
            onClick={() => navigate('/customers/add')}
            className="bg-q-green text-white px-6 py-3 rounded-2xl font-bold flex gap-2 items-center"
          >
            <UserPlus size={20} /> NEW CUSTOMER
          </button>
        </div>

        <div className="relative mb-6">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
          <input 
            className="w-full pl-12 pr-4 py-4 bg-white border border-slate-200 rounded-2xl outline-none focus:border-q-green transition-all"
            placeholder="Search customer name or phone..."
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        {loading ? <Loader2 className="animate-spin mx-auto mt-20 text-q-green" /> : (
          <div className="grid gap-4">
            {filtered.map(customer => (
              <div 
                key={customer.id} 
                onClick={() => navigate(`/customers/${customer.id}`)}
                className="bg-white p-5 rounded-3xl border border-slate-100 shadow-sm flex items-center gap-4 hover:shadow-md transition-all cursor-pointer group"
              >
                <div className="w-14 h-14 rounded-2xl bg-q-green/10 flex items-center justify-center text-q-green font-black text-xl">
                  {customer.name[0].toUpperCase()}
                </div>
                <div className="flex-1">
                  <h3 className="font-bold text-slate-800">{customer.name}</h3>
                  <div className="flex items-center gap-1 text-slate-400 text-xs mt-1">
                    <Phone size={12} /> {customer.phone || 'No phone'}
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Balance</p>
                  <p className={`font-black text-lg ${customer.current_balance > 0 ? 'text-red-500' : 'text-emerald-500'}`}>
                    ₹{customer.current_balance}
                  </p>
                </div>
                <ChevronRight className="text-slate-200 group-hover:text-q-green transition-colors" />
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default CustomerListPage;