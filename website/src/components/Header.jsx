import React from 'react';
import { Utensils, RefreshCw, Calendar, Clock } from 'lucide-react';

export const Header = ({ settings, lastUpdated, isFetching, onRefresh }) => {
  const shopName = settings?.businessName || 'FoodBillX Outlet';

  return (
    <header className="sticky top-0 z-40 glass-panel border-b border-slate-800/80 px-4 md:px-8 py-4 mb-6 shadow-xl">
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row md:items-center md:justify-between gap-4">
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
              <span>Honeymoon Biryani POS Analytics</span>
            </p>
          </div>
        </div>

        {/* Status Indicators & Refresh Button */}
        <div className="flex flex-wrap items-center gap-3 md:gap-4 text-xs">
          {/* Current Date Badge */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-slate-300">
            <Calendar className="w-3.5 h-3.5 text-[#FF5722]" />
            <span className="font-semibold">{new Date().toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })}</span>
          </div>

          {/* Last Refreshed Time */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-slate-400">
            <Clock className="w-3.5 h-3.5 text-slate-400" />
            <span>Updated {lastUpdated ? lastUpdated.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : 'just now'}</span>
          </div>

          {/* Prominent Refresh Button */}
          <button
            onClick={onRefresh}
            disabled={isFetching}
            className="px-4 py-2 rounded-xl bg-[#FF5722] hover:bg-[#F4511E] text-white font-bold shadow-lg shadow-[#FF5722]/30 flex items-center gap-2 transition-all disabled:opacity-50"
            title="Refresh Report Data"
          >
            <RefreshCw className={`w-4 h-4 ${isFetching ? 'animate-spin' : ''}`} />
            <span>{isFetching ? 'Refreshing...' : 'Refresh Data'}</span>
          </button>
        </div>
      </div>
    </header>
  );
};
