import React, { useEffect, useState } from 'react';
import { 
  Warehouse, AlertTriangle, Edit3, Plus, 
  Loader2, Trash2, Search, X, CheckCircle2,
  Package, Store
} from 'lucide-react';
import { getStocks, updateStock } from '../../api/inventoryApi';
import { fetchShops } from '../../api/shopApi';
import { getProducts } from '../../api/productApi';

const StocksPage = () => {
  const [stocks, setStocks] = useState([]);
  const [shops, setShops] = useState([]);
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  
  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  // Form State
  const [formData, setFormData] = useState({ shop_id: '', product_id: '', quantity: '', min_level: '5' });

  const loadInitialData = async () => {
    setLoading(true);
    const user = JSON.parse(localStorage.getItem('user'));
    try {
      const [sData, shopData, pData] = await Promise.all([
        getStocks(),
        fetchShops(user.id, user.UserType),
        getProducts()
      ]);
      setStocks(sData);
      setShops(shopData);
      setProducts(pData);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadInitialData(); }, []);

  const openModal = (item = null) => {
    if (item) {
      setEditingItem(item);
      setFormData({
        shop_id: item.shop_id,
        product_id: item.product_id,
        quantity: item.current_qty,
        min_level: item.min_stock_lvl
      });
    } else {
      setEditingItem(null);
      setFormData({ shop_id: '', product_id: '', quantity: '', min_level: '5' });
    }
    setIsModalOpen(true);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await updateStock({
        shop_id: parseInt(formData.shop_id),
        product_id: parseInt(formData.product_id),
        quantity: parseFloat(formData.quantity),
        min_level: parseFloat(formData.min_level)
      });
      setIsModalOpen(false);
      loadInitialData();
    } catch (err) {
      alert("Failed to update stock");
    } finally {
      setSubmitting(false);
    }
  };

  const filteredStocks = stocks.filter(s => 
    s.product_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.shop_name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-app-bg p-4 md:p-10 transition-colors duration-300 relative">
      <div className="max-w-7xl mx-auto">
        
        {/* Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-10">
          <div>
            <h1 className="text-3xl font-black text-text-h tracking-tight">Inventory Management</h1>
            <p className="text-text-m font-medium">Monitor and adjust bird & egg stocks per branch.</p>
          </div>
          <button 
            onClick={() => openModal()}
            className="bg-q-green hover:bg-q-green-dark text-white px-8 py-4 rounded-2xl font-black shadow-lg shadow-q-green/20 transition-all flex items-center gap-2"
          >
            <Plus size={20} /> ADD PRODUCT TO SHOP
          </button>
        </div>

        {/* Search */}
        <div className="relative mb-8 max-w-md">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m" size={18} />
          <input 
            type="text"
            placeholder="Search products or shops..."
            className="w-full pl-12 pr-4 py-4 bg-card-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {loading ? (
          <div className="py-20 text-center"><Loader2 className="animate-spin text-q-green mx-auto" /></div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {filteredStocks.map(item => {
              const isLow = item.current_qty <= item.min_stock_lvl;
              return (
                <div key={item.id} className="bg-card-bg p-5 rounded-[2rem] border border-border-v shadow-sm flex items-center gap-6 group hover:shadow-md transition-all">
                  <div className={`p-4 rounded-2xl ${isLow ? 'bg-red-500/10 text-red-500' : 'bg-q-green/10 text-q-green'}`}>
                    <Package size={24} />
                  </div>
                  
                  <div className="flex-1">
                    <h3 className="font-black text-text-h leading-tight uppercase">{item.product_name}</h3>
                    <p className="text-text-m text-[10px] font-black uppercase tracking-widest mt-1">{item.shop_name}</p>
                    <div className="flex items-center gap-4 mt-3">
                       <div>
                          <p className="text-[9px] font-bold text-text-m uppercase opacity-60">Available</p>
                          <p className={`font-black text-xl ${isLow ? 'text-red-500' : 'text-text-h'}`}>
                            {item.current_qty} <span className="text-xs">{item.uom}</span>
                          </p>
                       </div>
                       {isLow && <div className="text-red-500 animate-pulse"><AlertTriangle size={16} /></div>}
                    </div>
                  </div>

                  <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-all">
                    <button onClick={() => openModal(item)} className="p-3 bg-app-bg rounded-xl text-blue-500 hover:bg-blue-50 transition-colors">
                      <Edit3 size={18} />
                    </button>
                    <button className="p-3 bg-app-bg rounded-xl text-red-400 hover:bg-red-50 transition-colors">
                      <Trash2 size={18} />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* --- ADD/EDIT MODAL --- */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-card-bg w-full max-w-md rounded-[2.5rem] p-8 shadow-2xl border border-border-v">
            <div className="flex justify-between items-center mb-8">
              <h2 className="text-xl font-black text-text-h">{editingItem ? 'Edit Stock' : 'Add Stock Record'}</h2>
              <button onClick={() => setIsModalOpen(false)} className="p-2 bg-app-bg rounded-full text-text-m"><X size={18}/></button>
            </div>

            <form onSubmit={handleSave} className="space-y-6">
              <div className="space-y-1">
                <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Select Shop</label>
                <select 
                  disabled={!!editingItem}
                  value={formData.shop_id}
                  onChange={(e) => setFormData({...formData, shop_id: e.target.value})}
                  className="w-full p-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none text-text-h font-bold appearance-none disabled:opacity-50"
                  required
                >
                  <option value="">Choose Branch</option>
                  {shops.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Product</label>
                <select 
                  disabled={!!editingItem}
                  value={formData.product_id}
                  onChange={(e) => setFormData({...formData, product_id: e.target.value})}
                  className="w-full p-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none text-text-h font-bold appearance-none disabled:opacity-50"
                  required
                >
                  <option value="">Choose Item</option>
                  {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Current Qty</label>
                  <input 
                    type="number" step="0.01" value={formData.quantity}
                    onChange={(e) => setFormData({...formData, quantity: e.target.value})}
                    className="w-full p-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none text-text-h font-black text-center"
                    required
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Alert At</label>
                  <input 
                    type="number" step="0.1" value={formData.min_level}
                    onChange={(e) => setFormData({...formData, min_level: e.target.value})}
                    className="w-full p-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none text-text-h font-black text-center"
                  />
                </div>
              </div>

              <button 
                type="submit" disabled={submitting}
                className="w-full bg-q-green text-white font-black py-5 rounded-3xl shadow-xl shadow-q-green/20 transition-all flex items-center justify-center gap-2 active:scale-95"
              >
                {submitting ? <Loader2 className="animate-spin" /> : <><CheckCircle2 size={20}/> UPDATE WAREHOUSE</>}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default StocksPage;