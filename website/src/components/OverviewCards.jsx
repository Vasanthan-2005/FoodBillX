import React from 'react';
import { motion } from 'framer-motion';
import {
  IndianRupee,
  ShoppingBag,
  TrendingUp,
  Percent,
  Users,
  UserCheck,
  XCircle,
  Receipt,
} from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

export const OverviewCards = ({ kpis = {} }) => {
  const {
    revenue = 0,
    ordersCount = 0,
    aov = 0,
    netProfit = 0,
    profitMargin = 0,
    revenueGrowth = 0,
    returningPercent = 0,
    cancelledCount = 0,
    totalCustomers = 0,
  } = kpis;

  const cards = [
    {
      title: "Today's Revenue",
      value: formatCurrency(revenue),
      icon: IndianRupee,
      color: 'from-[#FF5722] to-[#FF8A65]',
      badge: `${revenueGrowth >= 0 ? '+' : ''}${revenueGrowth}% vs prev`,
      badgeColor: revenueGrowth >= 0 ? 'bg-emerald-500/20 text-emerald-400' : 'bg-rose-500/20 text-rose-400',
    },
    {
      title: 'Net Profit',
      value: formatCurrency(netProfit),
      icon: TrendingUp,
      color: 'from-emerald-500 to-teal-400',
      badge: `${profitMargin}% margin`,
      badgeColor: 'bg-emerald-500/20 text-emerald-400',
    },
    {
      title: 'Total Orders',
      value: formatNumber(ordersCount),
      icon: ShoppingBag,
      color: 'from-blue-500 to-indigo-500',
      badge: 'Completed',
      badgeColor: 'bg-blue-500/20 text-blue-400',
    },
    {
      title: 'Average Order Value',
      value: formatCurrency(aov),
      icon: Receipt,
      color: 'from-purple-500 to-pink-500',
      badge: 'Per Order',
      badgeColor: 'bg-purple-500/20 text-purple-400',
    },
    {
      title: 'Profit Margin',
      value: `${profitMargin}%`,
      icon: Percent,
      color: 'from-amber-500 to-orange-400',
      badge: 'Net Profit / Rev',
      badgeColor: 'bg-amber-500/20 text-amber-400',
    },
    {
      title: 'Total Customers',
      value: formatNumber(totalCustomers),
      icon: Users,
      color: 'from-cyan-500 to-blue-400',
      badge: 'Directory',
      badgeColor: 'bg-cyan-500/20 text-cyan-400',
    },
    {
      title: 'Returning Rate',
      value: `${returningPercent}%`,
      icon: UserCheck,
      color: 'from-indigo-500 to-purple-400',
      badge: 'Repeat Loyalty',
      badgeColor: 'bg-indigo-500/20 text-indigo-400',
    },
    {
      title: 'Refunded Orders',
      value: formatNumber(cancelledCount),
      icon: XCircle,
      color: 'from-rose-500 to-red-600',
      badge: 'Cancelled',
      badgeColor: 'bg-rose-500/20 text-rose-400',
    },
  ];

  return (
    <section className="max-w-7xl mx-auto px-4 md:px-8 mb-8">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {cards.map((card, idx) => {
          const Icon = card.icon;
          return (
            <motion.div
              key={card.title}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: idx * 0.05 }}
              className="glass-card glass-card-hover p-5 rounded-2xl relative overflow-hidden"
            >
              {/* Background Accent Glow */}
              <div className={`absolute -right-6 -bottom-6 w-24 h-24 rounded-full bg-gradient-to-br ${card.color} opacity-10 blur-xl pointer-events-none`} />

              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-semibold text-slate-400 tracking-wide">{card.title}</span>
                <div className={`w-10 h-10 rounded-xl bg-gradient-to-tr ${card.color} flex items-center justify-center shadow-md shadow-black/20`}>
                  <Icon className="w-5 h-5 text-white" />
                </div>
              </div>

              <div className="flex items-baseline justify-between gap-2">
                <span className="text-2xl font-black text-white tracking-tight">{card.value}</span>
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border border-current/20 ${card.badgeColor}`}>
                  {card.badge}
                </span>
              </div>
            </motion.div>
          );
        })}
      </div>
    </section>
  );
};
