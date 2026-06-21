import api from './axiosInstance';

export const getProfile = async (userId) => {
  const res = await api.post('/Get_UserProfile', { user_id: userId.toString() });
  return res.data.data;
};

export const updateProfile = async (formData) => {
  const res = await api.post('/Update_Cususer', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  return res.data;
};

export const getSettings = async (userId) => {
  const res = await api.post('/Get_UserSettings', { user_id: userId.toString() });
  return res.data.data;
};

export const updateSettings = async (settingsData) => {
  const res = await api.post('/Update_UserSettings', settingsData);
  return res.data;
};
// Add to src/api/profileApi.js
export const getCities = async () => {
  const res = await api.get('/Get_Cities');
  return res.data.data || [];
};
export const deleteAccount = async (userId) => {
  // Hits your Golang Delete_Cususer endpoint
  const res = await api.post('/Delete_Cususer', { id: userId.toString() });
  return res.data;
};