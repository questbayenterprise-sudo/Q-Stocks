import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, Camera, MapPin, Store, Info, Loader2, CheckCircle2 } from 'lucide-react';
import { saveShop } from '../../api/shopApi';

const AddShopPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const existingShop = location.state?.shop; // Data passed from the List page for editing

  // Form State
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

  // Set initial preview if editing
  useEffect(() => {
    if (existingShop?.image_url) {
      const baseUrl = import.meta.env.VITE_API_BASE_URL;
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

    const user = JSON.parse(localStorage.getItem('user'));
    
    // Construct Multi-part Form Data (Required for Go backend)
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
    <div className="min-h-screen bg-slate-50 pb-20">
      {/* Top Navigation Bar */}
      <div className="bg-white border-b border-slate-100 sticky top-0 z-30">
        <div className="max-w-3xl mx-auto px-6 py-4 flex items-center gap-4">
          <button onClick={() => navigate(-1)} className="p-2 hover:bg-slate-50 rounded-full transition-colors">
            <ArrowLeft size={20} className="text-slate-600" />
          </button>
          <h1 className="text-xl font-black text-slate-800 tracking-tight">
            {existingShop ? 'Edit Branch' : 'Add New Branch'}
          </h1>
        </div>
      </div>

      <div className="max-w-3xl mx-auto p-6">
        <form onSubmit={handleSubmit} className="space-y-8">
          
          {/* Image Picker Section */}
          <div className="relative group w-full h-64 bg-white rounded-[2rem] border-2 border-dashed border-slate-200 overflow-hidden flex items-center justify-center transition-all hover:border-q-green">
            {imagePreview ? (
              <img src={imagePreview} alt="Preview" className="w-full h-full object-cover" />
            ) : (
              <div className="text-center">
                <div className="w-16 h-16 bg-slate-50 rounded-2xl flex items-center justify-center mx-auto mb-3">
                  <Camera className="text-slate-300" size={32} />
                </div>
                <p className="text-slate-400 font-bold text-sm">Upload Shop Photo</p>
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

          {/* Form Fields */}
          <div className="bg-white rounded-[2.5rem] p-8 shadow-xl shadow-slate-200/50 border border-white space-y-6">
            <div className="space-y-2">
              <label className="text-sm font-black text-slate-700 uppercase tracking-widest ml-1">Branch Name</label>
              <div className="relative">
                <Store className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-5 h-5" />
                <input 
                  type="text"
                  required
                  placeholder="e.g. Mannargudi Main Branch"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green focus:bg-white transition-all font-medium"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-black text-slate-700 uppercase tracking-widest ml-1">Location / Area</label>
              <div className="relative">
                <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-5 h-5" />
                <input 
                  type="text"
                  required
                  placeholder="Street, City, District"
                  value={formData.location}
                  onChange={(e) => setFormData({...formData, location: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green focus:bg-white transition-all font-medium"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-black text-slate-700 uppercase tracking-widest ml-1">Short Description</label>
              <div className="relative">
                <Info className="absolute left-4 top-4 text-slate-400 w-5 h-5" />
                <textarea 
                  rows="3"
                  placeholder="Briefly describe this shop branch..."
                  value={formData.description}
                  onChange={(e) => setFormData({...formData, description: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green focus:bg-white transition-all font-medium resize-none"
                ></textarea>
              </div>
            </div>
          </div>

          {/* Fixed Action Bar for Mobile / Floating for Desktop */}
          <div className="pt-4">
            <button 
              type="submit"
              disabled={loading || success}
              className="w-full bg-q-green hover:bg-q-green-dark text-white font-black py-5 rounded-[1.5rem] shadow-xl shadow-green-200 transition-all flex items-center justify-center gap-3 active:scale-[0.98] disabled:opacity-70"
            >
              {loading ? (
                <Loader2 className="animate-spin" size={24} />
              ) : success ? (
                <CheckCircle2 size={24} />
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