import React, { useMemo, useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { FuturisticBackdrop } from './components/FuturisticBackdrop';
import { Header } from './components/Header';
import { CulinaryMotionReel } from './components/CulinaryMotionReel';
import { DateFilter } from './components/DateFilter';
import { OverviewCards } from './components/OverviewCards';
import { RevenueChart } from './components/RevenueChart';
import { OrdersChart } from './components/OrdersChart';
import { PaymentBreakdown } from './components/PaymentBreakdown';
import { TopSellingItems } from './components/TopSellingItems';
import { PeakHoursChart } from './components/PeakHoursChart';
import { CustomerInsights } from './components/CustomerInsights';
import { CustomersDirectory } from './components/CustomersDirectory';
import { RecentOrdersTable } from './components/RecentOrdersTable';
import { ExportActions } from './components/ExportActions';
import { SkeletonCard, SkeletonChart } from './components/SkeletonLoader';
import { useReportsData } from './hooks/useReportsData';

const queryClient = new QueryClient();

function formatSlicerLabel(period, refDate, customRange) {
  if (period === 'allTime') return 'All Time (Full History)';
  if (period === 'custom' && customRange.startDate && customRange.endDate) {
    return `${customRange.startDate} to ${customRange.endDate}`;
  }
  if (period === 'yearly') return `${refDate.getFullYear()} Full Year`;
  if (period === 'monthly') {
    return refDate.toLocaleDateString('en-IN', { month: 'long', year: 'numeric' });
  }
  if (period === 'weekly') {
    const day = refDate.getDay();
    const diffToMon = day === 0 ? 6 : day - 1;
    const mon = new Date(refDate);
    mon.setDate(refDate.getDate() - diffToMon);
    const sun = new Date(mon);
    sun.setDate(mon.getDate() + 6);
    const fmt = (d) => d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
    return `${fmt(mon)} – ${fmt(sun)} ${sun.getFullYear()}`;
  }
  return refDate.toLocaleDateString('en-IN', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
}

function isSameCalendarDay(a, b) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function MainDashboard() {
  const [activeTab, setActiveTab] = useState('reports');
  const [currentPeriod, setCurrentPeriod] = useState('monthly');
  const [refDate, setRefDate] = useState(() => new Date());
  const [customRange, setCustomRange] = useState({ startDate: '', endDate: '' });

  const filterParams = useMemo(
    () => ({
      period: currentPeriod,
      refDate: refDate.toISOString(),
      ...(currentPeriod === 'custom' && customRange.startDate && customRange.endDate
        ? customRange
        : {}),
    }),
    [currentPeriod, refDate, customRange]
  );

  const {
    analytics,
    settings,
    syncStatus,
    isLoading,
    isError,
    error,
    refetch,
    isFetching,
    lastUpdated,
    socketConnected,
  } = useReportsData(filterParams);

  const availableMonths = analytics?.availableMonths || [];

  const availableMonthStarts = useMemo(
    () =>
      availableMonths
        .map((ym) => {
          const [y, m] = String(ym).split('-').map(Number);
          return y && m ? new Date(y, m - 1, 1) : null;
        })
        .filter(Boolean)
        .sort((a, b) => a - b),
    [availableMonths]
  );

  const availableYears = useMemo(() => {
    const set = new Set(availableMonthStarts.map((d) => d.getFullYear()));
    return Array.from(set).sort((a, b) => a - b);
  }, [availableMonthStarts]);

  const handlePeriodChange = (period) => {
    setCurrentPeriod(period);
    setRefDate(new Date());
  };

  const handleStepPeriod = (delta) => {
    if (currentPeriod === 'monthly' && availableMonthStarts.length > 0) {
      const currStart = new Date(refDate.getFullYear(), refDate.getMonth(), 1);
      if (delta < 0) {
        const prev = availableMonthStarts.filter((d) => d < currStart);
        if (prev.length > 0) setRefDate(prev[prev.length - 1]);
      } else {
        const now = new Date();
        const currRealMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const next = availableMonthStarts.filter((d) => d > currStart && d <= currRealMonth);
        if (next.length > 0) setRefDate(next[0]);
      }
      return;
    }

    if (currentPeriod === 'yearly' && availableYears.length > 0) {
      const y = refDate.getFullYear();
      if (delta < 0) {
        const prev = availableYears.filter((yr) => yr < y);
        if (prev.length > 0) setRefDate(new Date(prev[prev.length - 1], 0, 1));
      } else {
        const next = availableYears.filter((yr) => yr > y && yr <= new Date().getFullYear());
        if (next.length > 0) setRefDate(new Date(next[0], 0, 1));
      }
      return;
    }

    const next = new Date(refDate);
    if (currentPeriod === 'daily') next.setDate(next.getDate() + delta);
    else if (currentPeriod === 'weekly') next.setDate(next.getDate() + delta * 7);
    else if (currentPeriod === 'monthly') next.setMonth(next.getMonth() + delta);
    else if (currentPeriod === 'yearly') next.setFullYear(next.getFullYear() + delta);
    setRefDate(next);
  };

  const canStepPrev = useMemo(() => {
    if (currentPeriod === 'allTime' || currentPeriod === 'custom') return false;
    if (availableMonthStarts.length === 0) return true;
    const earliest = availableMonthStarts[0];
    if (currentPeriod === 'monthly') {
      const currStart = new Date(refDate.getFullYear(), refDate.getMonth(), 1);
      return availableMonthStarts.some((d) => d < currStart);
    }
    if (currentPeriod === 'yearly') {
      return availableYears.some((yr) => yr < refDate.getFullYear());
    }
    const dayStart = new Date(refDate.getFullYear(), refDate.getMonth(), refDate.getDate());
    return dayStart > earliest;
  }, [currentPeriod, refDate, availableMonthStarts, availableYears]);

  const canStepNext = useMemo(() => {
    const now = new Date();
    if (currentPeriod === 'daily') return !isSameCalendarDay(refDate, now) && refDate < now;
    if (currentPeriod === 'monthly') {
      const currStart = new Date(refDate.getFullYear(), refDate.getMonth(), 1);
      const realMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      if (availableMonthStarts.length > 0) {
        return availableMonthStarts.some((d) => d > currStart && d <= realMonth);
      }
      return currStart < realMonth;
    }
    if (currentPeriod === 'yearly') {
      if (availableYears.length > 0) {
        return availableYears.some((yr) => yr > refDate.getFullYear() && yr <= now.getFullYear());
      }
      return refDate.getFullYear() < now.getFullYear();
    }
    if (currentPeriod === 'weekly') return refDate < now;
    return false;
  }, [currentPeriod, refDate, availableMonthStarts, availableYears]);

  const periodLabel = useMemo(
    () => formatSlicerLabel(currentPeriod, refDate, customRange),
    [currentPeriod, refDate, customRange]
  );

  return (
    <div className="min-h-screen text-slate-100 pb-16 relative selection:bg-[#FF6D00] selection:text-white">
      <FuturisticBackdrop />

      <Header
        settings={settings}
        syncStatus={syncStatus}
        lastUpdated={lastUpdated}
        isFetching={isFetching}
        socketConnected={socketConnected}
        onRefresh={refetch}
        activeTab={activeTab}
        onTabChange={setActiveTab}
      />

      <CulinaryMotionReel
        analytics={analytics}
        settings={settings}
        periodLabel={periodLabel}
      />

      {(activeTab === 'reports' || activeTab === 'orders' || activeTab === 'export') && (
        <DateFilter
          currentPeriod={currentPeriod}
          refDate={refDate}
          periodLabel={periodLabel}
          canStepPrev={canStepPrev}
          canStepNext={canStepNext}
          isCurrentToday={isSameCalendarDay(refDate, new Date())}
          availableMonths={availableMonths}
          onPeriodChange={handlePeriodChange}
          onStepPeriod={handleStepPeriod}
          onSelectDate={(d) => setRefDate(d)}
          onJumpToday={() => setRefDate(new Date())}
          onCustomRangeChange={(startDate, endDate) => {
            setCustomRange({ startDate, endDate });
            setCurrentPeriod('custom');
          }}
        />
      )}

      <main className="max-w-7xl mx-auto px-4 md:px-8">
        {isError && (
          <div className="cyber-panel p-4 mb-6 rounded-2xl border border-rose-500/35 bg-rose-500/10 text-rose-300 text-xs font-semibold flex items-center justify-between">
            <span>Unable to connect to backend server: {error?.message}</span>
            <button
              type="button"
              onClick={refetch}
              className="px-3 py-1 bg-rose-500 text-white rounded-lg font-bold"
            >
              Retry
            </button>
          </div>
        )}

        <AnimatePresence mode="wait">
          {activeTab === 'reports' && (
            <motion.div
              key="reports-tab"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -12 }}
              transition={{ duration: 0.25 }}
            >
              {isLoading ? (
                <div className="space-y-6">
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    <SkeletonCard />
                    <SkeletonCard />
                    <SkeletonCard />
                    <SkeletonCard />
                  </div>
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                    <div className="lg:col-span-8">
                      <SkeletonChart />
                    </div>
                    <div className="lg:col-span-4">
                      <SkeletonChart />
                    </div>
                  </div>
                </div>
              ) : (
                <div className="space-y-6">
                  <OverviewCards
                    kpis={analytics?.kpis}
                    customerInsights={analytics?.customerInsights}
                  />

                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                    <div className="lg:col-span-8">
                      <RevenueChart dailyTrend={analytics?.dailyTrend} />
                    </div>
                    <div className="lg:col-span-4">
                      <PaymentBreakdown paymentBreakdown={analytics?.paymentBreakdown} />
                    </div>

                    <div className="lg:col-span-6">
                      <TopSellingItems topSellingItems={analytics?.topSellingItems} />
                    </div>
                    <div className="lg:col-span-6">
                      <PeakHoursChart hourlyData={analytics?.hourlyData} />
                    </div>

                    <div className="lg:col-span-6">
                      <OrdersChart dailyTrend={analytics?.dailyTrend} />
                    </div>
                    <div className="lg:col-span-6">
                      <CustomerInsights customerInsights={analytics?.customerInsights} />
                    </div>
                  </div>
                </div>
              )}
            </motion.div>
          )}

          {activeTab === 'orders' && (
            <motion.div
              key="orders-tab"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -12 }}
              transition={{ duration: 0.25 }}
            >
              <RecentOrdersTable
                filterParams={filterParams}
                settings={settings}
                fallbackOrders={analytics?.recentOrders}
              />
            </motion.div>
          )}

          {activeTab === 'customers' && (
            <motion.div
              key="customers-tab"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -12 }}
              transition={{ duration: 0.25 }}
            >
              <CustomersDirectory />
            </motion.div>
          )}

          {activeTab === 'export' && (
            <motion.div
              key="export-tab"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -12 }}
              transition={{ duration: 0.25 }}
            >
              <ExportActions
                analytics={analytics}
                settings={settings}
                periodLabel={periodLabel}
              />
            </motion.div>
          )}
        </AnimatePresence>
      </main>

      <footer className="text-center text-xs text-slate-500 py-6 border-t border-white/10 mt-12 no-print">
        <p>
          {settings?.businessName || 'HMB Bills'} • Cloud Business Dashboard
        </p>
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
