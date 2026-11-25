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

  getOrders: async (params = {}) => {
    const response = await apiClient.get('/reports/orders', { params });
    return response.data || response;
  },

  deleteOrder: async (orderId) => {
    const response = await apiClient.delete(`/reports/orders/${orderId}`);
    return response.data || response;
  },

  getCustomers: async (params = {}) => {
    const response = await apiClient.get('/reports/customers', { params });
    return response.data || response;
  },

  getSettings: async () => {
    const response = await apiClient.get('/settings');
    return response.data?.settings || response.settings;
  },

  getSyncStatus: async () => {
    const response = await apiClient.get('/sync/status');
    return response.data || response;
  },

  fetchCloudExport: async () => {
    const response = await apiClient.get('/sync/export');
    return response.data || response;
  },

  exportMongoDBBackup: async () => {
    const exportData = await reportsService.fetchCloudExport();
    const blob = new Blob([JSON.stringify(exportData, null, 2)], {
      type: 'application/json',
    });
    const url = URL.createObjectURL(blob);
    const downloadAnchor = document.createElement('a');
    const dateStr = new Date().toISOString().split('T')[0];
    const timeStr = new Date().toTimeString().split(' ')[0].replace(/:/g, '-');
    downloadAnchor.href = url;
    downloadAnchor.download = `HMB_Cloud_Backup_${dateStr}_${timeStr}.json`;
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
    URL.revokeObjectURL(url);
    return exportData;
  },
};
