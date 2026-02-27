import axios from "axios";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api";

export const api = axios.create({
  baseURL: BASE_URL,
});

api.interceptors.request.use((config) => {
  if (typeof window !== "undefined") {
    const token = localStorage.getItem("access_token");
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (error) => {
    if (error.response?.status === 401 && typeof window !== "undefined") {
      localStorage.removeItem("access_token");
      window.location.href = "/login";
    }
    return Promise.reject(error);
  }
);

// Auth
export const login = (email: string, password: string) =>
  api.post<{ access_token: string }>("/auth/login", { email, password });

// Users
export const getUsers = () => api.get("/admin/users");
export const getUserById = (id: string) => api.get(`/admin/users/${id}`);
export const createUser = (data: unknown) => api.post("/admin/users", data);
export const updateUser = (id: string, data: unknown) => api.patch(`/admin/users/${id}`, data);
export const deleteUser = (id: string) => api.delete(`/admin/users/${id}`);

// Devices
export const getDevices = () => api.get("/admin/devices");

// Geofences
export const getGeofences = () => api.get("/admin/geofences");
export const deleteGeofence = (id: string) => api.delete(`/admin/geofences/${id}`);

// Alerts
export const getAlerts = () => api.get("/admin/alerts");

// Vehicles
export const getVehicles = () => api.get("/vehicles");
