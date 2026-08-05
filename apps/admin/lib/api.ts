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
export const getIncidents = () => api.get("/admin/incidents");
export const updateIncident = (id: string, status: string, note?: string) =>
  api.patch(`/admin/incidents/${id}`, { status, note });
export const getIncidentEvents = (id: string) =>
  api.get(`/admin/incidents/${id}/events`);

// Reports — fleet overview
export const getReportsOverview = () => api.get("/admin/reports/overview");
export const getVehicleReports = (period: "today" | "7d" | "30d") =>
  api.get(`/admin/reports/vehicles?period=${period}`);

// Reports — per-vehicle detail
export const getVehicleActivitySummary = (
  deviceId: number,
  period: "today" | "7d" | "30d"
) => api.get(`/admin/reports/vehicle/${deviceId}/activity?period=${period}`);

export const getVehicleTripLog = (
  deviceId: number,
  from: string,
  to: string
) => api.get(`/admin/reports/vehicle/${deviceId}/trip-log?from=${from}&to=${to}`);

export const getVehicleSpeedViolations = (
  deviceId: number,
  from: string,
  to: string,
  threshold = 120
) =>
  api.get(
    `/admin/reports/vehicle/${deviceId}/speed-violations?from=${from}&to=${to}&threshold=${threshold}`
  );

export const getVehicleIdleTime = (
  deviceId: number,
  from: string,
  to: string
) => api.get(`/admin/reports/vehicle/${deviceId}/idle?from=${from}&to=${to}`);

export const getVehicleGeofenceActivity = (
  deviceId: number,
  from: string,
  to: string
) =>
  api.get(
    `/admin/reports/vehicle/${deviceId}/geofence-activity?from=${from}&to=${to}`
  );

// Subscriptions
export const getSubscriptions = () => api.get("/admin/subscriptions");
export const upsertSubscription = (
  userId: number,
  data: {
    planId?: string;
    plan?: string;
    status?: string;
    nextBillingDate?: string | null;
    trialEndsAt?: string | null;
    notes?: string | null;
  }
) => api.patch(`/admin/subscriptions/${userId}`, data);

// Commercial catalogue
export type FeatureValueType = "boolean" | "number" | "string";

export interface FeatureDefinition {
  id: string;
  code: string;
  name: string;
  description: string | null;
  category: string;
  valueType: FeatureValueType;
  unit: string | null;
  isActive: boolean;
  displayOrder: number;
}

export interface PlanFeatureDefinition {
  id: string;
  featureId: string;
  enabled: boolean;
  value: boolean | number | string | null;
  feature: FeatureDefinition;
}

export interface CommercialPlan {
  id: string;
  code: string;
  name: string;
  description: string | null;
  priceMonthly: string;
  currency: string;
  isActive: boolean;
  displayOrder: number;
  planFeatures: PlanFeatureDefinition[];
}

export const getFeatures = () => api.get<FeatureDefinition[]>("/admin/features");
export const createFeature = (data: unknown) => api.post("/admin/features", data);
export const updateFeature = (id: string, data: unknown) => api.patch(`/admin/features/${id}`, data);
export const deactivateFeature = (id: string) => api.delete(`/admin/features/${id}`);

export const getPlans = () => api.get<CommercialPlan[]>("/admin/plans");
export const createPlan = (data: unknown) => api.post("/admin/plans", data);
export const updatePlan = (id: string, data: unknown) => api.patch(`/admin/plans/${id}`, data);
export const deactivatePlan = (id: string) => api.delete(`/admin/plans/${id}`);
export const replacePlanFeatures = (
  id: string,
  features: Array<{ featureId: string; enabled: boolean; value?: boolean | number | string | null }>,
) => api.put(`/admin/plans/${id}/features`, { features });
