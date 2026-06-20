import React, { useEffect, useState } from 'react';
import { Plus } from 'lucide-react';

// Core Dashboard Components
import DashboardHeader from './components/DashboardHeader';
import QuickActions from './components/QuickActions';
import AnalyticsCards from './components/AnalyticsCards';
import WeeklyTrendChart from './components/WeeklyTrendChart';
import RecentSalesList from './components/RecentSalesList';

const DashboardPage = () => {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate initial data fetch
    const timer = setTimeout(() => {
      setLoading(false);
    }, 800);
    return () => clearTimeout(timer);
  }, []);

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-slate-50">
        <div className="flex flex-col items-center gap-4">
          <div className="h-12 w-12 animate-spin rounded-full border-4 border-q-green border-t-transparent"></div>
          <p className="font-bold text-slate-400 animate-pulse">Loading Dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F8F9FA] pb-24">
      <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        
        {/* Top Section: Profile & Notifications */}
        <DashboardHeader />
        
        <main className="mt-8 space-y-8">
          {/* Navigation Shortcuts */}
          <QuickActions />
          
          {/* Primary Statistics */}
          <AnalyticsCards stats={{
            totalSales: 12500,
            totalStockValue: 450.5,
            customerDues: 8400
          }} />

          {/* Graphical Data & Tables */}
          <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
            <div className="lg:col-span-2">
              <WeeklyTrendChart trends={[
                { day: 'Mon', count: 12 }, { day: 'Tue', count: 15 },
                { day: 'Wed', count: 8 }, { day: 'Thu', count: 20 },
                { day: 'Fri', count: 18 }, { day: 'Sat', count: 25 },
                { day: 'Sun', count: 14 }
              ]} />
            </div>
            
            <div className="lg:col-span-1">
              <RecentSalesList sales={[
                { id: 1, orderRef: '101', customerName: 'Raja Kumar', amount: 1200 },
                { id: 2, orderRef: '102', customerName: 'Sundar M', amount: 850 },
                { id: 3, orderRef: '103', customerName: 'Anitha Stores', amount: 3200 },
              ]} />
            </div>
          </div>
        </main>
      </div>

      {/* Floating Action Button (FAB) */}
      <button className="fixed right-6 bottom-6 flex items-center gap-2 rounded-full bg-q-green px-6 py-4 font-black text-white shadow-2xl shadow-q-green/40 hover:bg-q-green-dark transition-all active:scale-90 group">
        <Plus className="h-6 w-6 group-hover:rotate-90 transition-transform duration-300" />
        <span className="hidden sm:inline">NEW SALE</span>
      </button>
    </div>
  );
};

export default DashboardPage;