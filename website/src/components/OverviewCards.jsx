import React from 'react';
import { motion } from 'framer-motion';
import {
  IndianRupee,
  ShoppingBag,
  Receipt,
  UserCheck,
  BadgePercent,
  Sparkles,
  Award,
  UtensilsCrossed,
  TrendingUp,
  TrendingDown,
} from 'lucide-react';
import { formatCompactCurrency, formatCurrency, formatNumber } from '../utils/formatters';

export const OverviewCards = ({ kpis = {}, customerInsights = {} }) => {
  const {
    revenue = 0,
    ordersCount = 0,
    aov = 0,
    totalDiscount = 0,
    totalServiceCharge = 0,
    itemsSoldTotal = 0,
    revenueGrowth = 0,
    ordersGrowth = 0,
    avgDailyRevenue = 0,
    returningPercent = 0,
    loyaltyMembers = 0,
    totalCustomers = 0,
  } = kpis;

  const returningCustomers = customerInsights?.returningCustomers || 0;

  const heroCards = [
    {
      title: 'Total Sales Revenue',
      value: formatCurrency(revenue),
      helper: avgDailyRevenue > 0 ? `Avg ${formatCompactCurrency(avgDailyRevenue)} / day` : 'Completed bill total',
      icon: IndianRupee,
      gradient: 'from-[#FF6D00] to-[#FFB300]',
      glow: 'bg-[#FF6D00]/20',
      trend: revenueGrowth,
      badgeFallback: 'Gross Sales',
    },
    {
      title: 'Total Orders',
      value: formatNumber(ordersCount),
      helper: itemsSoldTotal > 0 ? `${formatNumber(itemsSoldTotal)} dishes ordered` : 'Completed customer bills',
      icon: ShoppingBag,
      gradient: 'from-cyan-500 to-blue-600',
      glow: 'bg-cyan-500/20',
      trend: ordersGrowth,
      badgeFallback: 'Verified Bills',
    },
    {
      title: 'Average Bill Value',
      value: formatCurrency(aov),
      helper: 'Average spent per order',
      icon: Receipt,
      gradient: 'from-purple-500 to-pink-500',
      glow: 'bg-purple-500/20',
      trend: null,
      badgeFallback: 'Per Order',
    },
    {
      title: 'Repeat Customer Rate',
      value: `${returningPercent}%`,
      helper:
        totalCustomers > 0
          ? `${formatNumber(returningCustomers)} returning of ${formatNumber(totalCustomers)} guests`
          : 'Guests who visit again',
      icon: UserCheck,
      gradient: 'from-emerald-500 to-teal-500',
      glow: 'bg-emerald-500/20',
      trend: null,
      badgeFallback: `${formatNumber(loyaltyMembers)} Loyalty Cards`,
    },
  ];

  const secondaryStats = [
    {
      label: 'Dishes Sold',
      value: formatNumber(itemsSoldTotal),
      hint: 'Total portions',
      icon: UtensilsCrossed,
      accent: 'text-[#FF8F00] bg-[#FF6D00]/15 border-[#FF6D00]/30',
    },
    {
      label: 'Total Customers',
      value: formatNumber(totalCustomers),
      hint: `${formatNumber(loyaltyMembers)} loyalty cards`,
      icon: Award,
      accent: 'text-cyan-300 bg-cyan-500/15 border-cyan-500/30',
    },
    {
      label: 'Discounts Given',
      value: formatCurrency(totalDiscount),
      hint: 'Promo & loyalty off',
      icon: BadgePercent,
      accent: 'text-amber-300 bg-amber-500/15 border-amber-500/30',
    },
    {
      label: 'Service Charges',
      value: formatCurrency(totalServiceCharge),
      hint: 'Dine-in fee collected',
      icon: Sparkles,
      accent: 'text-emerald-300 bg-emerald-500/15 border-emerald-500/30',
    },
  ];

  return (
    <section className="mb-6">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-2 mb-4">
        <div>
          <h2 className="font-display text-lg font-bold text-white tracking-tight">
            Key Performance Indicators
          </h2>
          <p className="text-xs text-slate-400">
            Core sales, order activity, and customer retention numbers at a glance
          </p>
        </div>
      </div>

      {/* Row 1: 4 Clear Hero KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-4">
        {heroCards.map((card, idx) => {
          const Icon = card.icon;
          const hasTrend = card.trend !== null && card.trend !== 0;
          const isPositive = (card.trend || 0) >= 0;

          return (
            <motion.div
              key={card.title}
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.32, delay: idx * 0.04 }}
              className="cyber-card cyber-card-hover p-5 rounded-2xl relative overflow-hidden"
            >
              <div
                className={`absolute -right-8 -bottom-8 w-28 h-28 rounded-full ${card.glow} blur-2xl pointer-events-none`}
              />

              <div className="flex items-start justify-between gap-2 mb-3">
                <span className="text-xs font-semibold text-slate-300 tracking-wide">
                  {card.title}
                </span>
                <div
                  className={`w-9 h-9 rounded-xl bg-gradient-to-tr ${card.gradient} flex items-center justify-center shadow-lg shrink-0`}
                >
                  <Icon className="w-4 h-4 text-white" />
                </div>
              </div>

              <div className="flex items-baseline justify-between gap-2 flex-wrap mb-2">
                <span className="text-2xl md:text-[26px] font-black text-white tracking-tight tabular-nums">
                  {card.value}
                </span>

                {hasTrend ? (
                  <span
                    className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full border tabular-nums ${
                      isPositive
                        ? 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30'
                        : 'bg-rose-500/15 text-rose-300 border-rose-500/30'
                    }`}
                  >
                    {isPositive ? (
                      <TrendingUp className="w-3 h-3" />
                    ) : (
                      <TrendingDown className="w-3 h-3" />
                    )}
                    {isPositive ? '+' : ''}
                    {card.trend}% vs prior
                  </span>
                ) : (
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-white/5 text-slate-300 border border-white/10">
                    {card.badgeFallback}
                  </span>
                )}
              </div>

              <p className="text-[11px] text-slate-400 truncate">{card.helper}</p>
            </motion.div>
          );
        })}
      </div>

      {/* Row 2: 4 Compact Secondary Operational Tiles */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {secondaryStats.map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: 0.16 + idx * 0.03 }}
              className="cyber-panel cyber-card-hover px-4 py-3 rounded-2xl flex items-center justify-between gap-3"
            >
              <div className="min-w-0">
                <span className="text-[11px] font-medium text-slate-400 block truncate">
                  {stat.label}
                </span>
                <span className="text-base font-extrabold text-white tabular-nums block truncate">
                  {stat.value}
                </span>
                <span className="text-[10px] text-slate-500 block truncate">{stat.hint}</span>
              </div>
              <div
                className={`w-9 h-9 rounded-xl border flex items-center justify-center shrink-0 ${stat.accent}`}
              >
                <Icon className="w-4 h-4" />
              </div>
            </motion.div>
          );
        })}
      </div>
    </section>
  );
};
