import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Moon, ChevronRight, LogOut, Trash2, Sun, Loader2 } from 'lucide-react';
import { useTheme } from '../../context/ThemeContext';
import { updateSettings } from '../../api/profileApi'; // Ensure this API method exists

const SettingsPage = () => {
  const navigate = useNavigate();
  const { isDarkMode, toggleTheme } = useTheme();
  const [isSyncing, setIsSyncing] = useState(false);

  // Get current user from session
  const user = JSON.parse(localStorage.getItem('user'));

  // --- Unified Toggle Logic ---
  const handleThemeToggle = async () => {
    // 1. Update UI Instantly for best UX
    toggleTheme();

    // 2. Sync with Golang Backend (tbl_user_settings)
    if (user?.id) {
      setIsSyncing(true);
      try {
        await updateSettings({
          user_id: user.id.toString(),
          themes: !isDarkMode ? 'dark' : 'light' // Toggle logic
        });
      } catch (err) {
        console.error("Failed to sync theme to server:", err);
      } finally {
        setIsSyncing(false);
      }
    }
  };

  const handleLogout = () => {
    localStorage.clear();
    navigate('/', { replace: true });
  };

  return (
    <div className="min-h-screen bg-app-bg p-4 md:p-10 transition-colors duration-300">
      <div className="max-w-2xl mx-auto">
        
        {/* Header */}
        <div className="flex items-center justify-between mb-2">
          <h1 className="text-3xl font-black text-text-h tracking-tight">Settings</h1>
          {isSyncing && (
            <div className="flex items-center gap-2 text-[10px] font-bold text-q-green animate-pulse">
              <Loader2 size={12} className="animate-spin" /> SYNCING...
            </div>
          )}
        </div>
        <p className="text-text-m font-medium mb-10">Configure your enterprise shop experience.</p>

        <div className="space-y-8">
          
          {/* --- Appearance Section --- */}
          <Section label="Appearance">
            <ToggleTile 
              icon={isDarkMode ? <Moon size={20} /> : <Sun size={20} />} 
              label="Dark Mode" 
              subLabel="Adjust the interface for low-light environments"
              value={isDarkMode} 
              onToggle={handleThemeToggle} 
            />
          </Section>

          {/* --- Security Section --- */}
          <Section label="Account Security">
            <NavTile 
              icon={<Trash2 className="text-red-500" size={20} />} 
              label="Deactivate Account" 
              subLabel="Permanently revoke your access to this shop"
              isDestructive 
              onClick={() => navigate('/settings/delete')} 
            />
          </Section>

          {/* --- Logout & Version Info --- */}
          <div className="pt-10 space-y-6">
            <button 
              onClick={handleLogout}
              className="w-full flex items-center justify-center gap-3 p-5 bg-card-bg border border-border-v text-red-500 font-black rounded-3xl hover:bg-red-50 dark:hover:bg-red-950/20 transition-all shadow-sm active:scale-[0.98]"
            >
              <LogOut size={20} /> LOGOUT FROM SYSTEM
            </button>
            
            <div className="text-center space-y-1">
              <p className="text-[10px] font-black text-text-m uppercase tracking-[0.3em]">
                Q-Stocks Enterprise Web
              </p>
              <p className="text-[9px] font-bold text-text-m/50 uppercase">
                Version 1.0.2 • Build 2026.06.25
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// --- Reusable Sub-Components ---

const Section = ({ label, children }) => (
  <div className="space-y-3">
    <p className="ml-4 text-[10px] font-black text-text-m uppercase tracking-[0.2em]">
      {label}
    </p>
    <div className="bg-card-bg rounded-[2.5rem] border border-border-v overflow-hidden shadow-sm transition-colors duration-300">
      {children}
    </div>
  </div>
);

const ToggleTile = ({ icon, label, subLabel, value, onToggle }) => (
  <div className="flex items-center justify-between p-6 hover:bg-app-bg/50 transition-colors border-b border-border-v last:border-0">
    <div className="flex items-center gap-5">
      <div className={`p-3 rounded-2xl ${value ? 'bg-q-green/20 text-q-green' : 'bg-slate-100 text-slate-400 dark:bg-slate-800'}`}>
        {icon}
      </div>
      <div>
        <p className="font-bold text-text-h leading-tight">{label}</p>
        <p className="text-xs text-text-m mt-0.5">{subLabel}</p>
      </div>
    </div>
    <button 
      onClick={onToggle}
      className={`w-14 h-7 rounded-full transition-all relative shadow-inner ${value ? 'bg-q-green' : 'bg-slate-300 dark:bg-slate-700'}`}
    >
      <div className={`absolute top-1 w-5 h-5 bg-white rounded-full shadow-md transition-all duration-300 ${value ? 'left-8' : 'left-1'}`} />
    </button>
  </div>
);

const NavTile = ({ icon, label, subLabel, onClick, isDestructive }) => (
  <button 
    onClick={onClick}
    className="w-full flex items-center justify-between p-6 hover:bg-app-bg/50 transition-colors border-b border-border-v last:border-0 group"
  >
    <div className="flex items-center gap-5">
      <div className={`p-3 rounded-2xl ${isDestructive ? 'bg-red-500/10' : 'bg-slate-100 dark:bg-slate-800 text-slate-400'}`}>
        {icon}
      </div>
      <div className="text-left">
        <p className={`font-bold leading-tight ${isDestructive ? 'text-red-500' : 'text-text-h'}`}>
          {label}
        </p>
        <p className="text-xs text-text-m mt-0.5">{subLabel}</p>
      </div>
    </div>
    <ChevronRight size={18} className="text-text-m group-hover:translate-x-1 transition-transform" />
  </button>
);

export default SettingsPage;