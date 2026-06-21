import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import CustomerListPage from './pages/Customers/index';
import CustomerLedger from './pages/Customers/CustomerLedger';
import AddCustomerPage from './pages/Customers/AddCustomerPage';

import SalesListPage from './pages/Sales/SalesHistoryPage';
import AddSalePage from './pages/Sales/AddSalePage';
// --- Layouts ---
import MainLayout from './layouts/MainLayout';
import AddProductPage from './pages/Products/AddProductPage';

// --- Auth Pages ---
import LoginPage from './pages/Auth/LoginPage';
import OtpPage from './pages/Auth/OtpPage';

// --- Dashboard ---
import DashboardPage from './pages/Dashboard';

// --- Shop Management ---
import MyShopListPage from './pages/Shops';
import AddShopPage from './pages/Shops/AddShopPage';

// --- Product Management ---
import ProductListPage from './pages/Products';
// (Note: You can create a combined AddProductPage similar to AddShopPage)

// --- Simple Protected Route Wrapper ---
const PrivateRoute = ({ children }) => {
  const isAuthenticated = !!localStorage.getItem('user');
  return isAuthenticated ? children : <Navigate to="/" replace />;
};

function App() {
  return (
    <Router>
      <Routes>
        {/* ==========================================
            PUBLIC ROUTES (No Sidebar/BottomNav)
           ========================================== */}
        <Route path="/" element={<LoginPage />} />
        <Route path="/otp" element={<OtpPage />} />

        {/* ==========================================
            PRIVATE ROUTES (With Menu Layout)
           ========================================== */}
        <Route element={<PrivateRoute><MainLayout /></PrivateRoute>}>
          <Route path="/sales" element={<SalesListPage />} />
          <Route path="/sales/new" element={<AddSalePage />} />
          {/* Dashboard */}
          <Route path="/home" element={<DashboardPage />} />
          {/* --- CUSTOMER SECTION --- */}
          {/* 1. List Page */}
          <Route path="/customers" element={<CustomerListPage />} />

          {/* 2. ADD PAGE (Must be ABOVE the ID route) */}
          <Route path="/customers/add" element={<AddCustomerPage />} />

          {/* 3. EDIT PAGE */}
          <Route path="/customers/edit/:id" element={<AddCustomerPage />} />

          {/* 4. LEDGER PAGE (Dynamic ID last) */}
          <Route path="/customers/:id" element={<CustomerLedger />} />
          {/* Shop Management */}
          <Route path="/shops" element={<MyShopListPage />} />
          <Route path="/shops/add" element={<AddShopPage />} />
          <Route path="/shops/edit/:id" element={<AddShopPage />} />
          <Route path="/products/add" element={<AddProductPage />} />
          <Route path="/products/edit/:id" element={<AddProductPage />} />
          {/* Product Management */}
          <Route path="/products" element={<ProductListPage />} />
          <Route path="/products/add" element={<div className="p-10 font-bold">Add Product Form Coming Soon...</div>} />
          <Route path="/products/edit/:id" element={<div className="p-10 font-bold">Edit Product Form Coming Soon...</div>} />

          {/* Inventory & Ledger (Placeholders) */}
          <Route path="/customers" element={<div className="p-10 font-bold">Customer Ledger coming soon...</div>} />
          <Route path="/sales" element={<div className="p-10 font-bold">Sales History coming soon...</div>} />
          <Route path="/stocks" element={<div className="p-10 font-bold">Stock Management coming soon...</div>} />
          <Route path="/reports" element={<div className="p-10 font-bold">Business Reports coming soon...</div>} />

          {/* Settings */}
          <Route path="/settings" element={<div className="p-10 font-bold">App Settings coming soon...</div>} />
          <Route path="/profile" element={<div className="p-10 font-bold">User Profile coming soon...</div>} />
        </Route>

        {/* ==========================================
            FALLBACKS
           ========================================== */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

export default App;