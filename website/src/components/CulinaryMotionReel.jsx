import React, { useEffect, useMemo, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Sparkles,
  Flame,
  TrendingUp,
  Clock,
  Award,
  Play,
  Pause,
} from 'lucide-react';
import {
  formatCompactCurrency,
  formatCurrency,
  formatNumber,
} from '../utils/formatters';

export const CulinaryMotionReel = ({
  analytics = {},
  settings = {},
  periodLabel = 'Current Period',
}) => {
  const [sceneIdx, setSceneIdx] = useState(0);
  const [isPlaying, setIsPlaying] = useState(true);

  const kpis = analytics?.kpis || {};
  const topDish = analytics?.topSellingItems?.[0] || null;
  const shopName = settings?.businessName || 'HMB Bills';

  const scenes = useMemo(() => {
    const hourly = analytics?.hourlyData || [];
    const peakHour = hourly.reduce(
      (max, item) => ((item.count || 0) > (max.count || 0) ? item : max),
      { count: 0, hour: 'N/A' }
    );

    const pay = analytics?.paymentBreakdown || {};
    const topPaymentEntry = [
      { name: 'UPI', amount: pay.upi || 0 },
      { name: 'Cash', amount: pay.cash || 0 },
      { name: 'Card', amount: pay.card || 0 },
      { name: 'Wallet', amount: pay.wallet || 0 },
    ].sort((a, b) => b.amount - a.amount)[0];

    const growthText =
      kpis.revenueGrowth > 0
        ? `up ${kpis.revenueGrowth}% compared to previous period`
        : kpis.revenueGrowth < 0
        ? `${Math.abs(kpis.revenueGrowth)}% lower than previous period`
        : 'steady sales volume for this period';

    return [
      {
        id: 'sales-snapshot',
        tag: 'SALES SPOTLIGHT',
        title: `${formatCurrency(kpis.revenue || 0)} Total Revenue`,
        subtitle: `${formatNumber(kpis.ordersCount || 0)} completed customer bills with ${growthText}.`,
        accent: '#FF6D00',
        glowClass: 'from-[#FF6D00]/25 via-amber-500/10 to-transparent',
        icon: TrendingUp,
      },
      {
        id: 'top-dish',
        tag: 'MOST POPULAR DISH',
        title: topDish ? `#1 Bestseller: ${topDish.name}` : 'Ready for Kitchen Orders',
        subtitle: topDish
          ? `${formatNumber(topDish.qtySold)} portions ordered, generating ${formatCurrency(topDish.revenue)} in sales.`
          : 'Your highest-ordered menu items and dish earnings appear here once orders sync.',
        accent: '#FFB300',
        glowClass: 'from-amber-500/25 via-[#FF6D00]/10 to-transparent',
        icon: Flame,
      },
      {
        id: 'peak-payment',
        tag: 'RUSH HOUR & PAYMENTS',
        title:
          peakHour.count > 0
            ? `Busiest at ${peakHour.hour} (${formatNumber(peakHour.count)} bills)`
            : 'Peak Rush Hour Monitor',
        subtitle:
          topPaymentEntry?.amount > 0
            ? `Most customers paid via ${topPaymentEntry.name} (${formatCurrency(topPaymentEntry.amount)} collected).`
            : 'Track peak kitchen demand hours and preferred customer payment methods.',
        accent: '#22D3EE',
        glowClass: 'from-cyan-500/25 via-blue-500/10 to-transparent',
        icon: Clock,
      },
      {
        id: 'guest-loyalty',
        tag: 'CUSTOMER RETENTION',
        title: `${kpis.returningPercent || 0}% Repeat Customer Rate`,
        subtitle: `${formatNumber(kpis.loyaltyMembers || 0)} loyalty card holders across ${formatNumber(kpis.totalCustomers || 0)} saved guests.`,
        accent: '#00E676',
        glowClass: 'from-emerald-500/25 via-teal-500/10 to-transparent',
        icon: Award,
      },
    ];
  }, [analytics, kpis, topDish]);

  useEffect(() => {
    if (!isPlaying) return undefined;
    const timer = setInterval(() => {
      setSceneIdx((prev) => (prev + 1) % scenes.length);
    }, 5200);
    return () => clearInterval(timer);
  }, [isPlaying, scenes.length]);

  const scene = scenes[sceneIdx] || scenes[0];
  const SceneIcon = scene.icon;

  return (
    <section className="max-w-7xl mx-auto px-4 md:px-8 mb-6 no-print">
      <div className="cyber-hero-glow rounded-3xl relative overflow-hidden p-5 md:p-6">
        {/* Moving Ambient Motion Layer (Ken-Burns Gradient + Laser Scan Beam) */}
        <div
          className={`absolute inset-0 bg-gradient-to-r ${scene.glowClass} motion-kenburns pointer-events-none`}
        />
        <div className="absolute inset-x-0 top-0 h-[2px] overflow-hidden pointer-events-none">
          <div
            className="w-1/3 h-full cyber-scan-line"
            style={{
              background: `linear-gradient(90deg, transparent, ${scene.accent}, #ffffff, transparent)`,
            }}
          />
        </div>

        <div className="relative z-10 grid grid-cols-1 lg:grid-cols-12 gap-5 items-center">
          {/* Left Narrative + Interactive Controls */}
          <div className="lg:col-span-7 space-y-3">
            <div className="flex flex-wrap items-center gap-2.5">
              <span
                className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-mono font-bold uppercase tracking-widest border"
                style={{
                  color: scene.accent,
                  borderColor: `${scene.accent}60`,
                  backgroundColor: `${scene.accent}1A`,
                }}
              >
                <Sparkles className="w-3 h-3" />
                {scene.tag}
              </span>
              <span className="text-[11px] font-mono text-slate-400">
                {shopName} • {periodLabel}
              </span>
            </div>

            <AnimatePresence mode="wait">
              <motion.div
                key={scene.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                className="space-y-1.5"
              >
                <h2 className="font-display text-2xl md:text-3xl font-extrabold text-white tracking-tight leading-tight">
                  {scene.title}
                </h2>
                <p className="text-sm text-slate-300 max-w-xl leading-relaxed">
                  {scene.subtitle}
                </p>
              </motion.div>
            </AnimatePresence>

            <div className="flex flex-wrap items-center gap-3 pt-1">
              <button
                type="button"
                onClick={() => setIsPlaying((p) => !p)}
                className="w-8 h-8 rounded-full bg-white/5 hover:bg-white/15 border border-white/10 flex items-center justify-center text-slate-200 transition-colors"
                title={isPlaying ? 'Pause live spotlight' : 'Play live spotlight'}
              >
                {isPlaying ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
              </button>
              <div className="flex items-center gap-1.5">
                {scenes.map((s, idx) => (
                  <button
                    key={s.id}
                    type="button"
                    onClick={() => setSceneIdx(idx)}
                    className="h-2 rounded-full transition-all duration-300"
                    style={{
                      width: idx === sceneIdx ? '36px' : '12px',
                      backgroundColor: idx === sceneIdx ? s.accent : 'rgba(255,255,255,0.18)',
                    }}
                    title={s.tag}
                  />
                ))}
              </div>
              <span className="text-[11px] text-slate-400 hidden sm:inline">
                Key live highlights for your selected period
              </span>
            </div>
          </div>

          {/* Right Animated Holographic Stage */}
          <div className="lg:col-span-5 flex items-center justify-center">
            <div className="relative w-full max-w-[380px] h-44 rounded-2xl bg-[#050812]/80 holo-grid-bg border border-white/12 overflow-hidden flex items-center justify-center p-4">
              {/* Animated SVG Orbital Rings & Energy Wave */}
              <svg
                viewBox="0 0 320 176"
                className="absolute inset-0 w-full h-full opacity-70 pointer-events-none"
              >
                <defs>
                  <linearGradient id="reelWaveGrad" x1="0" y1="0" x2="1" y2="0">
                    <stop offset="0%" stopColor="transparent" />
                    <stop offset="50%" stopColor={scene.accent} />
                    <stop offset="100%" stopColor="transparent" />
                  </linearGradient>
                </defs>
                <motion.circle
                  cx="160"
                  cy="76"
                  r="58"
                  fill="none"
                  stroke={scene.accent}
                  strokeOpacity="0.24"
                  strokeDasharray="6 6"
                  animate={{ rotate: 360 }}
                  transition={{ duration: 24, repeat: Infinity, ease: 'linear' }}
                  style={{ originX: '160px', originY: '76px' }}
                />
                <motion.circle
                  cx="160"
                  cy="76"
                  r="40"
                  fill="none"
                  stroke="#22D3EE"
                  strokeOpacity="0.28"
                  strokeDasharray="3 5"
                  animate={{ rotate: -360 }}
                  transition={{ duration: 15, repeat: Infinity, ease: 'linear' }}
                  style={{ originX: '160px', originY: '76px' }}
                />
                <motion.path
                  d="M 10 130 Q 65 90 120 122 T 230 94 T 310 110"
                  fill="none"
                  stroke="url(#reelWaveGrad)"
                  strokeWidth="2.5"
                  animate={{
                    d: [
                      'M 10 130 Q 65 90 120 122 T 230 94 T 310 110',
                      'M 10 116 Q 75 142 140 96 T 240 126 T 310 92',
                      'M 10 130 Q 65 90 120 122 T 230 94 T 310 110',
                    ],
                  }}
                  transition={{ duration: 4.8, repeat: Infinity, ease: 'easeInOut' }}
                />
              </svg>

              {/* Center Holographic Icon & Clean Quick Numbers */}
              <div className="relative z-10 w-full flex flex-col items-center text-center">
                <div className="relative mb-3">
                  <div
                    className="absolute inset-0 rounded-2xl motion-ring"
                    style={{ border: `2px solid ${scene.accent}` }}
                  />
                  <div
                    className="w-11 h-11 rounded-2xl flex items-center justify-center shadow-lg"
                    style={{
                      backgroundColor: `${scene.accent}24`,
                      border: `1px solid ${scene.accent}80`,
                    }}
                  >
                    <SceneIcon className="w-5 h-5" style={{ color: scene.accent }} />
                  </div>
                </div>

                <div className="w-full grid grid-cols-3 gap-2 pt-2 border-t border-white/10 tabular-nums">
                  <div>
                    <span className="text-[10px] font-mono text-slate-400 block">SALES</span>
                    <span className="text-sm font-extrabold text-white">
                      {formatCompactCurrency(kpis.revenue || 0)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] font-mono text-slate-400 block">ORDERS</span>
                    <span className="text-sm font-extrabold text-cyan-300">
                      {formatNumber(kpis.ordersCount || 0)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] font-mono text-slate-400 block">AVG BILL</span>
                    <span className="text-sm font-extrabold text-emerald-400">
                      {formatCompactCurrency(kpis.aov || 0)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
