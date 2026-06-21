import React from 'react';
import { MapPin, Edit3, Trash2, Store } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const ShopCard = ({ shop, isGrid, onDelete }) => {
  const navigate = useNavigate();
  const baseUrl = import.meta.env.VITE_API_BASE_URL;

  // Resolve Image URL (Go Backend Path handling)
  const imageUrl = shop.image_url 
    ? (shop.image_url.startsWith('http') ? shop.image_url : `${baseUrl}/${shop.image_url.replace(/\\/g, '/')}`)
    : null;

  return (
    <div 
      onClick={() => navigate(`/shops/edit/${shop.id}`, { state: { shop } })}
      className={`bg-white rounded-3xl border border-slate-100 shadow-sm hover:shadow-md transition-all cursor-pointer group flex ${isGrid ? 'flex-col' : 'flex-row items-center p-4 gap-6'}`}
    >
      {/* Image Section */}
      <div className={`${isGrid ? 'w-full h-48' : 'w-24 h-24'} rounded-2xl bg-slate-100 overflow-hidden shrink-0`}>
        {imageUrl ? (
          <img src={imageUrl} alt={shop.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-slate-300">
            <Store size={isGrid ? 48 : 32} />
          </div>
        )}
      </div>

      {/* Info Section */}
      <div className={`flex-1 ${isGrid ? 'p-5' : ''}`}>
        <div className="flex justify-between items-start">
          <span className="text-[10px] font-black text-q-green bg-q-green/10 px-2 py-1 rounded-md uppercase tracking-wider mb-2 inline-block">
            Active Branch
          </span>
          <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <button 
              onClick={(e) => { e.stopPropagation(); onDelete(shop.id); }}
              className="p-1.5 text-red-400 hover:bg-red-50 rounded-lg"
            >
              <Trash2 size={16} />
            </button>
          </div>
        </div>
        
        <h3 className="text-lg font-bold text-slate-800 tracking-tight">{shop.name}</h3>
        <div className="flex items-center gap-1 mt-1 text-slate-500">
          <MapPin size={14} className="text-red-400" />
          <span className="text-sm font-medium">{shop.location}</span>
        </div>
        
        {isGrid && (
          <div className="mt-4 pt-4 border-t border-slate-50 flex justify-between items-center text-xs font-bold text-slate-400">
            <span>STOCK: OK</span>
            <Edit3 size={14} />
          </div>
        )}
      </div>
    </div>
  );
};

export default ShopCard;