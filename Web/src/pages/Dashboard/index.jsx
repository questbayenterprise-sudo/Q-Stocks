import React, { useState, useEffect, useCallback } from 'react';
import { Plus, RefreshCw } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

// Unified Imports
import DashboardHeader from './components/DashboardHeader';
import QuickActions from './components/QuickActions';
import AnalyticsCards from './components/AnalyticsCards';
import WeeklyChart from './components/WeeklyChart';
import RecentSales from './components/RecentSales';
import { fetchDashboardData } from '../../api/dashboardApi';

const DashboardPage = () => {
  const navigate = useNavigate();
  const [data, setData] = useState({ analytics: null, recentSales: [] });
  const [loading, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Memoized Load Function to prevent unnecessary re-creations
  const loadData = useCallback(async (showFullLoader = true) => {
    if (showFullLoader) setLoading(true);
    else setIsRefreshing(true);

    try {
      const userStr = localStorage.getItem('user');
      if (!userStr) {
        navigate('/'); // Redirect to login if session missing
        return;
      }
      
      const user = JSON.parse(userStr);
      const result = await fetchDashboardData(user.id, user.userType_id);
      
      setData(result);
    } catch (err) {
      console.error("Dashboard Sync Error:", err);
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  }, [navigate]);

  useEffect(() => {
    // This guard ensures that even in Strict Mode, 
    // we handle the data flow gracefully.
    let isMounted = true;

    if (isMounted) {
      loadData(true);
    }

    return () => {
      isMounted = false;
    };
  }, [loadData]);

  if (loading) return (
    <div className="flex h-screen flex-col items-center justify-center bg-slate-50">
      <div className="h-12 w-12 animate-spin rounded-full border-4 border-q-green border-t-transparent"></div>
      <p className="mt-4 font-black text-slate-400 animate-pulse tracking-widest uppercase text-xs">
        Establishing Secure Connection...
      </p>
    </div>
  );

  return (
    <div className="min-h-screen bg-[#F8F9FA] p-4 md:p-8 lg:p-12">
      <div className="max-w-7xl mx-auto space-y-8 pb-24">
        
        {/* Header with Manual Refresh */}
        <div className="flex items-center justify-between">
          <DashboardHeader />
          <button 
            onClick={() => loadData(false)}
            disabled={isRefreshing}
            className={`p-3 rounded-2xl bg-white border border-slate-200 text-slate-400 hover:text-q-green transition-all shadow-sm ${isRefreshing ? 'animate-spin text-q-green' : ''}`}
          >
            <RefreshCw size={20} />
          </button>
        </div>
        
        {/* Shortcuts */}
        <QuickActions />

        {/* Dynamic Analytics (Sales, Stocks, Dues) */}
        <AnalyticsCards analytics={data.analytics} />

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Chart Section */}
          <div className="lg:col-span-2">
            <WeeklyChart trends={data.analytics?.weekly_trend || []} />
          </div>
          
          {/* Right Side: Transactions */}
          <div className="lg:col-span-1">
            <RecentSales sales={data.recentSales} />
          </div>
        </div>
      </div>

      {/* Floating Action Button (FAB) - Visible on Desktop/Mobile */}
      <button 
        onClick={() => navigate('/sales/new')}
        className="fixed bottom-8 right-6 md:right-12 bg-q-green hover:bg-q-green-dark text-white px-6 py-4 rounded-3xl shadow-2xl shadow-green-200 transition-all active:scale-95 flex items-center gap-3 z-50 group"
      >
        <Plus size={24} className="group-hover:rotate-90 transition-transform duration-300" />
        <span className="font-black text-sm tracking-wide">NEW SALE</span>
      </button>
    </div>
  );
};

export default DashboardPage;