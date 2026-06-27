import React, { useState, useEffect } from 'react';
import { LayoutGrid, List, Search, Filter, Plus, Loader2, Store } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import ShopCard from './components/ShopCard';
import { fetchShops, deleteShop } from '../../api/shopApi';

const MyShopListPage = () => {
  const [shops, setShops] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isGridView, setIsGridView] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [showFilters, setShowFilter] = useState(false);
  const navigate = useNavigate();
  const user = JSON.parse(localStorage.getItem('user'));
  const canAddShop = ['admin', 'owner', 'manager'].includes(user?.UserType?.toLowerCase());

  const loadData = async () => {
    try {
      setLoading(true);
      debugger
      const data = await fetchShops(user.id, user.UserType);
      setShops(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData(); }, []);

  const handleDelete = async (id) => {
    if (window.confirm("Are you sure you want to deactivate this branch?")) {
      await deleteShop(id);
      loadData();
    }
  };

  const filteredShops = shops.filter(s => 
    s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.location.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg p-4 md:p-8 lg:p-10 transition-colors duration-300">
      
      {/* Header Section */}
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
        <div>
          {/* UNIFIED: text-text-h */}
          <h1 className="text-3xl font-black text-text-h tracking-tight leading-tight">
            Shop Network
          </h1>
          {/* UNIFIED: text-text-m */}
          <p className="text-text-m font-medium mt-1">
            Manage and monitor all broiler shop branches.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* UNIFIED: bg-card-bg, border-border-v, text-text-m */}
          <button 
            onClick={() => setIsGridView(!isGridView)}
            className="p-3 bg-card-bg border border-border-v rounded-2xl text-text-m hover:bg-app-bg transition-all shadow-sm active:scale-90"
          >
            {isGridView ? <List size={20} /> : <LayoutGrid size={20} />}
          </button>
          
          {canAddShop && (
            <button 
              onClick={() => navigate('/shops/add')}
              className="flex items-center gap-2 bg-q-green hover:bg-q-green-dark text-white px-6 py-3 rounded-2xl font-bold shadow-lg shadow-q-green/20 transition-all active:scale-95"
            >
              <Plus size={20} />
              <span className="hidden sm:inline">ADD BRANCH</span>
            </button>
          )}
        </div>
      </div>

      {/* Search & Filter Bar */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex flex-wrap gap-4">
          <div className="flex-1 relative group">
            {/* UNIFIED: text-text-m */}
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m group-focus-within:text-q-green transition-colors" size={18} />
            <input 
              type="text"
              placeholder="Search branch name or area..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              // UNIFIED: bg-card-bg, border-border-v, text-text-h
              className="w-full pl-12 pr-4 py-4 bg-card-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green transition-all font-medium text-text-h placeholder:text-text-m/40 shadow-sm"
            />
          </div>
          
          <button 
            onClick={() => setShowFilter(!showFilters)}
            className={`px-6 rounded-2xl border-2 flex items-center gap-2 font-black text-xs tracking-widest transition-all active:scale-95 
              ${showFilters 
                ? 'bg-q-green border-q-green text-white shadow-lg shadow-q-green/20' 
                : 'bg-card-bg border-border-v text-text-m hover:bg-app-bg'
              }`}
          >
            <Filter size={16} />
            <span className="hidden md:inline">FILTERS</span>
          </button>
        </div>
      </div>

      {/* Content Area */}
      <div className="max-w-7xl mx-auto">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="w-10 h-10 text-q-green animate-spin mb-4" />
            <p className="font-bold text-text-m uppercase tracking-widest text-[10px]">Syncing Branches...</p>
          </div>
        ) : filteredShops.length > 0 ? (
          <div className={`grid gap-6 ${isGridView ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4' : 'grid-cols-1'}`}>
            {filteredShops.map(shop => (
              <ShopCard 
                key={shop.id} 
                shop={shop} 
                isGrid={isGridView} 
                onDelete={handleDelete} 
              />
            ))}
          </div>
        ) : (
          /* Empty State - UNIFIED: bg-card-bg, border-border-v */
          <div className="text-center py-20 bg-card-bg rounded-[3rem] border-2 border-dashed border-border-v transition-colors duration-300">
            <Store size={64} className="mx-auto text-text-m opacity-20 mb-4" />
            <h3 className="text-xl font-bold text-text-m opacity-50 uppercase tracking-widest">
              No branches found
            </h3>
            <p className="text-text-m/40 text-sm mt-1">Try adjusting your search criteria.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default MyShopListPage;