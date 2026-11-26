import React from 'react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  Cell,
} from 'recharts';
import { ShoppingBag } from 'lucide-react';
import { formatNumber } from '../utils/formatters';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload;
    return (
      <div className="cyber-panel p-3 rounded-xl border border-cyan-500/35 shadow-xl text-xs space-y-1">
        <p className="font-bold text-white mb-1">{data.label || label}</p>
        <div className="flex items-center justify-between gap-4 text-cyan-300 font-semibold tabular-nums">
          <span>Completed Orders:</span>
          <span>{formatNumber(data.orders)}</span>
        </div>
      </div>
    );
  }
  return null;
};

export const OrdersChart = ({ dailyTrend = [] }) => {
  const totalOrders = dailyTrend.reduce((sum, d) => sum + (d.orders || 0), 0);

  return (
    <div className="cyber-card cyber-card-hover p-6 rounded-3xl h-full flex flex-col">
      <div className="flex items-center justify-between gap-2 mb-5">
        <div>
          <div className="flex items-center gap-2">
            <ShoppingBag className="w-5 h-5 text-cyan-400" />
            <h3 className="font-display text-lg font-bold text-white tracking-tight">
              Orders Over Time
            </h3>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            Number of customer bills completed in each interval
          </p>
        </div>
        <div className="text-right shrink-0">
          <span className="text-[10px] font-mono text-slate-400 uppercase font-bold block">
            Total Bills
          </span>
          <span className="text-xl font-black text-cyan-400 tabular-nums">
            {formatNumber(totalOrders)}
          </span>
        </div>
      </div>

      <div className="h-64 w-full mt-auto">
        {dailyTrend.length === 0 ? (
          <div className="h-full flex items-center justify-center text-slate-500 text-sm">
            No order volume data for selected timeframe
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={dailyTrend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid
                strokeDasharray="3 3"
                stroke="rgba(255, 255, 255, 0.05)"
                vertical={false}
              />
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
                allowDecimals={false}
              />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="orders" radius={[8, 8, 0, 0]}>
                {dailyTrend.map((_, index) => (
                  <Cell key={`cell-${index}`} fill={index % 2 === 0 ? '#22D3EE' : '#3B82F6'} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
};
