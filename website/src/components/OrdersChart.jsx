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
      <div className="glass-panel p-3 rounded-xl border border-slate-700 shadow-xl text-xs space-y-1">
        <p className="font-bold text-white mb-1">{data.label || label}</p>
        <div className="flex items-center justify-between gap-4 text-blue-400 font-semibold">
          <span>Orders Count:</span>
          <span>{formatNumber(data.orders)} orders</span>
        </div>
      </div>
    );
  }
  return null;
};

export const OrdersChart = ({ dailyTrend = [] }) => {
  const totalOrders = dailyTrend.reduce((sum, d) => sum + (d.orders || 0), 0);

  return (
    <div className="glass-card p-6 rounded-3xl mb-8">
      <div className="flex items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <ShoppingBag className="w-5 h-5 text-blue-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Order Volume Trend</h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Number of completed orders per day</p>
        </div>
        <div className="text-right">
          <span className="text-[10px] text-slate-400 uppercase font-bold block">Total Orders</span>
          <span className="text-xl font-black text-blue-400">{formatNumber(totalOrders)}</span>
        </div>
      </div>

      <div className="h-64 w-full">
        {dailyTrend.length === 0 ? (
          <div className="h-full flex items-center justify-center text-slate-500 text-sm">
            No order volume data available for selected range
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={dailyTrend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255, 255, 255, 0.05)" vertical={false} />
              <XAxis dataKey="label" stroke="#64748B" fontSize={11} tickLine={false} axisLine={false} />
              <YAxis stroke="#64748B" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="orders" radius={[6, 6, 0, 0]}>
                {dailyTrend.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill="#3B82F6" />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
};
