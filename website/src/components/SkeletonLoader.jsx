import React from 'react';

export const SkeletonCard = () => (
  <div className="cyber-card p-5 rounded-2xl animate-pulse space-y-3">
    <div className="flex justify-between items-center">
      <div className="h-3 bg-white/10 rounded w-24" />
      <div className="h-9 w-9 bg-white/10 rounded-xl" />
    </div>
    <div className="h-7 bg-white/10 rounded w-32" />
    <div className="h-2.5 bg-white/5 rounded w-28" />
  </div>
);

export const SkeletonChart = ({ heightClass = 'h-72' }) => (
  <div className="cyber-card p-6 rounded-3xl animate-pulse space-y-4">
    <div className="h-4 bg-white/10 rounded w-48" />
    <div className={`${heightClass} bg-white/5 rounded-2xl`} />
  </div>
);
