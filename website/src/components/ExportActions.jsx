import React, { useState } from 'react';
import {
  Download,
  Printer,
  FileText,
  FileSpreadsheet,
  Database,
  CheckCircle2,
  Users,
} from 'lucide-react';
import {
  exportBusinessReportPDF,
  exportCustomersToExcel,
  exportFullBackupExcel,
  exportOrdersToCSV,
  exportOrdersToExcel,
  exportTopItemsToCSV,
  printReportPage,
} from '../utils/exportHelpers';
import { reportsService } from '../services/reportsService';
import { formatNumber } from '../utils/formatters';

export const ExportActions = ({
  analytics = {},
  settings = {},
  periodLabel = 'Selected Period',
}) => {
  const { recentOrders = [], topSellingItems = [] } = analytics;
  const [isExporting, setIsExporting] = useState(false);
  const [statusMessage, setStatusMessage] = useState(null);

  const showToast = (msg) => {
    setStatusMessage(msg);
    setTimeout(() => setStatusMessage(null), 5000);
  };

  const handleFullCloudExcelBackup = async () => {
    try {
      setIsExporting(true);
      const exportPayload = await reportsService.fetchCloudExport();
      const cloudData = exportPayload?.data || exportPayload;
      exportFullBackupExcel({
        customers: cloudData.customers || [],
        orders: cloudData.orders || [],
        settings: cloudData.businessSettings || settings,
      });
      showToast(
        `Full Excel backup downloaded (${formatNumber(
          (cloudData.orders?.length || 0) + (cloudData.customers?.length || 0)
        )} records).`
      );
    } catch (err) {
      showToast(`Backup export failed: ${err.message}`);
    } finally {
      setIsExporting(false);
    }
  };

  const handleCustomersExcel = async () => {
    try {
      setIsExporting(true);
      const res = await reportsService.getCustomers({ page: 1, limit: 200 });
      exportCustomersToExcel(res.customers || []);
      showToast(`Exported ${formatNumber(res.customers?.length || 0)} customer records.`);
    } catch (err) {
      showToast(`Customer export failed: ${err.message}`);
    } finally {
      setIsExporting(false);
    }
  };

  const handleOrdersExcel = async () => {
    try {
      setIsExporting(true);
      const res = await reportsService.getOrders({ period: 'allTime', page: 1, limit: 200 });
      exportOrdersToExcel(res.orders || recentOrders);
      showToast('Orders spreadsheet downloaded (.xlsx).');
    } catch (err) {
      exportOrdersToExcel(recentOrders);
      showToast('Orders spreadsheet downloaded from current period.');
    } finally {
      setIsExporting(false);
    }
  };

  const handleCloudJson = async () => {
    try {
      setIsExporting(true);
      const data = await reportsService.exportMongoDBBackup();
      const total = data?.summary?.totalRecords ?? 'all';
      showToast(`Exported ${formatNumber(total)} cloud records as JSON.`);
    } catch (err) {
      showToast(`JSON export failed: ${err.message}`);
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <section className="mb-12 no-print">
      <div className="cyber-card p-6 rounded-3xl flex flex-col gap-5 border border-white/10">
        <div>
          <h3 className="font-display text-lg font-bold text-white flex items-center gap-2">
            <Download className="w-5 h-5 text-[#FF6D00]" />
            <span>Export Reports & Store Backups</span>
          </h3>
          <p className="text-xs text-slate-400 mt-0.5">
            Download printable PDF summaries, Excel workbooks, or full cloud backups in one click
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5">
          <button
            type="button"
            onClick={() => exportBusinessReportPDF({ analytics, settings, periodLabel })}
            className="p-4 rounded-2xl bg-gradient-to-br from-[#FF6D00] to-[#FF9100] hover:brightness-110 text-white shadow-glow text-left flex items-start gap-3 transition-all"
          >
            <div className="w-9 h-9 rounded-xl bg-black/20 flex items-center justify-center shrink-0">
              <FileText className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xs font-extrabold block">Business Summary (PDF)</span>
              <span className="text-[11px] text-white/85 block mt-0.5">
                Sales KPIs, payment split & top dishes for {periodLabel}
              </span>
            </div>
          </button>

          <button
            type="button"
            onClick={handleOrdersExcel}
            disabled={isExporting}
            className="p-4 rounded-2xl bg-white/[0.04] hover:bg-white/[0.08] text-white border border-white/15 text-left flex items-start gap-3 transition-all disabled:opacity-50"
          >
            <div className="w-9 h-9 rounded-xl bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xs font-extrabold block">Order History (Excel)</span>
              <span className="text-[11px] text-slate-400 block mt-0.5">
                Complete bill list, payment modes & totals (.xlsx)
              </span>
            </div>
          </button>

          <button
            type="button"
            onClick={handleCustomersExcel}
            disabled={isExporting}
            className="p-4 rounded-2xl bg-white/[0.04] hover:bg-white/[0.08] text-white border border-white/15 text-left flex items-start gap-3 transition-all disabled:opacity-50"
          >
            <div className="w-9 h-9 rounded-xl bg-cyan-500/20 text-cyan-300 flex items-center justify-center shrink-0">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xs font-extrabold block">Customer Directory (Excel)</span>
              <span className="text-[11px] text-slate-400 block mt-0.5">
                Phone numbers, visit counts & loyalty points (.xlsx)
              </span>
            </div>
          </button>

          <button
            type="button"
            onClick={handleFullCloudExcelBackup}
            disabled={isExporting}
            className="p-4 rounded-2xl bg-purple-600/25 hover:bg-purple-600/35 text-white border border-purple-500/35 text-left flex items-start gap-3 transition-all disabled:opacity-50"
          >
            <div className="w-9 h-9 rounded-xl bg-purple-500/25 text-purple-300 flex items-center justify-center shrink-0">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xs font-extrabold block">Full Backup (Excel)</span>
              <span className="text-[11px] text-slate-300 block mt-0.5">
                Multi-sheet archive: Orders, Customers & Settings
              </span>
            </div>
          </button>

          <button
            type="button"
            onClick={handleCloudJson}
            disabled={isExporting}
            className="p-4 rounded-2xl bg-emerald-600/20 hover:bg-emerald-600/30 text-white border border-emerald-500/35 text-left flex items-start gap-3 transition-all disabled:opacity-50"
          >
            <div className="w-9 h-9 rounded-xl bg-emerald-500/25 text-emerald-300 flex items-center justify-center shrink-0">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xs font-extrabold block">Raw Cloud Dump (JSON)</span>
              <span className="text-[11px] text-slate-300 block mt-0.5">
                Full MongoDB cloud snapshot for technical restore
              </span>
            </div>
          </button>

          <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/10 flex flex-col justify-between gap-2">
            <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
              Quick CSV & Print
            </span>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => exportOrdersToCSV(recentOrders)}
                className="flex-1 px-2.5 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-slate-200 border border-white/15 text-xs font-bold flex items-center justify-center gap-1"
              >
                <Download className="w-3.5 h-3.5 text-cyan-400" />
                <span>Orders</span>
              </button>
              <button
                type="button"
                onClick={() => exportTopItemsToCSV(topSellingItems)}
                className="flex-1 px-2.5 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-slate-200 border border-white/15 text-xs font-bold flex items-center justify-center gap-1"
              >
                <Download className="w-3.5 h-3.5 text-amber-400" />
                <span>Dishes</span>
              </button>
              <button
                type="button"
                onClick={printReportPage}
                className="px-3 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-white border border-white/15 text-xs font-bold"
                title="Print Current View"
              >
                <Printer className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {statusMessage && (
          <div className="px-4 py-2.5 rounded-xl bg-emerald-500/15 border border-emerald-500/35 text-emerald-300 text-xs font-semibold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>{statusMessage}</span>
          </div>
        )}
      </div>
    </section>
  );
};
