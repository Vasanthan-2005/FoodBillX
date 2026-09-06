import { useQuery } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { reportsService } from '../services/reportsService';

export const useReportsData = (filterParams) => {
  const [lastUpdated, setLastUpdated] = useState(new Date());

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

  const handleRefetchAll = () => {
    analyticsQuery.refetch();
    syncStatusQuery.refetch();
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
  };
};
