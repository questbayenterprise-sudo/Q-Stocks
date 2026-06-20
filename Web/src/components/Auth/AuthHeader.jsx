import React from 'react';
import { APP_CONFIG } from '../../config/appConfig';

const AuthHeader = () => {
  return (
    <div className="flex flex-col items-center animate-in fade-in slide-in-from-top-4 duration-700">
      {/* Dynamic Logo Container: Responsive sizes */}
      <div className="w-24 h-24 md:w-32 md:h-32 bg-white rounded-[2rem] shadow-xl shadow-emerald-100 flex items-center justify-center mb-6 overflow-hidden border border-slate-50">
        <img 
          src={APP_CONFIG.logoPath} 
          alt={APP_CONFIG.appName}
          className="w-full h-full object-contain p-4"
          // Fallback if image fails to load
          onError={(e) => {
            e.target.src = "https://ui-avatars.com/api/?name=QS&background=00A36C&color=fff";
          }}
        />
      </div>
      
      <h1 className="text-3xl md:text-4xl font-black text-slate-900 tracking-tight">
        {APP_CONFIG.appName}
      </h1>
      <p className="text-slate-500 font-medium mt-1 text-sm md:text-base">
        Enterprise Shop Management
      </p>
    </div>
  );
};

export default AuthHeader;