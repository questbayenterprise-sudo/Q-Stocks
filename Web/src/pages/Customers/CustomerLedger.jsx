import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Receipt, Calendar } from 'lucide-react';
import { getLedger } from '../../api/customerApi';

const CustomerLedger = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [ledger, setLedger] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getLedger(id).then(data => {
      setLedger(data);
      setLoading(false);
    });
  }, [id]);

  return (
    <div className="min-h-screen bg-white">
      <div className="sticky top-0 bg-white border-b border-slate-100 p-6 flex items-center gap-4 z-10">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-slate-100 rounded-full">
          <ArrowLeft />
        </button>
        <h1 className="text-xl font-black">Transaction History</h1>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead className="bg-slate-50 text-slate-400 text-[10px] font-black uppercase tracking-widest">
            <tr>
              <th className="p-4 border-b">Date</th>
              <th className="p-4 border-b text-center">Weight</th>
              <th className="p-4 border-b text-center">Rate</th>
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
                <td className="p-4 border-b text-center text-slate-500">{row.weight > 0 ? `${row.weight} kg` : '-'}</td>
                <td className="p-4 border-b text-center text-slate-500">{row.rate > 0 ? `₹${row.rate}` : '-'}</td>
                <td className="p-4 border-b text-right font-bold text-blue-600">{row.debit_amount > 0 ? `₹${row.debit_amount}` : ''}</td>
                <td className="p-4 border-b text-right font-bold text-emerald-600">{row.credit_amount > 0 ? `₹${row.credit_amount}` : ''}</td>
                <td className="p-4 border-b text-right font-black text-slate-900 bg-slate-50/50">₹{row.running_balance}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default CustomerLedger;