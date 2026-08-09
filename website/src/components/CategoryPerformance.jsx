import React from 'react';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import { Layers } from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

const CATEGORY_COLORS = ['#FF5722', '#10B981', '#3B82F6', '#8B5CF6', '#F59E0B', '#EC4899', '#06B6D4'];

export const CategoryPerformance = ({ categoryPerformance = [] }) => {
  return (
    <div className="glass-card p-6 rounded-3xl mb-8">
      <div className="flex items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Layers className="w-5 h-5 text-purple-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Category Performance</h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Revenue breakdown by food category</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
        {/* Horizontal Bar Chart */}
        <div className="h-64 w-full">
          {categoryPerformance.length === 0 ? (
            <div className="h-full flex items-center justify-center text-slate-500 text-sm">
              No category sales data available
            </div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart layout="vertical" data={categoryPerformance} margin={{ top: 0, right: 20, left: 30, bottom: 0 }}>
                <XAxis type="number" stroke="#64748B" fontSize={11} axisLine={false} tickLine={false} tickFormatter={(val) => `₹${val}`} />
                <YAxis dataKey="category" type="category" stroke="#94A3B8" fontSize={11} width={90} axisLine={false} tickLine={false} />
                <Tooltip
                  formatter={(val) => [formatCurrency(val), 'Revenue']}
                  contentStyle={{ backgroundColor: '#0F172A', borderRadius: '12px', borderColor: 'rgba(255,255,255,0.1)' }}
                />
                <Bar dataKey="revenue" radius={[0, 8, 8, 0]}>
                  {categoryPerformance.map((_, index) => (
                    <Cell key={`cat-cell-${index}`} fill={CATEGORY_COLORS[index % CATEGORY_COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Category Metrics Cards */}
        <div className="space-y-3">
          {categoryPerformance.map((cat, idx) => (
            <div key={cat.category} className="glass-panel p-3.5 rounded-2xl flex items-center justify-between border border-slate-800">
              <div className="flex items-center gap-3">
                <div className="w-3 h-8 rounded-full" style={{ backgroundColor: CATEGORY_COLORS[idx % CATEGORY_COLORS.length] }} />
                <div>
                  <h4 className="text-sm font-bold text-white">{cat.category}</h4>
                  <span className="text-xs text-slate-400">{formatNumber(cat.ordersCount)} items sold</span>
                </div>
              </div>
              <span className="text-base font-black text-white">{formatCurrency(cat.revenue)}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
