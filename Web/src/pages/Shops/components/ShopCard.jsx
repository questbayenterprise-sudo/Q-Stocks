import React from 'react';
import { MapPin, Edit3, Trash2, Store, AlertCircle } from 'lucide-react';
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

    // 1. If it's already a full URL (external), return as is
    if (shop.image_url.startsWith('http')) {
      return shop.image_url;
    }

    // 2. Clean Windows backslashes to Web forward slashes
    const cleanPath = shop.image_url.replace(/\\/g, '/');
    
    // 3. Append to backend URL
    return `${baseUrl}/${cleanPath}`;
  };

  const imageUrl = getImageUrl();

  return (
    <div 
      onClick={() => navigate(`/shops/edit/${shop.id}`, { state: { shop } })}
      className={`bg-white rounded-3xl border border-slate-100 shadow-sm hover:shadow-md transition-all cursor-pointer group flex overflow-hidden 
        ${isGrid ? 'flex-col' : 'flex-row items-center p-4 gap-6'}`}
    >
      {/* --- IMAGE SECTION --- */}
      <div className={`relative ${isGrid ? 'w-full h-48' : 'w-24 h-24'} rounded-2xl bg-slate-50 overflow-hidden shrink-0 border border-slate-50`}>
        {imageUrl ? (
          <img 
            src={imageUrl} 
            alt={shop.name} 
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            // If the server has the path but the file is missing, show placeholder
            onError={(e) => {
              e.target.onerror = null; 
              e.target.parentElement.innerHTML = `
                <div class="w-full h-full flex items-center justify-center bg-slate-50 text-slate-300">
                  <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
                </div>`;
            }}
          />
        ) : (
          /* Placeholder when no image URL exists in database */
          <div className="w-full h-full flex items-center justify-center text-slate-200">
            <Store size={isGrid ? 48 : 32} />
          </div>
        )}
      </div>

      {/* --- INFO SECTION --- */}
      <div className={`flex-1 ${isGrid ? 'p-5' : ''}`}>
        <div className="flex justify-between items-start">
          <span className="text-[10px] font-black text-q-green bg-q-green/10 px-2 py-1 rounded-md uppercase tracking-wider mb-2 inline-block">
            {shop.is_active ? 'Active Branch' : 'Inactive'}
          </span>
          
          {/* Action Buttons */}
          <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <button 
              onClick={(e) => { 
                e.stopPropagation(); // Prevents navigating to edit page
                onDelete(shop.id); 
              }}
              className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-xl transition-all"
              title="Deactivate Branch"
            >
              <Trash2 size={16} />
            </button>
          </div>
        </div>
        
        <h3 className="text-lg font-black text-slate-800 tracking-tight leading-tight mb-1">
          {shop.name}
        </h3>
        
        <div className="flex items-center gap-1 text-slate-500">
          <MapPin size={14} className="text-red-400 shrink-0" />
          <span className="text-sm font-medium truncate">{shop.location}</span>
        </div>

        {/* Description Snippet (Only in List view) */}
        {!isGrid && shop.description && (
           <p className="text-xs text-slate-400 mt-2 line-clamp-1 italic">
             {shop.description}
           </p>
        )}
        
        {/* Footer info (Only in Grid view) */}
        {isGrid && (
          <div className="mt-4 pt-4 border-t border-slate-50 flex justify-between items-center">
            <div className="flex items-center gap-1.5">
               <div className="w-1.5 h-1.5 rounded-full bg-q-green animate-pulse"></div>
               <span className="text-[10px] font-black text-slate-400 uppercase tracking-tighter">Inventory Sync</span>
            </div>
            <Edit3 size={14} className="text-slate-300 group-hover:text-q-green transition-colors" />
          </div>
        )}
      </div>
    </div>
  );
};

export default ShopCard;