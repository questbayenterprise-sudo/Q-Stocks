import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Search, ShoppingBag, Loader2, Edit2, Trash2, PackageSearch } from 'lucide-react';
import { getProducts, deleteProduct } from '../../api/productApi';

const ProductListPage = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const navigate = useNavigate();

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await getProducts();
      setProducts(data);
    } catch (err) {
      console.error("Failed to load products:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData(); }, []);

  const handleDelete = async (id) => {
    if (window.confirm("Remove this product from catalog?")) {
      await deleteProduct(id);
      loadData();
    }
  };

  const filtered = products.filter(p => p.name.toLowerCase().includes(searchQuery.toLowerCase()));

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg p-4 md:p-8 lg:p-10 transition-colors duration-300">
      <div className="max-w-7xl mx-auto">
        
        {/* Header Section */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
          <div>
            <h1 className="text-3xl font-black text-text-h tracking-tight leading-tight">
              Product Catalog
            </h1>
            <p className="text-text-m font-medium mt-1">Manage chicken items, eggs, and masala inventory.</p>
          </div>
          
          <button 
            onClick={() => navigate('/products/add')}
            className="flex items-center gap-2 bg-q-green hover:bg-q-green-dark text-white px-8 py-4 rounded-2xl font-black shadow-lg shadow-q-green/20 transition-all active:scale-95"
          >
            <Plus size={20} />
            <span>ADD NEW ITEM</span>
          </button>
        </div>

        {/* Search Bar - UNIFIED: bg-card-bg, border-border-v */}
        <div className="relative mb-10 group">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m group-focus-within:text-q-green transition-colors" size={20} />
          <input 
            type="text"
            placeholder="Search by product name..."
            className="w-full pl-12 pr-4 py-4 bg-card-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green transition-all shadow-sm text-text-h font-medium placeholder:text-text-m/40"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="animate-spin text-q-green w-10 h-10 mb-4" />
            <p className="text-text-m font-bold uppercase tracking-widest text-[10px]">Syncing Catalog...</p>
          </div>
        ) : (
          <>
            {filtered.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {filtered.map(p => (
                  <div 
                    key={p.id} 
                    // UNIFIED: bg-card-bg, border-border-v
                    className="bg-card-bg rounded-[2.5rem] p-6 border border-border-v shadow-sm hover:shadow-md transition-all group relative overflow-hidden"
                  >
                    {/* Image Container - UNIFIED: bg-app-bg */}
                    <div className="w-full h-44 bg-app-bg rounded-3xl flex items-center justify-center mb-5 overflow-hidden border border-border-v">
                       {p.image_url ? (
                         <img 
                           src={`${import.meta.env.VITE_API_BASE_URL}/${p.image_url.replace(/\\/g, '/')}`} 
                           className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" 
                           alt={p.name}
                         />
                       ) : (
                         <ShoppingBag size={48} className="text-text-m opacity-20" />
                       )}
                    </div>

                    <h3 className="font-black text-text-h text-lg uppercase tracking-tight leading-tight">
                      {p.name}
                    </h3>
                    
                    <div className="mt-2 flex items-baseline gap-1">
                      <span className="text-q-green font-black text-2xl tracking-tighter">₹{p.base_price}</span>
                      <span className="text-[10px] text-text-m font-bold uppercase tracking-widest">/ {p.uom}</span>
                    </div>
                    
                    {/* Floating Action Buttons */}
                    <div className="absolute top-4 right-4 flex flex-col gap-2 opacity-0 group-hover:opacity-100 translate-x-4 group-hover:translate-x-0 transition-all duration-300">
                      <button 
                        onClick={() => navigate(`/products/edit/${p.id}`, { state: { product: p } })} 
                        className="p-3 bg-card-bg shadow-xl border border-border-v rounded-2xl text-blue-500 hover:bg-blue-50 dark:hover:bg-blue-950/30 transition-colors"
                        title="Edit Product"
                      >
                        <Edit2 size={16} />
                      </button>
                      <button 
                        onClick={() => handleDelete(p.id)} 
                        className="p-3 bg-card-bg shadow-xl border border-border-v rounded-2xl text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors"
                        title="Delete Product"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              /* Empty State - UNIFIED: text-text-m */
              <div className="text-center py-20 bg-card-bg rounded-[3rem] border-2 border-dashed border-border-v">
                <PackageSearch size={64} className="mx-auto text-text-m opacity-20 mb-4" />
                <h3 className="text-xl font-bold text-text-m opacity-50 uppercase tracking-widest">No products found</h3>
                <p className="text-text-m/40 text-sm mt-1">Try adjusting your search or add a new item.</p>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default ProductListPage;