import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Loader2, ShieldCheck, ArrowLeft } from 'lucide-react';
import { verifyOtp, sendOtp } from '../../api/authApi';
import AuthHeader from '../../components/Auth/AuthHeader';

const OtpPage = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const email = location.state?.email || "";
  
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleVerify = async (e) => {
    e.preventDefault();
    if (otp.length < 6) return;
    setLoading(true);

    try {
      debugger
      const result = await verifyOtp(email, otp);
      if (result.success) {
        localStorage.setItem('user', JSON.stringify(result.data));
        navigate('/home');
      } else {
        setError(result.message || 'Invalid OTP');
      }
    } catch (err) {
      setError('Verification failed.');
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setOtp('');
    setError('New code sent to your email.');
    await sendOtp(email);
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50 p-4">
      <div className="w-full max-w-[420px]">
        <AuthHeader />
        
        <div className="mt-10 bg-white rounded-[2.5rem] shadow-2xl p-10 border border-slate-100">
          <button onClick={() => navigate(-1)} className="mb-6 flex items-center gap-2 text-slate-400 font-bold text-xs hover:text-q-green transition-colors">
            <ArrowLeft size={16} /> BACK
          </button>

          <h2 className="text-2xl font-bold text-slate-800">Verify Identity</h2>
          <p className="text-slate-500 text-sm mt-1">Enter the code sent to <span className="font-bold text-slate-700">{email}</span></p>

          <form onSubmit={handleVerify} className="mt-8 space-y-6">
            <input
              type="text"
              maxLength="6"
              value={otp}
              onChange={(e) => setOtp(e.target.value.replace(/\D/g, ""))}
              placeholder="000000"
              className="w-full text-center text-4xl font-black tracking-[0.5em] py-5 bg-slate-50 border-2 border-slate-100 rounded-2xl outline-none focus:border-q-green focus:bg-white transition-all"
            />

            {error && <p className="text-red-500 text-xs font-bold text-center">{error}</p>}

            <button
              type="submit"
              disabled={otp.length < 6 || loading}
              className="w-full bg-q-green hover:bg-q-green-dark text-white font-black py-4 rounded-2xl shadow-lg disabled:opacity-50 transition-all flex items-center justify-center gap-2"
            >
              {loading ? <Loader2 className="animate-spin" /> : <><ShieldCheck size={20}/> VERIFY OTP</>}
            </button>
          </form>

          <div className="mt-8 text-center">
            <button onClick={handleResend} className="text-q-green font-bold text-sm hover:underline">
              Resend Code
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OtpPage;