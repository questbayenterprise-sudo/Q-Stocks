import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';

// Unified Imports
import DashboardHeader from './components/DashboardHeader';
import QuickActions from './components/QuickActions';
import AnalyticsCards from './components/AnalyticsCards';
import WeeklyChart from './components/WeeklyChart';
import RecentSales from './components/RecentSales';
import { fetchDashboardData } from '../../api/dashboardApi';

const DashboardPage = () => {
  const [data, setData] = useState({ analytics: null, recentSales: [] });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user) return;

    fetchDashboardData(user.id, user.userType_id).then(res => {
      setData(res);
      setLoading(false);
    });
  }, []);

  if (loading) return (
    <div className="flex h-screen items-center justify-center bg-slate-50 font-black text-slate-300 tracking-widest">
      SYNCING...
    </div>
  );

  return (
    <div className="min-h-screen bg-[#F8F9FA] p-6 lg:p-12">
      <div className="max-w-7xl mx-auto space-y-8 pb-20">
        <DashboardHeader />
        
        <QuickActions />

        <AnalyticsCards analytics={data.analytics} />

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <WeeklyChart trends={data.analytics?.weekly_trend || []} />
          </div>
          <div className="lg:col-span-1">
            <RecentSales sales={data.recentSales} />
          </div>
        </div>
      </div>

      {/* Mobile FAB */}
      <button className="fixed bottom-24 right-6 md:right-12 bg-q-green text-white p-4 rounded-full shadow-2xl active:scale-90 transition-transform md:hidden">
        <Plus size={32} />
      </button>
    </div>
  );
};

export default DashboardPage;