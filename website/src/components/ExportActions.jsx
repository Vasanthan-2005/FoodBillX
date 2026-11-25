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
      showToast('Orders workbook downloaded (.xlsx).');
    } catch (err) {
      exportOrdersToExcel(recentOrders);
      showToast('Orders workbook downloaded from current period.');
    } finally {
      setIsExporting(false);
    }
  };

  const handleCloudJson = async () => {
    try {
      setIsExporting(true);
      const data = await reportsService.exportMongoDBBackup();
      const total = data?.summary?.totalRecords ?? 'all';
      showToast(`Exported ${formatNumber(total)} cloud documents as JSON.`);
    } catch (err) {
      showToast(`JSON export failed: ${err.message}`);
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <section className="max-w-7xl mx-auto px-4 md:px-8 mb-12 no-print">
      <div className="cyber-card p-6 rounded-3xl flex flex-col gap-5 border border-white/10">
        <div>
          <h3 className="font-display text-base font-bold text-white flex items-center gap-2">
            <Download className="w-5 h-5 text-[#FF6D00]" />
            <span>Export Vault & Cloud Backup</span>
          </h3>
          <p className="text-xs text-slate-400 mt-0.5">
            Download Business Reports (PDF), Customer Data (Excel), Order Data (Excel/CSV), or Full Cloud Backups
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          <button
            type="button"
            onClick={() => exportBusinessReportPDF({ analytics, settings, periodLabel })}
            className="px-4 py-3 rounded-2xl bg-gradient-to-r from-[#FF6D00] to-[#FF9100] hover:brightness-110 text-white shadow-glow text-xs font-bold flex items-center justify-center gap-2 transition-all"
          >
            <FileText className="w-4 h-4" />
            <span>Business Report (PDF)</span>
          </button>

          <button
            type="button"
            onClick={handleOrdersExcel}
            disabled={isExporting}
            className="px-4 py-3 rounded-2xl bg-white/5 hover:bg-white/10 text-white border border-white/15 text-xs font-bold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-400" />
            <span>Order Data (Excel)</span>
          </button>

          <button
            type="button"
            onClick={handleCustomersExcel}
            disabled={isExporting}
            className="px-4 py-3 rounded-2xl bg-white/5 hover:bg-white/10 text-white border border-white/15 text-xs font-bold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
          >
            <Users className="w-4 h-4 text-cyan-400" />
            <span>Customer Data (Excel)</span>
          </button>

          <button
            type="button"
            onClick={handleFullCloudExcelBackup}
            disabled={isExporting}
            className="px-4 py-3 rounded-2xl bg-purple-600/80 hover:bg-purple-500 text-white shadow-lg shadow-purple-600/20 text-xs font-bold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
          >
            <FileSpreadsheet className="w-4 h-4" />
            <span>Full Cloud Backup (Excel)</span>
          </button>

          <button
            type="button"
            onClick={handleCloudJson}
            disabled={isExporting}
            className="px-4 py-3 rounded-2xl bg-emerald-600/80 hover:bg-emerald-500 text-white text-xs font-bold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
          >
            <Database className="w-4 h-4" />
            <span>MongoDB Dump (JSON)</span>
          </button>

          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => exportOrdersToCSV(recentOrders)}
              className="flex-1 px-3 py-3 rounded-2xl bg-white/5 hover:bg-white/10 text-slate-200 border border-white/15 text-xs font-bold flex items-center justify-center gap-1.5"
            >
              <Download className="w-3.5 h-3.5 text-cyan-400" />
              <span>Orders CSV</span>
            </button>
            <button
              type="button"
              onClick={() => exportTopItemsToCSV(topSellingItems)}
              className="flex-1 px-3 py-3 rounded-2xl bg-white/5 hover:bg-white/10 text-slate-200 border border-white/15 text-xs font-bold flex items-center justify-center gap-1.5"
            >
              <Download className="w-3.5 h-3.5 text-amber-400" />
              <span>Dishes CSV</span>
            </button>
            <button
              type="button"
              onClick={printReportPage}
              className="px-3.5 py-3 rounded-2xl bg-white/5 hover:bg-white/10 text-white border border-white/15 text-xs font-bold"
              title="Print Page"
            >
              <Printer className="w-4 h-4" />
            </button>
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
