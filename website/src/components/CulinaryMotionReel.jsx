import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Sparkles, Flame, Cloud, Award, Activity, Play, Pause } from 'lucide-react';
import { formatCompactCurrency, formatNumber } from '../utils/formatters';

const MOTION_SCENES = [
  {
    id: 'kitchen-pulse',
    tag: 'LIVE CULINARY TELEMETRY',
    title: 'Precision POS Kitchen Velocity',
    subtitle: 'Instant billing, zero-GST itemized receipts & real-time dish velocity across every counter.',
    accent: '#FF6D00',
    glowClass: 'from-[#FF6D00]/30 via-amber-500/10 to-transparent',
    icon: Flame,
  },
  {
    id: 'cloud-stream',
    tag: 'CLOUD SYNC MATRIX',
    title: 'Seamless Offline-to-Atlas Sync',
    subtitle: 'SQLite mobile transactions stream continuously to MongoDB Atlas with idempotent receipts.',
    accent: '#22D3EE',
    glowClass: 'from-cyan-500/30 via-blue-500/10 to-transparent',
    icon: Cloud,
  },
  {
    id: 'loyalty-core',
    tag: 'LOYALTY NEURAL GRAPH',
    title: 'Automated Guest Reward Engine',
    subtitle: 'Every visit updates lifetime spend, visit streaks & milestone reward alerts automatically.',
    accent: '#A855F7',
    glowClass: 'from-purple-500/30 via-pink-500/10 to-transparent',
    icon: Award,
  },
  {
    id: 'analytics-hud',
    tag: 'EXECUTIVE ANALYTICS',
    title: 'Dynamic Slicers & Vector Exports',
    subtitle: 'Inspect Daily, Weekly, Monthly, Yearly & Custom periods with live chart projections.',
    accent: '#00E676',
    glowClass: 'from-emerald-500/30 via-teal-500/10 to-transparent',
    icon: Activity,
  },
];

export const CulinaryMotionReel = ({ analytics = {}, syncStatus = {}, settings = {} }) => {
  const [sceneIdx, setSceneIdx] = useState(0);
  const [isPlaying, setIsPlaying] = useState(true);

  useEffect(() => {
    if (!isPlaying) return undefined;
    const timer = setInterval(() => {
      setSceneIdx((prev) => (prev + 1) % MOTION_SCENES.length);
    }, 5200);
    return () => clearInterval(timer);
  }, [isPlaying]);

  const scene = MOTION_SCENES[sceneIdx];
  const SceneIcon = scene.icon;
  const kpis = analytics?.kpis || {};
  const shopName = settings?.businessName || 'HMB Bills';

  return (
    <section className="max-w-7xl mx-auto px-4 md:px-8 mb-7">
      <div className="cyber-card rounded-3xl relative overflow-hidden p-6 md:p-8 border border-white/10">
        {/* Moving Ambient Motion Layer (CSS Ken-Burns + Light Sweep) */}
        <div
          className={`absolute inset-0 bg-gradient-to-r ${scene.glowClass} motion-kenburns pointer-events-none`}
        />
        <div className="absolute inset-x-0 top-0 h-[1.5px] overflow-hidden pointer-events-none">
          <div
            className="w-1/3 h-full cyber-scan-line"
            style={{
              background: `linear-gradient(90deg, transparent, ${scene.accent}, #fff, transparent)`,
            }}
          />
        </div>

        <div className="relative z-10 grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
          {/* Left Narrative + Kinetic Controls */}
          <div className="lg:col-span-7 space-y-4">
            <div className="flex flex-wrap items-center gap-2.5">
              <span
                className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-mono font-bold uppercase tracking-widest border"
                style={{
                  color: scene.accent,
                  borderColor: `${scene.accent}55`,
                  backgroundColor: `${scene.accent}18`,
                }}
              >
                <Sparkles className="w-3 h-3" />
                {scene.tag}
              </span>
              <span className="text-[11px] font-mono text-slate-400">
                {shopName.toUpperCase()} // OS 2.0
              </span>
            </div>

            <AnimatePresence mode="wait">
              <motion.div
                key={scene.id}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -12 }}
                transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
                className="space-y-2"
              >
                <h2 className="font-display text-2xl md:text-3xl font-bold text-white tracking-tight leading-tight">
                  {scene.title}
                </h2>
                <p className="text-sm text-slate-300 max-w-xl leading-relaxed">
                  {scene.subtitle}
                </p>
              </motion.div>
            </AnimatePresence>

            {/* Interactive Motion Reel Controls */}
            <div className="flex flex-wrap items-center gap-3 pt-1">
              <button
                type="button"
                onClick={() => setIsPlaying((p) => !p)}
                className="w-8 h-8 rounded-full bg-white/5 hover:bg-white/15 border border-white/10 flex items-center justify-center text-slate-200 transition-colors"
                title={isPlaying ? 'Pause motion reel' : 'Play motion reel'}
              >
                {isPlaying ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
              </button>
              <div className="flex items-center gap-2">
                {MOTION_SCENES.map((s, idx) => (
                  <button
                    key={s.id}
                    type="button"
                    onClick={() => setSceneIdx(idx)}
                    className="group relative h-2 rounded-full transition-all duration-300 overflow-hidden"
                    style={{
                      width: idx === sceneIdx ? '38px' : '12px',
                      backgroundColor: idx === sceneIdx ? s.accent : 'rgba(255,255,255,0.16)',
                    }}
                    title={s.title}
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Right Animated Orbital SVG Motion Graphic + Live HUD */}
          <div className="lg:col-span-5 flex items-center justify-center">
            <div className="relative w-full max-w-[340px] h-48 rounded-2xl bg-black/50 border border-white/10 overflow-hidden flex items-center justify-center p-4">
              {/* Animated SVG Radar Rings & Waveform */}
              <svg
                viewBox="0 0 320 180"
                className="absolute inset-0 w-full h-full opacity-65 pointer-events-none"
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
                  cy="90"
                  r="64"
                  fill="none"
                  stroke={scene.accent}
                  strokeOpacity="0.22"
                  strokeDasharray="6 6"
                  animate={{ rotate: 360 }}
                  transition={{ duration: 24, repeat: Infinity, ease: 'linear' }}
                  style={{ originX: '160px', originY: '90px' }}
                />
                <motion.circle
                  cx="160"
                  cy="90"
                  r="44"
                  fill="none"
                  stroke="#22D3EE"
                  strokeOpacity="0.25"
                  strokeDasharray="3 5"
                  animate={{ rotate: -360 }}
                  transition={{ duration: 16, repeat: Infinity, ease: 'linear' }}
                  style={{ originX: '160px', originY: '90px' }}
                />
                <motion.path
                  d="M 10 132 Q 65 92 120 124 T 230 96 T 310 112"
                  fill="none"
                  stroke="url(#reelWaveGrad)"
                  strokeWidth="2.5"
                  animate={{
                    d: [
                      'M 10 132 Q 65 92 120 124 T 230 96 T 310 112',
                      'M 10 118 Q 70 144 135 98 T 235 128 T 310 92',
                      'M 10 132 Q 65 92 120 124 T 230 96 T 310 112',
                    ],
                  }}
                  transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
                />
              </svg>

              {/* Center Holographic Emblem + Telemetry Readout */}
              <div className="relative z-10 flex flex-col items-center text-center">
                <div className="relative mb-2.5">
                  <div
                    className="absolute inset-0 rounded-2xl motion-ring"
                    style={{ border: `2px solid ${scene.accent}` }}
                  />
                  <div
                    className="w-12 h-12 rounded-2xl flex items-center justify-center shadow-lg"
                    style={{
                      backgroundColor: `${scene.accent}26`,
                      border: `1px solid ${scene.accent}75`,
                    }}
                  >
                    <SceneIcon className="w-6 h-6" style={{ color: scene.accent }} />
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-4 mt-1 px-2">
                  <div>
                    <span className="text-[9px] font-mono text-slate-400 block">REVENUE</span>
                    <span className="text-xs font-extrabold text-white">
                      {formatCompactCurrency(kpis.revenue || 0)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[9px] font-mono text-slate-400 block">ORDERS</span>
                    <span className="text-xs font-extrabold text-cyan-300">
                      {formatNumber(kpis.ordersCount || 0)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[9px] font-mono text-slate-400 block">CLOUD</span>
                    <span className="text-xs font-extrabold text-emerald-400">
                      {formatNumber(syncStatus?.totalRecords || 0)}
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
