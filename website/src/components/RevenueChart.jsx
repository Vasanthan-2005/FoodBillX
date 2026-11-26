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
import { TrendingUp, Sparkles } from 'lucide-react';
import { formatCompactCurrency, formatCurrency, formatNumber } from '../utils/formatters';

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload;
    return (
      <div className="cyber-panel p-3.5 rounded-xl border border-[#FF6D00]/40 shadow-2xl text-xs space-y-1.5">
        <p className="font-bold text-white border-b border-white/10 pb-1">{data.label || label}</p>
        <div className="flex items-center justify-between gap-5 text-[#FF8F00] font-bold tabular-nums">
          <span>Sales Revenue:</span>
          <span>{formatCurrency(data.revenue)}</span>
        </div>
        <div className="flex items-center justify-between gap-5 text-cyan-300 font-semibold tabular-nums">
          <span>Completed Orders:</span>
          <span className="text-white">{formatNumber(data.orders)}</span>
        </div>
      </div>
    );
  }
  return null;
};

export const RevenueChart = ({ dailyTrend = [] }) => {
  const totalPeriodRevenue = dailyTrend.reduce((sum, d) => sum + (d.revenue || 0), 0);
  const bestPoint = dailyTrend.reduce(
    (best, d) => ((d.revenue || 0) > (best.revenue || 0) ? d : best),
    { revenue: 0, label: '' }
  );

  return (
    <div className="cyber-card cyber-card-hover p-6 rounded-3xl h-full flex flex-col">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-5">
        <div>
          <div className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-[#FF6D00]" />
            <h3 className="font-display text-lg font-bold text-white tracking-tight">
              Sales Revenue Trend
            </h3>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            Total bill amounts collected across this timeframe
          </p>
        </div>

        <div className="flex items-center gap-3 flex-wrap">
          {bestPoint.revenue > 0 && (
            <div className="px-3 py-1.5 rounded-xl bg-cyan-500/10 border border-cyan-500/30 text-cyan-300 text-[11px] font-bold flex items-center gap-1.5 tabular-nums">
              <Sparkles className="w-3.5 h-3.5" />
              <span>
                Best ({bestPoint.label}): {formatCompactCurrency(bestPoint.revenue)}
              </span>
            </div>
          )}
          <div className="text-left sm:text-right">
            <span className="text-[10px] font-mono text-slate-400 uppercase font-bold block">
              Period Total
            </span>
            <span className="text-xl font-black text-[#FF8F00] tabular-nums">
              {formatCurrency(totalPeriodRevenue)}
            </span>
          </div>
        </div>
      </div>

      <div className="h-72 w-full mt-auto">
        {dailyTrend.length === 0 ? (
          <div className="h-full flex items-center justify-center text-slate-500 text-sm">
            No sales revenue recorded for selected timeframe
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={dailyTrend} margin={{ top: 10, right: 12, left: -10, bottom: 0 }}>
              <defs>
                <linearGradient id="cyberRevGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#FF6D00" stopOpacity={0.55} />
                  <stop offset="65%" stopColor="#FF9100" stopOpacity={0.14} />
                  <stop offset="95%" stopColor="#FF6D00" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <CartesianGrid
                strokeDasharray="3 3"
                stroke="rgba(255, 255, 255, 0.06)"
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
                tickFormatter={(val) => formatCompactCurrency(val).replace('₹ ', '')}
              />
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey="revenue"
                name="Revenue"
                stroke="#FF6D00"
                strokeWidth={3}
                activeDot={{ r: 5, fill: '#FFB300', stroke: '#ffffff', strokeWidth: 2 }}
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
