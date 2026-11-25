import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { io } from 'socket.io-client';
import { reportsService } from '../services/reportsService';

export const useReportsData = (filterParams) => {
  const queryClient = useQueryClient();
  const [lastUpdated, setLastUpdated] = useState(new Date());
  const [socketConnected, setSocketConnected] = useState(false);

  const analyticsQuery = useQuery({
    queryKey: ['analytics', filterParams],
    queryFn: () => reportsService.getAnalytics(filterParams),
    staleTime: 0,
    gcTime: 300000,
  });

  const settingsQuery = useQuery({
    queryKey: ['settings'],
    queryFn: reportsService.getSettings,
    staleTime: 300000,
  });

  const syncStatusQuery = useQuery({
    queryKey: ['syncStatus'],
    queryFn: reportsService.getSyncStatus,
    staleTime: 15000,
    refetchInterval: 30000,
  });

  useEffect(() => {
    if (analyticsQuery.dataUpdatedAt) {
      setLastUpdated(new Date(analyticsQuery.dataUpdatedAt));
    }
  }, [analyticsQuery.dataUpdatedAt]);

  useEffect(() => {
    const baseApi = import.meta.env.VITE_API_URL || 'http://localhost:5000/api/v1';
    const socketUrl = baseApi.replace(/\/api\/v1\/?$/, '');
    const socket = io(socketUrl, {
      transports: ['websocket', 'polling'],
      reconnectionAttempts: 5,
    });

    socket.on('connect', () => setSocketConnected(true));
    socket.on('disconnect', () => setSocketConnected(false));
    socket.on('data_updated', () => {
      queryClient.invalidateQueries({ queryKey: ['analytics'] });
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['customers'] });
      queryClient.invalidateQueries({ queryKey: ['syncStatus'] });
    });

    return () => {
      socket.disconnect();
    };
  }, [queryClient]);

  const handleRefetchAll = () => {
    analyticsQuery.refetch();
    syncStatusQuery.refetch();
    queryClient.invalidateQueries({ queryKey: ['orders'] });
    queryClient.invalidateQueries({ queryKey: ['customers'] });
  };

  return {
    analytics: analyticsQuery.data,
    settings: settingsQuery.data,
    syncStatus: syncStatusQuery.data,
    isLoading: analyticsQuery.isLoading,
    isError: analyticsQuery.isError,
    error: analyticsQuery.error,
    refetch: handleRefetchAll,
    isFetching: analyticsQuery.isFetching || syncStatusQuery.isFetching,
    lastUpdated,
    socketConnected,
  };
};
