import React, { useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Header } from './components/Header';
import { DateFilter } from './components/DateFilter';
import { OverviewCards } from './components/OverviewCards';
import { RevenueChart } from './components/RevenueChart';
import { OrdersChart } from './components/OrdersChart';
import { PaymentBreakdown } from './components/PaymentBreakdown';
import { TopSellingItems } from './components/TopSellingItems';
import { CategoryPerformance } from './components/CategoryPerformance';
import { PeakHoursChart } from './components/PeakHoursChart';
import { CustomerInsights } from './components/CustomerInsights';
import { RecentOrdersTable } from './components/RecentOrdersTable';
import { ExportActions } from './components/ExportActions';
import { SkeletonCard, SkeletonChart } from './components/SkeletonLoader';
import { useReportsData } from './hooks/useReportsData';

const queryClient = new QueryClient();

function MainDashboard() {
  const [currentPeriod, setCurrentPeriod] = useState('today');
  const [customRange, setCustomRange] = useState({ startDate: '', endDate: '' });

  const filterParams = {
    period: currentPeriod,
    ...(currentPeriod === 'custom' && customRange.startDate && customRange.endDate ? customRange : {}),
  };

  const { analytics, settings, syncStatus, isLoading, isError, error, refetch, isFetching, lastUpdated } =
    useReportsData(filterParams);

  const handlePeriodChange = (period) => {
    setCurrentPeriod(period);
  };

  const handleCustomRangeChange = (start, end) => {
    setCustomRange({ startDate: start, endDate: end });
    setCurrentPeriod('custom');
  };

  return (
    <div className="min-h-screen bg-[#0F172A] text-slate-100 pb-16 selection:bg-[#FF5722] selection:text-white">
      {/* 1. Header */}
      <Header
        settings={settings}
        syncStatus={syncStatus}
        lastUpdated={lastUpdated}
        isFetching={isFetching}
        onRefresh={refetch}
      />

      {/* 2. Date Filter */}
      <DateFilter
        currentPeriod={currentPeriod}
        onPeriodChange={handlePeriodChange}
        onCustomRangeChange={handleCustomRangeChange}
      />

      {/* Main Single Page Content Flow */}
      <main className="max-w-7xl mx-auto px-4 md:px-8">
        {isError && (
          <div className="glass-panel p-4 mb-6 rounded-2xl border border-rose-500/30 bg-rose-500/10 text-rose-300 text-xs font-semibold flex items-center justify-between">
            <span>Unable to connect to backend server: {error?.message}</span>
            <button onClick={() => refetch()} className="px-3 py-1 bg-rose-500 text-white rounded-lg font-bold">
              Retry
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="space-y-6">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <SkeletonCard />
              <SkeletonCard />
              <SkeletonCard />
              <SkeletonCard />
            </div>
            <SkeletonChart />
            <SkeletonChart />
          </div>
        ) : (
          <>
            {/* 3. Overview KPI Cards */}
            <OverviewCards kpis={analytics?.kpis} />

            {/* 4. Revenue Trend Chart */}
            <RevenueChart dailyTrend={analytics?.dailyTrend} />

            {/* 5. Orders Volume Trend Chart */}
            <OrdersChart dailyTrend={analytics?.dailyTrend} />

            {/* 6. Payment Breakdown Chart */}
            <PaymentBreakdown paymentBreakdown={analytics?.paymentBreakdown} />

            {/* 7. Top Selling Items */}
            <TopSellingItems topSellingItems={analytics?.topSellingItems} />

            {/* 8. Category Performance */}
            <CategoryPerformance categoryPerformance={analytics?.categoryPerformance} />

            {/* 9. Peak Selling Hours */}
            <PeakHoursChart hourlyData={analytics?.hourlyData} />

            {/* 10. Customer Insights */}
            <CustomerInsights customerInsights={analytics?.customerInsights} />

            {/* 11. Recent Orders Table */}
            <RecentOrdersTable recentOrders={analytics?.recentOrders} />

            {/* 12. Export Actions */}
            <ExportActions analytics={analytics} syncStatus={syncStatus} />
          </>
        )}
      </main>

      {/* Footer */}
      <footer className="text-center text-xs text-slate-500 py-6 border-t border-slate-800/60 mt-12">
        <p>FoodBillX Reports Hub • Executive Analytics for Honeymoon Biryani</p>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <MainDashboard />
    </QueryClientProvider>
  );
}
