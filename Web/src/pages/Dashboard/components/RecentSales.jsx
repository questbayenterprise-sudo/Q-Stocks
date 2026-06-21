import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ReceiptText, ChevronRight } from 'lucide-react';

const RecentSales = ({ sales }) => {
  const navigate = useNavigate();

  return (
    <div className="bg-white p-8 rounded-[2.5rem] border border-slate-100 shadow-sm h-full flex flex-col">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h3 className="text-lg font-black text-slate-800">Recent Sales</h3>
          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Latest Transactions</p>
        </div>
        <button 
          onClick={() => navigate('/sales')} 
          className="text-xs font-bold text-q-green hover:underline flex items-center gap-1"
        >
          VIEW ALL <ChevronRight size={14} />
        </button>
      </div>

      <div className="space-y-4 flex-1 overflow-y-auto">
        {sales && sales.length > 0 ? (
          sales.map((sale) => (
            <div 
              key={sale.id} 
              className="flex items-center gap-4 rounded-2xl bg-slate-50 p-4 hover:bg-slate-100 transition-all cursor-pointer group border border-transparent hover:border-slate-200"
            >
              <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform">
                <ReceiptText size={18} className="text-slate-400 group-hover:text-q-green" />
              </div>
              
              <div className="flex-1">
                <p className="text-sm font-bold text-slate-800">Order #{sale.booking_ref}</p>
                <p className="text-[11px] text-slate-500 font-medium">{sale.user_name}</p>
              </div>
              
              <div className="text-right">
                <p className="font-black text-slate-900 text-sm">₹{sale.price}</p>
                <span className="text-[9px] font-black px-2 py-0.5 rounded-md bg-q-green/10 text-q-green uppercase tracking-tighter">
                  {sale.status}
                </span>
              </div>
            </div>
          ))
        ) : (
          <div className="flex flex-col items-center justify-center h-full py-10">
            <ReceiptText size={48} className="text-slate-100 mb-2" />
            <p className="text-sm font-bold text-slate-300 italic">No sales found today</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default RecentSales;