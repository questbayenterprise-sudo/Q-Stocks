import api from './axiosInstance';

export const processSale = async (data) => {
  const res = await api.post('/ProcessSale', data);
  return res.data;
};

export const getSalesList = async () => {
  const res = await api.post('/GetRecentSales', { limit: 100 });
  return res.data.data || [];
};