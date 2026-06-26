import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  ArrowLeft, Camera, User, Mail, Phone, 
  MapPin, Info, Loader2, CheckCircle2, Navigation 
} from 'lucide-react';
import { getProfile, updateProfile, getCities } from '../../api/profileApi';

const EditProfilePage = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showTrophy, setShowTrophy] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    phoneno: '',
    bio: '',
    city: ''
  });

  const [cities, setCities] = useState([]);
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user) return;

    // Load Data in parallel
    Promise.all([
      getProfile(user.id),
      getCities()
    ]).then(([profile, cityList]) => {
      setFormData({
        username: profile.username || '',
        email: profile.email || '',
        phoneno: profile.phoneno || '',
        bio: profile.bio || '',
        city: profile.city || ''
      });
      setCities(cityList);
      if (profile.image_url) {
        setImagePreview(`${import.meta.env.VITE_API_BASE_URL}/${profile.image_url.replace(/\\/g, '/')}`);
      }
      setLoading(false);
    }).catch(err => {
      console.error("Profile Load Error:", err);
      setLoading(false);
    });
  }, []);

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  const detectLocation = () => {
    if (!navigator.geolocation) return alert("Geolocation not supported");
    
    navigator.geolocation.getCurrentPosition(async (pos) => {
      try {
        const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.coords.latitude}&lon=${pos.coords.longitude}`);
        const data = await res.json();
        const detectedCity = data.address.city || data.address.town || data.address.village;
        if (detectedCity) setFormData({ ...formData, city: detectedCity });
      } catch (err) {
        alert("Could not determine city name");
      }
    });
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);

    const user = JSON.parse(localStorage.getItem('user'));
    const data = new FormData();
    data.append("id", user.id);
    data.append("username", formData.username);
    data.append("email", formData.email);
    data.append("phoneno", formData.phoneno);
    data.append("bio", formData.bio);
    data.append("city", formData.city);

    if (imageFile) data.append("image", imageFile);

    try {
      const res = await updateProfile(data);
      if (res.success) {
        setShowTrophy(true);
        const updatedUser = { ...user, username: formData.username };
        localStorage.setItem('user', JSON.stringify(updatedUser));
        setTimeout(() => navigate('/profile'), 2500);
      }
    } catch (err) {
      alert("Save failed");
    } finally {
      setSaving(false);
    }
  };

  if (loading) return (
    <div className="min-h-screen bg-app-bg flex items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <Loader2 className="animate-spin text-q-green w-10 h-10" />
        <p className="font-black text-text-m tracking-widest text-[10px] uppercase">Preparing Form...</p>
      </div>
    </div>
  );

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg pb-20 transition-colors duration-300">
      
      {/* Success Trophy Overlay - UNIFIED: bg-card-bg */}
      {showTrophy && (
        <div className="fixed inset-0 z-50 bg-card-bg flex flex-col items-center justify-center p-10 text-center animate-in fade-in duration-500">
          <img 
            src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3YxeXp6Znd4bmZyZ3RreHpxZ3RreHpxZ3RreHpxJmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/l0HlIDU8PZFn8vvDG/giphy.gif" 
            className="w-48 h-48 mb-6" alt="Trophy" 
          />
          <h2 className="text-3xl font-black text-text-h tracking-tight">Champion Updated! 🏆</h2>
          <p className="text-text-m mt-2 font-medium">Your manager profile is now match-ready.</p>
        </div>
      )}

      {/* Header - UNIFIED: bg-card-bg, border-border-v */}
      <div className="sticky top-0 bg-card-bg border-b border-border-v px-6 py-4 flex items-center justify-between z-30 transition-colors duration-300">
        <div className="flex items-center gap-4">
          <button 
            onClick={() => navigate(-1)} 
            className="p-2 bg-app-bg text-text-m hover:text-q-green rounded-full transition-all"
          >
            <ArrowLeft size={20}/>
          </button>
          <h1 className="text-lg font-black text-text-h tracking-tight">Edit Profile</h1>
        </div>
        <button 
          onClick={handleSave}
          disabled={saving}
          className="text-q-green font-black text-sm uppercase tracking-widest hover:bg-q-green/10 px-6 py-2 rounded-xl transition-all disabled:opacity-50"
        >
          {saving ? <Loader2 className="animate-spin" size={18}/> : "Save"}
        </button>
      </div>

      <form onSubmit={handleSave} className="max-w-2xl mx-auto p-6 space-y-8 mt-4">
        {/* Avatar Upload - UNIFIED: bg-app-bg, border-card-bg */}
        <div className="flex flex-col items-center">
          <div className="relative group">
            <div className="w-32 h-32 rounded-[2.5rem] bg-app-bg overflow-hidden border-4 border-card-bg shadow-2xl shadow-slate-900/10 transition-colors duration-300">
              {imagePreview ? (
                <img src={imagePreview} className="w-full h-full object-cover" alt="Avatar" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-text-m opacity-30">
                  <User size={48}/>
                </div>
              )}
            </div>
            <label className="absolute bottom-0 right-0 p-3 bg-q-green text-white rounded-2xl shadow-lg cursor-pointer hover:bg-q-green-dark transition-all active:scale-90">
              <Camera size={20} />
              <input type="file" accept="image/*" className="hidden" onChange={handleImageChange} />
            </label>
          </div>
        </div>

        {/* Inputs Section */}
        <div className="space-y-6">
          <InputField 
            label="Full Name" 
            icon={<User/>} 
            value={formData.username} 
            onChange={(v) => setFormData({...formData, username: v})} 
          />
          <InputField 
            label="Email Address" 
            icon={<Mail/>} 
            value={formData.email} 
            disabled 
          />
          <InputField 
            label="Phone Number" 
            icon={<Phone/>} 
            value={formData.phoneno} 
            onChange={(v) => setFormData({...formData, phoneno: v})} 
          />

          <div className="space-y-2">
            <div className="flex justify-between items-end">
                <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Assigned City</label>
                <button 
                  type="button" 
                  onClick={detectLocation}
                  className="text-[10px] font-bold text-q-green flex items-center gap-1 hover:underline"
                >
                  <Navigation size={12}/> AUTO DETECT
                </button>
            </div>
            <div className="relative">
              <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m opacity-50" size={18} />
              <input 
                list="city-list"
                value={formData.city}
                onChange={(e) => setFormData({...formData, city: e.target.value})}
                className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-bold transition-all placeholder:text-text-m/30"
                placeholder="Select or type city"
              />
              <datalist id="city-list">
                {cities.map((city, i) => <option key={i} value={city} />)}
              </datalist>
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Bio / Notes</label>
            <div className="relative">
              <Info className="absolute left-4 top-4 text-text-m opacity-50" size={18} />
              <textarea 
                rows="4"
                value={formData.bio}
                onChange={(e) => setFormData({...formData, bio: e.target.value})}
                className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-medium transition-all resize-none placeholder:text-text-m/30"
                placeholder="Tell us about yourself..."
              />
            </div>
          </div>
        </div>
      </form>
    </div>
  );
};

// --- Helper Component ---
const InputField = ({ label, icon, value, onChange, disabled }) => (
  <div className="space-y-2">
    <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">{label}</label>
    <div className="relative">
      <div className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m opacity-50">
        {React.cloneElement(icon, { size: 18 })}
      </div>
      <input 
        type="text"
        value={value}
        disabled={disabled}
        onChange={(e) => onChange(e.target.value)}
        className={`w-full pl-12 pr-4 py-4 rounded-2xl outline-none transition-all font-bold text-text-h 
          ${disabled 
            ? 'bg-app-bg/50 text-text-m cursor-not-allowed border-transparent' 
            : 'bg-app-bg border-2 border-border-v focus:border-q-green'}`}
      />
    </div>
  </div>
);

export default EditProfilePage;