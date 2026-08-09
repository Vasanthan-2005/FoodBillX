import React, { useState } from 'react';
import { Calendar, Filter } from 'lucide-react';

const FILTER_OPTIONS = [
  { id: 'today', label: "Today's Report" },
  { id: 'yesterday', label: 'Yesterday' },
  { id: 'last7', label: 'Last 7 Days' },
  { id: 'last30', label: 'Last 30 Days' },
  { id: 'thisMonth', label: 'This Month' },
  { id: 'lastMonth', label: 'Last Month' },
  { id: 'custom', label: 'Custom Range' },
];

export const DateFilter = ({ currentPeriod, onPeriodChange, onCustomRangeChange }) => {
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

  return (
    <div className="max-w-7xl mx-auto px-4 md:px-8 mb-8">
      <div className="glass-card p-2 md:p-3 rounded-2xl flex flex-wrap items-center justify-between gap-3 shadow-lg">
        {/* Label */}
        <div className="flex items-center gap-2 px-3 py-1 text-slate-400 text-xs font-semibold uppercase tracking-wider">
          <Filter className="w-3.5 h-3.5 text-[#FF5722]" />
          <span>Report Period</span>
        </div>

        {/* Option Chips */}
        <div className="flex flex-wrap items-center gap-1.5 md:gap-2">
          {FILTER_OPTIONS.map((opt) => {
            const isSelected = currentPeriod === opt.id;
            return (
              <button
                key={opt.id}
                onClick={() => {
                  if (opt.id === 'custom') {
                    setShowCustomModal(true);
                  } else {
                    onPeriodChange(opt.id);
                  }
                }}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all duration-200 ${
                  isSelected
                    ? 'bg-gradient-to-r from-[#FF5722] to-[#FF7043] text-white shadow-md shadow-[#FF5722]/30 scale-[1.02]'
                    : 'bg-slate-800/80 hover:bg-slate-700/80 text-slate-300 border border-slate-700/60'
                }`}
              >
                {opt.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Custom Date Range Modal */}
      {showCustomModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fadeIn">
          <div className="glass-panel w-full max-w-md p-6 rounded-3xl border border-slate-700 shadow-2xl">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Calendar className="w-5 h-5 text-[#FF5722]" />
                <span>Select Custom Date Range</span>
              </h3>
              <button
                onClick={() => setShowCustomModal(false)}
                className="text-slate-400 hover:text-white text-sm"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCustomSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-400 mb-1">Start Date</label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-[#FF5722]"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-400 mb-1">End Date</label>
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-[#FF5722]"
                  required
                />
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
                  className="px-5 py-2 text-xs font-bold text-white bg-[#FF5722] hover:bg-[#F4511E] rounded-xl shadow-lg shadow-[#FF5722]/30"
                >
                  Apply Date Range
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
