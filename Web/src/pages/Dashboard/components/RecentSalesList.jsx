import React from 'react';
import { ReceiptText, ChevronRight } from 'lucide-react';

const RecentSalesList = ({ sales }) => {
  return (
    <div className="rounded-[2rem] bg-white p-6 shadow-sm border border-slate-100">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-lg font-bold text-slate-800">Recent Sales</h3>
        <button className="text-sm font-bold text-q-green hover:underline">View All</button>
      </div>
      
      <div className="space-y-4">
        {sales.map((sale) => (
          <div key={sale.id} className="flex items-center gap-4 rounded-2xl bg-slate-50 p-4 transition-colors hover:bg-slate-100 cursor-pointer">
            <div className="rounded-full bg-white p-2 shadow-sm">
              <ReceiptText className="h-5 w-5 text-slate-400" />
            </div>
            <div className="flex-1">
              <p className="text-sm font-bold text-slate-800">Order #{sale.orderRef}</p>
              <p className="text-xs text-slate-500">{sale.customerName}</p>
            </div>
            <p className="font-black text-q-green">₹{sale.amount}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RecentSalesList;