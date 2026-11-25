import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Search, Users, Award, Phone, Star } from 'lucide-react';
import { reportsService } from '../services/reportsService';
import { formatCurrency, formatNumber } from '../utils/formatters';

export const CustomersDirectory = () => {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery({
    queryKey: ['customers', search, page],
    queryFn: () => reportsService.getCustomers({ search, page, limit: 30 }),
    staleTime: 10000,
  });

  const customers = data?.customers || [];
  const totalPages = data?.totalPages || 1;
  const total = data?.total || 0;

  return (
    <section className="max-w-7xl mx-auto px-4 md:px-8 mb-10">
      <div className="cyber-card p-6 rounded-3xl">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
          <div>
            <div className="flex items-center gap-2">
              <Users className="w-5 h-5 text-cyan-400" />
              <h2 className="font-display text-lg font-bold text-white tracking-tight">
                Customer & Loyalty Matrix ({formatNumber(total)})
              </h2>
            </div>
            <p className="text-xs text-slate-400 mt-0.5">
              Synced guest profiles, visit milestones & loyalty card numbers
            </p>
          </div>

          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search name, phone or loyalty card..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="bg-black/50 border border-white/15 rounded-xl pl-9 pr-4 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-[#FF6D00] w-64"
            />
          </div>
        </div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {Array.from({ length: 6 }).map((_, idx) => (
              <div key={idx} className="cyber-panel p-4 rounded-2xl animate-pulse h-28" />
            ))}
          </div>
        ) : customers.length === 0 ? (
          <div className="py-12 text-center text-slate-500 text-sm">
            No matching customers synced to cloud yet
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {customers.map((c) => (
              <div
                key={c._id || c.id || c.phone}
                className="cyber-panel cyber-card-hover p-4 rounded-2xl border border-white/10 space-y-3"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-10 h-10 rounded-xl bg-[#FF6D00]/20 border border-[#FF6D00]/40 text-[#FF8F00] font-black flex items-center justify-center shrink-0">
                      {(c.name || 'C').slice(0, 1).toUpperCase()}
                    </div>
                    <div className="min-w-0">
                      <h4 className="text-sm font-bold text-white truncate">{c.name}</h4>
                      <p className="text-xs text-slate-400 flex items-center gap-1">
                        <Phone className="w-3 h-3" />
                        <span>{c.phone}</span>
                      </p>
                    </div>
                  </div>
                  {c.loyaltyCardNumber && (
                    <span className="px-2 py-0.5 rounded-lg bg-amber-500/20 border border-amber-500/40 text-amber-300 text-[10px] font-mono font-bold flex items-center gap-1 shrink-0">
                      <Award className="w-3 h-3" />
                      {c.loyaltyCardNumber}
                    </span>
                  )}
                </div>

                <div className="grid grid-cols-3 gap-2 pt-2 border-t border-white/10 text-center">
                  <div>
                    <span className="text-[10px] text-slate-400 block">Visits</span>
                    <span className="text-xs font-extrabold text-white">
                      {formatNumber(c.totalVisits || 0)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] text-slate-400 block">Spent</span>
                    <span className="text-xs font-extrabold text-emerald-400">
                      {formatCurrency(c.totalSpent || 0)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] text-slate-400 block">Points</span>
                    <span className="text-xs font-extrabold text-cyan-300 flex items-center justify-center gap-0.5">
                      <Star className="w-3 h-3" />
                      {formatNumber(c.loyaltyPoints || 0)}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {totalPages > 1 && (
          <div className="flex items-center justify-between pt-5 text-xs text-slate-400">
            <span>
              Page {page} of {totalPages}
            </span>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 disabled:opacity-40 text-white font-bold"
              >
                Previous
              </button>
              <button
                type="button"
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 disabled:opacity-40 text-white font-bold"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
    </section>
  );
};
