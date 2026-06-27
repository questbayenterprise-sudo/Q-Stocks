import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, HandCoins, User, Store, Loader2, CheckCircle2, MessageSquare } from 'lucide-react';
import { getCustomers } from '../../api/customerApi';
import { fetchShops } from '../../api/shopApi';
import { saveIncome } from '../../api/inventoryApi';

const IncomeEntryPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const preSelected = location.state?.customer;

  const [customers, setCustomers] = useState([]);
  const [shops, setShops] = useState([]);
  const [loading, setLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  const [form, setForm] = useState({
    customer_id: preSelected?.id || '',
    shop_id: '',
    amount: '',
    remarks: ''
  });

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user) {
      navigate('/');
      return;
    }
    
    // Load parallel data
    Promise.all([getCustomers(), fetchShops(user.id, user.UserType)])
      .then(([customerData, shopData]) => {
        setCustomers(customerData);
        setShops(shopData);
      })
      .catch(err => console.error("Error loading form data", err));
  }, [navigate, user.id, user.userType_id]);

  const currentOutstanding = customers.find(c => c.id == form.customer_id)?.current_balance || 0;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.shop_id || !form.customer_id || !form.amount) return;
    
    setLoading(true);
    try {
      await saveIncome({
        customer_id: parseInt(form.customer_id),
        shop_id: parseInt(form.shop_id),
        amount: parseFloat(form.amount),
        remarks: form.remarks || "Payment Received"
      });
      
      setIsSuccess(true);
      // Wait for user to see success state before redirecting
      setTimeout(() => navigate('/inventory/pending'), 1500);
    } catch (err) {
      alert("Failed to save income entry. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg flex items-center justify-center p-4 md:p-10 transition-colors duration-300">
      
      {/* UNIFIED: bg-card-bg, border-border-v */}
      <div className="w-full max-w-xl bg-card-bg rounded-[2.5rem] shadow-2xl shadow-slate-900/5 p-6 md:p-10 border border-border-v relative overflow-hidden">
        
        {/* Success Overlay */}
        {isSuccess && (
          <div className="absolute inset-0 bg-card-bg/95 z-20 flex flex-col items-center justify-center p-8 text-center animate-in fade-in duration-500">
            <div className="w-20 h-20 bg-q-green/10 rounded-full flex items-center justify-center mb-4">
              <CheckCircle2 className="w-12 h-12 text-q-green animate-bounce" />
            </div>
            <h2 className="text-2xl font-black text-text-h">Payment Recorded</h2>
            <p className="text-text-m mt-2">Customer balance has been updated.</p>
          </div>
        )}

        <div className="flex items-center gap-4 mb-10">
           <button 
             onClick={() => navigate(-1)} 
             className="p-2 bg-app-bg text-text-m hover:text-q-green rounded-full transition-all"
           >
             <ArrowLeft size={20}/>
           </button>
           <h1 className="text-2xl font-black text-text-h tracking-tight">Receive Payment</h1>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-6">
            
            {/* Shop Selector */}
            <div className="space-y-2">
              <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Shop Branch</label>
              <div className="relative">
                <Store className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m" size={18} />
                <select 
                  value={form.shop_id}
                  onChange={(e) => setForm({...form, shop_id: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-bold transition-all appearance-none"
                  required
                >
                  <option value="">Select Shop</option>
                  {shops.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </div>
            </div>

            {/* Customer Selector */}
            <div className="space-y-2">
              <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Customer</label>
              <div className="relative">
                <User className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m" size={18} />
                <select 
                  value={form.customer_id}
                  onChange={(e) => setForm({...form, customer_id: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-bold transition-all appearance-none"
                  required
                >
                  <option value="">Select Customer</option>
                  {customers.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
            </div>

            {/* Outstanding Display (Optimized for Dark Mode) */}
            {form.customer_id && (
              <div className="p-6 bg-red-500/10 rounded-[2rem] border border-red-500/20 text-center animate-in zoom-in-95">
                <p className="text-[10px] font-black text-red-500 uppercase tracking-widest">Currently Owed</p>
                <p className="text-4xl font-black text-red-500 mt-1">₹{currentOutstanding.toLocaleString()}</p>
              </div>
            )}

            {/* Amount Input */}
            <div className="space-y-2">
              <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Amount Received</label>
              <input 
                type="number" 
                value={form.amount}
                onChange={(e) => setForm({...form, amount: e.target.value})}
                placeholder="0.00"
                className="w-full p-5 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green font-black text-3xl text-q-green placeholder:text-text-m/30 text-center"
                required
              />
            </div>

            {/* Remarks Input */}
            <div className="space-y-2">
              <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Remarks</label>
              <div className="relative">
                <MessageSquare className="absolute left-4 top-4 text-text-m" size={18} />
                <textarea 
                  value={form.remarks}
                  onChange={(e) => setForm({...form, remarks: e.target.value})}
                  placeholder="e.g. Received via G-Pay"
                  className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-medium resize-none h-24"
                />
              </div>
            </div>
          </div>

          {/* Action Button */}
          <button 
            type="submit" 
            disabled={loading || isSuccess}
            className="w-full bg-q-green hover:bg-q-green-dark disabled:bg-slate-300 disabled:cursor-not-allowed text-white font-black py-5 rounded-[1.5rem] shadow-xl shadow-q-green/20 transition-all flex justify-center items-center gap-3 active:scale-95"
          >
            {loading ? (
              <Loader2 className="animate-spin w-6 h-6" />
            ) : (
              <>
                <HandCoins size={22} />
                CONFIRM COLLECTION
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

export default IncomeEntryPage;