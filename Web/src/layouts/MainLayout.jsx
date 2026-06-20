import React, { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import BottomNav from './components/BottomNav';
import MoreMenuOverlay from './components/MoreMenuOverlay';

const MainLayout = () => {
  const [isMoreMenuOpen, setIsMoreMenuOpen] = useState(false);

  return (
    <div className="flex min-h-screen bg-[#F8F9FA]">
      {/* Desktop Sidebar (Hidden on Mobile) */}
      <div className="hidden md:flex">
        <Sidebar />
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <main className="flex-1 pb-24 md:pb-0">
          <Outlet /> {/* This renders the current page (Home, Shop, etc.) */}
        </main>
      </div>

      {/* Mobile Bottom Navigation (Hidden on Desktop) */}
      <div className="md:hidden">
        <BottomNav onMoreClick={() => setIsMoreMenuOpen(true)} />
      </div>

      {/* Mobile "More" Menu Drawer */}
      <MoreMenuOverlay 
        isOpen={isMoreMenuOpen} 
        onClose={() => setIsMoreMenuOpen(false)} 
      />
    </div>
  );
};

export default MainLayout;