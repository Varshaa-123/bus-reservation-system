// All calls use relative URLs (/api/...).
//  - npm run dev : Vite proxies /api to http://localhost:8080
//  - Docker      : nginx proxies /api to http://backend:8080
const BASE_URL = import.meta.env.VITE_API_URL || '';

async function request(path, options = {}) {
  let response;
  try {
    response = await fetch(`${BASE_URL}${path}`, {
      headers: { 'Content-Type': 'application/json' },
      ...options,
    });
  } catch (networkError) {
    throw new Error('Cannot reach the server. Is the backend running?');
  }

  let data = null;
  try {
    data = await response.json();
  } catch (parseError) {
    data = null;
  }

  if (!response.ok) {
    throw new Error(data?.message || `Request failed (HTTP ${response.status}). Is the backend running?`);
  }
  return data;
}

export const api = {
  getReservations: () => request('/api/reservations'),
  getRoutesAboveAverage: () => request('/api/routes/above-average'),
  getBuses: () => request('/api/buses'),
  getRoutes: () => request('/api/routes'),
  getPassengers: () => request('/api/passengers'),
  getFare: (routeId) => request(`/api/routes/${routeId}/fare`),
  reserveSeat: (payload) =>
    request('/api/reservations', { method: 'POST', body: JSON.stringify(payload) }),
  createPassenger: (payload) =>
    request('/api/passengers', { method: 'POST', body: JSON.stringify(payload) }),
};
