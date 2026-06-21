import api from './axiosInstance';

export const getIncomeHistory = async () => {
  const res = await api.get('/GetIncomeHistory');
  return res.data.data || [];
};

export const saveIncome = async (data) => {
  const res = await api.post('/SaveIncome', data);
  return res.data;
};

export const getStocks = async () => {
  const res = await api.get('/GetStocks');
  return res.data.data || [];
};

export const updateStock = async (data) => {
  const res = await api.post('/UpdateStock', data);
  return res.data;
};