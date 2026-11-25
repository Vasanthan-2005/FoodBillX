import React, { useState } from 'react';
import { Calendar, ChevronLeft, ChevronRight, Filter, RotateCcw } from 'lucide-react';

const FILTER_OPTIONS = [
  { id: 'daily', label: 'Daily' },
  { id: 'weekly', label: 'Weekly' },
  { id: 'monthly', label: 'Monthly' },
  { id: 'yearly', label: 'Yearly' },
  { id: 'custom', label: 'Custom' },
  { id: 'allTime', label: 'All Time' },
];

export const DateFilter = ({
  currentPeriod,
  periodLabel,
  canStepNext,
  isCurrentToday,
  onPeriodChange,
  onStepPeriod,
  onJumpToday,
  onCustomRangeChange,
}) => {
  const [showCustomModal, setShowCustomModal] = useState(false);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const handleCustomSubmit = (e) => {
    e.preventDefault();
    if (startDate && endDate) {
      onCustomRangeChange(startDate, endDate);
      setShowCustomModal(false);
    }
  };

  const isSlicerStatic = currentPeriod === 'allTime' || currentPeriod === 'custom';

  return (
    <div className="max-w-7xl mx-auto px-4 md:px-8 mb-7 space-y-3 no-print">
      {/* Period Slicer Above (< November 2026 >) */}
      <div className="cyber-card p-2 md:p-2.5 rounded-2xl flex items-center justify-between gap-3">
        <button
          type="button"
          onClick={() => onStepPeriod(-1)}
          disabled={isSlicerStatic}
          className="p-2 rounded-xl bg-white/5 hover:bg-white/10 disabled:opacity-25 text-white transition-all"
          title="Previous Period"
        >
          <ChevronLeft className="w-5 h-5" />
        </button>

        <div className="flex flex-wrap items-center justify-center gap-2.5 text-center">
          <Calendar className="w-4 h-4 text-[#FF6D00]" />
          <span className="font-display text-sm md:text-base font-bold text-white tracking-wide">
            {periodLabel}
          </span>
          {!isCurrentToday && currentPeriod !== 'allTime' && (
            <button
              type="button"
              onClick={onJumpToday}
              className="px-2.5 py-1 rounded-lg bg-[#FF6D00]/20 hover:bg-[#FF6D00]/30 border border-[#FF6D00]/40 text-[#FF8F00] text-[11px] font-bold flex items-center gap-1 transition-all"
            >
              <RotateCcw className="w-3 h-3" />
              <span>Today</span>
            </button>
          )}
        </div>

        <button
          type="button"
          onClick={() => onStepPeriod(1)}
          disabled={isSlicerStatic || !canStepNext}
          className="p-2 rounded-xl bg-white/5 hover:bg-white/10 disabled:opacity-25 text-white transition-all"
          title="Next Period"
        >
          <ChevronRight className="w-5 h-5" />
        </button>
      </div>

      {/* Timeframe Filter Bar Below */}
      <div className="cyber-card p-2.5 md:p-3 rounded-2xl flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2 px-2 text-slate-400 text-xs font-mono uppercase tracking-wider">
          <Filter className="w-3.5 h-3.5 text-[#FF6D00]" />
          <span>Timeframe</span>
        </div>

        <div className="flex flex-wrap items-center gap-1.5 md:gap-2">
          {FILTER_OPTIONS.map((opt) => {
            const isSelected = currentPeriod === opt.id;
            return (
              <button
                key={opt.id}
                type="button"
                onClick={() => {
                  if (opt.id === 'custom') {
                    setShowCustomModal(true);
                  } else {
                    onPeriodChange(opt.id);
                  }
                }}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all duration-200 ${
                  isSelected
                    ? 'bg-gradient-to-r from-[#FF6D00] to-[#FF9100] text-white shadow-glow scale-[1.02]'
                    : 'bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10'
                }`}
              >
                {opt.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Dual From/To Custom Date Modal */}
      {showCustomModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="cyber-card w-full max-w-md p-6 rounded-3xl border border-white/15 shadow-2xl">
            <div className="flex items-center justify-between mb-5">
              <h3 className="text-lg font-display font-bold text-white flex items-center gap-2">
                <Calendar className="w-5 h-5 text-[#FF6D00]" />
                <span>Select Custom Date Range</span>
              </h3>
              <button
                type="button"
                onClick={() => setShowCustomModal(false)}
                className="text-slate-400 hover:text-white text-sm"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCustomSubmit} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-400 mb-1">
                    From Date
                  </label>
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="w-full bg-black/60 border border-white/15 rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-[#FF6D00]"
                    required
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-400 mb-1">
                    To Date
                  </label>
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="w-full bg-black/60 border border-white/15 rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-[#FF6D00]"
                    required
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowCustomModal(false)}
                  className="px-4 py-2 text-xs font-bold text-slate-400 hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold text-white bg-gradient-to-r from-[#FF6D00] to-[#FF9100] rounded-xl shadow-glow"
                >
                  Apply Filter
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
