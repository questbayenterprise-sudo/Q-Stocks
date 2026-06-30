import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Plus, Trash2, Save, ShoppingCart, User, 
  Store, Loader2, IndianRupee, X, Phone 
} from 'lucide-react';
import { getProducts } from '../../api/productApi';
import { getCustomers, createCustomer } from '../../api/customerApi'; // Added createCustomer
import { fetchShops } from '../../api/shopApi';
import { processSale } from '../../api/saleApi';

const AddSalePage = () => {
  const navigate = useNavigate();
  const [products, setProducts] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [shops, setShops] = useState([]);
  const [loading, setLoading] = useState(false);

  // States for Quick Add Customer Modal
  const [showCustModal, setShowCustModal] = useState(false);
  const [custLoading, setCustLoading] = useState(false);
  const [newCust, setNewCust] = useState({ name: '', phone: '' });

  const [selectedShop, setSelectedShop] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState('');
  const [items, setItems] = useState([{ product_id: '', quantity: 1, price: 0, total: 0 }]);
  const [paidAmount, setPaidAmount] = useState(0);

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user) return navigate('/');

    loadInitialData(user);
  }, [navigate]);

  const loadInitialData = (user) => {
    Promise.all([
      getProducts(),
      getCustomers(),
      fetchShops(user.id, user.UserType)
    ]).then(([p, c, s]) => {
      setProducts(p);
      setCustomers(c);
      setShops(s);
    });
  };

  // Logic to handle Quick Customer Addition
  const handleQuickAddCustomer = async (e) => {
    e.preventDefault();
    if (!newCust.name) return;
    setCustLoading(true);
    try {
      const response = await createCustomer(newCust);
      // Fetch updated customer list
      const updatedCustomers = await getCustomers();
      setCustomers(updatedCustomers);
      
      // Attempt to select the newly created customer automatically
      // Note: This assumes your API returns the new ID or we find by name/phone
      const created = updatedCustomers.find(c => c.name === newCust.name && c.phone === newCust.phone);
      if (created) setSelectedCustomer(created.id);

      setShowCustModal(false);
      setNewCust({ name: '', phone: '' });
    } catch (err) {
      alert("Failed to add customer");
    } finally {
      setCustLoading(false);
    }
  };

  const addItem = () => setItems([...items, { product_id: '', quantity: 1, price: 0, total: 0 }]);
  
  const updateItem = (index, field, value) => {
    const newItems = [...items];
    newItems[index][field] = value;
    if (field === 'product_id') {
      const prod = products.find(p => p.id == value);
      newItems[index].price = prod?.base_price || 0;
    }
    newItems[index].total = Number(newItems[index].quantity) * Number(newItems[index].price);
    setItems(newItems);
  };

  const removeItem = (index) => {
    if (items.length > 1) setItems(items.filter((_, i) => i !== index));
  };

  const subTotal = items.reduce((sum, item) => sum + item.total, 0);
  const balance = subTotal - paidAmount;

  const handleSubmit = async (status) => {
    if (!selectedShop || !selectedCustomer) return alert("Please select Shop and Customer");
    const invalidItems = items.filter(item => !item.product_id || item.quantity <= 0);
    if (invalidItems.length > 0) return alert("Please ensure all items have a product and valid quantity");

    setLoading(true);
    try {
      await processSale({
        shop_id: parseInt(selectedShop),
        customer_id: parseInt(selectedCustomer),
        total_amount: Number(subTotal),
        paid_amount: Number(paidAmount),
        status: status,
        items: items.map(item => ({
          product_id: parseInt(item.product_id),
          quantity: Number(item.quantity),
          price: Number(item.price),
          total: Number(item.total)
        }))
      });
      navigate('/sales');
    } catch (err) {
      alert("Transaction failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-app-bg p-4 md:p-8 transition-colors duration-300 relative">
      
      {/* QUICK ADD CUSTOMER MODAL */}
      {showCustModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-card-bg w-full max-w-md rounded-[2.5rem] border border-border-v shadow-2xl p-8 animate-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-xl font-black text-text-h uppercase tracking-tight">Quick Add Customer</h3>
              <button onClick={() => setShowCustModal(false)} className="p-2 text-text-m hover:bg-app-bg rounded-full">
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleQuickAddCustomer} className="space-y-5">
              <div className="space-y-2">
                <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Name</label>
                <div className="relative">
                  <User className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m" size={18} />
                  <input 
                    autoFocus
                    type="text"
                    className="w-full pl-12 pr-4 py-4 bg-app-bg border border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-bold"
                    value={newCust.name}
                    onChange={e => setNewCust({...newCust, name: e.target.value})}
                    placeholder="Customer Name"
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Phone</label>
                <div className="relative">
                  <Phone className="absolute left-4 top-1/2 -translate-y-1/2 text-text-m" size={18} />
                  <input 
                    type="tel"
                    className="w-full pl-12 pr-4 py-4 bg-app-bg border border-border-v rounded-2xl outline-none focus:border-q-green text-text-h font-bold"
                    value={newCust.phone}
                    onChange={e => setNewCust({...newCust, phone: e.target.value})}
                    placeholder="Phone (Optional)"
                  />
                </div>
              </div>

              <button 
                type="submit"
                disabled={custLoading}
                className="w-full bg-q-green text-white font-black py-4 rounded-2xl shadow-lg flex items-center justify-center gap-2 hover:bg-q-green-dark transition-all"
              >
                {custLoading ? <Loader2 className="animate-spin" /> : <><Save size={18}/> SAVE CUSTOMER</>}
              </button>
            </form>
          </div>
        </div>
      )}

      <div className="max-w-6xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-card-bg p-6 md:p-8 rounded-[2.5rem] shadow-sm border border-border-v transition-colors">
            <h2 className="text-2xl font-black text-text-h mb-8 flex items-center gap-3">
              <div className="p-2 bg-q-green/10 rounded-xl text-q-green">
                <ShoppingCart size={24} />
              </div>
              New Invoice
            </h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
              <div className="space-y-2">
                <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Branch</label>
                <select 
                  value={selectedShop}
                  onChange={(e) => setSelectedShop(e.target.value)} 
                  className="w-full p-4 bg-app-bg text-text-h rounded-2xl border border-border-v outline-none focus:border-q-green font-bold text-sm appearance-none"
                >
                  <option value="">Select Shop</option>
                  {shops.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black text-text-m uppercase tracking-widest ml-2">Customer</label>
                <div className="flex gap-2">
                  <div className="relative flex-1">
                    <select 
                      value={selectedCustomer}
                      onChange={(e) => setSelectedCustomer(e.target.value)} 
                      className="w-full p-4 bg-app-bg text-text-h rounded-2xl border border-border-v outline-none focus:border-q-green font-bold text-sm appearance-none"
                    >
                      <option value="">Select Customer</option>
                      {customers.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                    </select>
                  </div>
                  {/* QUICK ADD BUTTON */}
                  <button 
                    onClick={() => setShowCustModal(true)}
                    type="button"
                    className="p-4 bg-q-green text-white rounded-2xl hover:bg-q-green-dark transition-colors shadow-lg shadow-q-green/20"
                  >
                    <Plus size={20} />
                  </button>
                </div>
              </div>
            </div>

            {/* Product Rows */}
            <div className="space-y-4">
              {items.map((item, index) => (
                <div key={index} className="flex flex-wrap md:flex-nowrap gap-4 items-center bg-app-bg/50 p-5 rounded-[1.8rem] border border-border-v group transition-all">
                  <div className="flex-1 min-w-[200px] space-y-1">
                    <label className="text-[9px] font-black text-text-m uppercase tracking-tighter">Product</label>
                    <select 
                      className="w-full bg-transparent text-text-h font-black outline-none cursor-pointer"
                      onChange={(e) => updateItem(index, 'product_id', e.target.value)}
                      value={item.product_id}
                    >
                      <option value="">Select Product</option>
                      {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                    </select>
                  </div>

                  <div className="w-20 space-y-1">
                    <label className="text-[9px] font-black text-text-m uppercase tracking-tighter">Qty</label>
                    <input 
                      type="number" 
                      className="w-full bg-card-bg text-text-h p-2 rounded-xl text-center font-bold border border-border-v outline-none focus:border-q-green"
                      value={item.quantity} 
                      onChange={(e) => updateItem(index, 'quantity', e.target.value)}
                    />
                  </div>

                  <div className="w-28 space-y-1">
                    <label className="text-[9px] font-black text-text-m uppercase tracking-tighter">Rate (₹)</label>
                    <input 
                      type="number" 
                      className="w-full bg-card-bg text-q-green p-2 rounded-xl text-center font-black border border-border-v outline-none focus:border-q-green"
                      value={item.price} 
                      onChange={(e) => updateItem(index, 'price', e.target.value)}
                    />
                  </div>

                  <div className="w-28 text-right space-y-1">
                    <label className="text-[9px] font-black text-text-m uppercase tracking-tighter">Total</label>
                    <div className="font-black text-text-h text-sm">₹{item.total.toLocaleString()}</div>
                  </div>

                  <button 
                    onClick={() => removeItem(index)} 
                    className="p-2 text-text-m hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-all"
                  >
                    <Trash2 size={20}/>
                  </button>
                </div>
              ))}
            </div>

            <button 
              onClick={addItem} 
              className="mt-8 w-full py-5 border-2 border-dashed border-border-v rounded-3xl font-black text-text-m hover:border-q-green hover:text-q-green hover:bg-q-green/5 transition-all uppercase tracking-widest text-xs"
            >
              + Add Item to Bill
            </button>
          </div>
        </div>

        {/* Right Side Summary */}
        <div className="lg:col-span-1">
          <div className="bg-card-bg p-8 rounded-[2.5rem] shadow-2xl border border-border-v sticky top-8 transition-colors">
            <h3 className="font-black text-text-h text-xl mb-8 uppercase tracking-tight">Checkout</h3>
            
            <div className="space-y-5 mb-8">
              <div className="flex justify-between text-text-m font-bold uppercase text-[10px] tracking-widest">
                <span>Total Bill</span>
                <span className="text-text-h text-sm font-black">₹{subTotal.toLocaleString()}</span>
              </div>

              <div className="pt-4 border-t border-border-v space-y-2">
                <label className="text-[10px] font-black text-text-m uppercase tracking-widest">Advance Payment</label>
                <div className="relative">
                  <IndianRupee className="absolute left-4 top-1/2 -translate-y-1/2 text-q-green" size={18} />
                  <input 
                    type="number" 
                    className="w-full pl-12 p-4 bg-app-bg text-text-h rounded-2xl font-black text-xl outline-none border border-border-v focus:border-q-green"
                    value={paidAmount} 
                    onChange={(e) => setPaidAmount(e.target.value)}
                  />
                </div>
              </div>
            </div>

            <div className="bg-app-bg p-6 rounded-3xl border border-border-v mb-8">
              <div className="flex justify-between items-center">
                <span className="font-black text-text-m text-[10px] uppercase tracking-widest">Balance Due</span>
                <span className={`text-3xl font-black ${balance > 0 ? 'text-red-500' : 'text-emerald-500'}`}>
                  ₹{balance.toLocaleString()}
                </span>
              </div>
            </div>

            <div className="space-y-4">
              <button 
                onClick={() => handleSubmit('COMPLETED')} 
                disabled={loading}
                className="w-full bg-q-green hover:bg-q-green-dark text-white font-black py-5 rounded-3xl shadow-xl shadow-q-green/20 flex justify-center items-center gap-3 transition-all active:scale-95 disabled:opacity-50"
              >
                {loading ? <Loader2 className="animate-spin" /> : <><Save size={22}/> COMPLETE SALE</>}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AddSalePage;