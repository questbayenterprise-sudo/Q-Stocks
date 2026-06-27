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
export const getPendingPayments = async () => {
  const res = await api.post('/GetPendingPayments');
  return res.data.data || [];
};
// Add deleteStock if not already there
export const deleteStock = async (id) => {
  const res = await api.post('/DeleteStock', { id: id.toString() });
  return res.data;
};