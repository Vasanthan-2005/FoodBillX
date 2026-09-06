import React, { useState } from 'react';
import { Utensils, RefreshCw, Calendar, Clock, Database, Download, Cloud, HardDrive, CheckCircle2 } from 'lucide-react';
import { reportsService } from '../services/reportsService';

export const Header = ({ settings, syncStatus, lastUpdated, isFetching, onRefresh }) => {
  const [isExporting, setIsExporting] = useState(false);
  const [exportMessage, setExportMessage] = useState(null);

  const shopName = settings?.businessName || 'FoodBillX Outlet';

  const handleExportBackup = async () => {
    try {
      setIsExporting(true);
      setExportMessage(null);
      const data = await reportsService.exportMongoDBBackup();
      const total = data?.summary?.totalRecords ?? 'all';
      setExportMessage(`✓ Successfully exported ${total} MongoDB cloud records!`);
      setTimeout(() => setExportMessage(null), 5000);
    } catch (err) {
      setExportMessage(`Export failed: ${err.message}`);
      setTimeout(() => setExportMessage(null), 5000);
    } finally {
      setIsExporting(false);
    }
  };

  const formatLastSync = (isoString) => {
    if (!isoString) return 'No sync recorded yet';
    const date = new Date(isoString);
    if (isNaN(date.getTime())) return 'Recently';
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
    <header className="sticky top-0 z-40 glass-panel border-b border-slate-800/80 px-4 md:px-8 py-4 mb-6 shadow-xl">
      <div className="max-w-7xl mx-auto flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        {/* Brand Logo & Shop Name */}
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-[#FF5722] to-[#FF8A65] flex items-center justify-center shadow-lg shadow-[#FF5722]/30">
            <Utensils className="w-6 h-6 text-white" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-extrabold text-white tracking-tight">{shopName}</h1>
              <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-[#FF5722]/20 text-[#FF5722] border border-[#FF5722]/40 uppercase tracking-wider">
                Reports Hub
              </span>
            </div>
            <p className="text-xs text-slate-400 font-medium flex items-center gap-1.5 mt-0.5">
              <span>Honeymoon Biryani Cloud Analytics</span>
            </p>
          </div>
        </div>

        {/* Live Refresh & Cloud Status Details */}
        <div className="flex flex-wrap items-center gap-2.5 md:gap-3 text-xs">
          {/* Cloud Database Health Badge */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800/90 border border-emerald-500/30 text-emerald-400 font-medium shadow-sm">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <Database className="w-3.5 h-3.5 text-emerald-400" />
            <span>MongoDB: <strong>{dbStatus}</strong></span>
          </div>

          {/* Last Mobile Cloud Sync Detail */}
          <div
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-slate-300"
            title="Last time local mobile POS synced changes to MongoDB"
          >
            <Cloud className="w-3.5 h-3.5 text-blue-400" />
            <span>Mobile Sync: <strong>{formatLastSync(lastSynced)}</strong></span>
            {totalCloudRecords > 0 && (
              <span className="ml-1 px-1.5 py-0.2 rounded-md bg-blue-500/20 text-blue-300 text-[10px] font-bold">
                {totalCloudRecords} docs
              </span>
            )}
          </div>

          {/* Last Refreshed Time */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-slate-400">
            <Clock className="w-3.5 h-3.5 text-slate-400" />
            <span>Refreshed: {lastUpdated ? lastUpdated.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : 'just now'}</span>
          </div>

          {/* Export All Data from MongoDB Button */}
          <button
            onClick={handleExportBackup}
            disabled={isExporting}
            className="px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold shadow-lg shadow-emerald-600/20 flex items-center gap-1.5 transition-all disabled:opacity-50"
            title="Export complete MongoDB cloud database as JSON"
          >
            <Download className={`w-3.5 h-3.5 ${isExporting ? 'animate-bounce' : ''}`} />
            <span>{isExporting ? 'Exporting...' : 'Export MongoDB Data'}</span>
          </button>

          {/* Refresh Dashboard Button */}
          <button
            onClick={onRefresh}
            disabled={isFetching}
            className="px-3.5 py-2 rounded-xl bg-[#FF5722] hover:bg-[#F4511E] text-white font-bold shadow-lg shadow-[#FF5722]/30 flex items-center gap-1.5 transition-all disabled:opacity-50"
            title="Refresh Report Data"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isFetching ? 'animate-spin' : ''}`} />
            <span>{isFetching ? 'Refreshing...' : 'Refresh'}</span>
          </button>
        </div>
      </div>

      {/* Export notification toast */}
      {exportMessage && (
        <div className="max-w-7xl mx-auto mt-3">
          <div className="px-4 py-2 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs font-semibold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>{exportMessage}</span>
          </div>
        </div>
      )}
    </header>
  );
};
