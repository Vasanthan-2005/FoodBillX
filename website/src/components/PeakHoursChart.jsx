import React from 'react';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Cell, CartesianGrid } from 'recharts';
import { Clock, Zap } from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

const CustomTooltip = ({ active, payload }) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload;
    return (
      <div className="cyber-panel p-3 rounded-xl border border-amber-500/40 shadow-xl text-xs space-y-1.5">
        <p className="font-bold text-amber-400 border-b border-white/10 pb-1">{data.hour}</p>
        <div className="flex items-center justify-between gap-4 text-white font-semibold tabular-nums">
          <span>Orders:</span>
          <span>{formatNumber(data.count)}</span>
        </div>
        <div className="flex items-center justify-between gap-4 text-emerald-400 font-semibold tabular-nums">
          <span>Sales:</span>
          <span>{formatCurrency(data.revenue)}</span>
        </div>
      </div>
    );
  }
  return null;
};

export const PeakHoursChart = ({ hourlyData = [] }) => {
  const peak = hourlyData.reduce(
    (max, item) => (item.count > max.count ? item : max),
    { count: 0, hour: 'N/A' }
  );

  return (
    <div className="cyber-card cyber-card-hover p-6 rounded-3xl h-full flex flex-col">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-5">
        <div>
          <div className="flex items-center gap-2">
            <Clock className="w-5 h-5 text-amber-400" />
            <h3 className="font-display text-lg font-bold text-white tracking-tight">
              Busiest Hours of the Day
            </h3>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            Helps plan kitchen prep and staff shifts for rush hours
          </p>
        </div>
        {peak.count > 0 && (
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-500/15 border border-amber-500/35 text-amber-300 shrink-0 tabular-nums">
            <Zap className="w-3.5 h-3.5 fill-current" />
            <span className="text-xs font-bold">
              Rush: {peak.hour} ({formatNumber(peak.count)})
            </span>
          </div>
        )}
      </div>

      <div className="h-72 w-full mt-auto">
        {hourlyData.length === 0 ? (
          <div className="h-full flex items-center justify-center text-slate-500 text-sm">
            No hourly sales data recorded for selected timeframe
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={hourlyData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid
                strokeDasharray="3 3"
                stroke="rgba(255, 255, 255, 0.05)"
                vertical={false}
              />
              <XAxis
                dataKey="hour"
                stroke="#64748B"
                fontSize={10}
                tickLine={false}
                axisLine={false}
                interval={1}
              />
              <YAxis
                stroke="#64748B"
                fontSize={11}
                tickLine={false}
                axisLine={false}
                allowDecimals={false}
              />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                {hourlyData.map((entry) => (
                  <Cell
                    key={entry.hour}
                    fill={entry.hour === peak.hour ? '#FFB300' : '#22D3EE'}
                    opacity={entry.count > 0 ? 0.92 : 0.22}
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
