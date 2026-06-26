import React, { useEffect, useState } from 'react';
import { Warehouse, AlertTriangle, Edit3, Plus, Loader2 } from 'lucide-react';
import { getStocks, updateStock } from '../../api/inventoryApi';

const StocksPage = () => {
  const [stocks, setStocks] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await getStocks();
      setStocks(data);
    } catch (err) {
      console.error("Stock Sync Error:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData(); }, []);

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg p-4 md:p-8 lg:p-10 transition-colors duration-300">
      <div className="max-w-7xl mx-auto">
        
        {/* Header Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-10">
          <div>
            <h1 className="text-3xl font-black text-text-h tracking-tight leading-tight">
              Stock Inventory
            </h1>
            <p className="text-text-m font-medium mt-1">Live stock levels across all branches.</p>
          </div>
          
          <button className="bg-q-green hover:bg-q-green-dark text-white px-8 py-4 rounded-2xl font-black shadow-lg shadow-q-green/20 transition-all active:scale-95 flex items-center gap-2">
            <Plus size={20} />
            <span>ADD STOCK</span>
          </button>
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="animate-spin text-q-green w-10 h-10 mb-4" />
            <p className="text-text-m font-bold uppercase tracking-widest text-[10px]">Syncing Warehouse...</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {stocks.map(item => {
              const isLow = item.current_qty <= item.min_stock_lvl;
              
              return (
                <div 
                  key={item.id} 
                  // UNIFIED: bg-card-bg, border-border-v
                  // LOW STOCK Logic: Use subtle red opacity tint instead of solid colors
                  className={`bg-card-bg p-6 rounded-[2.5rem] border transition-all duration-300 shadow-sm hover:shadow-md 
                    ${isLow ? 'border-red-500/30 bg-red-500/[0.03]' : 'border-border-v'}`}
                >
                  <div className="flex justify-between items-start mb-6">
                    {/* Icon Container with dynamic tint */}
                    <div className={`p-4 rounded-2xl ${isLow ? 'bg-red-500/10 text-red-500' : 'bg-q-green/10 text-q-green'}`}>
                      <Warehouse size={28} strokeWidth={2.5} />
                    </div>

                    {isLow && (
                      <div className="flex items-center gap-1.5 text-red-500 font-black text-[9px] uppercase tracking-widest bg-card-bg px-3 py-1.5 rounded-full shadow-sm border border-red-500/20">
                        <AlertTriangle size={12} className="animate-pulse" /> Low Stock
                      </div>
                    )}
                  </div>
                  
                  {/* UNIFIED: text-text-h and text-text-m */}
                  <h3 className="font-black text-text-h text-xl tracking-tight leading-tight uppercase">
                    {item.product_name}
                  </h3>
                  <p className="text-text-m text-xs font-bold uppercase tracking-[0.15em] mt-1 italic opacity-70">
                    {item.shop_name}
                  </p>
                  
                  <div className="mt-8 pt-6 border-t border-border-v flex justify-between items-end">
                    <div>
                      <p className="text-[10px] font-black text-text-m uppercase tracking-widest mb-1">
                        Current Available
                      </p>
                      <p className={`text-3xl font-black tracking-tighter ${isLow ? 'text-red-500' : 'text-text-h'}`}>
                        {item.current_qty} 
                        <span className="text-sm text-text-m font-bold ml-1 uppercase">{item.uom}</span>
                      </p>
                    </div>

                    {/* UNIFIED: bg-app-bg for secondary buttons */}
                    <button className="p-4 bg-app-bg rounded-2xl text-text-m hover:text-q-green hover:bg-q-green/5 transition-all active:scale-90">
                      <Edit3 size={20} />
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