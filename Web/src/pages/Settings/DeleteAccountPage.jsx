import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, AlertTriangle, Trash2, Loader2 } from 'lucide-react';
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
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg transition-colors duration-300">
      
      {/* Header - UNIFIED: bg-card-bg, border-border-v */}
      <div className="p-6 bg-card-bg border-b border-border-v flex items-center gap-4 transition-colors duration-300">
        <button 
          onClick={() => navigate(-1)} 
          className="p-2 bg-app-bg text-text-m hover:text-red-500 rounded-full transition-all"
        >
          <ArrowLeft size={20} />
        </button>
        <h1 className="text-xl font-black text-text-h tracking-tight">Account Settings</h1>
      </div>

      <div className="max-w-xl mx-auto p-8 pt-16 flex flex-col items-center text-center">
        {/* Warning Icon Container - UNIFIED: bg-red-500/10 (Opacity based) */}
        <div className="w-24 h-24 bg-red-500/10 rounded-[2.5rem] flex items-center justify-center mb-8 text-red-500 shadow-xl shadow-red-500/5 border border-red-500/20">
          <AlertTriangle size={48} strokeWidth={2.5} />
        </div>

        {/* UNIFIED: text-text-h */}
        <h2 className="text-3xl font-black text-text-h tracking-tight">
          Deactivate Account?
        </h2>
        
        {/* UNIFIED: text-text-m */}
        <p className="mt-6 text-text-m leading-relaxed font-medium">
          By deactivating, you will lose access to manage your 
          <strong className="text-text-h mx-1">Broiler Shop inventory, Sales logs, and Customer ledgers</strong>. 
          This action is permanent and your staff access will be revoked immediately.
        </p>

        <div className="w-full space-y-4 mt-12">
          <button 
            onClick={() => setIsModalOpen(true)}
            className="w-full bg-red-500 hover:bg-red-600 text-white font-black py-5 rounded-[1.5rem] shadow-xl shadow-red-500/20 transition-all active:scale-95 flex items-center justify-center gap-2"
          >
            <Trash2 size={20} /> DELETE MY ACCOUNT
          </button>
          
          <button 
            onClick={() => navigate(-1)}
            // UNIFIED: text-text-m
            className="w-full py-4 text-text-m font-bold hover:text-text-h transition-colors uppercase text-[10px] tracking-widest"
          >
            I WANT TO STAY
          </button>
        </div>
      </div>

      {/* Final Confirmation Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-300">
          {/* UNIFIED: bg-card-bg, border-border-v */}
          <div className="bg-card-bg w-full max-w-sm rounded-[2.5rem] p-10 shadow-2xl border border-border-v animate-in zoom-in-95 duration-300">
            <h3 className="text-xl font-black text-text-h text-center">One Last Thing...</h3>
            <p className="mt-4 text-text-m text-center text-sm font-medium">
              Are you 100% sure? All your session data will be wiped immediately.
            </p>

            <div className="mt-10 flex flex-col gap-3">
              <button 
                onClick={handleFinalDelete}
                disabled={loading}
                className="w-full bg-red-500 text-white font-black py-4 rounded-2xl flex items-center justify-center gap-2 hover:bg-red-600 transition-all active:scale-95 disabled:opacity-50"
              >
                {loading ? <Loader2 className="animate-spin" /> : "YES, DELETE"}
              </button>
              <button 
                onClick={() => setIsModalOpen(false)}
                // UNIFIED: bg-app-bg, text-text-h
                className="w-full bg-app-bg text-text-h font-black py-4 rounded-2xl border border-border-v hover:brightness-95 transition-all"
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