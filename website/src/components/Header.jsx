import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  Utensils,
  RefreshCw,
  Clock,
  Download,
  Cloud,
  CheckCircle2,
  BarChart3,
  Receipt,
  Users,
  FolderArchive,
  Radio,
} from 'lucide-react';
import { reportsService } from '../services/reportsService';
import { formatNumber } from '../utils/formatters';

const NAV_TABS = [
  { id: 'reports', label: 'Dashboard', icon: BarChart3 },
  { id: 'orders', label: 'Orders', icon: Receipt },
  { id: 'customers', label: 'Customers', icon: Users },
  { id: 'export', label: 'Export & Backup', icon: FolderArchive },
];

export const Header = ({
  settings,
  syncStatus,
  lastUpdated,
  isFetching,
  socketConnected,
  onRefresh,
  activeTab,
  onTabChange,
}) => {
  const [isExporting, setIsExporting] = useState(false);
  const [exportMessage, setExportMessage] = useState(null);

  const shopName = settings?.businessName || 'HMB Bills';

  const handleExportBackup = async () => {
    try {
      setIsExporting(true);
      setExportMessage(null);
      const data = await reportsService.exportMongoDBBackup();
      const total = data?.summary?.totalRecords ?? 'all';
      setExportMessage(`Downloaded full cloud backup (${formatNumber(total)} records).`);
      setTimeout(() => setExportMessage(null), 5000);
    } catch (err) {
      setExportMessage(`Backup failed: ${err.message}`);
      setTimeout(() => setExportMessage(null), 5000);
    } finally {
      setIsExporting(false);
    }
  };

  const formatLastSync = (isoString) => {
    if (!isoString) return 'Waiting for sync';
    const date = new Date(isoString);
    if (Number.isNaN(date.getTime())) return 'Recently';
    return date.toLocaleString('en-IN', {
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
    });
  };

  const dbConnected = (syncStatus?.databaseStatus || 'Connected').toLowerCase() === 'connected';
  const totalCloudRecords = syncStatus?.totalRecords ?? 0;
  const lastSynced = syncStatus?.lastSyncedAt;

  return (
    <header className="sticky top-0 z-40 cyber-panel border-b border-white/10 px-4 md:px-8 py-3 mb-6 shadow-glass no-print">
      <div className="max-w-7xl mx-auto flex flex-col gap-3">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
          {/* Brand Crest & Friendly Subtitle */}
          <div className="flex items-center gap-3.5">
            <div className="relative">
              <div className="absolute -inset-1 rounded-2xl border border-[#FF6D00]/40 border-dashed animate-slow-orbit pointer-events-none" />
              <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-[#FF6D00] via-[#FF8F00] to-[#FFB300] flex items-center justify-center shadow-glow relative">
                <Utensils className="w-5 h-5 text-white" />
              </div>
            </div>
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="font-display text-xl font-extrabold text-white tracking-tight">
                  {shopName}
                </h1>
                <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 text-[10px] font-mono font-bold rounded-full bg-emerald-500/15 text-emerald-300 border border-emerald-500/35 uppercase tracking-wider">
                  <span
                    className={`w-1.5 h-1.5 rounded-full ${
                      dbConnected ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'
                    }`}
                  />
                  {socketConnected ? 'Live Cloud' : 'Cloud Connected'}
                </span>
              </div>
              <p className="text-xs text-slate-400 font-medium mt-0.5">
                Live Restaurant Sales, Orders & Customer Analytics
              </p>
            </div>
          </div>

          {/* Clear Status Chips & Actions */}
          <div className="flex flex-wrap items-center gap-2 text-xs">
            <div
              className={`hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border ${
                socketConnected
                  ? 'border-cyan-500/35 text-cyan-300'
                  : 'border-white/10 text-slate-400'
              }`}
              title="Real-time updates from POS devices"
            >
              <Radio className={`w-3.5 h-3.5 ${socketConnected ? 'animate-pulse' : ''}`} />
              <span className="font-medium">
                {socketConnected ? 'Auto-Sync Live' : 'Auto-Updating'}
              </span>
            </div>

            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-slate-300">
              <Cloud className="w-3.5 h-3.5 text-cyan-400 shrink-0" />
              <span>
                Last Sync: <strong className="text-white">{formatLastSync(lastSynced)}</strong>
              </span>
              {totalCloudRecords > 0 && (
                <span className="ml-1 px-1.5 py-0.5 rounded-md bg-cyan-500/15 text-cyan-300 text-[10px] font-mono font-bold tabular-nums">
                  {formatNumber(totalCloudRecords)} saved
                </span>
              )}
            </div>

            <div className="hidden xl:flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-slate-400 tabular-nums">
              <Clock className="w-3.5 h-3.5" />
              <span>
                {lastUpdated
                  ? lastUpdated.toLocaleTimeString('en-IN', {
                      hour: '2-digit',
                      minute: '2-digit',
                      second: '2-digit',
                    })
                  : 'now'}
              </span>
            </div>

            <button
              type="button"
              onClick={handleExportBackup}
              disabled={isExporting}
              className="px-3.5 py-2 rounded-xl bg-emerald-500/15 hover:bg-emerald-500/25 border border-emerald-500/35 text-emerald-300 font-bold flex items-center gap-1.5 transition-all disabled:opacity-50"
              title="Download full cloud data in JSON format"
            >
              <Download className={`w-3.5 h-3.5 ${isExporting ? 'animate-bounce' : ''}`} />
              <span>{isExporting ? 'Saving...' : 'Backup JSON'}</span>
            </button>

            <button
              type="button"
              onClick={onRefresh}
              disabled={isFetching}
              className="px-3.5 py-2 rounded-xl bg-gradient-to-r from-[#FF6D00] to-[#FF9100] hover:brightness-110 text-white font-bold shadow-glow flex items-center gap-1.5 transition-all disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isFetching ? 'animate-spin' : ''}`} />
              <span>{isFetching ? 'Updating...' : 'Refresh'}</span>
            </button>
          </div>
        </div>

        {/* Navigation Switcher Bar with Animated Sliding Indicator */}
        <nav className="flex flex-wrap items-center gap-1.5 pt-2 border-t border-white/5">
          {NAV_TABS.map((tab) => {
            const Icon = tab.icon;
            const selected = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => onTabChange(tab.id)}
                className={`relative px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition-colors ${
                  selected ? 'text-white' : 'text-slate-400 hover:text-white'
                }`}
              >
                {selected && (
                  <motion.div
                    layoutId="headerTabPill"
                    transition={{ type: 'spring', stiffness: 420, damping: 32 }}
                    className="absolute inset-0 rounded-xl bg-gradient-to-r from-[#FF6D00] to-[#FF9100] shadow-glow"
                  />
                )}
                {!selected && (
                  <div className="absolute inset-0 rounded-xl bg-white/[0.03] border border-white/[0.07]" />
                )}
                <Icon className="w-3.5 h-3.5 relative z-10" />
                <span className="relative z-10">{tab.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {exportMessage && (
        <div className="max-w-7xl mx-auto mt-3">
          <div className="px-4 py-2 rounded-xl bg-emerald-500/15 border border-emerald-500/35 text-emerald-300 text-xs font-semibold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>{exportMessage}</span>
          </div>
        </div>
      )}
    </header>
  );
};
