import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Search, Receipt, Eye, Trash2 } from 'lucide-react';
import { reportsService } from '../services/reportsService';
import { formatCurrency, formatDate, formatNumber } from '../utils/formatters';

export const RecentOrdersTable = ({ filterParams = {}, settings = {}, fallbackOrders = [] }) => {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [paymentFilter, setPaymentFilter] = useState('ALL');
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);

  const shopName = settings?.businessName || 'HMB Bills';

  const { data } = useQuery({
    queryKey: ['orders', filterParams, searchTerm, paymentFilter, currentPage],
    queryFn: () =>
      reportsService.getOrders({
        ...filterParams,
        search: searchTerm,
        paymentMethod: paymentFilter,
        page: currentPage,
        limit: 12,
      }),
    staleTime: 5000,
  });

  const deleteMutation = useMutation({
    mutationFn: (orderId) => reportsService.deleteOrder(orderId),
    onSuccess: () => {
      setSelectedOrder(null);
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['analytics'] });
      queryClient.invalidateQueries({ queryKey: ['customers'] });
      queryClient.invalidateQueries({ queryKey: ['syncStatus'] });
    },
  });

  const orders = data?.orders || fallbackOrders;
  const totalPages = data?.totalPages || 1;
  const totalOrders = data?.total ?? orders.length;

  const handleDeleteOrder = (order) => {
    const id = order._id || order.id;
    if (!id) return;
    if (window.confirm(`Delete bill ${order.orderNumber} permanently and recalculate customer totals?`)) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <div className="cyber-card p-6 rounded-3xl mb-8">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Receipt className="w-5 h-5 text-cyan-400" />
            <h2 className="font-display text-lg font-bold text-white tracking-tight">
              Orders Terminal ({formatNumber(totalOrders)})
            </h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            Synced itemized bills with cloud deletion & customer total recalculation
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search bill #, customer or phone..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="bg-black/50 border border-white/15 rounded-xl pl-9 pr-4 py-1.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-[#FF6D00] w-60"
            />
          </div>

          <div className="flex items-center gap-1 bg-black/50 p-1 rounded-xl border border-white/15">
            {['ALL', 'CASH', 'UPI', 'CARD', 'WALLET'].map((pm) => (
              <button
                key={pm}
                type="button"
                onClick={() => {
                  setPaymentFilter(pm);
                  setCurrentPage(1);
                }}
                className={`px-2.5 py-1 rounded-lg text-[10px] font-bold transition-colors ${
                  paymentFilter === pm
                    ? 'bg-[#FF6D00] text-white'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                {pm}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="overflow-x-auto rounded-2xl border border-white/10">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-white/5 uppercase font-mono font-bold text-[10px] text-slate-400 border-b border-white/10">
            <tr>
              <th className="py-3.5 px-4">Bill No</th>
              <th className="py-3.5 px-4">Customer</th>
              <th className="py-3.5 px-4">Items</th>
              <th className="py-3.5 px-4">Payment</th>
              <th className="py-3.5 px-4">Grand Total</th>
              <th className="py-3.5 px-4">Status</th>
              <th className="py-3.5 px-4">Date & Time</th>
              <th className="py-3.5 px-4 text-center">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {orders.length === 0 ? (
              <tr>
                <td colSpan={8} className="py-10 text-center text-slate-500 text-xs">
                  No orders found for the current filters
                </td>
              </tr>
            ) : (
              orders.map((order) => {
                const status = (order.orderStatus || 'completed').toUpperCase();
                return (
                  <tr
                    key={order._id || order.id || order.orderNumber}
                    className="hover:bg-white/5 transition-colors"
                  >
                    <td className="py-3.5 px-4 font-black text-[#FF8F00]">
                      {order.orderNumber}
                    </td>
                    <td className="py-3.5 px-4 font-medium text-white">
                      {order.customerName || 'Walk-in Customer'}
                    </td>
                    <td className="py-3.5 px-4 max-w-xs truncate text-slate-400">
                      {(order.items || [])
                        .map((i) => `${i.name} (${i.quantity}x)`)
                        .join(', ')}
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="px-2 py-0.5 rounded-md font-bold text-[10px] bg-cyan-500/15 text-cyan-300 border border-cyan-500/30 uppercase">
                        {order.paymentMethod}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-black text-white">
                      {formatCurrency(order.grandTotal)}
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`px-2 py-0.5 rounded-md font-bold text-[10px] ${
                          status === 'REFUNDED'
                            ? 'bg-rose-500/15 text-rose-400 border border-rose-500/25'
                            : 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/25'
                        }`}
                      >
                        {status}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-slate-400">{formatDate(order.createdAt)}</td>
                    <td className="py-3.5 px-4 text-center">
                      <div className="inline-flex items-center gap-1.5">
                        <button
                          type="button"
                          onClick={() => setSelectedOrder(order)}
                          className="p-1.5 rounded-lg bg-white/5 hover:bg-[#FF6D00] hover:text-white text-slate-300 transition-colors inline-flex items-center gap-1 font-semibold text-[11px]"
                        >
                          <Eye className="w-3.5 h-3.5" />
                          <span>View</span>
                        </button>
                        {order._id && (
                          <button
                            type="button"
                            onClick={() => handleDeleteOrder(order)}
                            disabled={deleteMutation.isPending}
                            className="p-1.5 rounded-lg bg-rose-500/10 hover:bg-rose-600 text-rose-400 hover:text-white transition-colors"
                            title="Delete Order"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between pt-4 text-xs text-slate-400">
          <span>
            Page {currentPage} of {totalPages}
          </span>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 disabled:opacity-40 text-white font-bold"
            >
              Previous
            </button>
            <button
              type="button"
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 disabled:opacity-40 text-white font-bold"
            >
              Next
            </button>
          </div>
        </div>
      )}

      {/* Bill Receipt Modal (No GST, aligned with app) */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md">
          <div className="cyber-card w-full max-w-md p-6 rounded-3xl border border-white/15 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-white/10 pb-3">
              <div className="flex items-center gap-2">
                <Receipt className="w-5 h-5 text-[#FF6D00]" />
                <h3 className="text-base font-bold text-white">
                  Bill Receipt {selectedOrder.orderNumber}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setSelectedOrder(null)}
                className="text-slate-400 hover:text-white font-bold"
              >
                ✕
              </button>
            </div>

            <div className="text-center py-2.5 bg-white/5 rounded-xl border border-white/10">
              <h4 className="font-display font-extrabold text-white text-base">{shopName}</h4>
              <p className="text-xs text-slate-400">{formatDate(selectedOrder.createdAt)}</p>
            </div>

            <div className="space-y-1.5 text-xs text-slate-300">
              <div className="flex justify-between">
                <span>Customer:</span>
                <span className="font-bold text-white">
                  {selectedOrder.customerName || 'Walk-in Customer'}
                </span>
              </div>
              {selectedOrder.customerPhone && (
                <div className="flex justify-between">
                  <span>Phone:</span>
                  <span className="font-bold text-white">{selectedOrder.customerPhone}</span>
                </div>
              )}
              <div className="flex justify-between">
                <span>Payment Mode:</span>
                <span className="font-bold text-cyan-300 uppercase">
                  {selectedOrder.paymentMethod}
                </span>
              </div>
            </div>

            <div className="border-t border-b border-white/10 py-3 space-y-2 text-xs">
              <span className="font-mono font-bold text-slate-400 block uppercase tracking-wider text-[10px]">
                Items Billed
              </span>
              {(selectedOrder.items || []).map((item, idx) => (
                <div key={idx} className="flex justify-between items-center text-white">
                  <span>
                    {item.name} × {item.quantity}
                  </span>
                  <span className="font-bold">{formatCurrency(item.subtotal)}</span>
                </div>
              ))}
            </div>

            <div className="space-y-1.5 text-xs">
              <div className="flex justify-between text-slate-400">
                <span>Subtotal:</span>
                <span>{formatCurrency(selectedOrder.subtotal)}</span>
              </div>
              {selectedOrder.discountAmount > 0 && (
                <div className="flex justify-between text-emerald-400">
                  <span>Discount:</span>
                  <span>- {formatCurrency(selectedOrder.discountAmount)}</span>
                </div>
              )}
              {selectedOrder.serviceChargeAmount > 0 && (
                <div className="flex justify-between text-cyan-300">
                  <span>Service Charge:</span>
                  <span>+ {formatCurrency(selectedOrder.serviceChargeAmount)}</span>
                </div>
              )}
              <div className="flex justify-between items-baseline pt-2 border-t border-white/10 text-sm font-black text-white">
                <span>Grand Total:</span>
                <span className="text-[#FF8F00] text-lg">
                  {formatCurrency(selectedOrder.grandTotal)}
                </span>
              </div>
            </div>

            <div className="flex items-center gap-2 pt-2">
              {selectedOrder._id && (
                <button
                  type="button"
                  onClick={() => handleDeleteOrder(selectedOrder)}
                  disabled={deleteMutation.isPending}
                  className="px-4 py-2.5 rounded-xl bg-rose-600/80 hover:bg-rose-600 text-white font-bold text-xs flex items-center gap-1.5"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  <span>Delete Order</span>
                </button>
              )}
              <button
                type="button"
                onClick={() => setSelectedOrder(null)}
                className="flex-1 py-2.5 rounded-xl bg-white/10 hover:bg-white/15 text-white font-bold text-xs"
              >
                Close Receipt
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
