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

  useEffect(() => {
    if (analyticsQuery.dataUpdatedAt) {
      setLastUpdated(new Date(analyticsQuery.dataUpdatedAt));
    }
  }, [analyticsQuery.dataUpdatedAt]);

  return {
    analytics: analyticsQuery.data,
    settings: settingsQuery.data,
    isLoading: analyticsQuery.isLoading,
    isError: analyticsQuery.isError,
    error: analyticsQuery.error,
    refetch: analyticsQuery.refetch,
    isFetching: analyticsQuery.isFetching,
    lastUpdated,
  };
};
