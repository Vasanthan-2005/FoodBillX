import { apiClient } from './api';

export const reportsService = {
  getAnalytics: async (params = {}) => {
    const response = await apiClient.get('/reports/analytics', { params });
    return response.data?.analytics || response.analytics;
  },

  getDashboardSummary: async () => {
    const response = await apiClient.get('/reports/dashboard');
    return response.data?.summary || response.summary;
  },

  getSettings: async () => {
    const response = await apiClient.get('/settings');
    return response.data?.settings || response.settings;
  },
};
