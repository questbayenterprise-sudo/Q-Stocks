import React from 'react';
import { ShoppingBasket, NotebookText, Warehouse, BarChart3 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const QuickActions = () => {
  const navigate = useNavigate();

  const actions = [
    { label: "Products", icon: ShoppingBasket, color: "bg-orange-50 text-orange-600", path: "/products" },
    { label: "Ledger", icon: NotebookText, color: "bg-blue-50 text-blue-600", path: "/customers" },
    { label: "Stocks", icon: Warehouse, color: "bg-teal-50 text-teal-600", path: "/stocks" },
    { label: "Reports", icon: BarChart3, color: "bg-purple-50 text-purple-600", path: "/reports" },
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      {actions.map((action, i) => (
        <button
          key={i}
          onClick={() => navigate(action.path)}
          className="flex flex-col items-center gap-3 p-6 bg-white rounded-[2rem] border border-slate-50 shadow-sm hover:shadow-md transition-all active:scale-95 group"
        >
          <div className={`p-4 rounded-2xl ${action.color} group-hover:scale-110 transition-transform`}>
            <action.icon size={24} />
          </div>
          <span className="text-sm font-bold text-slate-700">{action.label}</span>
        </button>
      ))}
    </div>
  );
};

export default QuickActions;