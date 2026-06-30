import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, ChevronLeft, ChevronRight, Loader2 } from 'lucide-react';
import api from '../../api/axiosInstance'; // Assuming you use an axios instance

const CustomerLedger = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const [ledger, setLedger] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ total_pages: 1 });

  useEffect(() => {
    fetchLedger();
  }, [id, page]);

  const fetchLedger = async () => {
    setLoading(true);
    try {
      const response = await api.post('/GetCustomerLedger', {
        customer_id: id,
        page: page,
        limit: 10
      });
      setLedger(response.data.data);
      setPagination(response.data.pagination);
    } catch (err) {
      console.error("Failed to fetch ledger");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white">
      <div className="sticky top-0 bg-white border-b border-slate-100 p-6 flex items-center justify-between z-10">
        <div className="flex items-center gap-4">
          <button onClick={() => navigate(-1)} className="p-2 hover:bg-slate-100 rounded-full"><ArrowLeft /></button>
          <h1 className="text-xl font-black">Transaction History</h1>
        </div>
        
        {/* Pagination Controls in Header */}
        <div className="flex items-center gap-2">
           <span className="text-xs font-bold text-slate-400">Page {page} of {pagination.total_pages}</span>
           <button 
              disabled={page === 1}
              onClick={() => setPage(p => p - 1)}
              className="p-2 disabled:opacity-30 hover:bg-slate-100 rounded-lg"
           >
             <ChevronLeft size={20} />
           </button>
           <button 
              disabled={page >= pagination.total_pages}
              onClick={() => setPage(p => p + 1)}
              className="p-2 disabled:opacity-30 hover:bg-slate-100 rounded-lg"
           >
             <ChevronRight size={20} />
           </button>
        </div>
      </div>

      <div className="overflow-x-auto">
        {loading ? (
            <div className="flex justify-center py-20"><Loader2 className="animate-spin text-q-green" /></div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead className="bg-slate-50 text-slate-400 text-[10px] font-black uppercase tracking-widest">
              <tr>
                <th className="p-4 border-b">Date</th>
                <th className="p-4 border-b text-center">Weight</th>
                <th className="p-4 border-b text-right">Debit (+)</th>
                <th className="p-4 border-b text-right">Credit (-)</th>
                <th className="p-4 border-b text-right text-slate-800">Balance</th>
              </tr>
            </thead>
            <tbody className="text-sm">
              {ledger.map((row, i) => (
                <tr key={i} className="hover:bg-slate-50 transition-colors">
                  <td className="p-4 border-b font-medium text-slate-600">
                    {new Date(row.transaction_date).toLocaleDateString()}
                  </td>
                  <td className="p-4 border-b text-center">{row.weight > 0 ? `${row.weight} kg` : '-'}</td>
                  <td className="p-4 border-b text-right font-bold text-blue-600">{row.debit_amount > 0 ? `₹${row.debit_amount}` : ''}</td>
                  <td className="p-4 border-b text-right font-bold text-emerald-600">{row.credit_amount > 0 ? `₹${row.credit_amount}` : ''}</td>
                  <td className="p-4 border-b text-right font-black">₹{row.running_balance}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default CustomerLedger;