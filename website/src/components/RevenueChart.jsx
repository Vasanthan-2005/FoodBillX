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
import { TrendingUp, IndianRupee } from 'lucide-react';
import { formatCurrency } from '../utils/formatters';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload;
    return (
      <div className="glass-panel p-3.5 rounded-xl border border-slate-700 shadow-2xl text-xs space-y-1">
        <p className="font-bold text-white mb-1">{data.label || label}</p>
        <div className="flex items-center justify-between gap-4 text-[#FF5722] font-semibold">
          <span>Revenue:</span>
          <span>{formatCurrency(data.revenue)}</span>
        </div>
        <div className="flex items-center justify-between gap-4 text-emerald-400 font-semibold">
          <span>Profit:</span>
          <span>{formatCurrency(data.profit)}</span>
        </div>
        <div className="flex items-center justify-between gap-4 text-slate-400">
          <span>Orders:</span>
          <span className="font-bold text-white">{data.orders}</span>
        </div>
      </div>
    );
  }
  return null;
};

export const RevenueChart = ({ dailyTrend = [] }) => {
  const totalPeriodRevenue = dailyTrend.reduce((sum, d) => sum + (d.revenue || 0), 0);

  return (
    <div className="glass-card p-6 rounded-3xl mb-8">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-[#FF5722]" />
            <h2 className="text-lg font-bold text-white tracking-tight">Revenue & Profit Trend</h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Daily breakdown of gross revenue vs net profit</p>
        </div>
        <div className="flex items-center gap-2 text-right">
          <div>
            <span className="text-[10px] text-slate-400 uppercase font-bold block">Period Total</span>
            <span className="text-xl font-black text-[#FF5722]">{formatCurrency(totalPeriodRevenue)}</span>
          </div>
        </div>
      </div>

      <div className="h-72 w-full">
        {dailyTrend.length === 0 ? (
          <div className="h-full flex items-center justify-center text-slate-500 text-sm">
            No sales revenue data available for selected date range
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={dailyTrend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#FF5722" stopOpacity={0.4} />
                  <stop offset="95%" stopColor="#FF5722" stopOpacity={0.0} />
                </linearGradient>
                <linearGradient id="profitGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10B981" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#10B981" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255, 255, 255, 0.05)" vertical={false} />
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
                tickFormatter={(val) => (val >= 1000 ? `${(val / 1000).toFixed(0)}k` : val)}
              />
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey="revenue"
                name="Revenue"
                stroke="#FF5722"
                strokeWidth={3}
                fillOpacity={1}
                fill="url(#revenueGrad)"
              />
              <Area
                type="monotone"
                dataKey="profit"
                name="Net Profit"
                stroke="#10B981"
                strokeWidth={2}
                strokeDasharray="4 4"
                fillOpacity={1}
                fill="url(#profitGrad)"
              />
            </AreaChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
};
