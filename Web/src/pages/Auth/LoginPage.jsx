import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
// Added sendOtp to the imports
import { Mail, ArrowRight, Loader2, AlertCircle, CheckCircle2 } from 'lucide-react';
import AuthHeader from '../../components/Auth/AuthHeader';
import { signIn, sendOtp } from '../../api/authApi'; // Import sendOtp here
import { APP_CONFIG } from '../../config/appConfig';

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false); 
  const [error, setError] = useState('');
  const [isValid, setIsValid] = useState(false);
  
  const navigate = useNavigate();

  // Email Validation Logic
  useEffect(() => {
    const emailRegex = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    setIsValid(emailRegex.test(email.trim()));
  }, [email]);

  const handleSignIn = async (e) => {
    e.preventDefault();
    if (!isValid) return;
    
    // CLEAR OLD SESSION IMMEDIATELY
    localStorage.removeItem('user'); 
    
    setIsLoading(true);
    setError('');

    try {
      const result = await signIn(email.trim());
debugger
      if (result.success) {
        // If Backend says skip OTP (Setting is OFF)
        if (result.otp_skipped) {
          localStorage.setItem('user', JSON.stringify(result.data));
          setIsSuccess(true);
          setTimeout(() => navigate('/home', { replace: true }), 1500);
        } 
        // If Backend says OTP is required (Setting is ON)
        else {
          // IMPORTANT: Your Go 'SignIn' method ALREADY sends the OTP.
          // You don't need to call sendOtp() again here unless your Go SignIn 
          // doesn't generate the code. 
          
          navigate('/otp', { state: { email: email.trim() } });
        }
      } else {
        // Handle backend "User not found" or "Inactive"
        setError(result.message || 'Access denied. Please check your email.');
        setIsLoading(false);
      }
    } catch (err) {
      // Handle Network or Server Crash errors
      setError('Server connection failed. Please try again later.');
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-app-bg p-4 md:p-0 transition-colors duration-300">
      <div className="w-full max-w-[420px] lg:max-w-[450px]">
        
        <AuthHeader />
        
        <div className="mt-8 md:mt-12 bg-card-bg rounded-[2.5rem] md:rounded-[3rem] shadow-2xl shadow-slate-900/5 p-6 md:p-12 border border-border-v relative overflow-hidden transition-colors duration-300">
          
          {/* Success Overlay */}
          {isSuccess && (
            <div className="absolute inset-0 bg-card-bg z-20 flex flex-col items-center justify-center p-8 text-center animate-in fade-in duration-500">
              <div className="w-20 h-20 bg-q-green/10 rounded-full flex items-center justify-center mb-4">
                <CheckCircle2 className="w-12 h-12 text-q-green animate-bounce" />
              </div>
              <h2 className="text-2xl font-black text-text-h">Welcome Back!</h2>
              <p className="text-text-m mt-2 font-medium">Redirecting to your dashboard...</p>
            </div>
          )}

          <div className="mb-8 md:mb-10 text-center md:text-left">
            <h2 className="text-2xl font-black text-text-h tracking-tight uppercase">Sign In</h2>
            <p className="text-text-m text-xs font-bold mt-1 uppercase tracking-widest opacity-60">
              Manage Shop & Inventory
            </p>
          </div>

          <form onSubmit={handleSignIn} className="space-y-6 md:space-y-8">
            <div className="space-y-2">
              <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">
                Registered Email
              </label>
              <div className="relative group">
                <div className="absolute left-4 top-1/2 -translate-y-1/2">
                  <Mail className={`w-5 h-5 transition-colors duration-300 ${isValid ? 'text-q-green' : 'text-text-m opacity-40'}`} />
                </div>
                <input
                  type="email"
                  value={email}
                  disabled={isLoading || isSuccess}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="manager@example.com"
                  className="w-full pl-12 pr-4 py-4 md:py-5 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-medium transition-all placeholder:text-text-m/30"
                  required
                />
              </div>
            </div>

            {error && (
              <div className="flex items-center gap-3 p-4 bg-red-500/10 border border-red-500/20 rounded-2xl text-red-500 text-xs font-bold animate-in zoom-in-95">
                <AlertCircle className="w-5 h-5 shrink-0" />
                <p>{error}</p>
              </div>
            )}

            <button
              type="submit"
              disabled={!isValid || isLoading || isSuccess}
              className="w-full bg-q-green hover:bg-q-green-dark active:scale-[0.97] disabled:bg-slate-300 disabled:cursor-not-allowed text-white font-black py-4 md:py-5 rounded-2xl shadow-xl shadow-q-green/20 transition-all flex items-center justify-center gap-3"
            >
              {isLoading ? (
                <Loader2 className="w-6 h-6 animate-spin" />
              ) : (
                <>
                  PROCEED
                  <ArrowRight className="w-5 h-5" />
                </>
              )}
            </button>
          </form>
        </div>

        <div className="mt-10 text-center">
          <p className="text-text-m text-[10px] font-black tracking-[0.3em] uppercase opacity-40">
            &copy; 2026 {APP_CONFIG.companyName}
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;