import React, { useState } from 'react';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import { Flame, BarChart2, ListOrdered } from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

export const TopSellingItems = ({ topSellingItems = [] }) => {
  const [viewMode, setViewMode] = useState('list');
  const maxQty = topSellingItems[0]?.qtySold || 1;

  return (
    <div className="cyber-card cyber-card-hover p-6 rounded-3xl h-full flex flex-col">
      <div className="flex flex-wrap items-center justify-between gap-2 mb-5">
        <div>
          <div className="flex items-center gap-2">
            <Flame className="w-5 h-5 text-[#FF6D00]" />
            <h3 className="font-display text-lg font-bold text-white tracking-tight">
              Bestselling Dishes
            </h3>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            Top menu items ranked by portions sold
          </p>
        </div>

        <div className="flex items-center gap-1 bg-black/40 p-1 rounded-xl border border-white/10">
          <button
            type="button"
            onClick={() => setViewMode('list')}
            className={`px-2.5 py-1 rounded-lg text-[11px] font-bold flex items-center gap-1 transition-colors ${
              viewMode === 'list'
                ? 'bg-[#FF6D00] text-white'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <ListOrdered className="w-3.5 h-3.5" />
            <span>Ranked</span>
          </button>
          <button
            type="button"
            onClick={() => setViewMode('chart')}
            className={`px-2.5 py-1 rounded-lg text-[11px] font-bold flex items-center gap-1 transition-colors ${
              viewMode === 'chart'
                ? 'bg-[#FF6D00] text-white'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <BarChart2 className="w-3.5 h-3.5" />
            <span>Chart</span>
          </button>
        </div>
      </div>

      {topSellingItems.length === 0 ? (
        <div className="h-64 flex items-center justify-center text-slate-500 text-sm">
          No dish sales recorded for selected period
        </div>
      ) : viewMode === 'chart' ? (
        <div className="h-72 w-full mt-auto">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              layout="vertical"
              data={topSellingItems.slice(0, 8)}
              margin={{ top: 4, right: 16, left: 10, bottom: 0 }}
            >
              <XAxis type="number" stroke="#64748B" fontSize={11} axisLine={false} tickLine={false} />
              <YAxis
                dataKey="name"
                type="category"
                stroke="#CBD5E1"
                fontSize={11}
                width={105}
                axisLine={false}
                tickLine={false}
              />
              <Tooltip formatter={(val) => [`${formatNumber(val)} portions`, 'Sold']} />
              <Bar dataKey="qtySold" radius={[0, 8, 8, 0]}>
                {topSellingItems.slice(0, 8).map((_, index) => (
                  <Cell key={`cell-${index}`} fill={index < 3 ? '#FF6D00' : '#FFB300'} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      ) : (
        <div className="space-y-2.5 max-h-72 overflow-y-auto pr-1">
          {topSellingItems.slice(0, 8).map((item, idx) => {
            const pct = Math.max(8, Math.round(((item.qtySold || 0) / maxQty) * 100));
            const barColor =
              idx === 0
                ? '#FF6D00'
                : idx === 1
                ? '#22D3EE'
                : idx === 2
                ? '#FFB300'
                : '#64748B';

            return (
              <div
                key={item.name}
                className="p-3 rounded-2xl bg-white/[0.03] border border-white/10 space-y-2"
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2.5 min-w-0">
                    <span
                      className={`w-7 h-7 rounded-xl flex items-center justify-center text-xs font-black shrink-0 ${
                        idx === 0
                          ? 'bg-[#FF6D00]/25 text-[#FF8F00] border border-[#FF6D00]/45'
                          : idx === 1
                          ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/35'
                          : idx === 2
                          ? 'bg-amber-500/20 text-amber-300 border border-amber-500/35'
                          : 'bg-white/5 text-slate-400'
                      }`}
                    >
                      #{idx + 1}
                    </span>
                    <div className="min-w-0">
                      <h4 className="text-xs font-bold text-white truncate">{item.name}</h4>
                      <span className="text-[10px] text-slate-400 tabular-nums">
                        {formatNumber(item.qtySold)} portions ordered
                      </span>
                    </div>
                  </div>
                  <span className="text-xs font-black text-emerald-400 tabular-nums shrink-0">
                    {formatCurrency(item.revenue)}
                  </span>
                </div>
                <div className="h-1.5 w-full rounded-full bg-white/5 overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-500"
                    style={{ width: `${pct}%`, backgroundColor: barColor }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
