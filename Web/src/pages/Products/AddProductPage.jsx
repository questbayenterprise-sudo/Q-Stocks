import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, Camera, ShoppingBag, IndianRupee, Layers, Scale, Loader2, CheckCircle2 } from 'lucide-react';
import { saveProduct } from '../../api/productApi';

const AddProductPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const existingProduct = location.state?.product;

  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);

  const [formData, setFormData] = useState({
    id: existingProduct?.id || "0",
    name: existingProduct?.name || "",
    category_id: existingProduct?.category_id || "1",
    uom: existingProduct?.uom || "KG",
    base_price: existingProduct?.base_price || "",
  });

  useEffect(() => {
    if (existingProduct?.image_url) {
      const baseUrl = import.meta.env.VITE_API_BASE_URL;
      setImagePreview(`${baseUrl}/${existingProduct.image_url.replace(/\\/g, '/')}`);
    }
  }, [existingProduct]);

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

    const data = new FormData();
    data.append("id", formData.id);
    data.append("name", formData.name);
    data.append("category_id", formData.category_id);
    data.append("uom", formData.uom);
    data.append("base_price", formData.base_price);

    if (imageFile) {
      data.append("image", imageFile);
    } else if (existingProduct?.image_url) {
      data.append("existing_image", existingProduct.image_url);
    }

    try {
      const result = await saveProduct(data);
      if (result.success) {
        setSuccess(true);
        setTimeout(() => navigate('/products'), 1500);
      }
    } catch (err) {
      alert("Error saving product details.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 pb-20">
      {/* Header */}
      <div className="bg-white border-b border-slate-100 sticky top-0 z-30">
        <div className="max-w-3xl mx-auto px-6 py-4 flex items-center gap-4">
          <button onClick={() => navigate(-1)} className="p-2 hover:bg-slate-50 rounded-full transition-colors">
            <ArrowLeft size={20} className="text-slate-600" />
          </button>
          <h1 className="text-xl font-black text-slate-800 tracking-tight">
            {existingProduct ? 'Edit Product' : 'Add New Product'}
          </h1>
        </div>
      </div>

      <div className="max-w-3xl mx-auto p-6">
        <form onSubmit={handleSubmit} className="space-y-8">
          
          {/* Product Image Uploader */}
          <div className="relative group w-48 h-48 mx-auto bg-white rounded-[2.5rem] border-2 border-dashed border-slate-200 overflow-hidden flex items-center justify-center transition-all hover:border-q-green shadow-inner">
            {imagePreview ? (
              <img src={imagePreview} alt="Preview" className="w-full h-full object-cover" />
            ) : (
              <div className="text-center p-4">
                <Camera className="text-slate-300 mx-auto mb-2" size={32} />
                <p className="text-slate-400 text-[10px] font-black uppercase tracking-tighter">Product Photo</p>
              </div>
            )}
            <input type="file" accept="image/*" onChange={handleImageChange} className="absolute inset-0 opacity-0 cursor-pointer" />
          </div>

          <div className="bg-white rounded-[2.5rem] p-8 shadow-xl shadow-slate-200/50 border border-white space-y-6">
            {/* Name */}
            <div className="space-y-2">
              <label className="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Product Name</label>
              <div className="relative">
                <ShoppingBag className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 w-5 h-5" />
                <input 
                  type="text"
                  required
                  placeholder="e.g. Whole Broiler Chicken"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green focus:bg-white transition-all font-medium"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Category */}
              <div className="space-y-2">
                <label className="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Category</label>
                <div className="relative">
                  <Layers className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 w-5 h-5" />
                  <select 
                    value={formData.category_id}
                    onChange={(e) => setFormData({...formData, category_id: e.target.value})}
                    className="w-full pl-12 pr-10 py-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green focus:bg-white transition-all font-medium appearance-none"
                  >
                    <option value="1">Broiler Chicken</option>
                    <option value="2">Country Chicken</option>
                    <option value="3">Eggs</option>
                    <option value="4">Masala</option>
                  </select>
                </div>
              </div>

              {/* UOM */}
              <div className="space-y-2">
                <label className="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Unit (UOM)</label>
                <div className="relative">
                  <Scale className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 w-5 h-5" />
                  <select 
                    value={formData.uom}
                    onChange={(e) => setFormData({...formData, uom: e.target.value})}
                    className="w-full pl-12 pr-10 py-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green focus:bg-white transition-all font-medium appearance-none"
                  >
                    <option value="KG">Kilogram (KG)</option>
                    <option value="Piece">Piece (Qty)</option>
                    <option value="Tray">Tray</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Base Price */}
            <div className="space-y-2">
              <label className="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Base Selling Price (₹)</label>
              <div className="relative">
                <IndianRupee className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 w-5 h-5" />
                <input 
                  type="number"
                  required
                  step="0.01"
                  placeholder="0.00"
                  value={formData.base_price}
                  onChange={(e) => setFormData({...formData, base_price: e.target.value})}
                  className="w-full pl-12 pr-4 py-4 bg-slate-50 border-2 border-slate-50 rounded-2xl outline-none focus:border-q-green focus:bg-white transition-all font-black text-xl text-slate-900"
                />
              </div>
            </div>
          </div>

          <button 
            type="submit"
            disabled={loading || success}
            className="w-full bg-q-green hover:bg-q-green-dark text-white font-black py-5 rounded-3xl shadow-xl shadow-green-200 transition-all flex items-center justify-center gap-3 active:scale-[0.98] disabled:opacity-70"
          >
            {loading ? <Loader2 className="animate-spin" size={24} /> : success ? <CheckCircle2 size={24} /> : 'SAVE TO CATALOG'}
          </button>

        </form>
      </div>
    </div>
  );
};

export default AddProductPage;