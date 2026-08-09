import React from 'react';
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip, Legend } from 'recharts';
import { CreditCard, Wallet, Banknote, Smartphone } from 'lucide-react';
import { formatCurrency } from '../utils/formatters';

const COLOR_MAP = {
  Cash: '#10B981', // Emerald Green
  UPI: '#3B82F6', // Vibrant Blue
  Card: '#8B5CF6', // Purple
  Wallet: '#F59E0B', // Amber
  Others: '#64748B', // Slate
};

export const PaymentBreakdown = ({ paymentBreakdown = {} }) => {
  const data = [
    { name: 'Cash', value: paymentBreakdown.cash || 0, icon: Banknote },
    { name: 'UPI', value: paymentBreakdown.upi || 0, icon: Smartphone },
    { name: 'Card', value: paymentBreakdown.card || 0, icon: CreditCard },
    { name: 'Wallet', value: paymentBreakdown.wallet || 0, icon: Wallet },
  ].filter((item) => item.value > 0);

  const totalPayment = data.reduce((sum, item) => sum + item.value, 0);

  return (
    <div className="glass-card p-6 rounded-3xl mb-8">
      <div className="flex items-center justify-between gap-2 mb-4">
        <div>
          <div className="flex items-center gap-2">
            <CreditCard className="w-5 h-5 text-emerald-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Payment Methods Breakdown</h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Distribution of revenue by payment channel</p>
        </div>
        <div className="text-right">
          <span className="text-[10px] text-slate-400 uppercase font-bold block">Total Collected</span>
          <span className="text-xl font-black text-emerald-400">{formatCurrency(totalPayment)}</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-center">
        {/* Pie Donut Chart */}
        <div className="h-64 w-full">
          {data.length === 0 ? (
            <div className="h-full flex items-center justify-center text-slate-500 text-sm">
              No payment transactions recorded for selected period
            </div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={data}
                  cx="50%"
                  cy="50%"
                  innerRadius={65}
                  outerRadius={95}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {data.map((entry) => (
                    <Cell key={entry.name} fill={COLOR_MAP[entry.name] || '#64748B'} stroke="rgba(0,0,0,0.5)" strokeWidth={2} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(val) => [formatCurrency(val), 'Revenue']}
                  contentStyle={{ backgroundColor: '#0F172A', borderRadius: '12px', borderColor: 'rgba(255,255,255,0.1)' }}
                />
              </PieChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Payment Channel Cards */}
        <div className="space-y-3">
          {data.map((item) => {
            const Icon = item.icon;
            const pct = totalPayment > 0 ? Math.round((item.value / totalPayment) * 100) : 0;
            const color = COLOR_MAP[item.name] || '#64748B';

            return (
              <div key={item.name} className="glass-panel p-3.5 rounded-2xl flex items-center justify-between border border-slate-800">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ backgroundColor: `${color}20`, color }}>
                    <Icon className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-white">{item.name} Payments</h4>
                    <span className="text-xs text-slate-400">{pct}% of total revenue</span>
                  </div>
                </div>
                <span className="text-base font-black text-white">{formatCurrency(item.value)}</span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
