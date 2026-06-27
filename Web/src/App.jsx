import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';

// --- Providers & Context ---
import { ThemeProvider } from './context/ThemeContext';

// --- Layouts ---
import MainLayout from './layouts/MainLayout';

// --- Auth Modules ---
import LoginPage from './pages/Auth/LoginPage';
import OtpPage from './pages/Auth/OtpPage';

// --- Dashboard ---
import DashboardPage from './pages/Dashboard';

// --- Profile & Settings ---
import ProfilePage from './pages/Profile/ProfilePage';
import EditProfilePage from './pages/Profile/EditProfilePage';
import SettingsPage from './pages/Settings/SettingsPage';
import DeleteAccountPage from './pages/Settings/DeleteAccountPage';

// --- Shop Management ---
import MyShopListPage from './pages/Shops';
import AddShopPage from './pages/Shops/AddShopPage';

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
import IncomeListPage from './pages/Inventory/IncomeListPage';
import IncomeEntryPage from './pages/Inventory/IncomeEntryPage';
import PendingPayments from './pages/Inventory/PendingPayments';

// --- Reports ---
import ReportsPage from './pages/Inventory/ReportsPage';

/**
 * Private Route Guard
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
    <ThemeProvider>
      <Router>
        <Routes>
          {/* ==========================================
              PUBLIC ROUTES
             ========================================== */}
          <Route path="/" element={<LoginPage />} />
          <Route path="/otp" element={<OtpPage />} />

          {/* ==========================================
              PRIVATE ROUTES (Wrapped in Layout)
             ========================================== */}
          <Route element={<PrivateRoute><MainLayout /></PrivateRoute>}>
            
            {/* Dashboard */}
            <Route path="/home" element={<DashboardPage />} />

            {/* Profile & Settings */}
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/profile/edit" element={<EditProfilePage />} />
            <Route path="/settings" element={<SettingsPage />} />
            <Route path="/settings/delete" element={<DeleteAccountPage />} />

            {/* Shop Management */}
            <Route path="/shops" element={<MyShopListPage />} />
            <Route path="/shops/add" element={<AddShopPage />} />
            <Route path="/shops/edit/:id" element={<AddShopPage />} />

            {/* Product Management */}
            <Route path="/products" element={<ProductListPage />} />
            <Route path="/products/add" element={<AddProductPage />} />
            <Route path="/products/edit/:id" element={<AddProductPage />} />

            {/* Customer & Ledger */}
            <Route path="/customers" element={<CustomerListPage />} />
            <Route path="/customers/add" element={<AddCustomerPage />} />
            <Route path="/customers/:id" element={<CustomerLedger />} />

            {/* Inventory & Sales */}
            <Route path="/sales" element={<SalesHistoryPage />} />
            <Route path="/sales/new" element={<AddSalePage />} />
            <Route path="/stocks" element={<StocksPage />} />
            
            {/* Standardized Income Entry: List first, then New */}
            <Route path="/income-entry" element={<IncomeListPage />} />
            <Route path="/income-entry/new" element={<IncomeEntryPage />} />
            
            <Route path="/inventory/pending" element={<PendingPayments />} />
            
            {/* Reports */}
            <Route path="/reports" element={<ReportsPage />} />

          </Route>

          {/* ==========================================
              404 REDIRECT
             ========================================== */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
};

export default App;