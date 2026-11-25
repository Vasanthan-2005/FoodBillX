import React, { useState } from 'react';
import {
  Utensils,
  RefreshCw,
  Clock,
  Database,
  Download,
  Cloud,
  CheckCircle2,
  BarChart3,
  Receipt,
  Users,
  FolderArchive,
  Wifi,
} from 'lucide-react';
import { reportsService } from '../services/reportsService';
import { formatNumber } from '../utils/formatters';

const NAV_TABS = [
  { id: 'reports', label: 'Analytics Hub', icon: BarChart3 },
  { id: 'orders', label: 'Orders Terminal', icon: Receipt },
  { id: 'customers', label: 'Loyalty Matrix', icon: Users },
  { id: 'export', label: 'Export Vault', icon: FolderArchive },
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
      setExportMessage(`Exported ${formatNumber(total)} MongoDB cloud records.`);
      setTimeout(() => setExportMessage(null), 5000);
    } catch (err) {
      setExportMessage(`Export failed: ${err.message}`);
      setTimeout(() => setExportMessage(null), 5000);
    } finally {
      setIsExporting(false);
    }
  };

  const formatLastSync = (isoString) => {
    if (!isoString) return 'Pending initial sync';
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

  const dbStatus = syncStatus?.databaseStatus || 'Connected';
  const totalCloudRecords = syncStatus?.totalRecords ?? 0;
  const lastSynced = syncStatus?.lastSyncedAt;

  return (
    <header className="sticky top-0 z-40 cyber-panel border-b border-white/10 px-4 md:px-8 py-3.5 mb-6 shadow-glass no-print">
      <div className="max-w-7xl mx-auto flex flex-col gap-3.5">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
          {/* Brand Logo & Shop Name */}
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-[#FF6D00] to-[#FFB300] flex items-center justify-center shadow-glow">
              <Utensils className="w-6 h-6 text-white" />
            </div>
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="font-display text-xl font-extrabold text-white tracking-tight">
                  {shopName}
                </h1>
                <span className="px-2 py-0.5 text-[10px] font-mono font-bold rounded-full bg-[#FF6D00]/20 text-[#FF8F00] border border-[#FF6D00]/40 uppercase tracking-wider">
                  Command OS
                </span>
              </div>
              <p className="text-xs text-slate-400 font-medium mt-0.5">
                Executive Cloud Telemetry • Real-Time POS Mirror
              </p>
            </div>
          </div>

          {/* Telemetry Pills & Actions */}
          <div className="flex flex-wrap items-center gap-2 text-xs">
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border border-emerald-500/30 text-emerald-400 font-medium">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <Database className="w-3.5 h-3.5" />
              <span>
                Atlas: <strong>{dbStatus}</strong>
              </span>
            </div>

            <div
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border ${
                socketConnected
                  ? 'border-cyan-500/35 text-cyan-300'
                  : 'border-white/10 text-slate-400'
              }`}
            >
              <Wifi className="w-3.5 h-3.5" />
              <span>{socketConnected ? 'Stream Live' : 'Polling'}</span>
            </div>

            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-slate-300">
              <Cloud className="w-3.5 h-3.5 text-cyan-400" />
              <span>
                Synced: <strong>{formatLastSync(lastSynced)}</strong>
              </span>
              {totalCloudRecords > 0 && (
                <span className="ml-1 px-1.5 py-0.5 rounded-md bg-cyan-500/15 text-cyan-300 text-[10px] font-mono font-bold">
                  {formatNumber(totalCloudRecords)}
                </span>
              )}
            </div>

            <div className="hidden xl:flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-slate-400">
              <Clock className="w-3.5 h-3.5" />
              <span>
                {lastUpdated
                  ? lastUpdated.toLocaleTimeString([], {
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
              className="px-3.5 py-2 rounded-xl bg-emerald-600/90 hover:bg-emerald-500 text-white font-bold shadow-lg shadow-emerald-600/20 flex items-center gap-1.5 transition-all disabled:opacity-50"
            >
              <Download className={`w-3.5 h-3.5 ${isExporting ? 'animate-bounce' : ''}`} />
              <span>{isExporting ? 'Dumping...' : 'Cloud JSON'}</span>
            </button>

            <button
              type="button"
              onClick={onRefresh}
              disabled={isFetching}
              className="px-3.5 py-2 rounded-xl bg-gradient-to-r from-[#FF6D00] to-[#FF9100] hover:brightness-110 text-white font-bold shadow-glow flex items-center gap-1.5 transition-all disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isFetching ? 'animate-spin' : ''}`} />
              <span>{isFetching ? 'Syncing...' : 'Refresh'}</span>
            </button>
          </div>
        </div>

        {/* Navigation Switcher Bar */}
        <nav className="flex flex-wrap items-center gap-2 pt-1 border-t border-white/5">
          {NAV_TABS.map((tab) => {
            const Icon = tab.icon;
            const selected = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => onTabChange(tab.id)}
                className={`px-3.5 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition-all ${
                  selected
                    ? 'bg-gradient-to-r from-[#FF6D00] to-[#FF9100] text-white shadow-glow'
                    : 'bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span>{tab.label}</span>
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
