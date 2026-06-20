import axios from 'axios';

const api = axios.create({
  // This will look for VITE_API_BASE_URL in your .env file
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000',
  headers: {
    'Content-Type': 'application/json',
  },
});

export default api;