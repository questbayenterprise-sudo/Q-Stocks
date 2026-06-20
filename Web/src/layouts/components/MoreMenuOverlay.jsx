import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  User, ShoppingBasket, ChevronDown, Settings, 
  Users, LogOut, X, BarChart3, Warehouse, Receipt 
} from 'lucide-react';

const MoreMenuOverlay = ({ isOpen, onClose }) => {
  const navigate = useNavigate();
  const [inventoryOpen, setInventoryOpen] = useState(false);

  if (!isOpen) return null;

  const handleNav = (path) => {
    navigate(path);
    onClose();
  };

  const menuItems = [
    { label: 'Profile', icon: User, path: '/profile' },
    { label: 'Products', icon: ShoppingBasket, path: '/products' },
    { 
      label: 'Inventory', 
      icon: Warehouse, 
      isDropdown: true,
      subItems: [
        { label: 'Sales', icon: Receipt, path: '/sales' },
        { label: 'Stocks', icon: Warehouse, path: '/stocks' },
        { label: 'Reports', icon: BarChart3, path: '/reports' },
      ]
    },
    { label: 'Settings', icon: Settings, path: '/settings' },
    { label: 'Customers', icon: Users, path: '/customers' },
    { label: 'Users', icon: Users, path: '/admin-users' },
  ];

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-white animate-in slide-in-from-bottom duration-300">
      <div className="p-6 flex justify-between items-center border-bottom border-slate-100">
        <h2 className="text-xl font-black text-slate-900">Menu</h2>
        <button onClick={onClose} className="p-2 bg-slate-100 rounded-full"><X size={20} /></button>
      </div>

      <div className="flex-1 overflow-y-auto px-6 space-y-2">
        {menuItems.map((item) => (
          <div key={item.label}>
            <button
              onClick={() => item.isDropdown ? setInventoryOpen(!inventoryOpen) : handleNav(item.path)}
              className="w-full flex items-center gap-4 p-4 rounded-2xl hover:bg-slate-50 transition-colors"
            >
              <div className="p-2 bg-slate-100 rounded-xl text-slate-600">
                <item.icon size={20} />
              </div>
              <span className="flex-1 text-left font-bold text-slate-700">{item.label}</span>
              {item.isDropdown && (
                <ChevronDown size={18} className={`transition-transform ${inventoryOpen ? 'rotate-180' : ''}`} />
              )}
            </button>

            {item.isDropdown && inventoryOpen && (
              <div className="ml-12 mt-2 space-y-2 border-l-2 border-slate-100 pl-4 animate-in fade-in slide-in-from-top-2">
                {item.subItems.map((sub) => (
                  <button
                    key={sub.label}
                    onClick={() => handleNav(sub.path)}
                    className="w-full flex items-center gap-3 p-3 rounded-xl hover:bg-slate-50 text-slate-500 font-medium"
                  >
                    <sub.icon size={18} />
                    <span>{sub.label}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="p-6 border-t border-slate-100">
        <button 
          onClick={() => handleNav('/logout')}
          className="w-full flex items-center gap-4 p-4 rounded-2xl bg-red-50 text-red-600 font-bold"
        >
          <LogOut size={20} />
          <span>Logout</span>
        </button>
      </div>
    </div>
  );
};

export default MoreMenuOverlay;