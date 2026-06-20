import React from 'react';

const WeeklyTrendChart = ({ trends }) => {
  const maxCount = Math.max(...trends.map(t => t.count));

  return (
    <div className="rounded-[2rem] bg-white p-8 shadow-sm border border-slate-100">
      <h3 className="text-lg font-bold text-slate-800 mb-8">Weekly Sales Trend</h3>
      <div className="flex h-48 items-end justify-between gap-2 px-2">
        {trends.map((t, i) => (
          <div key={i} className="flex flex-col items-center gap-3 group">
            <div 
              style={{ height: `${(t.count / maxCount) * 100}%` }}
              className="w-8 min-h-[10px] rounded-lg bg-linear-to-b from-q-green-light to-q-green transition-all group-hover:brightness-110"
            />
            <span className="text-[10px] font-bold text-slate-400 uppercase">{t.day}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default WeeklyTrendChart;