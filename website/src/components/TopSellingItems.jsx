import React from 'react';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import { Award, Flame } from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

export const TopSellingItems = ({ topSellingItems = [] }) => {
  return (
    <div className="glass-card p-6 rounded-3xl mb-8">
      <div className="flex items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Flame className="w-5 h-5 text-amber-500" />
            <h2 className="text-lg font-bold text-white tracking-tight">Top 10 Selling Dishes</h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Most popular food items by quantity sold</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
        {/* Horizontal Bar Chart */}
        <div className="h-72 w-full">
          {topSellingItems.length === 0 ? (
            <div className="h-full flex items-center justify-center text-slate-500 text-sm">
              No top items recorded for selected period
            </div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart layout="vertical" data={topSellingItems} margin={{ top: 0, right: 20, left: 40, bottom: 0 }}>
                <XAxis type="number" stroke="#64748B" fontSize={11} axisLine={false} tickLine={false} />
                <YAxis dataKey="name" type="category" stroke="#94A3B8" fontSize={11} width={100} axisLine={false} tickLine={false} />
                <Tooltip
                  formatter={(val) => [`${formatNumber(val)} portions`, 'Quantity Sold']}
                  contentStyle={{ backgroundColor: '#0F172A', borderRadius: '12px', borderColor: 'rgba(255,255,255,0.1)' }}
                />
                <Bar dataKey="qtySold" radius={[0, 8, 8, 0]}>
                  {topSellingItems.map((_, index) => (
                    <Cell key={`cell-${index}`} fill={index < 3 ? '#FF5722' : '#F59E0B'} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Detailed Items Performance List */}
        <div className="space-y-2.5 max-h-72 overflow-y-auto pr-1">
          {topSellingItems.slice(0, 6).map((item, idx) => (
            <div key={item.name} className="glass-panel p-3 rounded-2xl flex items-center justify-between border border-slate-800/80">
              <div className="flex items-center gap-3">
                <span className={`w-7 h-7 rounded-xl flex items-center justify-center text-xs font-black ${
                  idx === 0 ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' :
                  idx === 1 ? 'bg-slate-300/20 text-slate-200 border border-slate-300/30' :
                  idx === 2 ? 'bg-orange-600/20 text-orange-400 border border-orange-600/30' :
                  'bg-slate-800 text-slate-400'
                }`}>
                  #{idx + 1}
                </span>
                <div>
                  <h4 className="text-xs font-bold text-white leading-tight">{item.name}</h4>
                  <span className="text-[10px] text-slate-400">{item.category} • {formatNumber(item.qtySold)} orders</span>
                </div>
              </div>
              <div className="text-right">
                <span className="text-xs font-black text-white block">{formatCurrency(item.revenue)}</span>
                <span className="text-[10px] text-emerald-400 font-semibold">+Est {formatCurrency(item.profit)}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
