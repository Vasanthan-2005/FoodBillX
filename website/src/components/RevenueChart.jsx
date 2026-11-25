import React from 'react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { TrendingUp } from 'lucide-react';
import { formatCompactCurrency, formatCurrency, formatNumber } from '../utils/formatters';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload;
    return (
      <div className="cyber-panel p-3.5 rounded-xl border border-[#FF6D00]/40 shadow-2xl text-xs space-y-1">
        <p className="font-bold text-white mb-1">{data.label || label}</p>
        <div className="flex items-center justify-between gap-4 text-[#FF8F00] font-semibold">
          <span>Revenue:</span>
          <span>{formatCurrency(data.revenue)}</span>
        </div>
        <div className="flex items-center justify-between gap-4 text-cyan-300">
          <span>Orders:</span>
          <span className="font-bold text-white">{formatNumber(data.orders)}</span>
        </div>
      </div>
    );
  }
  return null;
};

export const RevenueChart = ({ dailyTrend = [] }) => {
  const totalPeriodRevenue = dailyTrend.reduce((sum, d) => sum + (d.revenue || 0), 0);

  return (
    <div className="cyber-card cyber-card-hover p-6 rounded-3xl mb-8">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-[#FF6D00]" />
            <h2 className="font-display text-lg font-bold text-white tracking-tight">
              Revenue Velocity Waveform
            </h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            Period sales trajectory aggregated from synced bills
          </p>
        </div>
        <div className="text-left sm:text-right">
          <span className="text-[10px] font-mono text-slate-400 uppercase font-bold block">
            Period Total
          </span>
          <span className="text-xl font-black text-[#FF8F00]">
            {formatCurrency(totalPeriodRevenue)}
          </span>
        </div>
      </div>

      <div className="h-72 w-full">
        {dailyTrend.length === 0 ? (
          <div className="h-full flex items-center justify-center text-slate-500 text-sm">
            No sales revenue recorded for selected timeframe
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={dailyTrend} margin={{ top: 10, right: 12, left: -10, bottom: 0 }}>
              <defs>
                <linearGradient id="cyberRevGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#FF6D00" stopOpacity={0.5} />
                  <stop offset="95%" stopColor="#FF6D00" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255, 255, 255, 0.06)" vertical={false} />
              <XAxis
                dataKey="label"
                stroke="#64748B"
                fontSize={11}
                tickLine={false}
                axisLine={false}
              />
              <YAxis
                stroke="#64748B"
                fontSize={11}
                tickLine={false}
                axisLine={false}
                tickFormatter={(val) => formatCompactCurrency(val).replace('₹ ', '')}
              />
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey="revenue"
                name="Revenue"
                stroke="#FF6D00"
                strokeWidth={3}
                fillOpacity={1}
                fill="url(#cyberRevGrad)"
              />
            </AreaChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
};
