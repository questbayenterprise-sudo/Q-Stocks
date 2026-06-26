import React from 'react';

const WeeklyChart = ({ trends }) => {
  // Logic to find max value for scaling the bars
  const maxCount = trends && trends.length > 0 
    ? Math.max(...trends.map(t => t.total_bookings || 0)) 
    : 1;

  return (
    // UNIFIED: bg-card-bg, border-border-v, text-text-h
    <div className="bg-card-bg p-8 rounded-[2.5rem] border border-border-v shadow-sm h-full flex flex-col transition-colors duration-300">
      <div className="mb-10">
        <h3 className="text-lg font-black text-text-h uppercase tracking-tight">Sales Trend</h3>
        {/* UNIFIED: text-text-m (Muted text) */}
        <p className="text-[10px] font-bold text-text-m uppercase tracking-widest mt-1">
          Activity per day
        </p>
      </div>

      <div className="flex-1 flex items-end justify-between gap-2 px-2 min-h-[220px]">
        {trends && trends.length > 0 ? (
          trends.map((t, i) => {
            const barHeight = ((t.total_bookings || 0) / (maxCount || 1)) * 100;
            
            return (
              <div key={i} className="flex flex-col items-center gap-3 flex-1 group">
                {/* Value tooltip shown on hover */}
                <span className="text-[10px] font-black text-q-green opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  {t.total_bookings}
                </span>

                <div 
                  style={{ height: `${Math.max(barHeight, 6)}%` }}
                  // UNIFIED: Shadow-q for consistent glow
                  className="w-full max-w-[32px] rounded-t-xl bg-linear-to-b from-emerald-400 to-q-green shadow-q transition-all duration-500 group-hover:brightness-110 group-hover:scale-x-110 origin-bottom"
                />
                
                {/* UNIFIED: text-text-m for day labels */}
                <span className="text-[10px] font-black text-text-m uppercase tracking-tighter">
                  {t.day_name}
                </span>
              </div>
            );
          })
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center py-10">
            {/* Empty state styling */}
            <div className="w-full h-1 bg-border-v rounded-full mb-4 opacity-50" />
            <p className="text-sm font-bold text-text-m italic opacity-50">
              No data available for this period
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default WeeklyChart;