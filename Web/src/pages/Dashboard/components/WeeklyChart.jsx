import React from 'react';

const WeeklyChart = ({ trends }) => {
  // Logic to find max value for scaling the bars
  const maxCount = trends && trends.length > 0 
    ? Math.max(...trends.map(t => t.total_bookings || 0)) 
    : 1;

  return (
    <div className="bg-white p-8 rounded-[2.5rem] border border-slate-100 shadow-sm h-full">
      <div className="mb-10">
        <h3 className="text-lg font-black text-slate-800">Sales Trend</h3>
        <p className="text-xs font-bold text-slate-400 uppercase tracking-widest mt-1">Activity per day</p>
      </div>

      <div className="flex h-56 items-end justify-between gap-2 px-2">
        {trends && trends.map((t, i) => {
          const barHeight = ((t.total_bookings || 0) / (maxCount || 1)) * 100;
          
          return (
            <div key={i} className="flex flex-col items-center gap-3 flex-1 group">
              <div 
                style={{ height: `${Math.max(barHeight, 4)}%` }}
                className="w-full max-w-[32px] rounded-t-xl bg-linear-to-b from-emerald-400 to-q-green shadow-lg shadow-green-100 transition-all group-hover:brightness-110"
              />
              <span className="text-[10px] font-black text-slate-400 uppercase tracking-tighter">
                {t.day_name}
              </span>
            </div>
          );
        })}
      </div>
      
      {(!trends || trends.length === 0) && (
        <div className="flex h-48 items-center justify-center text-slate-300 font-bold italic">
          No data available
        </div>
      )}
    </div>
  );
};

export default WeeklyChart;