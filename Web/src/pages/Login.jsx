import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Loader2, Mail } from 'lucide-react';
import { signIn } from '../../api/authApi'; // Import your API call

export default function Login() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  // --- 1. AUTO-LOGIN CHECK ---
  // Runs every time the page loads
  useEffect(() => {
    const user = localStorage.getItem('user');
    if (user) {
      // If user exists in storage, go straight to dashboard
      navigate('/home', { replace: true });
    }
  }, [navigate]);

  // --- 2. LOGIN SUBMISSION ---
  const handleLogin = async (e) => {
    e.preventDefault();
    if (!email) return;

    setIsLoading(true);
    setError('');

    try {
      const result = await signIn(email.trim());

      if (result.success) {
        // --- 3. STORE IN BROWSER STORAGE ---
        // result.data should contain { id, username, userType_id, etc. }
        localStorage.setItem('user', JSON.stringify(result.data));
        
        // Handle OTP skip logic from your Go Backend
        if (result.otp_skipped) {
          navigate('/home', { replace: true });
        } else {
          navigate('/otp', { state: { email: email.trim() } });
        }
      } else {
        setError(result.message || 'Invalid email address');
      }
    } catch (err) {
      setError('Connection failed. Is the server running?');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-app-bg p-6 transition-colors duration-300">
      <div className="max-w-md w-full rounded-[2.5rem] bg-card-bg p-10 shadow-2xl shadow-slate-900/5 border border-border-v transition-colors duration-300">
        
        <div className="text-center mb-10">
          <h1 className="text-3xl font-black text-text-h tracking-tight uppercase">
            Sign In
          </h1>
          <p className="text-text-m text-xs font-bold mt-2 uppercase tracking-widest opacity-60">
            Enterprise Shop Management
          </p>
        </div>

        <form onSubmit={handleLogin} className="space-y-4 mb-8">
          <div className="space-y-2">
            <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">
              Email Address
            </label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m opacity-40" size={18} />
              <input 
                type="email" 
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="example@gmail.com"
                className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-medium transition-all"
              />
            </div>
          </div>

          {error && (
            <p className="text-red-500 text-[10px] font-bold uppercase text-center bg-red-500/10 py-2 rounded-xl">
              {error}
            </p>
          )}

          <button 
            type="submit"
            disabled={isLoading}
            className="w-full group bg-q-green hover:bg-q-green-dark text-white py-4 rounded-2xl font-black shadow-lg shadow-q-green/20 transition-all flex items-center justify-center gap-2 active:scale-95 disabled:opacity-50"
          >
            {isLoading ? (
              <Loader2 className="animate-spin" size={20} />
            ) : (
              <>
                PROCEED
                <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
              </>
            )}
          </button>
        </form>

        <p className="text-center mt-8 text-[10px] font-black text-text-m uppercase tracking-[0.3em] opacity-40">
          &copy; 2026 Questbay Enterprise
        </p>
      </div>
    </div>
  )
}