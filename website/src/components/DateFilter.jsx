import React, { useMemo, useState } from 'react';
import { Calendar, ChevronDown, ChevronLeft, ChevronRight, Filter, RotateCcw } from 'lucide-react';

const FILTER_OPTIONS = [
  { id: 'daily', label: 'Daily' },
  { id: 'weekly', label: 'Weekly' },
  { id: 'monthly', label: 'Monthly' },
  { id: 'yearly', label: 'Yearly' },
  { id: 'custom', label: 'Custom Dates' },
  { id: 'allTime', label: 'All Time' },
];

const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export const DateFilter = ({
  currentPeriod,
  refDate,
  periodLabel,
  canStepPrev = true,
  canStepNext = false,
  isCurrentToday,
  availableMonths = [],
  onPeriodChange,
  onStepPeriod,
  onSelectDate,
  onJumpToday,
  onCustomRangeChange,
}) => {
  const [showCustomModal, setShowCustomModal] = useState(false);
  const [showMonthModal, setShowMonthModal] = useState(false);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const availableSet = useMemo(() => new Set(availableMonths || []), [availableMonths]);
  const yearsWithData = useMemo(() => {
    const yrs = new Set();
    (availableMonths || []).forEach((ym) => {
      const y = Number(String(ym).split('-')[0]);
      if (y) yrs.add(y);
    });
    return Array.from(yrs).sort((a, b) => a - b);
  }, [availableMonths]);

  const now = new Date();
  const [modalYear, setModalYear] = useState(refDate?.getFullYear?.() || now.getFullYear());

  const openPeriodPicker = () => {
    if (currentPeriod === 'monthly' || currentPeriod === 'yearly') {
      const initialYear =
        yearsWithData.length > 0 && !yearsWithData.includes(refDate?.getFullYear?.())
          ? yearsWithData[yearsWithData.length - 1]
          : refDate?.getFullYear?.() || now.getFullYear();
      setModalYear(initialYear);
      setShowMonthModal(true);
    } else if (currentPeriod === 'custom') {
      setShowCustomModal(true);
    }
  };

  const applyQuickPreset = (daysBack) => {
    const end = new Date();
    const start = new Date();
    if (daysBack === 'thisMonth') {
      start.setDate(1);
    } else {
      start.setDate(end.getDate() - daysBack);
    }
    const fmt = (d) => d.toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });
    setStartDate(fmt(start));
    setEndDate(fmt(end));
  };

  const handleCustomSubmit = (e) => {
    e.preventDefault();
    if (startDate && endDate) {
      const ordered = startDate <= endDate ? [startDate, endDate] : [endDate, startDate];
      onCustomRangeChange(ordered[0], ordered[1]);
      setShowCustomModal(false);
    }
  };

  const isSlicerStatic = currentPeriod === 'allTime' || currentPeriod === 'custom';
  const canOpenCenterPicker =
    currentPeriod === 'monthly' || currentPeriod === 'yearly' || currentPeriod === 'custom';

  const canPrevModalYear =
    yearsWithData.length > 0
      ? yearsWithData.some((y) => y < modalYear)
      : modalYear > 2020;
  const canNextModalYear =
    yearsWithData.length > 0
      ? modalYear < now.getFullYear() && yearsWithData.some((y) => y > modalYear)
      : modalYear < now.getFullYear();

  return (
    <div className="max-w-7xl mx-auto px-4 md:px-8 mb-6 space-y-3 no-print">
      <div className="cyber-card p-3 rounded-2xl flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
        {/* Left/Center Date Slicer (< November 2026 >) */}
        <div className="flex items-center justify-between gap-2 bg-white/[0.03] border border-white/10 rounded-xl px-1.5 py-1 flex-1 max-w-xl">
          <button
            type="button"
            onClick={() => onStepPeriod(-1)}
            disabled={isSlicerStatic || !canStepPrev}
            className="p-2 rounded-lg bg-white/5 hover:bg-white/10 disabled:opacity-25 disabled:cursor-not-allowed text-white transition-all"
            title={canStepPrev ? 'Previous period' : 'No earlier data'}
          >
            <ChevronLeft className="w-4 h-4" />
          </button>

          <button
            type="button"
            onClick={openPeriodPicker}
            disabled={!canOpenCenterPicker}
            className={`flex flex-wrap items-center justify-center gap-2 px-3 py-1 rounded-lg text-center transition-colors ${
              canOpenCenterPicker ? 'hover:bg-white/5 cursor-pointer' : 'cursor-default'
            }`}
            title={canOpenCenterPicker ? 'Click to pick period' : periodLabel}
          >
            <Calendar className="w-4 h-4 text-[#FF6D00]" />
            <span className="font-display text-sm md:text-base font-bold text-white tracking-wide">
              {periodLabel}
            </span>
            {canOpenCenterPicker && <ChevronDown className="w-4 h-4 text-slate-400" />}
          </button>

          <div className="flex items-center gap-1.5">
            {!isCurrentToday && currentPeriod !== 'allTime' && (
              <button
                type="button"
                onClick={onJumpToday}
                className="px-2.5 py-1.5 rounded-lg bg-[#FF6D00]/20 hover:bg-[#FF6D00]/30 border border-[#FF6D00]/40 text-[#FF8F00] text-[11px] font-bold flex items-center gap-1 transition-all"
              >
                <RotateCcw className="w-3 h-3" />
                <span className="hidden sm:inline">Current</span>
              </button>
            )}
            <button
              type="button"
              onClick={() => onStepPeriod(1)}
              disabled={isSlicerStatic || !canStepNext}
              className="p-2 rounded-lg bg-white/5 hover:bg-white/10 disabled:opacity-25 disabled:cursor-not-allowed text-white transition-all"
              title={canStepNext ? 'Next period' : 'Already at latest data'}
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Right Timeframe Pills */}
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="hidden xl:flex items-center gap-1.5 pr-2 text-slate-400 text-xs font-medium">
            <Filter className="w-3.5 h-3.5 text-[#FF6D00]" />
            <span>View by:</span>
          </span>
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
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all duration-200 ${
                  isSelected
                    ? 'bg-gradient-to-r from-[#FF6D00] to-[#FF9100] text-white shadow-glow'
                    : 'bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10'
                }`}
              >
                {opt.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Month / Year Picker Modal (Dimmed empty months) */}
      {showMonthModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="cyber-card w-full max-w-sm p-6 rounded-3xl border border-white/15 shadow-2xl">
            <div className="flex items-center justify-between mb-4">
              <button
                type="button"
                disabled={!canPrevModalYear}
                onClick={() => {
                  if (yearsWithData.length > 0) {
                    const prev = yearsWithData.filter((y) => y < modalYear);
                    if (prev.length) setModalYear(prev[prev.length - 1]);
                  } else {
                    setModalYear((y) => y - 1);
                  }
                }}
                className="p-2 rounded-xl bg-white/5 hover:bg-white/10 disabled:opacity-25 text-white"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span className="font-display text-lg font-extrabold text-white">{modalYear}</span>
              <button
                type="button"
                disabled={!canNextModalYear}
                onClick={() => {
                  if (yearsWithData.length > 0) {
                    const nxt = yearsWithData.filter((y) => y > modalYear);
                    if (nxt.length) setModalYear(nxt[0]);
                  } else {
                    setModalYear((y) => y + 1);
                  }
                }}
                className="p-2 rounded-xl bg-white/5 hover:bg-white/10 disabled:opacity-25 text-white"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>

            {currentPeriod === 'yearly' ? (
              <div className="flex flex-wrap gap-2 justify-center py-2">
                {(yearsWithData.length > 0 ? [...yearsWithData].reverse() : [now.getFullYear()]).map((yr) => {
                  const isSel = refDate?.getFullYear?.() === yr;
                  return (
                    <button
                      key={yr}
                      type="button"
                      onClick={() => {
                        onSelectDate?.(new Date(yr, 0, 1));
                        setShowMonthModal(false);
                      }}
                      className={`px-4 py-2 rounded-xl text-xs font-bold border transition-all ${
                        isSel
                          ? 'bg-[#FF6D00] text-white border-[#FF6D00]'
                          : 'bg-white/5 hover:bg-white/10 text-white border-white/15'
                      }`}
                    >
                      {yr}
                    </button>
                  );
                })}
              </div>
            ) : (
              <div className="grid grid-cols-3 gap-2">
                {MONTH_NAMES.map((label, idx) => {
                  const monthNum = idx + 1;
                  const ym = `${modalYear}-${String(monthNum).padStart(2, '0')}`;
                  const isFuture =
                    modalYear > now.getFullYear() ||
                    (modalYear === now.getFullYear() && idx > now.getMonth());
                  const hasData =
                    availableSet.size === 0
                      ? modalYear === now.getFullYear() && idx === now.getMonth()
                      : availableSet.has(ym);
                  const disabled = isFuture || !hasData;
                  const isSel =
                    !disabled &&
                    refDate?.getFullYear?.() === modalYear &&
                    refDate?.getMonth?.() === idx;

                  return (
                    <button
                      key={ym}
                      type="button"
                      disabled={disabled}
                      onClick={() => {
                        onSelectDate?.(new Date(modalYear, idx, 1));
                        setShowMonthModal(false);
                      }}
                      className={`py-2.5 rounded-xl text-xs font-bold border transition-all ${
                        isSel
                          ? 'bg-gradient-to-r from-[#FF6D00] to-[#FF9100] text-white border-[#FF6D00] shadow-glow'
                          : disabled
                          ? 'bg-transparent text-slate-600 border-white/5 opacity-40 cursor-not-allowed'
                          : 'bg-white/5 hover:bg-[#FF6D00]/20 text-slate-100 border-white/15'
                      }`}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>
            )}

            <div className="flex items-center justify-between pt-4 mt-4 border-t border-white/10">
              <span className="text-[11px] text-slate-400">Months without orders are dimmed</span>
              <button
                type="button"
                onClick={() => setShowMonthModal(false)}
                className="px-3 py-1.5 text-xs font-bold text-slate-300 hover:text-white"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Dual From/To Custom Date Modal */}
      {showCustomModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="cyber-card w-full max-w-md p-6 rounded-3xl border border-white/15 shadow-2xl">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-display font-bold text-white flex items-center gap-2">
                <Calendar className="w-5 h-5 text-[#FF6D00]" />
                <span>Pick Custom Date Range</span>
              </h3>
              <button
                type="button"
                onClick={() => setShowCustomModal(false)}
                className="text-slate-400 hover:text-white text-sm"
              >
                ✕
              </button>
            </div>

            <div className="flex flex-wrap gap-2 mb-4">
              <button
                type="button"
                onClick={() => applyQuickPreset(6)}
                className="px-2.5 py-1 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-[11px] font-semibold text-slate-300"
              >
                Last 7 Days
              </button>
              <button
                type="button"
                onClick={() => applyQuickPreset(29)}
                className="px-2.5 py-1 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-[11px] font-semibold text-slate-300"
              >
                Last 30 Days
              </button>
              <button
                type="button"
                onClick={() => applyQuickPreset('thisMonth')}
                className="px-2.5 py-1 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-[11px] font-semibold text-slate-300"
              >
                This Month
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
                    max={now.toLocaleDateString('en-CA')}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="w-full bg-black/60 border border-white/15 rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-[#FF6D00] [color-scheme:dark]"
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
                    min={startDate || undefined}
                    max={now.toLocaleDateString('en-CA')}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="w-full bg-black/60 border border-white/15 rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-[#FF6D00] [color-scheme:dark]"
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
                  Apply Dates
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
