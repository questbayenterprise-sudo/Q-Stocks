import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, Camera, MapPin, Store, Info, Loader2, CheckCircle2 } from 'lucide-react';
import { saveShop } from '../../api/shopApi';

const AddShopPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const existingShop = location.state?.shop;

  const [formData, setFormData] = useState({
    id: existingShop?.id || "0",
    name: existingShop?.name || "",
    location: existingShop?.location || "",
    description: existingShop?.description || "",
  });

  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (existingShop?.image_url) {
      const baseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';
      setImagePreview(`${baseUrl}/${existingShop.image_url.replace(/\\/g, '/')}`);
    }
  }, [existingShop]);

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    const userStr = localStorage.getItem('user');
    if (!userStr) return navigate('/');
    const user = JSON.parse(userStr);
    
    const data = new FormData();
    data.append("id", formData.id);
    data.append("name", formData.name);
    data.append("location", formData.location);
    data.append("description", formData.description);
    data.append("userid", user.id);

    if (imageFile) {
      data.append("image", imageFile);
    } else if (existingShop?.image_url) {
      data.append("existing_image", existingShop.image_url);
    }

    try {
      const result = await saveShop(data);
      if (result.success) {
        setSuccess(true);
        setTimeout(() => navigate('/shops'), 1500);
      }
    } catch (err) {
      alert("Failed to save shop. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    // UNIFIED: bg-app-bg
    <div className="min-h-screen bg-app-bg pb-20 transition-colors duration-300">
      
      {/* Header - UNIFIED: bg-card-bg, border-border-v */}
      <div className="bg-card-bg border-b border-border-v sticky top-0 z-30 transition-colors duration-300">
        <div className="max-w-3xl mx-auto px-6 py-4 flex items-center gap-4">
          <button 
            onClick={() => navigate(-1)} 
            className="p-2 bg-app-bg text-text-m hover:text-q-green rounded-full transition-all"
          >
            <ArrowLeft size={20} />
          </button>
          <h1 className="text-xl font-black text-text-h tracking-tight leading-tight">
            {existingShop ? 'Edit Branch' : 'Add New Branch'}
          </h1>
        </div>
      </div>

      <div className="max-w-3xl mx-auto p-6">
        <form onSubmit={handleSubmit} className="space-y-8">
          
          {/* Image Picker - UNIFIED: bg-card-bg, border-border-v */}
          <div className="relative group w-full h-64 bg-card-bg rounded-[2.5rem] border-2 border-dashed border-border-v overflow-hidden flex items-center justify-center transition-all hover:border-q-green shadow-sm">
            {imagePreview ? (
              <img src={imagePreview} alt="Preview" className="w-full h-full object-cover" />
            ) : (
              <div className="text-center">
                <div className="w-16 h-16 bg-app-bg rounded-2xl flex items-center justify-center mx-auto mb-3 border border-border-v">
                  <Camera className="text-text-m opacity-50" size={32} />
                </div>
                <p className="text-text-m font-black uppercase tracking-widest text-[10px]">Upload Shop Photo</p>
              </div>
            )}
            <input 
              type="file" 
              accept="image/*" 
              onChange={handleImageChange}
              className="absolute inset-0 opacity-0 cursor-pointer" 
            />
            <div className="absolute bottom-4 right-4 bg-q-green text-white p-3 rounded-2xl shadow-lg opacity-0 group-hover:opacity-100 transition-opacity">
              <Camera size={20} />
            </div>
          </div>

          {/* Form Fields - UNIFIED: bg-card-bg, border-border-v */}
          <div className="bg-card-bg rounded-[2.5rem] p-8 shadow-xl shadow-slate-900/5 border border-border-v space-y-6 transition-colors duration-300">
            
            {/* Branch Name */}
            <div className="space-y-2">
              <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Branch Name</label>
              <div className="relative">
                <Store className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m opacity-50" size={18} />
                <input 
                  type="text"
                  required
                  placeholder="e.g. Mannargudi Main Branch"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-bold transition-all placeholder:text-text-m/30"
                />
              </div>
            </div>

            {/* Location */}
            <div className="space-y-2">
              <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Location / Area</label>
              <div className="relative">
                <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m opacity-50" size={18} />
                <input 
                  type="text"
                  required
                  placeholder="Street, City, District"
                  value={formData.location}
                  onChange={(e) => setFormData({...formData, location: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-bold transition-all placeholder:text-text-m/30"
                />
              </div>
            </div>

            {/* Description */}
            <div className="space-y-2">
              <label className="text-[10px] font-black text-text-m uppercase tracking-[0.2em] ml-2">Short Description</label>
              <div className="relative">
                <Info className="absolute left-4 top-4 text-text-m opacity-50" size={18} />
                <textarea 
                  rows="3"
                  placeholder="Briefly describe this shop branch..."
                  value={formData.description}
                  onChange={(e) => setFormData({...formData, description: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-app-bg border-2 border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-medium transition-all resize-none placeholder:text-text-m/30"
                ></textarea>
              </div>
            </div>
          </div>

          {/* Action Button */}
          <div className="pt-4">
            <button 
              type="submit"
              disabled={loading || success}
              className="w-full bg-q-green hover:bg-q-green-dark text-white font-black py-5 rounded-[1.5rem] shadow-xl shadow-q-green/20 transition-all flex items-center justify-center gap-3 active:scale-[0.98] disabled:bg-slate-300 disabled:cursor-not-allowed"
            >
              {loading ? (
                <Loader2 className="animate-spin w-6 h-6" />
              ) : success ? (
                <CheckCircle2 size={24} className="animate-in zoom-in" />
              ) : (
                'SAVE SHOP DETAILS'
              )}
            </button>
          </div>

        </form>
      </div>
    </div>
  );
};

export default AddShopPage;