import api from './axiosInstance';

export const getCustomers = async () => {
  const res = await api.get('/GetAllCustomers');
  return res.data.data || [];
};

export const createCustomer = async (data) => {
  const res = await api.post('/CreateCustomer', data);
  return res.data;
};

export const getLedger = async (customerId) => {
  const res = await api.post('/GetCustomerLedger', { customer_id: customerId.toString() });
  return res.data.data || [];
};