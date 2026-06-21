import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';

// --- Layouts ---
import MainLayout from './layouts/MainLayout';

// --- Auth Modules ---
import LoginPage from './pages/Auth/LoginPage';
import OtpPage from './pages/Auth/OtpPage';

// --- Dashboard Module ---
import DashboardPage from './pages/Dashboard';

// --- Shop Management ---
import MyShopListPage from './pages/Shops';
import AddShopPage from './pages/Shops/AddShopPage';
import ProfilePage from './pages/Profile/ProfilePage';
import EditProfilePage from './pages/Profile/EditProfilePage';
import SettingsPage from './pages/Settings/SettingsPage';
import DeleteAccountPage from './pages/Settings/DeleteAccountPage';
// --- Product Management ---
import ProductListPage from './pages/Products';
import AddProductPage from './pages/Products/AddProductPage';

// --- Customer & Ledger ---
import CustomerListPage from './pages/Customers';
import AddCustomerPage from './pages/Customers/AddCustomerPage';
import CustomerLedger from './pages/Customers/CustomerLedger';

// --- Inventory & Sales ---
import SalesHistoryPage from './pages/Sales/SalesHistoryPage';
import AddSalePage from './pages/Sales/AddSalePage';
import StocksPage from './pages/Inventory/StocksPage';
import IncomeEntryPage from './pages/Inventory/IncomeEntryPage';

// --- Reports ---
import ReportsPage from './pages/Inventory/ReportsPage';

/**
 * Enterprise Private Route Wrapper
 * Checks if a valid session exists in localStorage
 */
const PrivateRoute = ({ children }) => {
  const user = localStorage.getItem('user');
  if (!user) {
    return <Navigate to="/" replace />;
  }
  return children;
};

const App = () => {
  return (
    <Router>
      <Routes>
        {/* ==========================================
            PUBLIC ROUTES (Login Flow)
           ========================================== */}
        <Route path="/" element={<LoginPage />} />
        <Route path="/otp" element={<OtpPage />} />

        {/* ==========================================
            PRIVATE ROUTES (Authenticated Area)
           ========================================== */}
        <Route element={<PrivateRoute><MainLayout /></PrivateRoute>}>
          
          {/* Dashboard */}
          <Route path="/home" element={<DashboardPage />} />

          {/* Shops Module */}
          <Route path="/shops" element={<MyShopListPage />} />
          <Route path="/shops/add" element={<AddShopPage />} />
          <Route path="/shops/edit/:id" element={<AddShopPage />} />

          {/* Products Module */}
          <Route path="/products" element={<ProductListPage />} />
          <Route path="/products/add" element={<AddProductPage />} />
          <Route path="/products/edit/:id" element={<AddProductPage />} />
<Route path="/profile" element={<ProfilePage />} />
<Route path="/profile/edit" element={<EditProfilePage />} />
<Route path="/settings" element={<SettingsPage />} />
<Route path="/settings/delete" element={<DeleteAccountPage />} />

          {/* Customers & Ledger Module */}
          <Route path="/customers" element={<CustomerListPage />} />
          <Route path="/customers/add" element={<AddCustomerPage />} />
          <Route path="/customers/:id" element={<CustomerLedger />} />

          {/* Sales & Inventory Submenu */}
          <Route path="/sales" element={<SalesHistoryPage />} />
          <Route path="/sales/new" element={<AddSalePage />} />
          <Route path="/stocks" element={<StocksPage />} />
          <Route path="/income-entry" element={<IncomeEntryPage />} />
          
          {/* Reports */}
          <Route path="/reports" element={<ReportsPage />} />

          {/* General Placeholders */}
          <Route path="/settings" element={<div className="p-10 font-bold">App Settings - Mobile Style Coming Soon</div>} />
          <Route path="/profile" element={<div className="p-10 font-bold">User Profile - Mobile Style Coming Soon</div>} />
        </Route>

        {/* ==========================================
            404 REDIRECT
           ========================================== */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
};

export default App;