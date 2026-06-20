import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { 
  Home, Store, ShoppingBasket, Users, 
  Settings, LogOut, ChevronDown, 
  BarChart3, Warehouse, Receipt, LayoutDashboard 
} from 'lucide-react';
import { APP_CONFIG } from '../../config/appConfig';

const Sidebar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [inventoryOpen, setInventoryOpen] = useState(true);

  const menuItems = [
    { label: 'Dashboard', icon: LayoutDashboard, path: '/home' },
    { label: 'My Shops', icon: Store, path: '/shops' },
    { label: 'Products', icon: ShoppingBasket, path: '/products' },
    { label: 'Customers', icon: Users, path: '/customers' },
  ];

  const inventorySubItems = [
    { label: 'Sales', icon: Receipt, path: '/sales' },
    { label: 'Stocks', icon: Warehouse, path: '/stocks' },
    { label: 'Reports', icon: BarChart3, path: '/reports' },
  ];

  const isActive = (path) => location.pathname === path;

  return (
    <aside className="w-64 h-screen bg-white border-r border-slate-100 flex flex-col sticky top-0">
      {/* Branding Area */}
      <div className="p-6 flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-q-green flex items-center justify-center shadow-lg shadow-green-100">
<img src={APP_CONFIG.logoPath} className="w-full h-full object-contain" />
        </div>
        <span className="text-xl font-black text-slate-800 tracking-tight">Q-Stocks</span>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
        {menuItems.map((item) => (
          <button
            key={item.path}
            onClick={() => navigate(item.path)}
            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-bold text-sm ${
              isActive(item.path) 
                ? 'bg-q-green/10 text-q-green' 
                : 'text-slate-500 hover:bg-slate-50 hover:text-slate-700'
            }`}
          >
            <item.icon size={20} strokeWidth={isActive(item.path) ? 2.5 : 2} />
            {item.label}
          </button>
        ))}

        {/* Inventory Section (Collapsible) */}
        <div className="pt-4">
          <button
            onClick={() => setInventoryOpen(!inventoryOpen)}
            className="w-full flex items-center gap-3 px-4 py-2 text-slate-400 font-black text-[10px] uppercase tracking-[0.2em] mb-1"
          >
            Inventory
            <ChevronDown size={14} className={`ml-auto transition-transform ${inventoryOpen ? 'rotate-180' : ''}`} />
          </button>
          
          {inventoryOpen && (
            <div className="space-y-1">
              {inventorySubItems.map((sub) => (
                <button
                  key={sub.path}
                  onClick={() => navigate(sub.path)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-bold text-sm ${
                    isActive(sub.path) 
                      ? 'bg-q-green/10 text-q-green' 
                      : 'text-slate-500 hover:bg-slate-50 hover:text-slate-700'
                  }`}
                >
                  <sub.icon size={18} strokeWidth={isActive(sub.path) ? 2.5 : 2} />
                  {sub.label}
                </button>
              ))}
            </div>
          )}
        </div>
      </nav>

      {/* Bottom Profile/Settings */}
      <div className="p-4 border-t border-slate-50 space-y-1">
        <button 
          onClick={() => navigate('/settings')}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-slate-500 hover:bg-slate-50 font-bold text-sm"
        >
          <Settings size={20} />
          Settings
        </button>
        <button 
          className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-red-500 hover:bg-red-50 font-bold text-sm"
        >
          <LogOut size={20} />
          Logout
        </button>
      </div>
    </aside>
  );
};

export default Sidebar; // <--- This fixes your error