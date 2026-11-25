import React from 'react';
import { motion } from 'framer-motion';
import {
  IndianRupee,
  ShoppingBag,
  Receipt,
  BadgePercent,
  Sparkles,
  Users,
  UserCheck,
  Award,
} from 'lucide-react';
import { formatCurrency, formatNumber } from '../utils/formatters';

export const OverviewCards = ({ kpis = {} }) => {
  const {
    revenue = 0,
    ordersCount = 0,
    aov = 0,
    totalDiscount = 0,
    totalServiceCharge = 0,
    revenueGrowth = 0,
    returningPercent = 0,
    loyaltyMembers = 0,
    totalCustomers = 0,
  } = kpis;

  const cards = [
    {
      title: 'Period Revenue',
      value: formatCurrency(revenue),
      icon: IndianRupee,
      color: 'from-[#FF6D00] to-[#FFB300]',
      badge: `${revenueGrowth >= 0 ? '+' : ''}${revenueGrowth}% vs prior`,
      badgeColor:
        revenueGrowth >= 0
          ? 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30'
          : 'bg-rose-500/20 text-rose-400 border-rose-500/30',
    },
    {
      title: 'Orders Completed',
      value: formatNumber(ordersCount),
      icon: ShoppingBag,
      color: 'from-cyan-500 to-blue-600',
      badge: 'Verified Bills',
      badgeColor: 'bg-cyan-500/15 text-cyan-300 border-cyan-500/30',
    },
    {
      title: 'Avg Order Value',
      value: formatCurrency(aov),
      icon: Receipt,
      color: 'from-purple-500 to-pink-500',
      badge: 'Per Ticket',
      badgeColor: 'bg-purple-500/15 text-purple-300 border-purple-500/30',
    },
    {
      title: 'Discounts Applied',
      value: formatCurrency(totalDiscount),
      icon: BadgePercent,
      color: 'from-amber-500 to-orange-500',
      badge: 'Promo / Loyalty',
      badgeColor: 'bg-amber-500/15 text-amber-300 border-amber-500/30',
    },
    {
      title: 'Service Charges',
      value: formatCurrency(totalServiceCharge),
      icon: Sparkles,
      color: 'from-emerald-500 to-teal-400',
      badge: 'Dine-In Fee',
      badgeColor: 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30',
    },
    {
      title: 'Total Customers',
      value: formatNumber(totalCustomers),
      icon: Users,
      color: 'from-blue-500 to-indigo-500',
      badge: 'CRM Directory',
      badgeColor: 'bg-blue-500/15 text-blue-300 border-blue-500/30',
    },
    {
      title: 'Repeat Rate',
      value: `${returningPercent}%`,
      icon: UserCheck,
      color: 'from-indigo-500 to-violet-500',
      badge: 'Returning Guests',
      badgeColor: 'bg-indigo-500/15 text-indigo-300 border-indigo-500/30',
    },
    {
      title: 'Loyalty Members',
      value: formatNumber(loyaltyMembers),
      icon: Award,
      color: 'from-pink-500 to-rose-500',
      badge: 'Active Cards',
      badgeColor: 'bg-pink-500/15 text-pink-300 border-pink-500/30',
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
              initial={{ opacity: 0, y: 18 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.35, delay: idx * 0.04 }}
              className="cyber-card cyber-card-hover p-5 rounded-2xl relative overflow-hidden"
            >
              <div
                className={`absolute -right-6 -bottom-6 w-28 h-28 rounded-full bg-gradient-to-br ${card.color} opacity-15 blur-2xl pointer-events-none`}
              />

              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-semibold text-slate-400 tracking-wide">
                  {card.title}
                </span>
                <div
                  className={`w-10 h-10 rounded-xl bg-gradient-to-tr ${card.color} flex items-center justify-center shadow-lg`}
                >
                  <Icon className="w-5 h-5 text-white" />
                </div>
              </div>

              <div className="flex items-baseline justify-between gap-2 flex-wrap">
                <span className="text-2xl font-black text-white tracking-tight">
                  {card.value}
                </span>
                <span
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${card.badgeColor}`}
                >
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
