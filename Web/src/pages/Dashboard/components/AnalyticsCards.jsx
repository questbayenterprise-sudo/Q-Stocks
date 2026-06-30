import React from 'react';

const AnalyticsCards = ({ analytics }) => {
  const cards = [
    { 
      label: "Today Sales", 
      value: `₹${analytics?.today_sales || 0}`, 
      color: "text-emerald-500" 
    },
    { 
      label: "Weekly Sales", 
      value: `₹${analytics?.weekly_sales || 0}`, 
      color: "text-cyan-500" 
    },
    { 
      label: "Monthly Sales", 
      value: `₹${analytics?.monthly_sales || 0}`, 
      color: "text-indigo-500" 
    },
    { 
      label: "Stock (kg)", 
      value: `${analytics?.total_stock || 0}`, 
      color: "text-blue-500" 
    },
    { 
      label: "Pending Dues", 
      value: `₹${analytics?.total_pending || 0}`, 
      color: "text-red-500" 
    },
  ];

  return (
    // Changed grid-cols to handle 5 cards: 1 on mobile, 2 on tablet, 5 on desktop
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
      {cards.map((card, i) => (
        <div 
          key={i} 
          className="bg-card-bg p-6 rounded-[2rem] border border-border-v shadow-sm transition-all duration-300 hover:scale-[1.02]"
        >
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-text-muted">
            {card.label}
          </p>
          
          <p className={`text-2xl font-black mt-2 tracking-tight ${card.color}`}>
            {card.value}
          </p>
          
          <div className="mt-4 w-12 h-1 rounded-full bg-slate-100 dark:bg-slate-800">
            <div className={`h-full rounded-full ${card.color.replace('text', 'bg')} w-1/2`} />
          </div>
        </div>
      ))}
    </div>
  );
};

export default AnalyticsCards;