import React, { useEffect, useState } from 'react';
import { Warehouse, AlertTriangle, Edit3, Plus, Loader2 } from 'lucide-react';
import { getStocks, updateStock } from '../../api/inventoryApi';

const StocksPage = () => {
  const [stocks, setStocks] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    const data = await getStocks();
    setStocks(data);
    setLoading(false);
  };

  useEffect(() => { loadData(); }, []);

  return (
    <div className="min-h-screen bg-[#F8F9FA] p-6 lg:p-10">
      <div className="max-w-7xl mx-auto">
        <div className="flex justify-between items-center mb-10">
          <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight">Stock Inventory</h1>
            <p className="text-slate-500 font-medium">Live stock levels across all branches.</p>
          </div>
          <button className="bg-q-green text-white px-6 py-3 rounded-2xl font-bold flex gap-2 items-center shadow-lg shadow-green-100">
            <Plus size={20} /> ADD STOCK
          </button>
        </div>

        {loading ? <Loader2 className="animate-spin mx-auto mt-20 text-q-green" /> : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {stocks.map(item => {
              const isLow = item.current_qty <= item.min_stock_lvl;
              return (
                <div key={item.id} className={`bg-white p-6 rounded-[2rem] border ${isLow ? 'border-red-100 bg-red-50/30' : 'border-slate-100'} shadow-sm`}>
                  <div className="flex justify-between items-start mb-4">
                    <div className={`p-3 rounded-2xl ${isLow ? 'bg-red-100 text-red-600' : 'bg-q-green/10 text-q-green'}`}>
                      <Warehouse size={24} />
                    </div>
                    {isLow && (
                      <div className="flex items-center gap-1 text-red-500 font-black text-[10px] uppercase tracking-tighter bg-white px-2 py-1 rounded-lg shadow-sm border border-red-50">
                        <AlertTriangle size={12} /> Low Stock
                      </div>
                    )}
                  </div>
                  
                  <h3 className="font-bold text-slate-800 text-lg">{item.product_name}</h3>
                  <p className="text-slate-400 text-xs font-bold uppercase tracking-widest">{item.shop_name}</p>
                  
                  <div className="mt-6 flex justify-between items-end">
                    <div>
                      <p className="text-[10px] font-bold text-slate-400 uppercase">Available</p>
                      <p className={`text-2xl font-black ${isLow ? 'text-red-600' : 'text-slate-800'}`}>
                        {item.current_qty} <span className="text-sm text-slate-400 font-bold">{item.uom}</span>
                      </p>
                    </div>
                    <button className="p-3 bg-slate-50 rounded-xl text-slate-400 hover:text-q-green transition-colors">
                      <Edit3 size={18} />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default StocksPage;