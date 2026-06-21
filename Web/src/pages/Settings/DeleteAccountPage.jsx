import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, AlertTriangle, Trash2, Loader2, XCircle } from 'lucide-react';
import { deleteAccount } from '../../api/profileApi';

const DeleteAccountPage = () => {
  const navigate = useNavigate();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleFinalDelete = async () => {
    setLoading(true);
    const user = JSON.parse(localStorage.getItem('user'));
    
    try {
      const res = await deleteAccount(user.id);
      if (res.success) {
        // Clear session and redirect to login
        localStorage.clear();
        navigate('/', { replace: true });
      }
    } catch (err) {
      alert("Error deactivating account. Please try again.");
    } finally {
      setLoading(false);
      setIsModalOpen(false);
    }
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <div className="p-6 border-b border-slate-100 flex items-center gap-4">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-slate-50 rounded-full transition-colors">
          <ArrowLeft size={20} />
        </button>
        <h1 className="text-xl font-black text-slate-800">Account Settings</h1>
      </div>

      <div className="max-w-xl mx-auto p-8 pt-16 flex flex-col items-center text-center">
        <div className="w-24 h-24 bg-red-50 rounded-[2rem] flex items-center justify-center mb-8 text-red-500 shadow-xl shadow-red-100">
          <AlertTriangle size={48} strokeWidth={2.5} />
        </div>

        <h2 className="text-3xl font-black text-slate-900 tracking-tight">Deactivate Account?</h2>
        
        <p className="mt-6 text-slate-500 leading-relaxed font-medium">
          By deactivating, you will lose access to manage your <strong>Broiler Shop inventory, Sales logs, and Customer ledgers</strong>. 
          This action is permanent and your staff access will be revoked immediately.
        </p>

        <div className="w-full space-y-4 mt-12">
          <button 
            onClick={() => setIsModalOpen(true)}
            className="w-full bg-red-500 hover:bg-red-600 text-white font-black py-5 rounded-3xl shadow-xl shadow-red-100 transition-all active:scale-95 flex items-center justify-center gap-2"
          >
            <Trash2 size={20} /> DELETE MY ACCOUNT
          </button>
          
          <button 
            onClick={() => navigate(-1)}
            className="w-full py-4 text-slate-400 font-bold hover:text-slate-600 transition-colors"
          >
            I WANT TO STAY
          </button>
        </div>
      </div>

      {/* Final Confirmation Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-white w-full max-w-sm rounded-[2.5rem] p-10 shadow-2xl animate-in zoom-in-95 duration-300">
            <h3 className="text-xl font-black text-slate-900 text-center">One Last Thing...</h3>
            <p className="mt-4 text-slate-500 text-center text-sm font-medium">
              Are you 100% sure? All your session data will be wiped immediately.
            </p>

            <div className="mt-10 flex flex-col gap-3">
              <button 
                onClick={handleFinalDelete}
                disabled={loading}
                className="w-full bg-red-500 text-white font-black py-4 rounded-2xl flex items-center justify-center gap-2 hover:bg-red-600 transition-all"
              >
                {loading ? <Loader2 className="animate-spin" /> : "YES, DELETE"}
              </button>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="w-full bg-slate-100 text-slate-600 font-black py-4 rounded-2xl hover:bg-slate-200 transition-all"
              >
                NO, GO BACK
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DeleteAccountPage;