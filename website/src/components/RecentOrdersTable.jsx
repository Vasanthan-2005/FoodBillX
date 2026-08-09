import React, { useState, useMemo } from 'react';
import { Search, Receipt, ArrowUpDown, Eye, CheckCircle, XCircle, CreditCard, Banknote, Smartphone } from 'lucide-react';
import { formatCurrency, formatDate } from '../utils/formatters';

export const RecentOrdersTable = ({ recentOrders = [] }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [paymentFilter, setPaymentFilter] = useState('ALL');
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;

  // Filtered & Search Results
  const filteredOrders = useMemo(() => {
    return recentOrders.filter((order) => {
      const matchesSearch =
        !searchTerm ||
        order.orderNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.customerName.toLowerCase().includes(searchTerm.toLowerCase());

      const matchesPayment =
        paymentFilter === 'ALL' || order.paymentMethod.toUpperCase() === paymentFilter;

      return matchesSearch && matchesPayment;
    });
  }, [recentOrders, searchTerm, paymentFilter]);

  // Pagination
  const totalPages = Math.ceil(filteredOrders.length / itemsPerPage) || 1;
  const paginatedOrders = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return filteredOrders.slice(start, start + itemsPerPage);
  }, [filteredOrders, currentPage]);

  return (
    <div className="glass-card p-6 rounded-3xl mb-8">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <Receipt className="w-5 h-5 text-blue-400" />
            <h2 className="text-lg font-bold text-white tracking-tight">Recent Orders History</h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">Live stream of bills generated from the mobile app</p>
        </div>

        {/* Search & Payment Filters */}
        <div className="flex flex-wrap items-center gap-3">
          {/* Search Box */}
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search bill # or customer..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="bg-slate-900/90 border border-slate-700/80 rounded-xl pl-9 pr-4 py-1.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-[#FF5722] w-56"
            />
          </div>

          {/* Payment Method Filter */}
          <div className="flex items-center gap-1 bg-slate-900/90 p-1 rounded-xl border border-slate-700/80">
            {['ALL', 'CASH', 'UPI', 'CARD'].map((pm) => (
              <button
                key={pm}
                onClick={() => {
                  setPaymentFilter(pm);
                  setCurrentPage(1);
                }}
                className={`px-2.5 py-1 rounded-lg text-[10px] font-bold transition-colors ${
                  paymentFilter === pm ? 'bg-[#FF5722] text-white shadow-sm' : 'text-slate-400 hover:text-white'
                }`}
              >
                {pm}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Orders Table */}
      <div className="overflow-x-auto rounded-2xl border border-slate-800">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-900/80 uppercase font-bold text-[10px] text-slate-400 border-b border-slate-800 sticky top-0">
            <tr>
              <th className="py-3.5 px-4">Bill No</th>
              <th className="py-3.5 px-4">Customer</th>
              <th className="py-3.5 px-4">Dishes</th>
              <th className="py-3.5 px-4">Payment</th>
              <th className="py-3.5 px-4">Total Amount</th>
              <th className="py-3.5 px-4">Status</th>
              <th className="py-3.5 px-4">Date & Time</th>
              <th className="py-3.5 px-4 text-center">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {paginatedOrders.length === 0 ? (
              <tr>
                <td colSpan={8} className="py-8 text-center text-slate-500 text-xs">
                  No orders match your search criteria
                </td>
              </tr>
            ) : (
              paginatedOrders.map((order) => {
                const isRefunded = order.orderStatus === 'refunded';
                return (
                  <tr key={order._id || order.id || order.orderNumber} className="hover:bg-slate-800/40 transition-colors">
                    <td className="py-3.5 px-4 font-black text-[#FF5722]">{order.orderNumber}</td>
                    <td className="py-3.5 px-4 font-medium text-white">{order.customerName || 'Walk-in Customer'}</td>
                    <td className="py-3.5 px-4 max-w-xs truncate text-slate-400">
                      {(order.items || []).map((i) => `${i.name} (${i.quantity}x)`).join(', ')}
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="px-2 py-0.5 rounded-md font-bold text-[10px] bg-blue-500/10 text-blue-400 border border-blue-500/20 uppercase">
                        {order.paymentMethod}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-black text-white">{formatCurrency(order.grandTotal)}</td>
                    <td className="py-3.5 px-4">
                      <span className={`px-2 py-0.5 rounded-md font-bold text-[10px] ${
                        isRefunded ? 'bg-rose-500/10 text-rose-400 border border-rose-500/20' : 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                      }`}>
                        {isRefunded ? 'REFUNDED' : 'COMPLETED'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-slate-400">{formatDate(order.createdAt)}</td>
                    <td className="py-3.5 px-4 text-center">
                      <button
                        onClick={() => setSelectedOrder(order)}
                        className="p-1.5 rounded-lg bg-slate-800 hover:bg-[#FF5722] hover:text-white text-slate-300 transition-colors inline-flex items-center gap-1 font-semibold text-[11px]"
                      >
                        <Eye className="w-3.5 h-3.5" />
                        <span>View</span>
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination Footer */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between pt-4 text-xs text-slate-400">
          <span>Showing page {currentPage} of {totalPages}</span>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 disabled:opacity-40 text-white font-bold"
            >
              Previous
            </button>
            <button
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 disabled:opacity-40 text-white font-bold"
            >
              Next
            </button>
          </div>
        </div>
      )}

      {/* Order Receipt Modal */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fadeIn">
          <div className="glass-panel w-full max-w-md p-6 rounded-3xl border border-slate-700 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <div className="flex items-center gap-2">
                <Receipt className="w-5 h-5 text-[#FF5722]" />
                <h3 className="text-base font-bold text-white">Bill Receipt {selectedOrder.orderNumber}</h3>
              </div>
              <button onClick={() => setSelectedOrder(null)} className="text-slate-400 hover:text-white font-bold">
                ✕
              </button>
            </div>

            <div className="text-center py-2 bg-slate-900/60 rounded-xl border border-slate-800">
              <h4 className="font-extrabold text-white text-base">HMB Bills - Honeymoon Biryani</h4>
              <p className="text-xs text-slate-400">{formatDate(selectedOrder.createdAt)}</p>
            </div>

            <div className="space-y-1.5 text-xs text-slate-300">
              <div className="flex justify-between">
                <span>Customer:</span>
                <span className="font-bold text-white">{selectedOrder.customerName || 'Walk-in Customer'}</span>
              </div>
              {selectedOrder.customerPhone && (
                <div className="flex justify-between">
                  <span>Phone:</span>
                  <span className="font-bold text-white">{selectedOrder.customerPhone}</span>
                </div>
              )}
              <div className="flex justify-between">
                <span>Payment Method:</span>
                <span className="font-bold text-blue-400 uppercase">{selectedOrder.paymentMethod}</span>
              </div>
            </div>

            <div className="border-t border-b border-slate-800 py-3 space-y-2 text-xs">
              <span className="font-bold text-slate-400 block uppercase tracking-wider text-[10px]">Items Billed</span>
              {(selectedOrder.items || []).map((item, idx) => (
                <div key={idx} className="flex justify-between items-center text-white">
                  <span>{item.name} × {item.quantity}</span>
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
              {selectedOrder.gstAmount > 0 && (
                <div className="flex justify-between text-slate-400">
                  <span>GST Tax:</span>
                  <span>{formatCurrency(selectedOrder.gstAmount)}</span>
                </div>
              )}
              <div className="flex justify-between items-baseline pt-2 border-t border-slate-800 text-sm font-black text-white">
                <span>Grand Total:</span>
                <span className="text-[#FF5722] text-lg">{formatCurrency(selectedOrder.grandTotal)}</span>
              </div>
            </div>

            <div className="pt-2">
              <button
                onClick={() => setSelectedOrder(null)}
                className="w-full py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs"
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
