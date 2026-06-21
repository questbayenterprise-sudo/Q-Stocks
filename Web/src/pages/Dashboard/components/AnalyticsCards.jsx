import React from 'react';

const AnalyticsCards = ({ analytics }) => {
  const cards = [
    { label: "Today Sales", value: `₹${analytics?.total_revenue || 0}`, color: "text-emerald-600" },
    { label: "Stock (kg)", value: `${analytics?.total_bookings || 0}`, color: "text-blue-600" },
    { label: "Pending Dues", value: `₹${analytics?.occupancy || 0}`, color: "text-red-600" },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {cards.map((card, i) => (
        <div key={i} className="bg-white p-6 rounded-[2rem] border border-slate-100 shadow-sm">
          <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">{card.label}</p>
          <p className={`text-2xl font-black mt-2 ${card.color}`}>{card.value}</p>
        </div>
      ))}
    </div>
  );
};

export default AnalyticsCards;