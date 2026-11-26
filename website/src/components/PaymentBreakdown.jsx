import React from 'react';
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip } from 'recharts';
import { CreditCard, Wallet, Banknote, Smartphone } from 'lucide-react';
import { formatCompactCurrency, formatCurrency } from '../utils/formatters';

const COLOR_MAP = {
  Cash: '#00E676',
  UPI: '#22D3EE',
  Card: '#A855F7',
  Wallet: '#FFB300',
};

export const PaymentBreakdown = ({ paymentBreakdown = {} }) => {
  const data = [
    { name: 'UPI', value: paymentBreakdown.upi || 0, icon: Smartphone },
    { name: 'Cash', value: paymentBreakdown.cash || 0, icon: Banknote },
    { name: 'Card', value: paymentBreakdown.card || 0, icon: CreditCard },
    { name: 'Wallet', value: paymentBreakdown.wallet || 0, icon: Wallet },
  ].filter((item) => item.value > 0);

  const totalPayment = data.reduce((sum, item) => sum + item.value, 0);

  return (
    <div className="cyber-card cyber-card-hover p-6 rounded-3xl h-full flex flex-col">
      <div className="flex items-start justify-between gap-2 mb-3">
        <div>
          <div className="flex items-center gap-2">
            <CreditCard className="w-5 h-5 text-emerald-400" />
            <h3 className="font-display text-lg font-bold text-white tracking-tight">
              How Customers Paid
            </h3>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Payment split by method</p>
        </div>
      </div>

      {/* Centered Donut with Total inside ring */}
      <div className="relative h-48 w-full my-1">
        {data.length === 0 ? (
          <div className="h-full flex items-center justify-center text-slate-500 text-sm text-center">
            No payment data recorded for selected period
          </div>
        ) : (
          <>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={data}
                  cx="50%"
                  cy="50%"
                  innerRadius={54}
                  outerRadius={78}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {data.map((entry) => (
                    <Cell
                      key={entry.name}
                      fill={COLOR_MAP[entry.name] || '#64748B'}
                      stroke="rgba(6,8,15,0.9)"
                      strokeWidth={2}
                    />
                  ))}
                </Pie>
                <Tooltip formatter={(val) => [formatCurrency(val), 'Collected']} />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-[10px] font-mono uppercase text-slate-400">Collected</span>
              <span className="text-sm font-black text-white tabular-nums">
                {formatCompactCurrency(totalPayment)}
              </span>
            </div>
          </>
        )}
      </div>

      {/* Clean Progress Bar Rows */}
      <div className="space-y-2.5 mt-auto pt-2">
        {data.map((item) => {
          const Icon = item.icon;
          const pct = totalPayment > 0 ? Math.round((item.value / totalPayment) * 100) : 0;
          const color = COLOR_MAP[item.name] || '#64748B';

          return (
            <div
              key={item.name}
              className="p-2.5 rounded-xl bg-white/[0.03] border border-white/10 space-y-1.5"
            >
              <div className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <div
                    className="w-7 h-7 rounded-lg flex items-center justify-center"
                    style={{ backgroundColor: `${color}20`, color }}
                  >
                    <Icon className="w-3.5 h-3.5" />
                  </div>
                  <span className="font-bold text-white">{item.name}</span>
                  <span className="text-[11px] text-slate-400 tabular-nums">({pct}%)</span>
                </div>
                <span className="font-extrabold text-white tabular-nums">
                  {formatCurrency(item.value)}
                </span>
              </div>
              <div className="h-1.5 w-full rounded-full bg-white/5 overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{ width: `${pct}%`, backgroundColor: color }}
                />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
