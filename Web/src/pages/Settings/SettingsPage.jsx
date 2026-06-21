import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Moon, Bell, ShieldAlert, ChevronRight, LogOut, Trash2 } from 'lucide-react';

const SettingsPage = () => {
  const navigate = useNavigate();
  const [darkMode, setDarkMode] = useState(false);

  const handleLogout = () => {
    localStorage.clear();
    navigate('/', { replace: true });
  };

  return (
    <div className="min-h-screen bg-slate-50 p-6 md:p-10">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-black text-slate-900 mb-2">Settings</h1>
        <p className="text-slate-500 font-medium mb-10">Configure your app experience.</p>

        <div className="space-y-4">
          <Section label="Appearance">
            <ToggleTile 
              icon={<Moon />} 
              label="Dark Mode" 
              value={darkMode} 
              onToggle={setDarkMode} 
            />
          </Section>

          <Section label="Security">
            <NavTile 
              icon={<ShieldAlert />} 
              label="Change Password" 
              onClick={() => {}} 
            />
            <NavTile 
              icon={<Trash2 className="text-red-500" />} 
              label="Deactivate Account" 
              isDestructive 
              onClick={() => navigate('/settings/delete')} 
            />
          </Section>

          <div className="pt-10">
            <button 
              onClick={handleLogout}
              className="w-full flex items-center justify-center gap-3 p-5 bg-white border border-red-100 text-red-600 font-black rounded-3xl hover:bg-red-50 transition-all shadow-sm"
            >
              <LogOut size={20} /> LOGOUT
            </button>
            <p className="text-center mt-6 text-[10px] font-black text-slate-300 uppercase tracking-[0.3em]">
              Q-Stocks Web v1.0.2 (Build 44)
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

const Section = ({ label, children }) => (
  <div className="space-y-3">
    <p className="ml-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">{label}</p>
    <div className="bg-white rounded-[2rem] border border-slate-100 overflow-hidden shadow-sm">
      {children}
    </div>
  </div>
);

const ToggleTile = ({ icon, label, value, onToggle }) => (
  <div className="flex items-center justify-between p-5 hover:bg-slate-50 transition-colors border-b border-slate-50 last:border-0">
    <div className="flex items-center gap-4">
      <div className="text-slate-400">{icon}</div>
      <span className="font-bold text-slate-700">{label}</span>
    </div>
    <button 
      onClick={() => onToggle(!value)}
      className={`w-12 h-6 rounded-full transition-all relative ${value ? 'bg-q-green' : 'bg-slate-200'}`}
    >
      <div className={`absolute top-1 w-4 h-4 bg-white rounded-full transition-all ${value ? 'left-7' : 'left-1'}`} />
    </button>
  </div>
);

const NavTile = ({ icon, label, onClick, isDestructive }) => (
  <button 
    onClick={onClick}
    className="w-full flex items-center justify-between p-5 hover:bg-slate-50 transition-colors border-b border-slate-50 last:border-0"
  >
    <div className="flex items-center gap-4">
      <div className="text-slate-400">{icon}</div>
      <span className={`font-bold ${isDestructive ? 'text-red-500' : 'text-slate-700'}`}>{label}</span>
    </div>
    <ChevronRight size={18} className="text-slate-300" />
  </button>
);

export default SettingsPage;