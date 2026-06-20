import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';

// --- Layouts ---
import MainLayout from './layouts/MainLayout';

// --- Pages ---
import LoginPage from './pages/Auth/LoginPage';
import DashboardPage from './pages/Dashboard';

function App() {
  return (
    <Router>
      <Routes>
        {/* Public Route: Login */}
        <Route path="/" element={<LoginPage />} />
        
        {/* Private Routes: Wrapped in MainLayout (Sidebar/BottomNav) */}
        <Route element={<MainLayout />}>
          <Route path="/home" element={<DashboardPage />} />
          
          {/* Placeholders for your other modules */}
          <Route path="/shops" element={<div className="p-8 font-bold">Shops Management Coming Soon...</div>} />
          <Route path="/products" element={<div className="p-8 font-bold">Product Catalog Coming Soon...</div>} />
          <Route path="/customers" element={<div className="p-8 font-bold">Customer Ledger Coming Soon...</div>} />
          <Route path="/sales" element={<div className="p-8 font-bold">Sales History Coming Soon...</div>} />
          <Route path="/stocks" element={<div className="p-8 font-bold">Inventory Stocks Coming Soon...</div>} />
          <Route path="/reports" element={<div className="p-8 font-bold">Business Reports Coming Soon...</div>} />
          <Route path="/settings" element={<div className="p-8 font-bold">App Settings Coming Soon...</div>} />
        </Route>

        {/* Catch-all: Redirect unknown paths to login or home */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

// CRITICAL: This line fixes the "Uncaught SyntaxError"
export default App;