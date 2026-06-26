import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { User, Mail, Phone, MapPin, Edit3, Loader2 } from 'lucide-react';
import { getProfile } from '../../api/profileApi';

const ProfilePage = () => {
  const navigate = useNavigate();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const userStr = localStorage.getItem('user');
    if (!userStr) {
      navigate('/');
      return;
    }
    const user = JSON.parse(userStr);
    
    getProfile(user.id).then(data => {
      setProfile(data);
      setLoading(false);
    }).catch(err => {
      console.error("Profile Fetch Error:", err);
      setLoading(false);
    });
  }, [navigate]);

  if (loading) return (
    <div className="min-h-screen bg-app-bg flex items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <Loader2 className="animate-spin text-q-green w-10 h-10" />
        <p className="font-black text-text-m tracking-widest text-[10px] uppercase">Syncing Profile...</p>
      </div>
    </div>
  );

  if (!profile) return null;

  // Resolve dynamic avatar URL
  const baseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';
  const avatarUrl = profile.image_url 
    ? `${baseUrl}/${profile.image_url.replace(/\\/g, '/')}` 
    : `https://ui-avatars.com/api/?name=${profile.username}&background=00A36C&color=fff`;

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg p-4 md:p-10 transition-colors duration-300">
      <div className="max-w-4xl mx-auto">
        
        {/* Header Section */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-6 mb-10">
          <div>
            <h1 className="text-3xl font-black text-text-h tracking-tight leading-tight uppercase">
              Manager Profile
            </h1>
            <p className="text-text-m font-medium mt-1">Manage your personal and business identity.</p>
          </div>
          
          <button 
            onClick={() => navigate('/profile/edit')}
            className="flex items-center gap-2 bg-card-bg border border-border-v px-6 py-3 rounded-2xl font-bold text-text-h hover:bg-app-bg transition-all shadow-sm active:scale-95"
          >
            <Edit3 size={18} className="text-q-green" /> 
            <span>Edit Profile</span>
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          
          {/* Avatar Card - UNIFIED: bg-card-bg, border-border-v */}
          <div className="bg-card-bg p-8 rounded-[2.5rem] shadow-sm border border-border-v flex flex-col items-center text-center transition-colors duration-300">
            <div className="w-32 h-32 rounded-[2.5rem] bg-app-bg p-1 border-4 border-card-bg shadow-2xl shadow-slate-900/10 mb-6 overflow-hidden">
              <img 
                src={avatarUrl} 
                className="w-full h-full object-cover rounded-[2.2rem]" 
                alt="Avatar" 
              />
            </div>
            <h2 className="text-xl font-black text-text-h tracking-tight">{profile.username}</h2>
            
            {/* Role Badge - UNIFIED: bg-app-bg */}
            <span className="text-[10px] font-black bg-app-bg px-4 py-1.5 rounded-full text-text-m uppercase mt-3 tracking-[0.2em] border border-border-v">
              Shop Manager
            </span>
          </div>

          {/* Details Card - UNIFIED: bg-card-bg, border-border-v */}
          <div className="md:col-span-2 bg-card-bg p-6 md:p-10 rounded-[2.5rem] shadow-sm border border-border-v space-y-8 transition-colors duration-300">
            <InfoRow icon={<Mail />} label="Email Address" value={profile.email} />
            <div className="h-px bg-border-v w-full" />
            <InfoRow icon={<Phone />} label="Phone Number" value={profile.phoneno || 'Not provided'} />
            <div className="h-px bg-border-v w-full" />
            <InfoRow icon={<MapPin />} label="Assigned City" value={profile.city || 'Not set'} />
            
            {/* Bio Section */}
            <div className="pt-6 border-t border-border-v">
              <p className="text-[10px] font-black text-text-m uppercase tracking-widest mb-3">About / Bio</p>
              <p className="text-text-h leading-relaxed font-medium opacity-80 italic">
                "{profile.bio || "This manager hasn't added a bio yet."}"
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// --- Sub Component ---
const InfoRow = ({ icon, label, value }) => (
  <div className="flex items-start gap-5 group">
    {/* UNIFIED: bg-app-bg for icon box */}
    <div className="p-3.5 bg-app-bg rounded-2xl text-text-m group-hover:text-q-green transition-colors border border-border-v">
      {React.cloneElement(icon, { size: 20, strokeWidth: 2.5 })}
    </div>
    <div>
      <p className="text-[9px] font-black text-text-m uppercase tracking-[0.2em] mb-1">{label}</p>
      <p className="text-text-h font-bold text-lg leading-tight">{value}</p>
    </div>
  </div>
);

export default ProfilePage;