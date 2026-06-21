import api from './axiosInstance';

/**
 * Fetches all shops based on user role and location.
 * Replaces: Venue_overall_list
 */
export const fetchShops = async (userId, userType) => {
  const response = await api.post('Shop_overall_list', {
    user_id: userId.toString(),
    user_type: userType
  });
  return response.data.rows || [];
};

/**
 * Deactivates a shop branch.
 * Replaces: DeleteVenue
 */
export const deleteShop = async (id) => {
  const response = await api.post('DeleteShop', { 
    id: id.toString() 
  });
  return response.data;
}
export const saveShop = async (formData) => {
  // We use multipart/form-data to send the image file to Go
  const response = await api.post('/SaveShop', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  return response.data;
};