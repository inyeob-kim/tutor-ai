// src/services/http.ts
import { getApiBaseUrl } from "./baseUrl";

const base = getApiBaseUrl();

export async function http<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(base + path, {
    headers: { "Content-Type": "application/json", ...(init?.headers || {}) },
    ...init,
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json() as Promise<T>;
}
