import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { 
  ShoppingBasket, Users, Settings, LogOut, 
  ChevronDown, BarChart3, Warehouse, Receipt, 
  LayoutDashboard, Store, HandCoins, Wallet2 
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
    { label: 'Sales History', icon: Receipt, path: '/sales' },
    { label: 'Pending Payments', icon: HandCoins, path: '/inventory/pending' },
    { label: 'Income Entry', icon: Wallet2, path: '/income-entry' },
    { label: 'Stocks', icon: Warehouse, path: '/stocks' },
    { label: 'Reports', icon: BarChart3, path: '/reports' },
  ];

  const isActive = (path) => location.pathname === path;

  const handleLogout = () => {
    localStorage.removeItem('user');
    localStorage.clear();
    navigate('/', { replace: true });
  };

  return (
    // UNIFIED: Using bg-card-bg and border-border-main
    <aside className="w-64 h-screen bg-card-bg border-r border-border-main flex flex-col sticky top-0 z-40 transition-colors duration-300">
      
      {/* Branding Area */}
      <div className="p-6 flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-q-green flex items-center justify-center shadow-lg shadow-q-green/20 p-2">
          <img src={APP_CONFIG.logoPath} alt="Logo" className="w-full h-full object-contain" />
        </div>
        {/* UNIFIED: text-text-main */}
        <span className="text-xl font-black text-text-main tracking-tight">Q-Stocks</span>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto custom-scrollbar">
        {menuItems.map((item) => (
          <button
            key={item.path}
            onClick={() => navigate(item.path)}
            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-bold text-sm ${
              isActive(item.path) 
                ? 'bg-q-green/10 text-q-green' 
                // UNIFIED: text-text-muted and bg-app-bg for hover
                : 'text-text-muted hover:bg-app-bg hover:text-text-main'
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
            // UNIFIED: text-text-muted
            className="w-full flex items-center gap-3 px-4 py-2 text-text-muted font-black text-[10px] uppercase tracking-[0.2em] mb-1 hover:text-text-main transition-colors"
          >
            Inventory
            <ChevronDown size={14} className={`ml-auto transition-transform duration-300 ${inventoryOpen ? 'rotate-180' : ''}`} />
          </button>
          
          {inventoryOpen && (
            <div className="space-y-1 animate-in fade-in slide-in-from-top-1">
              {inventorySubItems.map((sub) => (
                <button
                  key={sub.path}
                  onClick={() => navigate(sub.path)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-bold text-sm ${
                    isActive(sub.path) 
                      ? 'bg-q-green/10 text-q-green' 
                      : 'text-text-muted hover:bg-app-bg hover:text-text-main'
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
      {/* UNIFIED: border-border-main */}
      <div className="p-4 border-t border-border-main space-y-1">
        <button 
          onClick={() => navigate('/settings')}
          className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-bold text-sm ${
            // UNIFIED: bg-app-bg for active setting
            isActive('/settings') ? 'bg-app-bg text-text-main' : 'text-text-muted hover:bg-app-bg hover:text-text-main'
          }`}
        >
          <Settings size={20} />
          Settings
        </button>
        <button 
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-red-500 hover:bg-red-50 dark:hover:bg-red-950/20 transition-colors font-bold text-sm"
        >
          <LogOut size={20} />
          Logout
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;