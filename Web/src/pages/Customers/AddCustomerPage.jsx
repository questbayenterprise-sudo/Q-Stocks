import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, User, Phone, Save, Loader2 } from 'lucide-react';
import { createCustomer } from '../../api/customerApi';

const AddCustomerPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const existingCustomer = location.state?.customer; // For edit mode

  const [name, setName] = useState(existingCustomer?.name || '');
  const [phone, setPhone] = useState(existingCustomer?.phone || '');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await createCustomer({ name, phone });
      navigate('/customers'); // Go back to list
    } catch (err) {
      alert("Failed to save customer");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white">
      <div className="p-6 border-b border-slate-100 flex items-center gap-4">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-slate-100 rounded-full">
          <ArrowLeft />
        </button>
        <h1 className="text-xl font-black">
          {existingCustomer ? 'Edit Customer' : 'New Customer'}
        </h1>
      </div>

      <form onSubmit={handleSubmit} className="p-8 max-w-xl mx-auto space-y-6">
        <div className="space-y-2">
          <label className="text-sm font-bold text-slate-700">Full Name</label>
          <div className="relative">
            <User className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
            <input 
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-slate-100 rounded-2xl outline-none focus:border-q-green"
              placeholder="Enter customer name"
              required
            />
          </div>
        </div>

        <div className="space-y-2">
          <label className="text-sm font-bold text-slate-700">Phone Number</label>
          <div className="relative">
            <Phone className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
            <input 
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-slate-100 rounded-2xl outline-none focus:border-q-green"
              placeholder="Optional"
            />
          </div>
        </div>

        <button 
          type="submit"
          disabled={loading}
          className="w-full bg-q-green text-white font-black py-4 rounded-2xl shadow-lg flex items-center justify-center gap-2"
        >
          {loading ? <Loader2 className="animate-spin" /> : <><Save size={20}/> SAVE CUSTOMER</>}
        </button>
      </form>
    </div>
  );
};

export default AddCustomerPage;