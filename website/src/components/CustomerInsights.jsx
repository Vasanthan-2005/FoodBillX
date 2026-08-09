import React from 'react';
import { Users, UserPlus, RefreshCcw, Crown, HeartHandshake } from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

export const CustomerInsights = ({ customerInsights = {} }) => {
  const {
    totalCustomers = 0,
    newCustomers = 0,
    returningCustomers = 0,
    returningPercent = 0,
    highestSpender = null,
    mostFrequent = null,
  } = customerInsights;

  return (
    <div className="glass-card p-6 rounded-3xl mb-8">
      <div className="flex items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-cyan-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Customer Analytics & Insights</h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Loyalty metrics, repeat visitors, and top customers</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* New vs Returning */}
        <div className="glass-panel p-4 rounded-2xl border border-slate-800 flex items-center justify-between">
          <div className="space-y-1">
            <span className="text-xs font-semibold text-slate-400 block">New Customers</span>
            <span className="text-2xl font-black text-white">{formatNumber(newCustomers)}</span>
            <span className="text-[10px] text-slate-400 block">First-time visitors</span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-cyan-500/20 text-cyan-400 flex items-center justify-center">
            <UserPlus className="w-5 h-5" />
          </div>
        </div>

        {/* Returning Rate */}
        <div className="glass-panel p-4 rounded-2xl border border-slate-800 flex items-center justify-between">
          <div className="space-y-1">
            <span className="text-xs font-semibold text-slate-400 block">Repeat Customers</span>
            <span className="text-2xl font-black text-emerald-400">{formatNumber(returningCustomers)}</span>
            <span className="text-[10px] text-emerald-400 font-bold block">{returningPercent}% Loyalty Retention Rate</span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
            <RefreshCcw className="w-5 h-5" />
          </div>
        </div>

        {/* Highest Spender */}
        <div className="glass-panel p-4 rounded-2xl border border-slate-800 flex items-center justify-between">
          <div className="space-y-1">
            <span className="text-xs font-semibold text-slate-400 block">Top Spender</span>
            <span className="text-sm font-bold text-white block truncate max-w-[130px]">{highestSpender?.name || 'Walk-in Customer'}</span>
            <span className="text-sm font-black text-amber-400 block">{formatCurrency(highestSpender?.amount || 0)}</span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center">
            <Crown className="w-5 h-5" />
          </div>
        </div>

        {/* Most Frequent Visitor */}
        <div className="glass-panel p-4 rounded-2xl border border-slate-800 flex items-center justify-between">
          <div className="space-y-1">
            <span className="text-xs font-semibold text-slate-400 block">Most Frequent</span>
            <span className="text-sm font-bold text-white block truncate max-w-[130px]">{mostFrequent?.name || 'Regular Customer'}</span>
            <span className="text-sm font-black text-indigo-400 block">{formatNumber(mostFrequent?.visits || 0)} Total Visits</span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-indigo-500/20 text-indigo-400 flex items-center justify-center">
            <HeartHandshake className="w-5 h-5" />
          </div>
        </div>
      </div>
    </div>
  );
};
