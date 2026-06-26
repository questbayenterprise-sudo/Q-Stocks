import React from 'react';
import { ArrowRight } from 'lucide-react';

export default function Login() {
  return (
    // UNIFIED: bg-app-bg (Switches between light grey and dark slate)
    <div className="min-h-screen flex items-center justify-center bg-app-bg p-6 transition-colors duration-300">
      
      {/* UNIFIED: bg-card-bg, border-border-v */}
      <div className="max-w-md w-full rounded-[2.5rem] bg-card-bg p-10 shadow-2xl shadow-slate-900/5 border border-border-v transition-colors duration-300">
        
        {/* UNIFIED: text-text-h (Heading color) */}
        <div className="text-center mb-10">
          <h1 className="text-3xl font-black text-text-h tracking-tight uppercase">
            Sign In
          </h1>
          <p className="text-text-m text-xs font-bold mt-2 uppercase tracking-widest opacity-60">
            Enterprise Shop Management
          </p>
        </div>

        {/* Input Placeholder (Added for a complete feel) */}
        <div className="space-y-4 mb-8">
          <div className="space-y-2">
            <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Email Address</label>
            <input 
              type="email" 
              placeholder="name@company.com"
              className="w-full p-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-medium transition-all"
            />
          </div>
        </div>

        {/* Brand Button */}
        <button className="w-full group bg-q-green hover:bg-q-green-dark text-white py-4 rounded-2xl font-black shadow-lg shadow-q-green/20 transition-all flex items-center justify-center gap-2 active:scale-95">
          PROCEED
          <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
        </button>

        <p className="text-center mt-8 text-[10px] font-black text-text-m uppercase tracking-[0.3em] opacity-40">
          &copy; 2026 Questbay Enterprise
        </p>
      </div>
    </div>
  )
}