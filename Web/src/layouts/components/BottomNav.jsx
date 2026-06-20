import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Home, Store, MoreHorizontal } from 'lucide-react';

const BottomNav = ({ onMoreClick }) => {
  const navigate = useNavigate();
  const location = useLocation();

  const tabs = [
    { label: 'Home', icon: Home, path: '/home' },
    { label: 'Shop', icon: Store, path: '/shops' },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-100 px-6 py-3 flex justify-between items-center z-40 shadow-[0_-4px_20px_rgba(0,0,0,0.03)]">
      {tabs.map((tab) => (
        <button
          key={tab.path}
          onClick={() => navigate(tab.path)}
          className={`flex flex-col items-center gap-1 transition-colors ${
            location.pathname === tab.path ? 'text-q-green' : 'text-slate-400'
          }`}
        >
          <tab.icon size={24} strokeWidth={location.pathname === tab.path ? 2.5 : 2} />
          <span className="text-[10px] font-bold uppercase tracking-widest">{tab.label}</span>
        </button>
      ))}
      
      <button
        onClick={onMoreClick}
        className="flex flex-col items-center gap-1 text-slate-400"
      >
        <MoreHorizontal size={24} />
        <span className="text-[10px] font-bold uppercase tracking-widest">More</span>
      </button>
    </div>
  );
};

export default BottomNav;