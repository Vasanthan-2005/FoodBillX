import React from 'react';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import { Flame } from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

export const TopSellingItems = ({ topSellingItems = [] }) => {
  return (
    <div className="cyber-card cyber-card-hover p-6 rounded-3xl mb-8">
      <div className="flex items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Flame className="w-5 h-5 text-[#FF6D00]" />
            <h2 className="font-display text-lg font-bold text-white tracking-tight">
              Top Selling Dishes Leaderboard
            </h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Ranked by portions billed & item revenue</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
        <div className="h-72 w-full">
          {topSellingItems.length === 0 ? (
            <div className="h-full flex items-center justify-center text-slate-500 text-sm">
              No dish sales recorded for selected period
            </div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                layout="vertical"
                data={topSellingItems.slice(0, 10)}
                margin={{ top: 0, right: 20, left: 32, bottom: 0 }}
              >
                <XAxis type="number" stroke="#64748B" fontSize={11} axisLine={false} tickLine={false} />
                <YAxis
                  dataKey="name"
                  type="category"
                  stroke="#CBD5E1"
                  fontSize={11}
                  width={110}
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip
                  formatter={(val) => [`${formatNumber(val)} portions`, 'Sold']}
                />
                <Bar dataKey="qtySold" radius={[0, 8, 8, 0]}>
                  {topSellingItems.slice(0, 10).map((_, index) => (
                    <Cell key={`cell-${index}`} fill={index < 3 ? '#FF6D00' : '#FFB300'} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="space-y-2.5 max-h-72 overflow-y-auto pr-1">
          {topSellingItems.slice(0, 8).map((item, idx) => (
            <div
              key={item.name}
              className="cyber-panel p-3 rounded-2xl flex items-center justify-between border border-white/10"
            >
              <div className="flex items-center gap-3 min-w-0">
                <span
                  className={`w-7 h-7 rounded-xl flex items-center justify-center text-xs font-black shrink-0 ${
                    idx === 0
                      ? 'bg-[#FF6D00]/25 text-[#FF8F00] border border-[#FF6D00]/40'
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
                  <span className="text-[10px] text-slate-400">
                    {formatNumber(item.qtySold)} portions sold
                  </span>
                </div>
              </div>
              <span className="text-xs font-black text-emerald-400 ml-3 shrink-0">
                {formatCurrency(item.revenue)}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
