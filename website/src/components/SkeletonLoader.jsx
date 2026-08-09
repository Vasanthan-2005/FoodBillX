import React from 'react';

export const SkeletonCard = () => (
  <div className="glass-card p-5 rounded-2xl animate-pulse space-y-3">
    <div className="flex justify-between items-center">
      <div className="h-3 bg-slate-800 rounded w-24"></div>
      <div className="h-8 w-8 bg-slate-800 rounded-xl"></div>
    </div>
    <div className="h-7 bg-slate-800 rounded w-32"></div>
  </div>
);

export const SkeletonChart = () => (
  <div className="glass-card p-6 rounded-3xl animate-pulse space-y-4 mb-8">
    <div className="h-4 bg-slate-800 rounded w-48"></div>
    <div className="h-64 bg-slate-900/50 rounded-2xl"></div>
  </div>
);
