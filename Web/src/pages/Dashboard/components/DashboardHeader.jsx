import React from 'react';
import { Bell, User } from 'lucide-react';

const DashboardHeader = () => {
  // In a real app, get this from Redux or LocalStorage
  const user = JSON.parse(localStorage.getItem('user')) || { username: 'Manager' };

  return (
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-4">
        <div className="h-12 w-12 rounded-2xl bg-q-green/10 flex items-center justify-center border border-q-green/20">
          <User className="text-q-green w-6 h-6" />
        </div>
        <div>
          <h2 className="text-xl font-black text-slate-800 tracking-tight">
            Hello, {user.username}!
          </h2>
          <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">
            Shop Manager
          </p>
        </div>
      </div>

      <button className="relative p-3 rounded-2xl bg-white border border-slate-100 shadow-sm hover:bg-slate-50 transition-colors">
        <Bell className="w-5 h-5 text-slate-600" />
        <span className="absolute top-3 right-3 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
      </button>
    </div>
  );
};

export default DashboardHeader;