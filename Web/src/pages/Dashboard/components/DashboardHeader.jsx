import React from 'react';
import { Bell, User } from 'lucide-react';

const DashboardHeader = () => {
  // Safe parsing of user session
  const user = JSON.parse(localStorage.getItem('user')) || { username: 'Manager' };

  return (
    <div className="flex items-center justify-between transition-colors duration-300">
      <div className="flex items-center gap-4">
        {/* Avatar Container: brand green transparency works well in both modes */}
        <div className="h-12 w-12 rounded-2xl bg-q-green/10 flex items-center justify-center border border-q-green/20 shadow-sm">
          <User className="text-q-green w-6 h-6" />
        </div>
        
        <div>
          {/* UNIFIED: text-text-h (Heading color) */}
          <h2 className="text-xl font-black text-text-h tracking-tight leading-tight">
            Hello, {user.username}!
          </h2>
          {/* UNIFIED: text-text-m (Muted text color) */}
          <p className="text-[10px] font-bold text-text-m uppercase tracking-[0.15em] mt-0.5">
            Store Manager
          </p>
        </div>
      </div>

      {/* Notification Button */}
      {/* UNIFIED: bg-card-bg, border-border-v, hover:bg-app-bg */}
      <button className="relative p-3 rounded-2xl bg-card-bg border border-border-v shadow-sm hover:bg-app-bg transition-all active:scale-95 group">
        <Bell className="w-5 h-5 text-text-m group-hover:text-q-green transition-colors" />
        
        {/* Notification Dot */}
        <span className="absolute top-3 right-3 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-card-bg"></span>
      </button>
    </div>
  );
};

export default DashboardHeader;