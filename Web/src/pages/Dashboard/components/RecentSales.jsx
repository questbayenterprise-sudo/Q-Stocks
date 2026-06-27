import { useNavigate } from 'react-router-dom'; 
import { ReceiptText, ChevronRight } from 'lucide-react'; // Added ChevronRight here

const RecentSales = ({ sales }) => {
  const navigate = useNavigate();

  return (
    // FIXED: Changed border-border-main to border-border-v
    <div className="bg-card-bg p-8 rounded-[2.5rem] border border-border-v shadow-sm h-full flex flex-col transition-colors duration-300">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h3 className="text-lg font-black text-text-h uppercase tracking-tight">Recent Sales</h3>
          <p className="text-[10px] font-bold text-text-m uppercase tracking-widest">Latest Transactions</p>
        </div>
        <button 
          onClick={() => navigate('/sales')} 
          className="text-xs font-bold text-q-green hover:underline flex items-center gap-1 transition-all active:scale-95"
        >
          VIEW ALL <ChevronRight size={14} />
        </button>
      </div>

      <div className="space-y-4 flex-1 overflow-y-auto custom-scrollbar">
        {sales && sales.length > 0 ? (
          sales.map((sale) => (
            <div 
              key={sale.id} 
              // FIXED: Changed hover:border-border-main to hover:border-border-v
              className="flex items-center gap-4 rounded-2xl bg-app-bg p-4 hover:brightness-95 dark:hover:brightness-110 transition-all cursor-pointer group border border-transparent hover:border-border-v"
            >
              <div className="w-10 h-10 rounded-full bg-card-bg flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform">
                <ReceiptText size={18} className="text-text-m group-hover:text-q-green" />
              </div>
              
              <div className="flex-1">
                <p className="text-sm font-bold text-text-h">Order #{sale.booking_ref}</p>
                <p className="text-[11px] text-text-m font-medium">{sale.user_name}</p>
              </div>
              
              <div className="text-right">
                <p className="font-black text-text-h text-sm">₹{sale.price}</p>
                <span className="text-[9px] font-black px-2 py-0.5 rounded-md bg-q-green/10 text-q-green uppercase tracking-tighter">
                  {sale.status}
                </span>
              </div>
            </div>
          ))
        ) : (
          <div className="flex flex-col items-center justify-center h-full py-10">
            {/* FIXED: Changed text-border-main to text-border-v */}
            <ReceiptText size={48} className="text-border-v mb-2" />
            <p className="text-sm font-bold text-text-m italic">No sales found today</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default RecentSales;