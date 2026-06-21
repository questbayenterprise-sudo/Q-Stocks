import axios from 'axios';

// Get the base URL from env or default to localhost:5000
const rawBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';

// Ensure the URL ends with /api to match your Golang router.Group("/api")
const baseURL = `${rawBaseUrl.replace(/\/$/, '')}/api`;
const api = axios.create({
  baseURL: baseURL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export default api;