import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  headers: { 'Content-Type': 'application/json' }
});

export const signIn = async (email) => {
  const response = await api.post('api/SignIn', { email });
  return response.data;
};

// Trigger the OTP generation on the Go backend
export const sendOtp = async (email) => {
  const response = await api.post('api/Send_OTP', { email });
  return response.data;
};

// Final verification
export const verifyOtp = async (email, otp) => {
  const response = await api.post('api/Verify_OTP', { email, otp });
  return response.data;
};