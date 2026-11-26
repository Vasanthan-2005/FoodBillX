import React from 'react';
import { Users, UserPlus, RefreshCcw, Crown, HeartHandshake } from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

export const CustomerInsights = ({ customerInsights = {} }) => {
  const {
    newCustomers = 0,
    returningCustomers = 0,
    returningPercent = 0,
    highestSpender = null,
    mostFrequent = null,
  } = customerInsights;

  return (
    <div className="cyber-card cyber-card-hover p-6 rounded-3xl h-full flex flex-col">
      <div className="flex items-center justify-between gap-2 mb-5">
        <div>
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-cyan-400" />
            <h3 className="font-display text-lg font-bold text-white tracking-tight">
              Customer Loyalty Summary
            </h3>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            First-time vs. returning guests and top regular customers
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 my-auto">
        <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/10 flex items-center justify-between gap-2">
          <div className="space-y-1 min-w-0">
            <span className="text-xs font-semibold text-slate-400 block">First-Time Guests</span>
            <span className="text-2xl font-black text-white tabular-nums">
              {formatNumber(newCustomers)}
            </span>
            <span className="text-[10px] text-slate-400 block">1 visit recorded</span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-cyan-500/20 text-cyan-400 flex items-center justify-center shrink-0">
            <UserPlus className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/10 flex items-center justify-between gap-2">
          <div className="space-y-1 min-w-0">
            <span className="text-xs font-semibold text-slate-400 block">Repeat Guests</span>
            <span className="text-2xl font-black text-emerald-400 tabular-nums">
              {formatNumber(returningCustomers)}
            </span>
            <span className="text-[10px] text-emerald-400 font-bold block">
              {returningPercent}% return rate
            </span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0">
            <RefreshCcw className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/10 flex items-center justify-between gap-2">
          <div className="space-y-1 min-w-0">
            <span className="text-xs font-semibold text-slate-400 block">Highest Spender</span>
            <span className="text-sm font-bold text-white block truncate">
              {highestSpender?.name || 'No customer yet'}
            </span>
            <span className="text-sm font-black text-amber-400 tabular-nums block">
              {formatCurrency(highestSpender?.amount || 0)}
            </span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center shrink-0">
            <Crown className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/10 flex items-center justify-between gap-2">
          <div className="space-y-1 min-w-0">
            <span className="text-xs font-semibold text-slate-400 block">Most Frequent Guest</span>
            <span className="text-sm font-bold text-white block truncate">
              {mostFrequent?.name || 'No customer yet'}
            </span>
            <span className="text-sm font-black text-purple-400 tabular-nums block">
              {formatNumber(mostFrequent?.visits || 0)} Visits
            </span>
          </div>
          <div className="w-10 h-10 rounded-xl bg-purple-500/20 text-purple-400 flex items-center justify-center shrink-0">
            <HeartHandshake className="w-5 h-5" />
          </div>
        </div>
      </div>
    </div>
  );
};
