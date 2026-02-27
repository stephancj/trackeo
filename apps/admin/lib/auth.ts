"use client";

const KEY = "access_token";
const COOKIE_MAX_AGE = 7 * 24 * 60 * 60; // 7 days

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(KEY);
}

export function setToken(token: string) {
  localStorage.setItem(KEY, token);
  // Also write to a cookie so middleware (server-side) can read it
  document.cookie = `${KEY}=${token}; path=/; max-age=${COOKIE_MAX_AGE}; SameSite=Lax`;
}

export function clearToken() {
  localStorage.removeItem(KEY);
  document.cookie = `${KEY}=; path=/; max-age=0`;
}

export function isAuthenticated(): boolean {
  return !!getToken();
}
