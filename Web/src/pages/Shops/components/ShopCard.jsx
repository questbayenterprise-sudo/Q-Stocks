import React from 'react';
import { MapPin, Edit3, Trash2, Store } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const ShopCard = ({ shop, isGrid, onDelete }) => {
  const navigate = useNavigate();
  
  // Use the API Base URL from .env, fallback to localhost:5000 if not set
  const baseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';

  /**
   * Logic to construct the full Image URL.
   * Prevents 404s by checking if the path is a valid filename.
   */
  const getImageUrl = () => {
    if (!shop.image_url || shop.image_url.trim() === "" || shop.image_url === "uploads/shops/") {
      return null;
    }

    if (shop.image_url.startsWith('http')) {
      return shop.image_url;
    }

    const cleanPath = shop.image_url.replace(/\\/g, '/');
    return `${baseUrl}/${cleanPath}`;
  };

  const imageUrl = getImageUrl();

  return (
    <div 
      onClick={() => navigate(`/shops/edit/${shop.id}`, { state: { shop } })}
      // UNIFIED: bg-card-bg, border-border-v, text-text-h
      className={`bg-card-bg rounded-3xl border border-border-v shadow-sm hover:shadow-md transition-all duration-300 cursor-pointer group flex overflow-hidden 
        ${isGrid ? 'flex-col' : 'flex-row items-center p-4 gap-6'}`}
    >
      {/* --- IMAGE SECTION --- */}
      {/* UNIFIED: bg-app-bg (provides contrast inside the card) */}
      <div className={`relative ${isGrid ? 'w-full h-48' : 'w-24 h-24'} rounded-2xl bg-app-bg overflow-hidden shrink-0 border border-border-v transition-colors`}>
        {imageUrl ? (
          <img 
            src={imageUrl} 
            alt={shop.name} 
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            onError={(e) => {
              e.target.onerror = null; 
              // UNIFIED: Placeholder updated to match theme background
              e.target.parentElement.innerHTML = `
                <div class="w-full h-full flex items-center justify-center bg-app-bg text-text-m opacity-20">
                  <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
                </div>`;
            }}
          />
        ) : (
          /* UNIFIED: text-text-m with low opacity for the placeholder icon */
          <div className="w-full h-full flex items-center justify-center text-text-m opacity-20">
            <Store size={isGrid ? 48 : 32} />
          </div>
        )}
      </div>

      {/* --- INFO SECTION --- */}
      <div className={`flex-1 ${isGrid ? 'p-5' : ''}`}>
        <div className="flex justify-between items-start">
          {/* Badge: Brand green with 10% opacity works perfectly on both Light and Dark card backgrounds */}
          <span className="text-[9px] font-black text-q-green bg-q-green/10 px-2 py-1 rounded-md uppercase tracking-[0.1em] mb-2 inline-block">
            {shop.is_active ? 'Active Branch' : 'Inactive'}
          </span>
          
          <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <button 
              onClick={(e) => { 
                e.stopPropagation(); 
                onDelete(shop.id); 
              }}
              // UNIFIED: hover:bg-red-500/10 for consistent dark mode tint
              className="p-2 text-text-m hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-all"
              title="Deactivate Branch"
            >
              <Trash2 size={16} />
            </button>
          </div>
        </div>
        
        {/* UNIFIED: text-text-h (High contrast headings) */}
        <h3 className="text-lg font-black text-text-h tracking-tight leading-tight mb-1 uppercase">
          {shop.name}
        </h3>
        
        {/* UNIFIED: text-text-m (Secondary text) */}
        <div className="flex items-center gap-1 text-text-m font-medium">
          <MapPin size={14} className="text-red-500 shrink-0" />
          <span className="text-sm truncate">{shop.location}</span>
        </div>

        {!isGrid && shop.description && (
           <p className="text-xs text-text-m mt-2 line-clamp-1 italic opacity-70">
             {shop.description}
           </p>
        )}
        
        {/* Footer (Only in Grid view) */}
        {isGrid && (
          // UNIFIED: border-border-v
          <div className="mt-4 pt-4 border-t border-border-v flex justify-between items-center transition-colors">
            <div className="flex items-center gap-1.5">
               <div className="w-1.5 h-1.5 rounded-full bg-q-green animate-pulse"></div>
               <span className="text-[10px] font-black text-text-m uppercase tracking-tighter">Inventory Sync</span>
            </div>
            {/* UNIFIED: text-text-m for icons */}
            <Edit3 size={14} className="text-text-m group-hover:text-q-green transition-colors" />
          </div>
        )}
      </div>
    </div>
  );
};

export default ShopCard;