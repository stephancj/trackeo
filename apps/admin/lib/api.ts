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
export const getUserDetail = (id: number) => api.get(`/admin/users/${id}`);
export const createUser = (data: unknown) => api.post("/admin/users", data);
export const updateUser = (id: string | number, data: unknown) => api.patch(`/admin/users/${id}`, data);
export const deleteUser = (id: string | number) => api.delete(`/admin/users/${id}`);

// Vehicles (enriched: device + position + assignment)
export const getAdminVehicles = () => api.get("/admin/vehicles");
export const getVehicleDetail = (id: number) => api.get(`/admin/vehicles/${id}`);
export const assignDevice = (deviceId: number, userId: number) =>
  api.post(`/admin/devices/${deviceId}/assign/${userId}`);
export const unassignDevice = (deviceId: number) =>
  api.delete(`/admin/devices/${deviceId}/assign`);

// Geofences
export const getGeofences = () => api.get("/admin/geofences");
export const deleteGeofence = (id: string) => api.delete(`/admin/geofences/${id}`);

// Alerts
export const getAlerts = () => api.get("/admin/alerts");
export const ackAlert = (id: string) => api.patch(`/admin/alerts/${id}`);

// Reports
export const getReportsOverview = () => api.get("/admin/reports/overview");
export const getVehicleReports = (period: "today" | "7d" | "30d") =>
  api.get(`/admin/reports/vehicles?period=${period}`);

// Subscriptions
export const getSubscriptions = () => api.get("/admin/subscriptions");
export const upsertSubscription = (
  userId: number,
  data: {
    plan?: string;
    status?: string;
    nextBillingDate?: string | null;
    trialEndsAt?: string | null;
    notes?: string | null;
  }
) => api.patch(`/admin/subscriptions/${userId}`, data);
