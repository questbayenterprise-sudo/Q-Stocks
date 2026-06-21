    import api from './axiosInstance';

export const getProducts = async () => {
  const res = await api.post('/GetProducts');
  return res.data.data || [];
};

export const saveProduct = async (formData) => {
  const res = await api.post('/SaveProduct', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  return res.data;
};

export const deleteProduct = async (id) => {
  const res = await api.post('/DeleteProduct', { id: id.toString() });
  return res.data;
};
