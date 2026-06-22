import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Moon, ChevronRight, LogOut, Trash2, Sun } from 'lucide-react';
import { useTheme } from '../../context/ThemeContext'; // Import the global hook

const SettingsPage = () => {
  const navigate = useNavigate();
  // Using the unified theme state
  const { isDarkMode, toggleTheme } = useTheme();

  const handleLogout = () => {
    localStorage.clear();
    navigate('/', { replace: true });
  };

  return (
    <div className="min-h-screen bg-[color:var(--color-app-bg)] p-6 md:p-10 transition-colors duration-300">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-black text-[color:var(--color-text-main)] mb-2">
          Settings
        </h1>
        <p className="text-[color:var(--color-text-muted)] font-medium mb-10">
          Configure your app experience.
        </p>

        <div className="space-y-8">
          {/* --- Appearance --- */}
          <Section label="Appearance">
            <ToggleTile 
              icon={isDarkMode ? <Moon size={20} /> : <Sun size={20} />} 
              label={isDarkMode ? "Dark Mode Active" : "Light Mode Active"} 
              value={isDarkMode} 
              onToggle={toggleTheme} 
            />
          </Section>

          {/* --- Security (Change Password Removed) --- */}
          <Section label="Account Security">
            <NavTile 
              icon={<Trash2 className="text-red-500" size={20} />} 
              label="Deactivate Account" 
              isDestructive 
              onClick={() => navigate('/settings/delete')} 
            />
          </Section>

          {/* --- Footer & Logout --- */}
          <div className="pt-10">
            <button 
              onClick={handleLogout}
              className="w-full flex items-center justify-center gap-3 p-5 bg-[color:var(--color-card-bg)] border border-[color:var(--color-border)] text-red-500 font-black rounded-3xl hover:bg-red-50 dark:hover:bg-red-950/20 transition-all shadow-sm"
            >
              <LogOut size={20} /> LOGOUT
            </button>
            <p className="text-center mt-6 text-[10px] font-black text-[color:var(--color-text-muted)] uppercase tracking-[0.3em]">
              Q-Stocks Web v1.0.2 (Build 44)
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

// --- Reusable Layout Components ---

const Section = ({ label, children }) => (
  <div className="space-y-3">
    <p className="ml-4 text-[10px] font-black text-[color:var(--color-text-muted)] uppercase tracking-widest">
      {label}
    </p>
    <div className="bg-[color:var(--color-card-bg)] rounded-[2rem] border border-[color:var(--color-border)] overflow-hidden shadow-sm">
      {children}
    </div>
  </div>
);

const ToggleTile = ({ icon, label, value, onToggle }) => (
  <div className="flex items-center justify-between p-5 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors border-b border-[color:var(--color-border)] last:border-0">
    <div className="flex items-center gap-4">
      <div className="text-q-green">{icon}</div>
      <span className="font-bold text-[color:var(--color-text-main)]">{label}</span>
    </div>
    <button 
      onClick={onToggle}
      className={`w-12 h-6 rounded-full transition-all relative ${value ? 'bg-q-green' : 'bg-slate-300'}`}
    >
      <div className={`absolute top-1 w-4 h-4 bg-white rounded-full transition-all ${value ? 'left-7' : 'left-1'}`} />
    </button>
  </div>
);

const NavTile = ({ icon, label, onClick, isDestructive }) => (
  <button 
    onClick={onClick}
    className="w-full flex items-center justify-between p-5 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors border-b border-[color:var(--color-border)] last:border-0"
  >
    <div className="flex items-center gap-4">
      <div className="text-slate-400">{icon}</div>
      <span className={`font-bold ${isDestructive ? 'text-red-500' : 'text-[color:var(--color-text-main)]'}`}>
        {label}
      </span>
    </div>
    <ChevronRight size={18} className="text-slate-300" />
  </button>
);

export default SettingsPage;