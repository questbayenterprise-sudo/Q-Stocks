import React from 'react';

const AnalyticsCards = ({ analytics }) => {
  const cards = [
    // Using 500-weight colors as they are more vibrant and visible in both light and dark backgrounds
    { label: "Today Sales", value: `₹${analytics?.total_revenue || 0}`, color: "text-emerald-500" },
    { label: "Stock (kg)", value: `${analytics?.total_bookings || 0}`, color: "text-blue-500" },
    { label: "Pending Dues", value: `₹${analytics?.occupancy || 0}`, color: "text-red-500" },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {cards.map((card, i) => (
        <div 
          key={i} 
          // UNIFIED: bg-card-bg and border-border-main
  className="bg-card-bg p-8 rounded-[2rem] border border-border-v shadow-sm transition-all duration-300"
        >
          {/* UNIFIED: text-text-muted */}
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-text-muted">
            {card.label}
          </p>
          
          {/* Dynamic Color + font weight */}
          <p className={`text-3xl font-black mt-2 tracking-tight ${card.color}`}>
            {card.value}
          </p>
          
          {/* Subtle indicator bar at the bottom of the card */}
          <div className="mt-4 w-12 h-1 rounded-full bg-slate-100 dark:bg-slate-800">
            <div className={`h-full rounded-full ${card.color.replace('text', 'bg')} w-1/2`} />
          </div>
        </div>
      ))}
    </div>
  );
};

export default AnalyticsCards;