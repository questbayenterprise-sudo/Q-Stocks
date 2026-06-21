import React, { useState, useEffect } from 'react';
// ADDED 'Store' to the list
import { LayoutGrid, List, Search, Filter, Plus, Loader2, MapPin, Store } from 'lucide-react';import { useNavigate } from 'react-router-dom';
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
const canAddShop = ['admin', 'owner', 'manager'].includes(user?.userType_id?.toLowerCase());

  const loadData = async () => {
    try {
      setLoading(true);
      const data = await fetchShops(user.id, user.userType_id);
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
    <div className="min-h-screen bg-[#F8F9FA] p-6 lg:p-10">
      {/* Header */}
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
        <div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">Shop Network</h1>
          <p className="text-slate-500 font-medium">Manage and monitor all broiler shop branches.</p>
        </div>

        <div className="flex items-center gap-3">
          <button 
            onClick={() => setIsGridView(!isGridView)}
            className="p-3 bg-white border border-slate-200 rounded-2xl text-slate-600 hover:bg-slate-50 transition-colors"
          >
            {isGridView ? <List size={20} /> : <LayoutGrid size={20} />}
          </button>
          
         {canAddShop && (
  <button 
    onClick={() => navigate('/shops/add')}
    className="flex items-center gap-2 bg-q-green hover:bg-q-green-dark text-white px-6 py-3 rounded-2xl font-bold shadow-lg shadow-green-200 transition-all active:scale-95"
  >
    <Plus size={20} />
    <span>ADD BRANCH</span>
  </button>
)}
        </div>
      </div>

      {/* Search & Filter Bar */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-5 h-5" />
            <input 
              type="text"
              placeholder="Search branch name or area..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-4 bg-white border border-slate-200 rounded-2xl outline-none focus:border-q-green transition-all font-medium"
            />
          </div>
          <button 
            onClick={() => setShowFilter(!showFilters)}
            className={`px-6 rounded-2xl border flex items-center gap-2 font-bold transition-all ${showFilters ? 'bg-q-green border-q-green text-white' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'}`}
          >
            <Filter size={18} />
            <span className="hidden md:inline">Filters</span>
          </button>
        </div>
      </div>

      {/* Content Area */}
      <div className="max-w-7xl mx-auto">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="w-10 h-10 text-q-green animate-spin mb-4" />
            <p className="font-bold text-slate-400 uppercase tracking-widest text-sm">Fetching Branches...</p>
          </div>
        ) : filteredShops.length > 0 ? (
          <div className={`grid gap-6 ${isGridView ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4' : 'grid-cols-1'}`}>
            {filteredShops.map(shop => (
              <ShopCard key={shop.id} shop={shop} isGrid={isGridView} onDelete={handleDelete} />
            ))}
          </div>
        ) : (
          <div className="text-center py-20 bg-white rounded-[3rem] border-2 border-dashed border-slate-100">
            <Store size={64} className="mx-auto text-slate-200 mb-4" />
            <h3 className="text-xl font-bold text-slate-400">No shops found matching your search.</h3>
          </div>
        )}
      </div>
    </div>
  );
};

export default MyShopListPage;