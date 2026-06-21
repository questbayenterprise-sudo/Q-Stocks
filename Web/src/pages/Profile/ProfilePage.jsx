import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { User, Mail, Phone, MapPin, Edit3, Globe, Shield } from 'lucide-react';
import { getProfile } from '../../api/profileApi';

const ProfilePage = () => {
  const navigate = useNavigate();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user'));
    getProfile(user.id).then(data => {
      setProfile(data);
      setLoading(false);
    });
  }, []);

  if (loading) return <div className="p-20 text-center animate-pulse font-black text-slate-300">LOADING PROFILE...</div>;

  return (
    <div className="min-h-screen bg-slate-50 p-4 md:p-10">
      <div className="max-w-4xl mx-auto">
        <div className="flex justify-between items-end mb-8">
          <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight">Manager Profile</h1>
            <p className="text-slate-500 font-medium">Manage your personal and business identity.</p>
          </div>
          <button 
            onClick={() => navigate('/profile/edit')}
            className="flex items-center gap-2 bg-white border border-slate-200 px-6 py-3 rounded-2xl font-bold text-slate-700 hover:bg-slate-50 transition-all shadow-sm"
          >
            <Edit3 size={18} /> Edit Profile
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Avatar Card */}
          <div className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100 flex flex-col items-center text-center">
            <div className="w-32 h-32 rounded-[2.5rem] bg-q-green/10 p-1 border-4 border-white shadow-xl mb-6 overflow-hidden">
              <img 
                src={profile.image_url ? `${import.meta.env.VITE_API_BASE_URL}/${profile.image_url}` : `https://ui-avatars.com/api/?name=${profile.username}&background=00A36C&color=fff`} 
                className="w-full h-full object-cover rounded-[2.2rem]" 
                alt="Avatar" 
              />
            </div>
            <h2 className="text-xl font-black text-slate-800">{profile.username}</h2>
            <span className="text-[10px] font-black bg-slate-100 px-3 py-1 rounded-full text-slate-500 uppercase mt-2 tracking-widest">
              Shop Manager
            </span>
          </div>

          {/* Details Card */}
          <div className="md:col-span-2 bg-white p-10 rounded-[2.5rem] shadow-sm border border-slate-100 space-y-8">
            <InfoRow icon={<Mail />} label="Email Address" value={profile.email} />
            <InfoRow icon={<Phone />} label="Phone Number" value={profile.phoneno || 'Not provided'} />
            <InfoRow icon={<MapPin />} label="Assigned City" value={profile.city || 'Not set'} />
            <div className="pt-6 border-t border-slate-50">
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3">About / Bio</p>
              <p className="text-slate-600 leading-relaxed font-medium">
                {profile.bio || "This manager hasn't added a bio yet."}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const InfoRow = ({ icon, label, value }) => (
  <div className="flex items-start gap-4">
    <div className="p-3 bg-slate-50 rounded-xl text-slate-400">{React.cloneElement(icon, { size: 20 })}</div>
    <div>
      <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{label}</p>
      <p className="text-slate-800 font-bold text-lg">{value}</p>
    </div>
  </div>
);

export default ProfilePage;