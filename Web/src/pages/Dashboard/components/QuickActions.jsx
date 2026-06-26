import React from 'react';
import { ShoppingBasket, NotebookText, Warehouse, BarChart3 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const QuickActions = () => {
  const navigate = useNavigate();

  const actions = [
    // Using 500-weight colors with opacity (applied in JSX) for a unified look
    { label: "Products", icon: ShoppingBasket, color: "text-orange-500", bgColor: "bg-orange-500/10", path: "/products" },
    { label: "Ledger", icon: NotebookText, color: "text-blue-500", bgColor: "bg-blue-500/10", path: "/customers" },
    { label: "Stocks", icon: Warehouse, color: "text-teal-500", bgColor: "bg-teal-500/10", path: "/stocks" },
    { label: "Reports", icon: BarChart3, color: "text-purple-500", bgColor: "bg-purple-500/10", path: "/reports" },
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 transition-colors duration-300">
      {actions.map((action, i) => (
        <button
          key={i}
          onClick={() => navigate(action.path)}
          // UNIFIED: bg-card-bg, border-border-v, hover:bg-app-bg
          className="flex flex-col items-center gap-3 p-6 bg-card-bg rounded-[2rem] border border-border-v shadow-sm hover:shadow-md hover:bg-app-bg transition-all active:scale-95 group"
        >
          {/* Icon Container with dynamic opacity background */}
          <div className={`p-4 rounded-2xl ${action.bgColor} ${action.color} group-hover:scale-110 transition-transform duration-300`}>
            <action.icon size={26} strokeWidth={2.5} />
          </div>
          
          {/* UNIFIED: text-text-h (High contrast text) */}
          <span className="text-sm font-black text-text-h tracking-tight">
            {action.label}
          </span>
        </button>
      ))}
    </div>
  );
};

export default QuickActions;