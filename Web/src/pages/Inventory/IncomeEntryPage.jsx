import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, HandCoins, User, Store, Loader2 } from 'lucide-react';
import { getCustomers } from '../../api/customerApi';
import { fetchShops } from '../../api/shopApi';
import { saveIncome } from '../../api/inventoryApi';

const IncomeEntryPage = () => {
  const navigate = useNavigate();
  const [customers, setCustomers] = useState([]);
  const [shops, setShops] = useState([]);
  const [loading, setLoading] = useState(false);

  const [selectedShop, setSelectedShop] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState('');
  const [amount, setAmount] = useState('');
  const [remarks, setRemarks] = useState('');

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user'));
    getCustomers().then(setCustomers);
    fetchShops(user.id, user.userType_id).then(setShops);
  }, []);

  const currentOutstanding = customers.find(c => c.id == selectedCustomer)?.current_balance || 0;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!selectedShop || !selectedCustomer || !amount) return;
    
    setLoading(true);
    try {
      await saveIncome({
        customer_id: parseInt(selectedCustomer),
        shop_id: parseInt(selectedShop),
        amount: parseFloat(amount),
        remarks: remarks || "Payment Received"
      });
      navigate('/reports'); // Go to reports to see updated dues
    } catch (err) {
      alert("Save failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-6">
      <div className="w-full max-w-xl bg-white rounded-[2.5rem] shadow-2xl p-10 border border-slate-100">
        <div className="flex items-center gap-4 mb-10">
           <button onClick={() => navigate(-1)} className="p-2 bg-slate-50 rounded-full"><ArrowLeft/></button>
           <h1 className="text-2xl font-black text-slate-800">Receive Payment</h1>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 gap-6">
            {/* Shop Selector */}
            <div className="space-y-2">
              <label className="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Shop Branch</label>
              <select 
                onChange={(e) => setSelectedShop(e.target.value)}
                className="w-full p-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green transition-all font-bold"
                required
              >
                <option value="">Select Shop</option>
                {shops.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>

            {/* Customer Selector */}
            <div className="space-y-2">
              <label className="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Customer</label>
              <select 
                onChange={(e) => setSelectedCustomer(e.target.value)}
                className="w-full p-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green transition-all font-bold"
                required
              >
                <option value="">Select Customer</option>
                {customers.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>

            {selectedCustomer && (
              <div className="p-6 bg-red-50 rounded-[1.5rem] border border-red-100 text-center">
                <p className="text-[10px] font-black text-red-400 uppercase tracking-widest">Outstanding Debt</p>
                <p className="text-3xl font-black text-red-600">₹{currentOutstanding}</p>
              </div>
            )}

            <div className="space-y-2">
              <label className="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Amount Received</label>
              <input 
                type="number" 
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="0.00"
                className="w-full p-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green font-black text-2xl text-q-green"
                required
              />
            </div>
          </div>

          <button 
            type="submit" 
            disabled={loading}
            className="w-full bg-q-green text-white font-black py-5 rounded-3xl shadow-xl shadow-green-200 transition-all flex justify-center items-center gap-2 active:scale-95"
          >
            {loading ? <Loader2 className="animate-spin" /> : <><HandCoins /> RECORD PAYMENT</>}
          </button>
        </form>
      </div>
    </div>
  );
};

export default IncomeEntryPage;