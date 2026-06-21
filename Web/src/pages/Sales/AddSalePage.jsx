import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Trash2, Save, ShoppingCart, User, Store, Loader2 } from 'lucide-react';
import { getProducts } from '../../api/productApi';
import { getCustomers } from '../../api/customerApi';
import { fetchShops } from '../../api/shopApi';
import { processSale } from '../../api/saleApi';

const AddSalePage = () => {
  const navigate = useNavigate();
  const [products, setProducts] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [shops, setShops] = useState([]);
  const [loading, setLoading] = useState(false);

  // Form State
  const [selectedShop, setSelectedShop] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState('');
  const [items, setItems] = useState([{ product_id: '', quantity: 1, price: 0, total: 0 }]);
  const [paidAmount, setPaidAmount] = useState(0);

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user'));
    getProducts().then(setProducts);
    getCustomers().then(setCustomers);
    fetchShops(user.id, user.userType_id).then(setShops);
  }, []);

  const addItem = () => setItems([...items, { product_id: '', quantity: 1, price: 0, total: 0 }]);
  
  const updateItem = (index, field, value) => {
    const newItems = [...items];
    newItems[index][field] = value;
    
    if (field === 'product_id') {
      const prod = products.find(p => p.id == value);
      newItems[index].price = prod?.base_price || 0;
    }
    
    newItems[index].total = newItems[index].quantity * newItems[index].price;
    setItems(newItems);
  };

  const removeItem = (index) => setItems(items.filter((_, i) => i !== index));

  const subTotal = items.reduce((sum, item) => sum + item.total, 0);
  const balance = subTotal - paidAmount;

  const handleSubmit = async (status) => {
    if (!selectedShop || !selectedCustomer) return alert("Select Shop & Customer");
    setLoading(true);
    try {
      await processSale({
        shop_id: parseInt(selectedShop),
        customer_id: parseInt(selectedCustomer),
        total_amount: subTotal,
        paid_amount: parseFloat(paidAmount),
        status: status,
        items: items
      });
      navigate('/sales');
    } catch (err) {
      alert("Sale failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 p-4 md:p-8">
      <div className="max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Side: Invoice Items */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white p-6 rounded-[2rem] shadow-sm border border-slate-100">
            <h2 className="text-xl font-black mb-6 flex items-center gap-2">
              <ShoppingCart className="text-q-green" /> New Invoice
            </h2>
            
            <div className="grid grid-cols-2 gap-4 mb-8">
              <select onChange={(e) => setSelectedShop(e.target.value)} className="p-4 bg-slate-50 rounded-2xl border-none outline-none font-bold text-sm">
                <option value="">Select Shop</option>
                {shops.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
              <select onChange={(e) => setSelectedCustomer(e.target.value)} className="p-4 bg-slate-50 rounded-2xl border-none outline-none font-bold text-sm">
                <option value="">Select Customer</option>
                {customers.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>

            <div className="space-y-4">
              {items.map((item, index) => (
                <div key={index} className="flex flex-wrap md:flex-nowrap gap-3 items-center bg-slate-50 p-4 rounded-2xl">
                  <select 
                    className="flex-1 min-w-[150px] bg-transparent font-bold outline-none"
                    onChange={(e) => updateItem(index, 'product_id', e.target.value)}
                  >
                    <option value="">Select Product</option>
                    {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                  </select>
                  <input 
                    type="number" placeholder="Qty" className="w-20 bg-white p-2 rounded-xl text-center font-bold"
                    value={item.quantity} onChange={(e) => updateItem(index, 'quantity', e.target.value)}
                  />
                  <div className="w-24 text-right font-black text-q-green">₹{item.total}</div>
                  <button onClick={() => removeItem(index)} className="text-red-400 p-2"><Trash2 size={18}/></button>
                </div>
              ))}
            </div>

            <button onClick={addItem} className="mt-6 w-full py-4 border-2 border-dashed border-slate-200 rounded-2xl font-bold text-slate-400 hover:border-q-green hover:text-q-green transition-all">
              + ADD ITEM
            </button>
          </div>
        </div>

        {/* Right Side: Summary Card */}
        <div className="lg:col-span-1">
          <div className="bg-white p-8 rounded-[2.5rem] shadow-xl border border-slate-100 sticky top-8">
            <h3 className="font-black text-slate-800 mb-6">Bill Summary</h3>
            <div className="space-y-4 mb-8">
              <div className="flex justify-between text-slate-500 font-medium"><span>Subtotal</span><span>₹{subTotal}</span></div>
              <div className="flex flex-col gap-2">
                <span className="text-sm font-bold text-slate-700">Advance Paid</span>
                <input 
                   type="number" className="w-full p-3 bg-slate-50 rounded-xl font-black text-q-green outline-none"
                   value={paidAmount} onChange={(e) => setPaidAmount(e.target.value)}
                />
              </div>
            </div>
            <div className="border-t pt-6 mb-8">
              <div className="flex justify-between items-end">
                <span className="font-bold text-slate-400 text-xs uppercase tracking-widest">Balance Due</span>
                <span className="text-3xl font-black text-red-500">₹{balance}</span>
              </div>
            </div>
            <div className="space-y-3">
              <button 
                onClick={() => handleSubmit('COMPLETED')} disabled={loading}
                className="w-full bg-q-green text-white font-black py-4 rounded-2xl shadow-lg shadow-green-100 flex justify-center items-center gap-2"
              >
                {loading ? <Loader2 className="animate-spin" /> : <><Save size={20}/> COMPLETE SALE</>}
              </button>
              <button className="w-full py-4 font-bold text-slate-400 hover:text-slate-600">SAVE AS DRAFT</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AddSalePage;