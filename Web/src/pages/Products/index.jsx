import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Search, ShoppingBag, Loader2, Edit2, Trash2 } from 'lucide-react';
import { getProducts, deleteProduct } from '../../api/productApi';

const ProductListPage = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const navigate = useNavigate();

  const loadData = async () => {
    setLoading(true);
    const data = await getProducts();
    setProducts(data);
    setLoading(false);
  };

  useEffect(() => { loadData(); }, []);

  const handleDelete = async (id) => {
    if (window.confirm("Remove this product?")) {
      await deleteProduct(id);
      loadData();
    }
  };

  const filtered = products.filter(p => p.name.toLowerCase().includes(searchQuery.toLowerCase()));

  return (
    <div className="min-h-screen bg-[#F8F9FA] p-6 lg:p-10">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-10">
          <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight">Product Catalog</h1>
            <p className="text-slate-500 font-medium">Manage chicken items, eggs, and masala inventory.</p>
          </div>
          <button 
            onClick={() => navigate('/products/add')}
            className="flex items-center gap-2 bg-q-green hover:bg-q-green-dark text-white px-8 py-4 rounded-2xl font-black shadow-lg shadow-green-200 transition-all"
          >
            <Plus size={20} /> ADD NEW ITEM
          </button>
        </div>

        {/* Search */}
        <div className="relative mb-8">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
          <input 
            type="text"
            placeholder="Search products..."
            className="w-full pl-12 pr-4 py-4 bg-white border border-slate-200 rounded-2xl outline-none focus:border-q-green transition-all shadow-sm"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {loading ? (
          <div className="flex justify-center py-20"><Loader2 className="animate-spin text-q-green" size={40} /></div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {filtered.map(p => (
              <div key={p.id} className="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-md transition-all group relative">
                <div className="w-full h-40 bg-slate-50 rounded-2xl flex items-center justify-center mb-4 overflow-hidden">
                   {p.image_url ? <img src={`${import.meta.env.VITE_API_BASE_URL}/${p.image_url}`} className="w-full h-full object-cover" /> : <ShoppingBag size={48} className="text-slate-200" />}
                </div>
                <h3 className="font-bold text-slate-800 text-lg">{p.name}</h3>
                <p className="text-q-green font-black text-xl mt-1">₹{p.base_price} <span className="text-xs text-slate-400 font-bold uppercase">/ {p.uom}</span></p>
                
                <div className="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => navigate(`/products/edit/${p.id}`, { state: { product: p } })} className="p-2 bg-white shadow-md rounded-xl text-blue-500 hover:bg-blue-50"><Edit2 size={16} /></button>
                  <button onClick={() => handleDelete(p.id)} className="p-2 bg-white shadow-md rounded-xl text-red-500 hover:bg-red-50"><Trash2 size={16} /></button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default ProductListPage;