import api from './axiosInstance';

/**
 * Fetches analytics and recent sales in parallel.
 * Replicates the logic from the Flutter HomeRepository.
 */
export const fetchDashboardData = async (userId, userType) => {
  try {
    // Note: ensure these paths match your main.go exactly
    const [analyticsRes, salesRes] = await Promise.all([
      api.post('/GetShopAnalytics', { user_id: userId.toString(), user_type: userType }),
      api.post('/GetRecentSales', { user_id: userId.toString(), user_type: userType, limit: 5 })
    ]);

    return {
      analytics: analyticsRes.data.data,
      recentSales: salesRes.data.data || []
    };
  } catch (error) {
    console.error("Dashboard API Error:", error);
    throw error;
  }
};
export const fetchSalesHistory = async (userId, userType) => {
  const response = await api.post('/GetRecentSales', { 
    user_id: userId.toString(), 
    user_type: userType, 
    limit: 50 // Higher limit for history page
  });
  return response.data.data || [];
};