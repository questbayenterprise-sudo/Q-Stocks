import React from 'react';

const AnalyticsCards = ({ stats }) => {
  const cards = [
    { label: "Today Sales", value: `₹${stats.totalSales}`, color: "text-green-600" },
    { label: "Stock (kg)", value: `${stats.totalStockValue}`, color: "text-blue-600" },
    { label: "Pending Dues", value: `₹${stats.customerDues}`, color: "text-red-600" },
  ];

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
      {cards.map((card, i) => (
        <div key={i} className="rounded-3xl bg-white p-6 shadow-sm border border-slate-100">
          <p className="text-xs font-black text-slate-400 uppercase tracking-widest">{card.label}</p>
          <p className={`mt-2 text-2xl font-black ${card.color}`}>{card.value}</p>
        </div>
      ))}
    </div>
  );
};

export default AnalyticsCards;