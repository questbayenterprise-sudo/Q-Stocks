import axios from 'axios';

// Base URL is configurable via .env file (VITE_API_BASE_URL)
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000',
  headers: { 'Content-Type': 'application/json' }
});

export const signIn = async (email) => {
  const response = await api.post('api/SignIn', { email });
  return response.data;
};