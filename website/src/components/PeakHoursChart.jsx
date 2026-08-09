import React from 'react';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import { Clock, Zap } from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload;
    return (
      <div className="glass-panel p-3 rounded-xl border border-slate-700 shadow-xl text-xs space-y-1">
        <p className="font-bold text-[#FF5722] mb-1">{data.hour}</p>
        <div className="flex items-center justify-between gap-4 text-white font-semibold">
          <span>Orders:</span>
          <span>{formatNumber(data.count)} orders</span>
        </div>
        <div className="flex items-center justify-between gap-4 text-emerald-400 font-semibold">
          <span>Sales:</span>
          <span>{formatCurrency(data.revenue)}</span>
        </div>
      </div>
    );
  }
  return null;
};

export const PeakHoursChart = ({ hourlyData = [] }) => {
  // Identify peak hour
  const peak = hourlyData.reduce((max, item) => (item.count > max.count ? item : max), { count: 0, hour: 'N/A' });

  return (
    <div className="glass-card p-6 rounded-3xl mb-8">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Clock className="w-5 h-5 text-amber-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Peak Selling Hours</h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Hourly customer order distribution (8:00 AM - 11:00 PM)</p>
        </div>
        {peak.count > 0 && (
          <div className="flex items-center gap-2 px-3.5 py-1.5 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-amber-400">
            <Zap className="w-4 h-4 fill-current" />
            <span className="text-xs font-bold">Busiest Hour: {peak.hour} ({peak.count} orders)</span>
          </div>
        )}
      </div>

      <div className="h-64 w-full">
        {hourlyData.length === 0 ? (
          <div className="h-full flex items-center justify-center text-slate-500 text-sm">
            No hourly sales data recorded for selected date range
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={hourlyData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <XAxis dataKey="hour" stroke="#64748B" fontSize={10} tickLine={false} axisLine={false} interval={1} />
              <YAxis stroke="#64748B" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                {hourlyData.map((entry) => (
                  <Cell
                    key={entry.hour}
                    fill={entry.hour === peak.hour ? '#F59E0B' : '#3B82F6'}
                    opacity={entry.count > 0 ? 0.9 : 0.2}
                  />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
};
