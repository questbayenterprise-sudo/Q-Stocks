import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, ArrowRight, Loader2, AlertCircle } from 'lucide-react';
import AuthHeader from '../../components/Auth/AuthHeader';
import { signIn } from '../../api/authApi';
import { APP_CONFIG } from '../../config/appConfig';

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [isValid, setIsValid] = useState(false);
  
  const navigate = useNavigate();

  useEffect(() => {
    const emailRegex = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    setIsValid(emailRegex.test(email.trim()));
  }, [email]);

  const handleSignIn = async (e) => {
    e.preventDefault();
    if (!isValid) return;
    setIsLoading(true);
    setError('');

    try {
      const result = await signIn(email.trim());
      if (result.success) {
        if (result.otp_skipped) {
          localStorage.setItem('user', JSON.stringify(result.data));
          navigate('/home');
        } else {
          navigate('/otp', { state: { email: email.trim() } });
        }
      } else {
        setError(result.message || 'Login failed.');
      }
    } catch (err) {
      setError('Backend unreachable. Ensure Golang server is running.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    // Responsive background padding: p-4 on mobile, p-0 on large screens
    <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50 p-4 md:p-0">
      
      {/* Container max-width for enterprise standard look */}
      <div className="w-full max-w-[420px] lg:max-w-[450px]">
        
        <AuthHeader />
        
        {/* Card: Mobile (smaller rounding/padding) vs Desktop (large rounding/padding) */}
        <div className="mt-8 md:mt-12 bg-white rounded-[2rem] md:rounded-[3rem] shadow-2xl shadow-slate-200/60 p-6 md:p-12 border border-white/50">
          <div className="mb-8 md:mb-10">
            <h2 className="text-xl md:text-2xl font-bold text-slate-800">Welcome Back</h2>
            <p className="text-slate-400 text-xs md:text-sm mt-1">Sign in to manage your shop and inventory.</p>
          </div>

          <form onSubmit={handleSignIn} className="space-y-6 md:space-y-8">
            <div className="space-y-2">
              <label className="text-xs md:text-sm font-bold text-slate-700 ml-1 uppercase tracking-wider">
                Email Address
              </label>
              <div className="relative">
                <div className="absolute left-4 top-1/2 -translate-y-1/2">
                  <Mail className={`w-5 h-5 transition-colors duration-300 ${isValid ? 'text-[#00A36C]' : 'text-slate-300'}`} />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="example@gmail.com"
                  className="w-full pl-12 pr-4 py-4 md:py-5 bg-slate-50 border-2 border-slate-100 rounded-2xl outline-none focus:border-[#00A36C] focus:bg-white transition-all font-medium text-slate-900"
                  required
                />
              </div>
            </div>

            {error && (
              <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-100 rounded-2xl text-red-600 text-xs md:text-sm font-bold animate-shake">
                <AlertCircle className="w-5 h-5 shrink-0" />
                <p>{error}</p>
              </div>
            )}

            <button
              type="submit"
              disabled={!isValid || isLoading}
              className="w-full bg-[#00A36C] hover:bg-[#008F5D] active:scale-[0.97] disabled:bg-slate-200 disabled:cursor-not-allowed text-white font-black py-4 md:py-5 rounded-2xl shadow-xl shadow-green-200/50 transition-all flex items-center justify-center gap-3"
            >
              {isLoading ? (
                <Loader2 className="w-6 h-6 animate-spin" />
              ) : (
                <>
                  SIGN IN
                  <ArrowRight className="w-5 h-5" />
                </>
              )}
            </button>
          </form>
        </div>

        <div className="mt-10 text-center">
          <p className="text-slate-400 text-[9px] md:text-[10px] font-black tracking-[0.3em] uppercase">
            &copy; 2026 {APP_CONFIG.companyName} • V{APP_CONFIG.version}
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;